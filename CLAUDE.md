# Health Helper

Personal health + nutrition app. This repo is a starting point — the specific features, integrations, and priorities should come from Ian.

## For Claude Code

**This is Ian's project.** He's not deeply technical but he's ambitious. Your job is to help him build something real. Here's how to work with him:

1. **Ask before assuming.** The docs in this repo sketch out possibilities (nutrition tracking, WHOOP activity/recovery, CGM monitoring, recipe suggestions, grocery automation, AI chat). Don't build all of them at once. Ask Ian what matters most to him right now and start there.

2. **Explain as you go.** When you create a file, tell him what it does and why. When you make an architecture decision, explain the tradeoff in plain language. He's learning — treat every task as a chance to teach.

3. **Keep it working.** After every meaningful change, make sure `npm run build` passes and the app is deployable. Show him how to run it locally. A working app with one feature beats a broken app with five.

4. **One feature at a time.** Suggest a starting point (e.g., "Let's get a basic meal logger working first, then we can add the glucose tracking"). Build incrementally.

5. **Handle the infrastructure.** Ian shouldn't need to figure out Cloudflare D1 bindings, wrangler.toml config, or Astro routing. Set those up correctly and explain what they do. The `docs/setup-guide.md` walks through the Cloudflare setup step by step.

## Questions to Ask Ian

These haven't been decided yet. Ask before building:

- **What's the #1 thing you want this app to do?** (track meals? monitor glucose? suggest recipes? all of the above?)
- **Do you use a WHOOP?** (determines recovery, strain, sleep, workout features)
- **Do you use a CGM / Nightscout / Tidepool?** (determines whether glucose features are relevant)
- **Do you use an insulin pump or Loop?** (determines IOB/COB features)
- **What does your current meal tracking look like?** (pen and paper? MyFitnessPal? nothing?)
- **Do you want this to be just for you, or shareable with a doctor/nutritionist?**
- **Are there specific dietary goals?** (low-carb, keto, Mediterranean, macro counting, etc.)
- **Do you cook regularly?** (determines how useful recipe/grocery features are)
- **Mobile or desktop primarily?** (determines design priorities)

## Tech Stack

- **Frontend**: Astro (static site generation) — generates fast, simple HTML pages
- **Backend**: Cloudflare Pages Functions — serverless API endpoints (JavaScript)
- **Database**: Cloudflare D1 (SQLite at the edge) — binding `DB`
- **Storage**: Cloudflare R2 — binding `PHOTOS` (for meal photos if needed)
- **KV**: Cloudflare KV — binding `KV` (API tokens, caching)
- **Auth**: Cookie-based sessions (single user to start)
- **Charts**: Chart.js with modular chart files in `public/charts/`

This is the same stack Andrew uses for his trips app — proven, free-tier friendly, deploys automatically.

## Project Structure

```
src/
  pages/          # Astro pages (each .astro file = a URL)
  components/     # Reusable Astro components
  layouts/        # Base page layout (nav, footer)
  styles/         # CSS
functions/api/    # API endpoints (Cloudflare Pages Functions)
public/           # Static assets (JS, images)
  charts/         # Chart.js modules
db/
  schema.sql      # Database schema
  migrations/     # Schema changes over time
docs/             # Architecture docs, API reference, setup guide
scripts/          # Utility scripts
```

## Development

```bash
npm install
npm run dev              # localhost:4321
npm run build            # production build
npx wrangler pages dev dist  # test with D1 locally
```

## Deploy

Cloudflare Pages auto-deploys from `main`. Config in `wrangler.toml`.

```bash
npx wrangler pages deploy dist     # Manual deploy
npx wrangler d1 execute health-helper-db --remote --file=db/schema.sql
```

## Key Patterns

- API routes live in `functions/api/` and return JSON
- Chart modules in `public/charts/` follow IIFE pattern (self-initializing)
- `public/charts/shared.js` provides colors, data fetching with caching, chart helpers
- `external_id` fields prevent duplicate data imports
- Environment variables (API keys, secrets) go in Cloudflare dashboard, never in code

## Environment Variables

Set in Cloudflare dashboard (or `.env` locally, gitignored):
- `SESSION_SECRET` — cookie signing
- `ANTHROPIC_API_KEY` — AI chat features
- `WHOOP_CLIENT_ID` / `WHOOP_CLIENT_SECRET` — WHOOP OAuth2
- Others added as integrations are built (Nightscout, Spoonacular, Instacart, etc.)
