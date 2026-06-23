# GitHub MCP Setup (Cursor)

This project uses the [official GitHub MCP server](https://github.com/github/github-mcp-server) via GitHub's hosted endpoint.

## 1. Create a GitHub Personal Access Token

1. Open https://github.com/settings/personal-access-tokens/new
2. Scopes: `repo`, `read:org`, `workflow` (adjust as needed)
3. Copy the token

Or reuse the GitHub CLI token:

```bash
gh auth login   # if not already logged in
export GITHUB_TOKEN="$(gh auth token)"
```

## 2. Cursor configuration

Config files (already added):

- Global: `~/.cursor/mcp.json`
- Project: `.cursor/mcp.json`

Both point to:

```json
{
  "mcpServers": {
    "github": {
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": {
        "Authorization": "Bearer ${env:GITHUB_TOKEN}"
      }
    }
  }
}
```

## 3. Set `GITHUB_TOKEN` in your shell

Add to `~/.zshrc`:

```bash
# GitHub MCP (Cursor) — uses gh CLI token when available
if command -v gh >/dev/null 2>&1 && [ -z "${GITHUB_TOKEN:-}" ]; then
  export GITHUB_TOKEN="$(gh auth token 2>/dev/null)"
fi
```

Then run: `source ~/.zshrc`

**Alternative:** In Cursor → Settings → Tools & MCP → edit **github** → paste your PAT directly (do not commit tokens to git).

## 4. Restart Cursor

Fully quit and reopen Cursor. Check Settings → Tools & MCP — **github** should show a green status dot.

## 5. Verify

In chat, ask: *"List my GitHub repositories using MCP"*

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Server not listed | Restart Cursor completely |
| Auth errors | `gh auth login` or refresh PAT scopes |
| `${env:GITHUB_TOKEN}` not resolved | Export token in shell before opening Cursor, or paste PAT in MCP settings UI |
| Docker path | Not needed — we use remote HTTP server |
