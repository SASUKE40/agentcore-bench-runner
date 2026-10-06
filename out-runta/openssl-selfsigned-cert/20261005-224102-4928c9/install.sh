# Installs the Codex CLI inside the task runtime.
# Only adds Node.js (under /opt/bench-node) and the Codex CLI; the task environment is
# otherwise untouched. Task images are often slim and ship without curl, so every
# download falls back to whatever the image already has.
set -e

fetch() {  # fetch <url> <dest>, with whatever the image already has
  if command -v curl >/dev/null 2>&1; then curl -fsSL "$1" -o "$2"
  elif command -v wget >/dev/null 2>&1; then wget -qO "$2" "$1"
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c 'import sys,urllib.request; urllib.request.urlretrieve(sys.argv[1], sys.argv[2])' "$1" "$2"
  else echo "no downloader in image (curl/wget/python3)" >&2; return 1
  fi
}

# Always use our own Node under /opt/bench-node, even when the image has one: the task's
# node/npm is the task's business.
if [ ! -x /opt/bench-node/bin/node ]; then
  ARCH=$(uname -m); case "$ARCH" in x86_64) ARCH=x64;; aarch64) ARCH=arm64;; esac
  NODE_VERSION=v22.23.2
  # .tar.gz rather than .tar.xz: many task images ship without xz.
  fetch "https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-${ARCH}.tar.gz" /tmp/node.tar.gz
  mkdir -p /opt/bench-node && tar --no-same-owner -xzf /tmp/node.tar.gz -C /opt/bench-node --strip-components=1
  rm -f /tmp/node.tar.gz
fi
export PATH=/opt/bench-node/bin:$PATH

quiet() { "$@" > /tmp/.bench-npm.log 2>&1 || { tail -20 /tmp/.bench-npm.log; return 1; }; }
quiet npm install -g --silent @openai/codex
echo "node=$(node --version) codex=$(codex --version 2>/dev/null | head -1)"
