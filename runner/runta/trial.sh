#!/bin/bash
# Runs one trial inside a Runta runtime, start to finish:
#   agent (foreground, waits for it to exit) -> unpack tests -> tests/test.sh
#   -> write summary.json
# Started in the background by `runta_bench.py run`; configuration comes from /bench/env.
# Unlike the AgentCore trial.sh there is no S3 upload and no self-stop: results stay in
# /bench and the client pulls them with `runta cp`, then removes the runtime.
set -u
exec >> /bench/trial.log 2>&1
. /bench/env
export PATH=/opt/bench-node/bin:$PATH
# GNU tar cannot restore archive owners without CAP_CHOWN.
export TAR_OPTIONS=--no-same-owner
cd /bench

now() { date +%s; }
json_str() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
free_mb() { df -Pm / 2>/dev/null | awk 'NR==2 {print $4}'; }

DISK_START=$(free_mb)
T0=$(now); AGENT_EXIT=""; VERIFIER_EXIT=""; REWARD=""; ERROR=""

write_status() {  # write_status <phase>
  printf '{"run_id":"%s","phase":"%s","updated":"%s"}\n' \
    "$BENCH_RUN_ID" "$1" "$(date -u +%FT%TZ)" > /bench/status.json
}

finish() {
  DISK_END=$(free_mb)
  T_END=$(now)
  [ -f /logs/verifier/reward.json ] && REWARD_JSON=$(cat /logs/verifier/reward.json) || REWARD_JSON=null
  [ -f /logs/verifier/reward.txt ] && REWARD=$(tr -d ' \n' < /logs/verifier/reward.txt)
  cp -f /logs/verifier/reward.txt /logs/verifier/reward.json /logs/verifier/ctrf.json /bench/ 2>/dev/null
  # Written last: its presence means "done".
  cat > /bench/summary.json <<EOF
{
  "run_id": "$BENCH_RUN_ID",
  "task": "$BENCH_TASK",
  "mode": "runta",
  "model": "$BENCH_MODEL",
  "reward": ${REWARD:-null},
  "reward_json": $REWARD_JSON,
  "agent_exit": ${AGENT_EXIT:-null},
  "verifier_exit": ${VERIFIER_EXIT:-null},
  "error": "$(json_str "$ERROR")",
  "disk_free_mb": {"start": ${DISK_START:-null}, "end": ${DISK_END:-null}},
  "timings_s": {"agent": ${T_AGENT:-null}, "verifier": ${T_VERIFIER:-null}, "total": $((T_END - T0))},
  "finished": "$(date -u +%FT%TZ)"
}
EOF
}
trap finish EXIT

write_status agent
mkdir -p /logs/agent /logs/verifier
cd "$BENCH_WORKDIR" 2>/dev/null || cd /
A0=$(now)
timeout "$BENCH_AGENT_TIMEOUT" bash /bench/agent.sh > /bench/agent.log 2>&1
AGENT_EXIT=$?; T_AGENT=$(( $(now) - A0 ))
[ "$AGENT_EXIT" = 124 ] && ERROR="agent timed out after ${BENCH_AGENT_TIMEOUT}s"

# Tests are unpacked only now, after the agent has exited.
write_status verifier
if mkdir -p /tests && tar -xzf /bench/tests.tgz -C /tests; then
  cd "$BENCH_WORKDIR" 2>/dev/null || cd /
  V0=$(now)
  timeout "$BENCH_VERIFIER_TIMEOUT" bash /tests/test.sh > /bench/verifier.log 2>&1
  VERIFIER_EXIT=$?; T_VERIFIER=$(( $(now) - V0 ))
else
  ERROR="${ERROR:+$ERROR; }could not unpack tests"
fi
write_status done
