#!/usr/bin/env python3
"""Run Harbor-format tasks on Runta cloud runtimes.

A Runta alternative to bench.py (Amazon Bedrock AgentCore). The task format, the two
agent scripts and the summary.json shape are unchanged; only the sandbox differs:

    bench.py        Harness / Agent Runtime   image from ECR     results via S3
    runta_bench.py  Runta runtime             private Runtime Image   results via runta cp

Because `runta exec` is cheap and a runtime has no session lifetime cap, this client
orchestrates the trial directly instead of handing it off to the sandbox: it stages the
task, starts runner/runta/trial.sh in the background, polls for summary.json, copies the
results out and removes the runtime.

    python runner/runta_bench.py build tasks/fix-git
    python runner/runta_bench.py run tasks/fix-git
    python runner/runta_bench.py run tasks/* --jobs 3 --out out-runta
    python runner/runta_bench.py cleanup
"""
import argparse
import concurrent.futures
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
import uuid
from urllib.parse import urlparse

from harbor_task import load_task

HERE = os.path.dirname(os.path.abspath(__file__))
PREFIX = "bench-"  # name prefix of images and runtimes created by this tool
# The agent never holds the real provider credential: Runta's egress proxy swaps this
# placeholder for the secret on the way out (see `runta secret rule set` below).
STUB = "runta-secret-stub"
DEFAULT_PROVIDER = "OpenAI API"
# Runta model-provider protocol -> Codex wire_api.
WIRE_API = {"openai_responses": "responses", "openai_chat": "chat"}


# --------------------------------------------------------------------------- CLI

def runta(*args, timeout=900):
    """Run one runta command and return its parsed JSON."""
    p = subprocess.run(["runta", *args], capture_output=True, text=True, timeout=timeout)
    # Some commands print a human-readable note before the JSON document.
    start = p.stdout.find("{")
    if start < 0:
        raise RuntimeError(f"runta {' '.join(args)}: no JSON output\n{p.stdout}{p.stderr}")
    out = json.loads(p.stdout[start:])
    if "error" in out:
        raise RuntimeError(f"runta {args[0]}: {out['error'].get('message', out['error'])}")
    return out


def sh(runtime, script, timeout=900):
    """Run a shell snippet inside a runtime; returns (exit_status, stdout, stderr)."""
    out = runta("exec", runtime, "--", "sh", "-lc", script, timeout=timeout)
    return out["status"], out["stdout"], out["stderr"]


# --------------------------------------------------------------------------- resources

def find_image(name):
    for img in runta("image", "ls").get("images") or []:
        if img.get("name") == name:
            # `image ls` reports the already-prefixed id; `image build` names it separately.
            return img.get("runtime_image_id") or img["id"]
    return None


def recipe(task_dir, task, tmp, from_dockerfile):
    """Choose the Dockerfile to build from, and describe the choice.

    `runta image build` uploads the Dockerfile only -- there is no build context -- so a
    task whose environment/Dockerfile COPYs files cannot be built that way. Preferring
    the task's published [environment].docker_image avoids the problem entirely and
    matches what the AgentCore Instances mode already does (scripts/build_instances.sh).
    """
    local = os.path.join(task_dir, "environment", "Dockerfile")
    if not from_dockerfile and task.get("docker_image"):
        path = os.path.join(tmp, "Dockerfile")
        with open(path, "w") as f:
            f.write(f"FROM {task['docker_image']}\n")
        return path, f"FROM {task['docker_image']}"
    if not os.path.exists(local):
        raise RuntimeError(f"{task_dir} has neither environment/Dockerfile nor docker_image")
    if re.search(r"^\s*(COPY|ADD)\s", open(local).read(), re.M):
        raise RuntimeError(
            f"{local} uses COPY/ADD, but `runta image build` uploads no build context. "
            "Use the task's [environment].docker_image (the default) instead.")
    return local, local


