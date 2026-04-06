# Health Helper

A personal health app — built by you, with Claude Code.

## What is this?

This is a starting point for building a health app on Cloudflare. The repo has:

- **Architecture docs** (`docs/`) — sketches out what's possible: nutrition tracking, glucose monitoring, recipe search, grocery automation, AI chat
- **Database schema** (`db/schema.sql`) — tables for meals, foods, glucose readings, recipes, pantry, grocery lists
- **Setup guide** (`docs/setup-guide.md`) — step-by-step Cloudflare setup
- **Starter config** — Astro, wrangler.toml, package.json ready to go

The specific features and priorities are up to you. Tell Claude Code what you want and build it one feature at a time.

## Getting Started

```bash
# Install dependencies
npm install

# Start local dev server
npm run dev
# → http://localhost:4321

# Build for production
npm run build
```

See `docs/setup-guide.md` for the full Cloudflare setup walkthrough.

## Using Claude Code

Open this project in your terminal and start Claude Code:

```bash
cd ~/Code/personal/health-helper
claude
```

Claude Code has read the `CLAUDE.md` file and understands the project structure. Start by telling it what you want to build. Some ideas to get going:

- "What can this app do? Walk me through the possibilities."
- "I want to start with meal logging. Help me build that."
- "Set up the Cloudflare database and deploy the starter app."
- "I use a Dexcom CGM with Nightscout — can we pull in my glucose data?"

## Tech Stack

Same stack as Andrew's trips app:

- **Astro** — generates fast static pages
- **Cloudflare Pages** — hosts the site + API (free tier)
- **Cloudflare D1** — SQLite database at the edge (free tier)
- **Chart.js** — data visualization
- **Claude API** — AI chat features

## Docs

| Doc | What's in it |
|-----|-------------|
| `docs/setup-guide.md` | Step-by-step Cloudflare setup |
| `docs/architecture.md` | How the pieces fit together |
| `docs/api-reference.md` | Every API endpoint spec'd out |
| `docs/integrations.md` | Nightscout, Spoonacular, Instacart, Claude API details |
| `docs/pages.md` | Page designs and component sketches |
| `CLAUDE.md` | Instructions for Claude Code (read automatically) |
