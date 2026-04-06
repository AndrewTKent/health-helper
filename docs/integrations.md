# External Integrations

## Nightscout (CGM + Loop Data)

Nightscout is an open-source CGM visualization tool. If Ian runs a Nightscout instance (or uses a hosted service like ns.10be.de), we can pull CGM readings and Loop pump data.

### Setup

1. Get the Nightscout site URL (e.g., `https://ian-cgm.herokuapp.com` or `https://ian.ns.10be.de`)
2. Get the API secret (set in Nightscout's `API_SECRET` env var)
3. Store both in Health Helper settings

### Endpoints We Use

```
GET /api/v1/entries.json?count=288&find[dateString][$gte]=2026-04-04
  → CGM readings (sgv in mg/dL, direction, dateString, _id)

GET /api/v1/treatments.json?find[created_at][$gte]=2026-04-04
  → Insulin boluses, temp basals, carb entries from Loop
  → Types: "Bolus", "Temp Basal", "Carb Correction", "Meal Bolus"

GET /api/v1/devicestatus.json?count=1
  → Current Loop status: IOB, COB, predicted glucose, loop state
  → Fields: loop.iob.iob, loop.cob.cob, loop.predicted.values
```

### Auth

Header: `api-secret: <sha1 hash of API_SECRET>` or query param `?token=<readable token>`

### Sync Strategy

- Pull last 24h on page load (288 5-min readings)
- GitHub Actions cron every 15 minutes for background sync
- Upsert by `_id` field to prevent duplicates
- Store in D1 `glucose_readings` table for historical queries

### Fallback: Tidepool

If Nightscout isn't available, Tidepool is an alternative CGM data source. OAuth2 flow, documented at `https://developer.tidepool.org/`. Lower priority — implement only if needed.

---

## Spoonacular (Recipe + Nutrition API)

Spoonacular provides recipe search, nutrition data, meal planning, and ingredient info. Free tier: 150 requests/day. Paid plans available for higher volume.

### Setup

1. Sign up at https://spoonacular.com/food-api
2. Get API key
3. Store in `SPOONACULAR_API_KEY` env var

### Endpoints We Use

```
GET /recipes/complexSearch
  ?query=chicken
  &diet=gluten-free
  &intolerances=dairy
  &maxCarbs=40
  &minProtein=20
  &includeIngredients=chicken,broccoli   ← use pantry items
  &addRecipeNutrition=true
  &number=12
  → Search results with nutrition data

GET /recipes/{id}/information
  ?includeNutrition=true
  → Full recipe: ingredients, steps, nutrition per serving

GET /food/ingredients/{id}/information
  ?amount=100&unit=grams
  → Detailed nutrition for a single ingredient

GET /recipes/findByIngredients
  ?ingredients=chicken,rice,broccoli
  &number=10
  → "What can I make with what I have?"
```

### Key Fields for T1D

- `nutrition.nutrients` array contains carbs, fiber, sugar, glycemic index
- Net carbs = carbs - fiber (important for bolus calculation)
- `glycemicIndex` and `glycemicLoad` when available
- Per-serving values (not per-recipe) — critical for accurate carb counting

### Rate Limiting

Free tier: 150 points/day. Complex search = 1 point, recipe info = 1 point.
Cache saved recipes in D1 to avoid re-fetching.

---

## Instacart Connect API

Instacart Connect lets apps create grocery orders programmatically. Currently in limited access — may need to apply for API access.

### Setup

1. Apply at https://www.instacart.com/company/connect
2. Get OAuth2 credentials (client_id, client_secret)
3. Store in env vars

### OAuth2 Flow

```
1. Redirect user to:
   https://www.instacart.com/oauth/authorize
     ?client_id={id}
     &redirect_uri={callback}
     &response_type=code
     &scope=orders:create

2. User authorizes → Instacart redirects to callback with code

3. Exchange code for tokens:
   POST https://www.instacart.com/oauth/token
     { grant_type: "authorization_code", code, redirect_uri, client_id, client_secret }

4. Store access_token + refresh_token in KV
```

### Order Creation Flow

```
1. Generate grocery list from meal plan
   → List of items with names, quantities, units

2. Search for products on Instacart:
   GET /v1/products/search?query=chicken+breast&store_id={store}
   → Returns product matches with prices

3. Build cart:
   POST /v1/carts
     { items: [{ product_id: "...", quantity: 2 }] }

4. Create order:
   POST /v1/orders
     { cart_id: "...", delivery_window: "..." }

5. Webhook receives status updates:
   POST /api/instacart-webhook
     { order_id, status, delivery_eta, ... }
```

### Alternative: Instacart Affiliate Links

If the Connect API isn't available, generate Instacart deep links for each ingredient. Less seamless but works without API access:
```
https://www.instacart.com/store/search?query=chicken+breast
```

### Alternative: Manual Shopping List

Always support a plain text grocery list export (copy to clipboard, share via text) as a fallback when Instacart isn't connected.

---

## Claude API (AI Nutritionist)

### Setup

1. Get API key from https://console.anthropic.com
2. Store in `ANTHROPIC_API_KEY` env var

### Implementation

Use `@anthropic-ai/sdk` or direct HTTP to the Messages API. System prompt includes live data sections (see architecture.md for full system prompt design).

### Key Capabilities

The AI nutritionist should be able to:

1. **Answer nutrition questions** — "How many carbs in a banana?"
2. **Suggest meals** — "What should I eat?" (uses pantry, macro targets, glucose)
3. **Explain glucose patterns** — "Why did I spike after lunch?"
4. **Recommend recipes** — triggers Spoonacular search, returns formatted recipe
5. **Adjust to context** — knows current glucose, IOB, time of day, remaining macros

### Tool Use

Give Claude tools for:
- `search_recipes(query, maxCarbs, minProtein)` → calls Spoonacular
- `lookup_food(name)` → searches foods table or USDA
- `get_glucose(hours)` → returns recent CGM data
- `get_pantry()` → returns current pantry
- `add_to_grocery_list(items)` → adds items to shopping list

This lets the AI take actions: "Let me find a recipe for that... here's one. Want me to add the ingredients to your grocery list?"

---

## USDA FoodData Central (Free Nutrition Lookup)

No API key needed. Useful for looking up nutrition for raw/unbranded foods.

```
GET https://api.nal.usda.gov/fdc/v1/foods/search
  ?query=chicken+breast
  &dataType=Foundation,SR+Legacy
  &pageSize=5

→ Returns nutrition per 100g with full micronutrient breakdown
```

Use this as the primary food database for manual meal logging. Spoonacular for recipes, USDA for individual ingredients.