def ensure_image(task_dir, task, rebuild=False, from_dockerfile=False, log=print):
    """Build the task environment into a private Runtime Image, once.

    Images are keyed by task name and reused across runs, like the ECR images in the
    AgentCore flow. A build takes a few minutes; a run from a built image takes seconds.
    """
    name = PREFIX + task["name"]
    if not rebuild:
        existing = find_image(name)
        if existing:
            log(f"image: reusing {name} ({existing})")
            return existing
    with tempfile.TemporaryDirectory() as tmp:
        dockerfile, source = recipe(task_dir, task, tmp, from_dockerfile)
        log(f"image: building {name} from {source} (a few minutes)")
        t0 = time.time()
        build = runta("image", "build", "--file", dockerfile, "--name", name,
                      "--arch", "x86_64", timeout=3600)["build"]
    if build.get("status") != "succeeded":
        raise RuntimeError(f"image build {build.get('status')}: {build.get('safe_error_code')}")
    log(f"image: built {name} in {time.time() - t0:.0f}s")
    return build["runtime_image_id"]


def find_provider(name):
    """Look up an organization-managed model provider by display name or ID."""
    providers = runta("model-provider", "ls").get("model_providers") or []
    for p in providers:
        if name.lower() in (p["display_name"].lower(), p["id"]):
            return p
    names = ", ".join(repr(p["display_name"]) for p in providers)
    raise SystemExit(f"no model provider matching {name!r}; available: {names}")


# --------------------------------------------------------------------------- trial

def stage(runtime, task, run_id, model, provider, log=print):
    """Put the task, the agent scripts and the trial config into /bench, in one copy."""
    base = provider["base_url"]
    env = {
        "BENCH_RUN_ID": run_id,
        "BENCH_TASK": task["name"],
        "BENCH_MODEL": model,
        "BENCH_WORKDIR": task["workdir"],
        "BENCH_AGENT_TIMEOUT": str(task["agent_timeout"]),
        "BENCH_VERIFIER_TIMEOUT": str(task["verifier_timeout"]),
        "BENCH_API_BASE": base.rstrip("/"),
        "BENCH_WIRE_API": WIRE_API.get(provider["protocol"], "responses"),
        "BENCH_API_KEY_STUB": STUB,
    }
    with tempfile.TemporaryDirectory() as tmp:
        bench = os.path.join(tmp, "bench")
        os.makedirs(bench)
        with open(os.path.join(bench, "env"), "w") as f:
            for k, v in env.items():
                f.write(f'{k}="{v}"\n')
        with open(os.path.join(bench, "instruction.md"), "w") as f:
            f.write(task["instruction"])
        with open(os.path.join(bench, "tests.tgz"), "wb") as f:
            f.write(task["tests_tgz"])
        for script in ("install.sh", "agent.sh", "trial.sh"):
            shutil.copy(os.path.join(HERE, "runta", script), bench)
        bundle = os.path.join(tmp, "bench.tgz")
        # COPYFILE_DISABLE: keep macOS from adding ._* AppleDouble members to the archive.
        subprocess.run(["tar", "-czf", bundle, "-C", bench, "."], check=True,
                       env={**os.environ, "COPYFILE_DISABLE": "1"})
        sh(runtime, "mkdir -p /bench /logs/agent /logs/verifier")
        runta("cp", bundle, f"{runtime}:/bench/bench.tgz", timeout=600)
    status, out, err = sh(runtime, "tar --no-same-owner -xzf /bench/bench.tgz -C /bench")
    if status != 0:
        raise RuntimeError(f"could not unpack the trial bundle: {err or out}")
    log(f"staged /bench (model {model} via {provider['display_name']})")


