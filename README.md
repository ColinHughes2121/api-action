# GoCreative AI — GitHub Action

> Call **145+ pay-per-call AI / enrichment / scraping endpoints** from any GitHub workflow. Free demo tier with zero signup. Pay in USDC on Base via [x402](https://x402.org), or with a standard API key.

[![GoCreative AI](https://img.shields.io/badge/api-gocreativeai.com-purple)](https://api.gocreativeai.com)
[![Pay per call](https://img.shields.io/badge/pay--per--call-USDC%20on%20Base-blue)](https://api.gocreativeai.com/pricing)

## What this Action does

Drop one step into any workflow and call:

- **Enrichment** — company by domain, person by email, GitHub user, LinkedIn profile, IP geo
- **Scraping** — Amazon ASIN, Google Maps place, Instagram profile, YouTube video, news article
- **Lookups** — DNS, WHOIS, SSL cert, headers, robots.txt, sitemap
- **AI tools** — summarize, classify, extract, translate
- **Utilities** — QR codes, JWT decode, password strength, IBAN check, lorem ipsum, geocode

Full catalog: [api.gocreativeai.com](https://api.gocreativeai.com)

---

## Quick start

```yaml
- uses: gocreativeai/api-action@v1
  with:
    endpoint: enrich/company
    args: '{"domain": "stripe.com"}'
```

That's it. With no `api_key` or `wallet`, you get the **free demo tier — 5 calls/day per runner IP**, no signup.

For real workloads, add an API key (paid) or wallet (USDC pay-per-call):

```yaml
- uses: gocreativeai/api-action@v1
  with:
    endpoint: enrich/company
    args: '{"domain": "stripe.com"}'
    api_key: ${{ secrets.GOCREATIVE_API_KEY }}
```

---

## Three concrete examples

### 1. Enrich a company by domain

```yaml
- name: Enrich Stripe
  id: enrich
  uses: gocreativeai/api-action@v1
  with:
    endpoint: enrich/company
    args: '{"domain": "stripe.com"}'
    api_key: ${{ secrets.GOCREATIVE_API_KEY }}

- name: Use the response
  run: echo '${{ steps.enrich.outputs.response }}' | jq .
```

### 2. Scrape an Amazon ASIN

```yaml
- name: Pull Amazon listing
  uses: gocreativeai/api-action@v1
  with:
    endpoint: scrape/amazon
    args: '{"asin": "B0CHX1W1XY"}'
    output_file: ./out/amazon.json
    api_key: ${{ secrets.GOCREATIVE_API_KEY }}
```

### 3. Look up a GitHub user

```yaml
- name: Inspect contributor
  uses: gocreativeai/api-action@v1
  with:
    endpoint: github/user
    args: '{"username": "torvalds"}'
    # no api_key → free demo tier, perfect for occasional lookups
```

---

## Inputs

| Input | Required | Description |
|---|---|---|
| `endpoint` | yes | Path under `/v1/` (e.g. `enrich/company`, `scrape/amazon`, `github/user`) |
| `args` | no | JSON string of arguments. Default `{}`. |
| `method` | no | `GET` (default) or `POST` |
| `api_key` | no | Paid-tier API key. Get one at [api.gocreativeai.com/start](https://api.gocreativeai.com/start) |
| `wallet` | no | Base wallet address for USDC x402 pay-per-call. Pair with `X402_PRIVATE_KEY` env var to auto-sign. |
| `output_file` | no | Write JSON response to this path |
| `fail_on_error` | no | Fail the step on non-2xx (default `true`) |

## Outputs

| Output | Description |
|---|---|
| `response` | Raw JSON response body |
| `status` | HTTP status code |
| `tier` | `paid`, `x402`, or `demo` — which path serviced the call |

---

## Pricing & tiers

| Tier | How | Cost | Limits |
|---|---|---|---|
| **Demo** | Use Action with no `api_key`/`wallet` | Free | 5 calls/day per IP |
| **x402 USDC** | Set `wallet` + `X402_PRIVATE_KEY` secret | ~$0.001–$0.05 / call on Base | Unlimited |
| **API key** | Set `api_key` | Volume tiers from $9/mo | Unlimited |

All payments settle to wallet `0xbAf55b24CA99bd7393B6e627093b13c6628b53Cc` on Base (x402).

---

## Why this exists

Most CI workflows need *some* data from the outside world — enrichment, scraping, lookups, AI summarization. Today you stitch together half a dozen vendors (Clearbit, Apify, OpenAI, Hunter, Bright Data) and juggle five API keys. **One action. One bill. 145 endpoints.**

Built for AI-agent developers and CI nerds who'd rather ship than integrate.

→ **[See all 145 endpoints](https://api.gocreativeai.com)** · **[Get an API key (free tier available)](https://api.gocreativeai.com/start)** · **[MCP server for Claude Code / Cursor](https://api.gocreativeai.com/mcp)**

---

## License

MIT. Use it. Ship it. Make money.

## Support

- Web: https://api.gocreativeai.com
- Email: contact@gocreativeai.com
- Issues: open a GitHub issue on this repo
