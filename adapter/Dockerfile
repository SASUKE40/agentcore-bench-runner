# One template for every task image, in both modes. The task's own files are not modified.
#
#   microVM:    docker build --target tools --build-arg BASE=<task-image> adapter/
#   Instances:  docker build                --build-arg BASE=<original-image> adapter/
#
# Stage "tools" (both modes) adds:
#   /opt/bench/busybox                        static busybox, so the agent installer can
#                                             download even when the image has no
#                                             curl/wget/python3
#   curl + ca-certificates (only if missing)  test scripts commonly apt-get these at grading
#                                             time; on Instances the runtime has no Linux
#                                             capabilities, so packages go in at build time
#   APT_PACKAGES="pkg ..." adds more packages the same way.
#   The image's own ENTRYPOINT/CMD are kept (the microVM harness manages the session).
#
# Final stage (Instances) adds /opt/bench/entry.sh: keeps the container alive and
# answers the runtime health check on :8080/ping.
ARG BASE
FROM busybox:1.36-musl AS bb

FROM ${BASE} AS tools
ARG APT_PACKAGES=""
RUN if command -v apt-get >/dev/null 2>&1; then \
      pkgs="$APT_PACKAGES"; command -v curl >/dev/null 2>&1 || pkgs="$pkgs curl ca-certificates"; \
      if [ -n "$(echo $pkgs)" ]; then \
        apt-get update && apt-get install -y --no-install-recommends $pkgs && rm -rf /var/lib/apt/lists/*; \
      fi; \
    fi
COPY --from=bb /bin/busybox /opt/bench/busybox

FROM tools
COPY entry.sh /opt/bench/entry.sh
# Instances only: grading scripts often run "apt-get install -y curl ...". With no Linux
# capabilities dpkg cannot unpack anything, so an upgrade of an already-installed package
# fails the grading. The packages are installed above; this pin keeps apt from upgrading
# them (already-installed packages stay at the installed version).
RUN if [ -d /etc/apt/preferences.d ]; then \
      printf 'Package: *\nPin: release *\nPin-Priority: 50\n' > /etc/apt/preferences.d/99-bench-keep-installed; \
    fi
ENTRYPOINT ["/opt/bench/busybox", "sh", "/opt/bench/entry.sh"]