def wait_for_summary(runtime, deadline, log=print):
    """Poll until trial.sh has written summary.json, reporting phase changes."""
    phase = None
    while time.time() < deadline:
        _, out, _ = sh(runtime, "cat /bench/summary.json 2>/dev/null")
        if out.strip():
            return json.loads(out)
        _, status, _ = sh(runtime, "cat /bench/status.json 2>/dev/null")
        try:
            now = json.loads(status)["phase"]
        except (ValueError, KeyError):
            now = None
        if now != phase:
            phase = now
            log(f"phase: {phase}")
        time.sleep(10)
    raise RuntimeError("timed out waiting for the trial to finish")


def collect(runtime, out_dir):
    """Copy /bench out of the runtime, flattened, without the staging archive."""
    runta("cp", f"{runtime}:/bench", out_dir, timeout=900)
    pulled = os.path.join(out_dir, "bench")  # runta cp writes the directory itself
    if os.path.isdir(pulled):
        for name in os.listdir(pulled):
            shutil.move(os.path.join(pulled, name), os.path.join(out_dir, name))
        os.rmdir(pulled)
    for name in ("bench.tgz", "tests.tgz"):
        if os.path.exists(os.path.join(out_dir, name)):
            os.remove(os.path.join(out_dir, name))


def run_one(task_dir, args, log=print):
    task = load_task(task_dir)
    provider = find_provider(args.provider)
    model = args.model or provider["default_model"]
    image = ensure_image(task_dir, task, args.rebuild, args.from_dockerfile, log)

    run_id = f"{time.strftime('%Y%m%d-%H%M%S')}-{uuid.uuid4().hex[:6]}"
    runtime = f"{PREFIX}{task['name']}-{uuid.uuid4().hex[:6]}"
    out_dir = os.path.join(args.out, task["name"], run_id)
    os.makedirs(out_dir, exist_ok=True)

    log(f"runtime: creating {runtime}")
    t0 = time.time()
    runta("run", "--name", runtime, "--image", image,
          "--cpus", str(args.cpus or task["cpus"]),
          "--memory", str(args.memory or task["memory_mb"]),
          "--wait", "--timeout-secs", "300", timeout=600)
    t_start = time.time() - t0
    log(f"runtime: ready in {t_start:.0f}s")
    try:
        # Credential injection: the runtime sends STUB, the proxy substitutes the secret.
        runta("secret", "rule", "set", runtime,
              "--secret", provider["secret_id"],
              "--host", urlparse(provider["base_url"]).netloc,
              "--path", "*",
              "--header", provider["header_name"],
              "--template", provider["value_template"])
        stage(runtime, task, run_id, model, provider, log)

        t0 = time.time()
        status, out, err = sh(runtime, "bash /bench/install.sh 2>&1", timeout=1800)
        if status != 0:
            raise RuntimeError(f"agent install failed: {out or err}")
        versions = out.strip().splitlines()  # install.sh ends by echoing what it installed
        log(f"installed agent in {time.time() - t0:.0f}s"
            + (f": {versions[-1]}" if versions else ""))

        sh(runtime, "nohup bash /bench/trial.sh > /dev/null 2>&1 & echo started")
        log("trial: running")
        budget = task["agent_timeout"] + task["verifier_timeout"] + 900
        summary = wait_for_summary(runtime, time.time() + budget, log)

        collect(runtime, out_dir)
        summary["runtime_start_s"] = round(t_start, 1)
        summary["image_id"] = image
        with open(os.path.join(out_dir, "summary.json"), "w") as f:
            json.dump(summary, f, indent=2)
        log(f"reward={summary.get('reward')} -> {out_dir}")
        return summary
    finally:
        if args.keep:
            log(f"runtime: keeping {runtime} (--keep)")
        else:
            runta("rm", runtime, timeout=300)
            log(f"runtime: removed {runtime}")


# --------------------------------------------------------------------------- commands

def cmd_build(args):
    for task_dir in args.tasks:
        print(ensure_image(task_dir, load_task(task_dir), args.rebuild, args.from_dockerfile))


