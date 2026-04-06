# Health Helper

A personal health app — built by you, with [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

---

## The Idea

Track nutrition, monitor glucose, discover recipes, automate groceries — all in one place, tailored to how you actually eat and live.

This repo is the foundation. The docs sketch out what's possible. The database schema is ready. The infrastructure is wired up. What gets built first — and what matters most — is up to you.

---

## What You Can Build

| Feature | What it does |
|---------|-------------|
| **Meal Logging** | Log what you eat — search by name, scan a barcode, or snap a photo. See macros and carb counts in real time. |
| **Glucose Monitoring** | Pull CGM readings from Nightscout. Visualize trends, time-in-range, and how meals affect your blood sugar. |
| **AI Nutritionist** | A chat interface that knows your glucose patterns, pantry, and dietary goals. Ask it what to eat. |
| **Recipe Search** | Find recipes filtered by carbs, protein, dietary restrictions, and what's already in your kitchen. |
| **Grocery Automation** | Turn a meal plan into a grocery list. One tap sends it to Instacart for delivery. |

You don't need to build all of this. Start with the one thing that would help you the most, and grow from there.

---

## Working with Claude Code

Claude Code is an AI coding assistant that runs in your terminal. It reads your project files, writes code, runs commands, and deploys — all through conversation. You describe what you want in plain English; it builds it.

### What to expect

**It's fast.** A working feature — database, API endpoint, frontend page with charts — can go from idea to deployed in a single session. The trips app that inspired this project has 60+ API endpoints, a full training dashboard with 30+ charts, and an AI coach. Most of it was built in conversation.

**You don't need to know how to code.** Claude Code handles the Cloudflare setup, database migrations, API routes, page layouts, and deployment. You make decisions ("I want to track carbs", "show me a glucose chart for the last 24 hours", "make it look better on mobile") and it does the implementation.

**It explains as it goes.** Every file it creates, every decision it makes — it'll tell you what it did and why. If something doesn't make sense, ask. It's a conversation, not a black box.

**You stay in control.** Claude Code proposes changes and asks before doing anything irreversible. You approve each step. If you don't like something, say so and it'll adjust.

### How a session typically goes

1. Open the project and start Claude Code
2. Describe what you want ("I want to log meals and see my daily macros")
3. Claude Code writes the database table, API endpoint, and frontend page
4. You review, give feedback ("make the cards bigger", "add a pie chart for macros")
5. It refines, you approve, it deploys
6. Feature is live in minutes

### Getting started

```bash
cd ~/Code/personal/health-helper
claude
```

Claude Code reads the `CLAUDE.md` file automatically — it already understands the project structure, tech stack, and what's been planned. Just tell it what you want.

**First session ideas:**
- *"Walk me through what this app can do."*
- *"Set up the Cloudflare database and deploy the starter page."*
- *"I want to start by tracking what I eat. Build me a meal logger."*
- *"I use a Dexcom CGM — can we pull in my glucose data?"*

---

## Tech Stack

Everything runs on Cloudflare's free tier. No servers to manage, no bills to worry about.

| Layer | Technology | Cost |
|-------|-----------|------|
| **Pages** | [Astro](https://astro.build) — fast static site generator | Free |
| **API** | [Cloudflare Pages Functions](https://developers.cloudflare.com/pages/functions/) — serverless endpoints | Free |
| **Database** | [Cloudflare D1](https://developers.cloudflare.com/d1/) — SQLite at the edge | Free (5M reads/day) |
| **Storage** | [Cloudflare R2](https://developers.cloudflare.com/r2/) — meal photos | Free (10GB) |
| **Charts** | [Chart.js](https://www.chartjs.org/) — data visualization | Free |
| **AI Chat** | [Claude API](https://docs.anthropic.com/en/docs/about-claude/models) — nutritionist chat | ~$0.01/conversation |

### Integrations (added as needed)

| Service | Purpose |
|---------|---------|
| [Nightscout](http://www.nightscout.info/) | CGM readings + Loop/pump data |
| [Spoonacular](https://spoonacular.com/food-api) | Recipe search + nutrition data |
| [Instacart Connect](https://www.instacart.com/company/connect) | Grocery ordering + delivery |
| [USDA FoodData Central](https://fdc.nal.usda.gov/) | Free nutrition database |

---

## Project Structure

```
health-helper/
├── src/
│   ├── pages/           # Each .astro file = a page on the site
│   ├── components/      # Reusable UI pieces
│   ├── layouts/         # Page template (nav, footer)
│   └── styles/          # CSS
├── functions/api/       # Backend API endpoints
├── public/charts/       # Chart.js visualization modules
├── db/
│   ├── schema.sql       # Database tables
│   └── migrations/      # Schema changes over time
├── docs/                # Architecture, API specs, guides
├── CLAUDE.md            # Claude Code reads this automatically
├── wrangler.toml        # Cloudflare config
└── package.json         # Dependencies
```

---

## Development

```bash
npm install              # Install dependencies
npm run dev              # Start local server → http://localhost:4321
npm run build            # Production build
```

---

## Documentation

| Doc | What's inside |
|-----|--------------|
| [`docs/setup-guide.md`](docs/setup-guide.md) | Step-by-step Cloudflare account + database + deploy |
| [`docs/architecture.md`](docs/architecture.md) | System diagram, data flow, how the pieces connect |
| [`docs/api-reference.md`](docs/api-reference.md) | Every API endpoint with request/response examples |
| [`docs/integrations.md`](docs/integrations.md) | Nightscout, Spoonacular, Instacart, Claude API setup |
| [`docs/pages.md`](docs/pages.md) | Page wireframes and component designs |
| [`CLAUDE.md`](CLAUDE.md) | Instructions Claude Code reads on every session |
