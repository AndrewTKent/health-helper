# Setup Guide

Step-by-step instructions for getting Health Helper running. You don't need to understand all of this — Claude Code can help with each step. But this explains what's happening and why.

## Prerequisites

You need these installed on your Mac:

1. **Node.js** (v22+) — the JavaScript runtime
   ```bash
   # Check if installed:
   node --version

   # If not installed, use Homebrew:
   brew install node
   ```

2. **Git** — version control (almost certainly already installed)
   ```bash
   git --version
   ```

3. **Wrangler** — Cloudflare's CLI tool for deploying
   ```bash
   npm install -g wrangler
   ```

4. **Claude Code** — your AI coding assistant
   ```bash
   # If not installed:
   npm install -g @anthropic-ai/claude-code
   ```

## Step 1: Cloudflare Account

Cloudflare hosts the app for free. You need an account.

1. Go to https://dash.cloudflare.com/sign-up
2. Create a free account
3. In your terminal, log in:
   ```bash
   wrangler login
   ```
   This opens a browser window — authorize Wrangler.

## Step 2: Create the Database

Cloudflare D1 is a SQLite database that runs at the edge (fast globally). Free tier is generous.

```bash
# Create the database
npx wrangler d1 create health-helper-db

# This prints a database_id — copy it
# Open wrangler.toml and paste the database_id in the d1_databases section
```

Then initialize the schema:
```bash
npx wrangler d1 execute health-helper-db --remote --file=db/schema.sql
```

## Step 3: Create the Pages Project

Cloudflare Pages hosts the website and API.

```bash
# Build the site
npm run build

# Deploy for the first time
npx wrangler pages deploy dist --project-name health-helper
```

After this, Cloudflare auto-deploys every time you push to `main`.

To connect to GitHub for auto-deploy:
1. Go to https://dash.cloudflare.com → Pages → health-helper → Settings → Builds & deployments
2. Connect your GitHub repo
3. Build command: `npm run build`
4. Build output directory: `dist`

## Step 4: Environment Variables

API keys and secrets are stored in Cloudflare, not in code.

1. Go to https://dash.cloudflare.com → Pages → health-helper → Settings → Environment variables
2. Add:
   - `SESSION_SECRET` — any random string (e.g., run `openssl rand -hex 32`)
   - `ANTHROPIC_API_KEY` — from https://console.anthropic.com (for AI chat)
   - Add others as you build integrations

## Step 5: Local Development

```bash
# Install dependencies
npm install

# Start local dev server
npm run dev
# → Open http://localhost:4321

# To test with the real database locally:
npx wrangler pages dev dist
```

## Step 6: Make Changes

This is where Claude Code comes in. Open the project in your terminal:

```bash
cd ~/Code/personal/health-helper
claude
```

Tell Claude Code what you want to build. For example:
- "I want to be able to log what I eat and see my daily macros"
- "Can we add a chart that shows my blood sugar over the past 24 hours?"
- "I want to search for recipes and save the ones I like"

Claude Code will write the code, explain what it does, and help you deploy it.

## How Deployment Works

Once GitHub is connected to Cloudflare Pages:

1. You make changes locally (with Claude Code's help)
2. Commit and push to GitHub (`git add . && git commit -m "message" && git push`)
3. Cloudflare automatically builds and deploys in ~30 seconds
4. Your app is live at `https://health-helper.pages.dev`

You can also use a custom domain if you want (Settings → Custom domains in Cloudflare).

## Costs

Everything in this stack has a generous free tier:

| Service | Free Tier | Enough for... |
|---------|-----------|---------------|
| Cloudflare Pages | Unlimited sites, 500 builds/mo | Always |
| Cloudflare D1 | 5M reads, 100K writes/day | Years of personal use |
| Cloudflare R2 | 10GB storage | Thousands of meal photos |
| Cloudflare KV | 100K reads, 1K writes/day | Always |
| Spoonacular | 150 requests/day | ~50 recipe searches/day |
| USDA FoodData | Unlimited | Always |
| Claude API | Pay-per-use (~$0.01/chat) | Very cheap |

The only thing that costs money is the Claude API for the chat feature, and it's pennies per conversation.
