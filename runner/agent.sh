# Runs the agent once, headless, in the foreground; returns the agent's exit code.
# Example agent: Claude Code on Amazon Bedrock. To use another agent, replace the
# install step in install.sh and the command below; keep reading /bench/instruction.md.
. /bench/env
export PATH=/opt/bench-node/bin:$PATH

# Bedrock via the AgentCore execution role (IMDSv2); no keys are injected.
export CLAUDE_CODE_USE_BEDROCK=1
export ANTHROPIC_MODEL="$BENCH_MODEL"
export AWS_REGION="$BENCH_REGION"
export DISABLE_TELEMETRY=1 DISABLE_AUTOUPDATER=1 DISABLE_ERROR_REPORTING=1
# Claude Code refuses bypassPermissions as root unless it is told it is sandboxed.
export IS_SANDBOX=1
export TAR_OPTIONS=--no-same-owner

exec claude -p "$(cat /bench/instruction.md)" --permission-mode bypassPermissions < /dev/null
