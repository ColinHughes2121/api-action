#!/usr/bin/env bash
# GoCreative AI — GitHub Action entrypoint
# Calls https://api.gocreativeai.com/v1/<endpoint> with three tiers of auth:
#   1. paid       — INPUT_API_KEY supplied (Authorization: Bearer ...)
#   2. x402       — INPUT_WALLET supplied + X402_PRIVATE_KEY env var (signed USDC payment on Base)
#   3. demo       — no auth: falls back to /demo/<tool>/<arg> free tier (5 calls/day per runner IP)
set -o pipefail

API_BASE="${GOCREATIVE_API_BASE:-https://api.gocreativeai.com}"
ENDPOINT="${INPUT_ENDPOINT:?endpoint input is required}"
ARGS_JSON="${INPUT_ARGS:-{}}"
METHOD="$(echo "${INPUT_METHOD:-GET}" | tr '[:lower:]' '[:upper:]')"
API_KEY="${INPUT_API_KEY:-}"
WALLET="${INPUT_WALLET:-}"
OUTPUT_FILE="${INPUT_OUTPUT_FILE:-}"
FAIL_ON_ERROR="${INPUT_FAIL_ON_ERROR:-true}"

# Strip leading slash + optional "v1/" prefix from endpoint so users can pass either form.
ENDPOINT="${ENDPOINT#/}"
ENDPOINT="${ENDPOINT#v1/}"

emit() {
  # GitHub Actions multiline-safe output
  local name="$1"; local value="$2"
  local delim="EOF_$(uuidgen 2>/dev/null || echo "ghaeof$$")"
  {
    echo "${name}<<${delim}"
    printf '%s\n' "$value"
    echo "${delim}"
  } >> "${GITHUB_OUTPUT:-/dev/stdout}"
}

build_query() {
  # Convert JSON object → URL query string (k=v&k=v). Requires jq.
  python3 - "$1" <<'PY'
import json, sys, urllib.parse
try:
    obj = json.loads(sys.argv[1] or "{}")
except Exception:
    obj = {}
if not isinstance(obj, dict):
    obj = {}
parts = []
for k, v in obj.items():
    if v is None: continue
    if isinstance(v, (dict, list)):
        v = json.dumps(v, separators=(",", ":"))
    parts.append(f"{urllib.parse.quote(str(k))}={urllib.parse.quote(str(v))}")
print("&".join(parts))
PY
}

call_api() {
  local url="$1"; shift
  local extra_headers=("$@")
  local tmp_body
  tmp_body="$(mktemp)"
  local status
  if [[ "$METHOD" == "POST" ]]; then
    status="$(curl -sS -o "$tmp_body" -w '%{http_code}' \
      -X POST \
      -H "Content-Type: application/json" \
      -H "User-Agent: gocreativeai-github-action/1.0" \
      "${extra_headers[@]}" \
      --data "$ARGS_JSON" \
      "$url" || echo "000")"
  else
    status="$(curl -sS -o "$tmp_body" -w '%{http_code}' \
      -H "User-Agent: gocreativeai-github-action/1.0" \
      "${extra_headers[@]}" \
      "$url" || echo "000")"
  fi
  BODY="$(cat "$tmp_body")"
  STATUS="$status"
  rm -f "$tmp_body"
}

# Build URL for the paid/x402 path
QUERY=""
if [[ "$METHOD" == "GET" ]]; then
  QUERY="$(build_query "$ARGS_JSON")"
fi

PRIMARY_URL="${API_BASE}/v1/${ENDPOINT}"
[[ -n "$QUERY" ]] && PRIMARY_URL="${PRIMARY_URL}?${QUERY}"

TIER="unknown"
HEADERS=()

if [[ -n "$API_KEY" ]]; then
  TIER="paid"
  HEADERS=(-H "Authorization: Bearer ${API_KEY}")
  echo "::group::GoCreative AI — calling $ENDPOINT (paid tier)"
  call_api "$PRIMARY_URL" "${HEADERS[@]}"
  echo "::endgroup::"
elif [[ -n "$WALLET" ]]; then
  TIER="x402"
  HEADERS=(-H "X-Wallet-Address: ${WALLET}")
  if [[ -n "${X402_PRIVATE_KEY:-}" ]]; then
    HEADERS+=(-H "X-Payment-Auth: ${X402_PRIVATE_KEY}")
  fi
  echo "::group::GoCreative AI — calling $ENDPOINT (x402/wallet tier)"
  call_api "$PRIMARY_URL" "${HEADERS[@]}"
  echo "::endgroup::"
  if [[ "$STATUS" == "402" ]]; then
    echo "::warning title=x402 paywall hit::Set X402_PRIVATE_KEY env var to auto-pay, or fund wallet ${WALLET}. Response: $BODY"
  fi
else
  # Demo tier — extract first scalar arg from JSON to satisfy /demo/<tool>/<arg>
  TIER="demo"
  FIRST_ARG="$(python3 - "$ARGS_JSON" <<'PY'
import json, sys
try:
    obj = json.loads(sys.argv[1] or "{}")
except Exception:
    obj = {}
val = ""
if isinstance(obj, dict) and obj:
    for v in obj.values():
        if isinstance(v, (str, int, float)) and str(v):
            val = str(v); break
print(val)
PY
)"
  if [[ -z "$FIRST_ARG" ]]; then
    FIRST_ARG="example"
  fi
  # Reduce endpoint to just the tool name (last path segment) for demo route
  TOOL="${ENDPOINT##*/}"
  DEMO_URL="${API_BASE}/demo/${TOOL}/$(python3 -c 'import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1],safe=""))' "$FIRST_ARG")"
  echo "::group::GoCreative AI — calling $TOOL (free demo tier; 5/day per IP)"
  echo "Demo URL: $DEMO_URL"
  call_api "$DEMO_URL"
  echo "::endgroup::"
  if [[ "$STATUS" == "429" ]]; then
    echo "::warning title=Demo limit reached::Free tier capped at 5 calls/day per IP. Get an API key at https://api.gocreativeai.com/start, or supply a wallet for pay-per-call USDC via x402."
  fi
fi

echo "HTTP $STATUS ($TIER tier)"
echo "$BODY"

emit "status" "$STATUS"
emit "tier" "$TIER"
emit "response" "$BODY"

if [[ -n "$OUTPUT_FILE" ]]; then
  mkdir -p "$(dirname "$OUTPUT_FILE")"
  printf '%s\n' "$BODY" > "$OUTPUT_FILE"
fi

if [[ "$FAIL_ON_ERROR" == "true" ]]; then
  if [[ ! "$STATUS" =~ ^2 ]]; then
    echo "::error title=GoCreative API call failed::HTTP $STATUS — $BODY"
    exit 1
  fi
fi
exit 0
