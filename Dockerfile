# Upstream's static binary, pinned. Its own image is FROM scratch with no shell, and
# the template needs one to turn the login variables into an auth rule safely.
FROM sigoden/dufs:v0.47.0 AS dufs

FROM alpine:3.24.4

# python3 runs drop-file-cache (see railway-entrypoint.sh); busybox's mkpasswd hashes
# passwords that dufs's rule syntax can't hold in plain text.
RUN apk add --no-cache python3 tini

COPY --from=dufs /bin/dufs /usr/local/bin/dufs
COPY --chmod=0755 drop-file-cache /usr/local/bin/drop-file-cache
COPY --chmod=0755 railway-entrypoint.sh /railway-entrypoint.sh

ENV PORT=5000
ENTRYPOINT ["/sbin/tini", "--", "/railway-entrypoint.sh"]
