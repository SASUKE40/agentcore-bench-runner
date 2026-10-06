"""Reading a Harbor-format task directory.

Shared by the AgentCore client (bench.py) and the Runta client (runta_bench.py): both
need the same instruction, timeouts, working directory and tests archive, and neither
modifies the task files.
"""
import io
import os
import re
import tarfile
import tomllib


def load_task(task_dir):
    """Read a Harbor task: instruction.md, task.toml, tests/."""
    cfg = tomllib.load(open(os.path.join(task_dir, "task.toml"), "rb"))
    instruction = open(os.path.join(task_dir, "instruction.md")).read()
    workdir = cfg.get("environment", {}).get("workdir")
    if not workdir:  # fall back to the last WORKDIR of environment/Dockerfile
        dockerfile = os.path.join(task_dir, "environment", "Dockerfile")
        if os.path.exists(dockerfile):
            found = re.findall(r"^\s*WORKDIR\s+(\S+)", open(dockerfile).read(), re.M)
            workdir = found[-1] if found else None
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w:gz") as tar:
        tests = os.path.join(task_dir, "tests")
        for name in sorted(os.listdir(tests)):
            tar.add(os.path.join(tests, name), arcname=name)
    return {
        "name": os.path.basename(os.path.normpath(task_dir)),
        "instruction": instruction,
        "tests_tgz": buf.getvalue(),
        "workdir": workdir or "/",
        "agent_timeout": int(cfg.get("agent", {}).get("timeout_sec", 3600)),
        "verifier_timeout": int(cfg.get("verifier", {}).get("timeout_sec", 900)),
        "cpus": int(cfg.get("environment", {}).get("cpus", 2)),
        "memory_mb": int(cfg.get("environment", {}).get("memory_mb", 4096)),
        "docker_image": cfg.get("environment", {}).get("docker_image"),
    }
