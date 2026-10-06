# Runs the agent once, headless, in the foreground; returns the agent's exit code.
# Example agent: Codex CLI against a Runta managed model provider. To use another agent,
# replace the install step in install.sh and the command below; keep reading
# /bench/instruction.md.
. /bench/env
export PATH=/opt/bench-node/bin:$PATH

# The real provider credential is never in the runtime. Runta's egress proxy rewrites the
# Authorization header on the way out, so the agent only ever holds this stub.
export OPENAI_API_KEY="$BENCH_API_KEY_STUB"
export TAR_OPTIONS=--no-same-owner

# Point Codex at the Runta-managed provider rather than its built-in default, so the
# base URL and wire protocol come from `runta model-provider ls`.
mkdir -p /root/.codex
cat > /root/.codex/config.toml <<EOF
model = "$BENCH_MODEL"
model_provider = "runta"
approval_policy = "never"
sandbox_mode = "danger-full-access"

[model_providers.runta]
name = "runta"
base_url = "$BENCH_API_BASE"
env_key = "OPENAI_API_KEY"
wire_api = "$BENCH_WIRE_API"
EOF

exec codex exec --dangerously-bypass-approvals-and-sandbox \
  --cd "$BENCH_WORKDIR" "$(cat /bench/instruction.md)" < /dev/null
