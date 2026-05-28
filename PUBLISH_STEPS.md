# Publish steps — GoCreative AI GitHub Action

These commands take the action from local files to live on GitHub Marketplace.
Run them from `/Users/carlspackler/x402-api/integrations/github-action/`.

## Prereqs (one-time)

1. **GitHub PAT with `repo` + `workflow` scopes** must be exported, OR `gh auth login` completed for the `gocreativeai` org (or whichever org/user owns the repo).
2. The org `gocreativeai` must exist on GitHub. If you want to publish under your personal account instead, replace `gocreativeai/api-action` with `ColinHughes2121/api-action` everywhere below.
3. `gh` CLI installed and authenticated: `gh auth status`.

## The 6 commands

```bash
# 1. Go to the action directory
cd /Users/carlspackler/x402-api/integrations/github-action

# 2. Initialize a git repo locally
git init -b main && git add . && git commit -m "feat: initial release of GoCreative AI GitHub Action"

# 3. Create the public repo on GitHub (requires gh auth + org access) and push
gh repo create gocreativeai/api-action --public --source=. --push \
  --description "Call 145+ pay-per-call AI/enrichment/scraping endpoints from any GitHub workflow. Free demo tier; pay in USDC via x402 or API key."

# 4. Tag a release
git tag -a v1.0.0 -m "v1.0.0 — initial release"
git push origin v1.0.0

# 5. Also push a moving major tag (so users can pin to @v1)
git tag -f v1 && git push origin v1 --force

# 6. Cut a GitHub Release (this is what triggers Marketplace listing)
gh release create v1.0.0 \
  --title "v1.0.0 — initial release" \
  --notes "First public release. Composite action calling https://api.gocreativeai.com/v1/* with three auth tiers: paid API key, x402 USDC on Base, or free demo (5/day per IP)."
```

## Submit to GitHub Marketplace (manual, 2 min in browser)

GitHub Marketplace can't be submitted via CLI — only the web UI:

1. Open `https://github.com/gocreativeai/api-action/releases/tag/v1.0.0`
2. Click **"Edit release"**
3. Tick **"Publish this Action to the GitHub Marketplace"**
4. Pick primary category: **API management** (or **Utilities**); secondary: **Continuous integration**
5. Confirm the icon (`zap`) and color (`purple`) — already set in `action.yml`
6. Click **"Update release"**

GitHub reviews the listing automatically (usually < 5 min). When approved it appears at:

`https://github.com/marketplace/actions/gocreative-ai-agent-api`

## After publishing

- Add the Marketplace badge to README:
  ```
  [![Marketplace](https://img.shields.io/badge/marketplace-gocreative--ai-blue)](https://github.com/marketplace/actions/gocreative-ai-agent-api)
  ```
- Tweet/Show HN the listing with one of the example workflows.
- Add a link from `https://api.gocreativeai.com/integrations` to the Marketplace page.

## If `gocreativeai` org doesn't exist yet

Create it first (web only): https://github.com/account/organizations/new — free tier is fine. Then re-run step 3.

## Updating the action later

```bash
# bump version, re-tag, re-release
git commit -am "feat: <change>"
git tag -a v1.1.0 -m "v1.1.0 — <change summary>"
git tag -f v1 && git push origin main v1.1.0 v1 --force
gh release create v1.1.0 --title "v1.1.0" --notes "<changelog>"
```

Pinning to `@v1` means users auto-get minor/patch updates; `@v1.0.0` is fully pinned.
