# Optional Docker runtime — the action.yml uses `composite` by default for speed.
# This Dockerfile is provided for users who want to pin the runtime.
FROM alpine:3.20

RUN apk add --no-cache bash curl python3 util-linux jq

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
