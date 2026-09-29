# Keeps the task container alive for the session and answers the runtime health
# check on :8080/ping. Uses a bundled static busybox, so it works whether or not
# the task image has python, curl or a shell of its own.
BB=/opt/bench/busybox
mkdir -p /opt/bench/www
echo '{"status":"Healthy"}' > /opt/bench/www/ping
exec $BB httpd -f -p 0.0.0.0:8080 -h /opt/bench/www
