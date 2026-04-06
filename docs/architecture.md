# Architecture

## Overview

Health Helper is a single-page-ish app built with Astro (static pages) + Cloudflare Pages Functions (API). Same stack as the [trips](https://github.com/AndrewTKent/trips) repo — proven pattern, zero-cost hosting, fast globally.

```
Browser (Astro pages + Chart.js)
    │
    ├── /api/meals, /api/glucose, /api/recipes, /api/chat ...
    │       │
    │       ├── Cloudflare D1 (SQLite)     ← meals, glucose, pantry, etc.
    │       ├── Cloudflare R2              ← meal photos
    │       ├── Cloudflare KV             ← API tokens, session cache
    │       │
    │       └── External APIs
    │           ├── Nightscout            ← CGM + Loop data
    │           ├── Spoonacular           ← recipes + nutrition
    │           ├── Instacart Connect     ← grocery ordering
    │           ├── Claude API            ← AI nutritionist
    │           └── USDA FoodData Central ← nutrition lookup
    │
    └── public/charts/*.js                ← Chart.js modules (IIFE pattern)
```

## Pages

| Page | Purpose | Key Data |
|------|---------|----------|
| `/` (Home) | Daily summary — today's macros, current glucose, next meal | meals, glucose, meal_plans |
| `/nutrition` | Meal logging, food search, macro breakdown | meals, meal_items, foods |
| `/glucose` | CGM timeline, time-in-range, meal impact analysis | glucose_readings, insulin_doses, meals |
| `/recipes` | Recipe search, saved recipes, meal planning calendar | saved_recipes, meal_plans |
| `/groceries` | Pantry inventory, grocery list, Instacart checkout | pantry, grocery_items, grocery_orders |
| `/chat` | AI nutritionist conversation | chat_conversations, chat_messages |

## Data Sync Strategy

### Glucose (Nightscout)

```
Browser loads glucose.astro
  → JS calls /api/glucose-sync (POST, triggers background sync)
  → glucose-sync.js fetches last 24h from Nightscout REST API
  → Upserts into D1 glucose_readings (external_id dedup)
  → Also pulls treatments (boluses) into insulin_doses
  → Returns fresh data to the page

Periodic: GitHub Actions cron every 15min calls /api/glucose-sync
  → Keeps D1 current even when page isn't open
```

Nightscout API: `GET /api/v1/entries.json?count=288&find[dateString][$gte]=...`
- 288 entries = 24h at 5-min intervals
- Each entry has: `sgv` (mg/dL), `direction`, `dateString`, `_id`

### Recipes (Spoonacular)

Not cached in D1 — search results are fetched fresh from Spoonacular each time.
Only *saved* recipes get stored in D1 (with their ingredients for grocery list generation).

Spoonacular endpoints:
- `GET /recipes/complexSearch` — search with filters (diet, intolerances, maxCarbs, etc.)
- `GET /recipes/{id}/information` — full recipe with ingredients + nutrition
- `GET /recipes/{id}/nutritionWidget.json` — detailed nutrition breakdown

### Instacart (Connect API)

OAuth2 flow:
1. User clicks "Connect Instacart" → redirect to Instacart auth
2. Callback stores tokens in KV
3. Grocery list → mapped to Instacart products → create order
4. Webhook receives delivery status updates

## Chart Architecture

Same pattern as trips — modular chart files that self-initialize:

```
public/charts/
  shared.js              ← colors, gradients, fetch cache, helpers
  glucose-timeline.js    ← 24h CGM trace with meal markers + insulin
  macro-rings.js         ← daily macro progress (carbs, protein, fat, cals)
  time-in-range.js       ← donut: time below/in/above range
  meal-impact.js         ← post-meal glucose curves (overlay multiple meals)
  weekly-nutrition.js    ← stacked bar: weekly macro intake vs targets
  iob-cob.js             ← dual gauge: insulin on board + carbs on board
```

Each module:
1. Wraps in an IIFE
2. On DOMContentLoaded, finds its canvas by ID
3. Fetches data via `ChartShared.fetchData()` (cached)
4. Renders Chart.js config
5. Sets narrative text below the chart

## AI Chat System Prompt

The chat endpoint builds a system prompt with live data sections:

```
[GLUCOSE_CONTEXT]
Current: 142 mg/dL, trend: Flat
Last 3h: 128 → 155 → 142
Time in range today: 82% (target 70%+)
IOB: 1.2U, COB: 15g

[NUTRITION_TODAY]
Meals logged: breakfast (45g carbs), lunch (62g carbs)
Remaining targets: 93g carbs, 65g protein, 30g fat, 840 kcal

[DIETARY_PROFILE]
Restrictions: none
Preferences: high-protein, Mediterranean-leaning
Glucose-friendly foods: lentils, nuts, Greek yogurt (historically good responses)
Spike triggers: white rice, orange juice (historically 50+ mg/dL spikes)

[PANTRY]
On hand: chicken breast, broccoli, quinoa, eggs, olive oil, feta, lemons

[UPCOMING]
Dinner planned: none
Tomorrow breakfast: Overnight oats (from meal plan)
```

This lets the AI give contextual advice: "You have 93g carbs left and chicken + broccoli in the pantry. Here's a stir-fry that'll be about 35g carbs..."

## Auth

Simple cookie-based sessions, same as trips:

1. Login with name + password → server sets signed cookie
2. API routes read cookie, look up user in D1
3. No OAuth for the app itself (single user to start)
4. External service OAuth (Instacart, Tidepool) tokens stored in KV per user

## Error Handling

- API routes return `{ error: "message" }` with appropriate HTTP status
- External API failures (Nightscout down, Spoonacular rate limit) return cached/stale data with a warning flag
- Glucose sync failures are non-blocking — page still renders with last-known data
- Instacart errors surface to the user (payment issues, out-of-stock, etc.)