def cmd_run(args):
    os.makedirs(args.out, exist_ok=True)
    results = {}

    def one(task_dir):
        name = os.path.basename(os.path.normpath(task_dir))

        def log(msg):
            print(f"[{name}] {msg}", flush=True)
        try:
            return run_one(task_dir, args, log)
        except Exception as exc:  # one task failing must not stop the batch
            log(f"FAILED: {exc}")
            return {"task": name, "reward": None, "error": str(exc)}

    if args.jobs > 1 and len(args.tasks) > 1:
        with concurrent.futures.ThreadPoolExecutor(args.jobs) as pool:
            for task_dir, summary in zip(args.tasks, pool.map(one, args.tasks)):
                results[task_dir] = summary
    else:
        for task_dir in args.tasks:
            results[task_dir] = one(task_dir)

    with open(os.path.join(args.out, "results.jsonl"), "w") as f:
        for summary in results.values():
            f.write(json.dumps(summary) + "\n")
    print("\ntask                             reward  agent_s  verifier_s  error")
    for task_dir, s in results.items():
        t = s.get("timings_s") or {}
        print(f"{os.path.basename(os.path.normpath(task_dir)):32} "
              f"{str(s.get('reward')):>6}  {str(t.get('agent')):>7}  {str(t.get('verifier')):>10}  "
              f"{s.get('error') or ''}")
    rewards = [s.get("reward") for s in results.values()]
    scored = [r for r in rewards if isinstance(r, (int, float))]
    print(f"\nsolved {sum(1 for r in scored if r)}/{len(rewards)}")
    return 0 if len(scored) == len(rewards) else 1


def cmd_cleanup(args):
    """Remove the runtimes, and optionally the images, that this tool created."""
    for rt in runta("ps", "-a").get("runtimes") or []:
        # `ps` reports `name`; `run` and `inspect` call the same field `display_name`.
        name = rt.get("name") or rt.get("display_name") or ""
        if name.startswith(PREFIX):
            runta("rm", name, timeout=300)
            print(f"removed runtime {name}")
    if args.images:
        for img in runta("image", "ls").get("images") or []:
            if img.get("name", "").startswith(PREFIX):
                runta("image", "delete", img["id"], timeout=300)
                print(f"removed image {img['name']}")


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)

    dockerfile_help = ("build environment/Dockerfile instead of the task's docker_image; "
                       "only works if it has no COPY/ADD (no build context is uploaded)")
    b = sub.add_parser("build", help="build the Runtime Image for one or more tasks")
    b.add_argument("tasks", nargs="+")
    b.add_argument("--rebuild", action="store_true")
    b.add_argument("--from-dockerfile", action="store_true", help=dockerfile_help)
    b.set_defaults(func=cmd_build)

    r = sub.add_parser("run", help="run one trial per task and fetch the results")
    r.add_argument("tasks", nargs="+")
    r.add_argument("--provider", default=DEFAULT_PROVIDER,
                   help=f"Runta model provider name or ID (default: {DEFAULT_PROVIDER})")
    r.add_argument("--model", help="model id (default: the provider's default model)")
    r.add_argument("--cpus", type=int, help="override the task's vCPU request")
    r.add_argument("--memory", type=int, help="override the task's memory request (MiB)")
    r.add_argument("--out", default="out-runta")
    r.add_argument("--jobs", type=int, default=1, help="tasks to run at the same time")
    r.add_argument("--rebuild", action="store_true")
    r.add_argument("--from-dockerfile", action="store_true", help=dockerfile_help)
    r.add_argument("--keep", action="store_true", help="do not remove the runtime")
    r.set_defaults(func=cmd_run)

    c = sub.add_parser("cleanup", help="remove runtimes created by this tool")
    c.add_argument("--images", action="store_true", help="also delete the built images")
    c.set_defaults(func=cmd_cleanup)

    args = ap.parse_args()
    sys.exit(args.func(args) or 0)


if __name__ == "__main__":
    main()
