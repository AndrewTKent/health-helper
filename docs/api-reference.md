# API Reference

All endpoints are Cloudflare Pages Functions in `functions/api/`. They accept/return JSON.

## Auth

### `POST /api/auth`

Login. Sets session cookie.

```json
{ "name": "Ian", "password": "..." }
→ { "ok": true, "user": { "id": 1, "name": "Ian" } }
```

### `DELETE /api/auth`

Logout. Clears session cookie.

---

## Meals

### `GET /api/meals?date=2026-04-05`

Returns meals for a date with their items and nutrition totals.

```json
{
  "meals": [
    {
      "id": 1,
      "meal_type": "breakfast",
      "time": "08:30",
      "name": "Overnight oats",
      "total_calories": 420,
      "total_carbs": 52,
      "total_protein": 18,
      "total_fat": 14,
      "glucose_at_meal": 105,
      "glucose_1h_after": 135,
      "items": [
        { "name": "Rolled oats", "quantity": 0.5, "serving_unit": "cup", "carbs": 27, "calories": 150 },
        { "name": "Greek yogurt", "quantity": 0.5, "serving_unit": "cup", "carbs": 4, "calories": 65 }
      ]
    }
  ],
  "daily_totals": {
    "calories": 1580,
    "carbs": 142,
    "protein": 98,
    "fat": 55,
    "fiber": 22
  }
}
```

### `POST /api/meals`

Log a new meal.

```json
{
  "date": "2026-04-05",
  "time": "12:30",
  "meal_type": "lunch",
  "name": "Chipotle bowl",
  "items": [
    { "food_id": 42, "quantity": 1 },
    { "name": "Guacamole", "carbs": 8, "calories": 230, "protein": 3, "fat": 22 }
  ]
}
```

Items can reference a `food_id` (from the foods table) or provide inline nutrition for quick-log.

### `PUT /api/meals?id=1`

Update a meal (edit items, change time, add notes).

### `DELETE /api/meals?id=1`

Delete a meal and its items.

---

## Meal Photos

### `POST /api/meal-photo`

Upload a meal photo to R2. Accepts `multipart/form-data` with a `photo` field.

Returns the R2 URL. Optionally triggers AI food recognition to pre-populate meal items.

```json
{
  "url": "https://r2.health-helper.dev/photos/2026-04-05-lunch.jpg",
  "recognized_items": [
    { "name": "Grilled chicken", "confidence": 0.92, "estimated_carbs": 0, "estimated_calories": 280 },
    { "name": "Brown rice", "confidence": 0.87, "estimated_carbs": 45, "estimated_calories": 215 }
  ]
}
```

---

## Glucose

### `GET /api/glucose?hours=24`

Returns CGM readings for the last N hours.

```json
{
  "readings": [
    { "timestamp": "2026-04-05T14:30:00Z", "value": 142, "direction": "Flat" },
    { "timestamp": "2026-04-05T14:25:00Z", "value": 145, "direction": "FortyFiveDown" }
  ],
  "stats": {
    "current": 142,
    "direction": "Flat",
    "time_in_range": 82,
    "average": 128,
    "high_pct": 12,
    "low_pct": 6,
    "iob": 1.2,
    "cob": 15
  },
  "last_sync": "2026-04-05T14:32:00Z"
}
```

### `POST /api/glucose-sync`

Trigger a Nightscout sync. Fetches latest readings and insulin doses, upserts into D1.

```json
{
  "synced": 48,
  "new_readings": 12,
  "new_doses": 2,
  "latest": "2026-04-05T14:30:00Z"
}
```

---

## Recipes

### `GET /api/recipes?query=chicken&maxCarbs=40&diet=gluten-free`

Search recipes via Spoonacular with nutrition filters.

Query params:
- `query` — search term
- `maxCarbs`, `maxCalories`, `minProtein` — macro filters (grams)
- `diet` — dietary filter (gluten-free, vegetarian, etc.)
- `intolerances` — comma-separated (dairy, egg, gluten, etc.)
- `includeIngredients` — comma-separated (use pantry items)
- `number` — results per page (default 12)

```json
{
  "results": [
    {
      "id": 654959,
      "title": "Lemon Herb Chicken",
      "image": "https://spoonacular.com/...",
      "readyInMinutes": 35,
      "servings": 4,
      "nutrition": {
        "calories": 310,
        "carbs": 8,
        "protein": 42,
        "fat": 12,
        "fiber": 2
      }
    }
  ],
  "total": 84
}
```

### `GET /api/recipe-nutrition?id=654959`

Full recipe detail with ingredients, steps, and detailed nutrition.

### `POST /api/recipes` — Save a recipe to favorites

### `DELETE /api/recipes?id=1` — Remove saved recipe

---

## Meal Plans

### `GET /api/meal-plan?week=2026-04-06`

Returns the meal plan for a week (Mon-Sun).

```json
{
  "days": [
    {
      "date": "2026-04-06",
      "meals": [
        { "meal_type": "breakfast", "recipe_id": 12, "title": "Overnight Oats", "carbs": 52 },
        { "meal_type": "lunch", "custom_name": "Leftover stir-fry", "carbs": 35 },
        { "meal_type": "dinner", "recipe_id": 15, "title": "Lemon Herb Chicken", "carbs": 8 }
      ],
      "total_carbs": 95
    }
  ]
}
```

### `POST /api/meal-plan` — Add/update a meal plan entry
### `DELETE /api/meal-plan?id=1` — Remove a planned meal

---

## Pantry

### `GET /api/pantry`

```json
{
  "items": [
    { "id": 1, "name": "Chicken breast", "category": "protein", "quantity": 2, "unit": "lbs", "expiry_date": "2026-04-08" },
    { "id": 2, "name": "Quinoa", "category": "grain", "quantity": 1, "unit": "bag", "is_staple": true }
  ],
  "expiring_soon": [
    { "id": 1, "name": "Chicken breast", "expiry_date": "2026-04-08", "days_left": 3 }
  ]
}
```

### `POST /api/pantry` — Add item
### `PUT /api/pantry?id=1` — Update quantity/expiry
### `DELETE /api/pantry?id=1` — Remove item

---

## Grocery List

### `GET /api/grocery-list`

Returns current grocery list (auto-generated from meal plan minus pantry, plus manual additions).

### `POST /api/grocery-list`

Generate grocery list from a date range of meal plans.

```json
{ "from": "2026-04-06", "to": "2026-04-12" }
→ {
    "items": [
      { "name": "Chicken breast", "quantity": 3, "unit": "lbs", "category": "protein", "from_recipes": ["Lemon Herb Chicken", "Stir-fry"] },
      { "name": "Broccoli", "quantity": 2, "unit": "heads", "category": "produce" }
    ],
    "already_have": ["Quinoa", "Olive oil"],
    "estimated_cost": 65.40
  }
```

### `POST /api/grocery-list/add` — Add manual item
### `DELETE /api/grocery-list?id=1` — Remove item

---

## Instacart

### `GET /api/instacart-connect`

Returns OAuth redirect URL for connecting Instacart account.

### `POST /api/instacart-connect`

Handle OAuth callback, store tokens.

### `POST /api/instacart-connect/order`

Submit current grocery list as an Instacart order.

```json
{
  "order_id": "inst_abc123",
  "status": "submitted",
  "estimated_delivery": "2026-04-06T14:00:00-07:00",
  "estimated_total": 72.30
}
```

### `POST /api/instacart-webhook`

Receives delivery status updates from Instacart.

---

## Chat

### `GET /api/chat?conversation_id=1`

Returns conversation history.

### `POST /api/chat`

Send a message to the AI nutritionist.

```json
{ "message": "What should I eat for dinner?", "conversation_id": 1 }
→ {
    "response": "You have 93g carbs and 65g protein left for today. With the chicken breast and broccoli in your pantry, I'd suggest a simple stir-fry...",
    "suggested_recipe": { "title": "Chicken Broccoli Stir-fry", "spoonacular_id": 654321 }
  }
```

The AI has access to: current glucose, today's nutrition, pantry contents, dietary preferences, and glucose response history.

---

## Insights

### `GET /api/insights`

Daily summary with AI-generated observations.

```json
{
  "glucose": {
    "time_in_range": 82,
    "trend": "improving",
    "best_meal": { "name": "Overnight oats", "glucose_impact": 30 },
    "worst_meal": { "name": "Pasta", "glucose_impact": 95 }
  },
  "nutrition": {
    "calories_remaining": 840,
    "carbs_remaining": 93,
    "protein_remaining": 65
  },
  "insight": "Your time-in-range is up 5% this week. The overnight oats consistently keep you stable — consider making it a daily staple. Tonight, aim for a low-carb dinner to stay under target."
}
```

---

## Settings

### `GET /api/settings`
### `PUT /api/settings`

Update user preferences: glucose targets, macro targets, dietary restrictions, timezone, connected services.
