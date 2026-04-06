# Page Designs

## Home (`/`)

Daily command center. At a glance: where am I at today?

### Layout

```
┌─────────────────────────────────────────────────┐
│  Health Helper               [Ian]    [Settings] │
├─────────────────────────────────────────────────┤
│                                                   │
│  ┌─────────────┐  ┌──────────────────────────┐  │
│  │  Glucose     │  │  Today's Macros          │  │
│  │  142 mg/dL → │  │  ████████░░ 1580/2000    │  │
│  │  Time in     │  │  Carbs  ███░░░ 142/200g  │  │
│  │  range: 82%  │  │  Protein ██░░░ 98/150g   │  │
│  │  IOB: 1.2U   │  │  Fat    ██░░░░ 55/80g    │  │
│  └─────────────┘  └──────────────────────────┘  │
│                                                   │
│  ┌──────────────────────────────────────────┐    │
│  │  Glucose Timeline (24h)                   │    │
│  │  ~~~~~~~~~~~~/\~~~~~___~~~~~              │    │
│  │  🍳 breakfast    🥗 lunch                 │    │
│  └──────────────────────────────────────────┘    │
│                                                   │
│  ┌──────────────────────────────────────────┐    │
│  │  Today's Meals                            │    │
│  │  ☀ Breakfast  8:30am  420 cal  52g carbs  │    │
│  │  🌤 Lunch     12:30pm 580 cal  42g carbs  │    │
│  │  🌙 Dinner    — not logged —  [Log meal]  │    │
│  └──────────────────────────────────────────┘    │
│                                                   │
│  ┌──────────────────────────────────────────┐    │
│  │  💡 Insight                               │    │
│  │  "TIR up 5% this week. Oats keeping you   │    │
│  │   stable — keep it up. Low-carb dinner     │    │
│  │   tonight to stay under target."           │    │
│  └──────────────────────────────────────────┘    │
│                                                   │
│  [🍳 Log Meal]  [💬 Ask Coach]  [📋 Recipes]    │
│                                                   │
└─────────────────────────────────────────────────┘
```

### Components

- `GlucoseCard.astro` — current reading, direction arrow, TIR, IOB
- `MacroRings.astro` — circular progress for each macro (canvas: `macro-rings`)
- `GlucoseTimeline.astro` — 24h line chart with meal markers (canvas: `glucose-timeline`)
- `MealList.astro` — today's meals, expandable for items
- `InsightCard.astro` — AI-generated daily insight

---

## Nutrition (`/nutrition`)

Meal logging and detailed nutrition tracking.

### Tabs

**Log** — the main meal logger
- Meal type selector (breakfast / lunch / dinner / snack)
- Food search (autocomplete from foods table + USDA API)
- Barcode scanner (uses device camera + Open Food Facts API)
- Photo upload (optional AI food recognition)
- Quick-log: just type "chicken breast 6oz, rice 1 cup" and it parses
- Running total of the meal's macros as you add items

**Today** — full nutrition breakdown
- Meal-by-meal breakdown with expandable items
- Macro ring charts (same as home but larger)
- Calorie/carb/protein/fat trend over the past 7 days

**History** — past days
- Calendar picker → see any day's meals and macros
- Weekly/monthly summary charts

### Key Interactions

1. **Quick add**: Type "banana" → autocomplete shows "Banana, medium (27g carbs)" → tap → added
2. **Barcode**: Scan a package → lookup nutrition → confirm serving size → added
3. **Photo**: Take a photo → AI suggests items → confirm/edit → added
4. **From recipe**: Search saved recipes → select → auto-populates items with nutrition

---

## Glucose (`/glucose`)

CGM and Loop monitoring dashboard.

### Charts

1. **24h Timeline** (canvas: `glucose-timeline`)
   - Line chart: glucose readings over 24h
   - Horizontal bands: green (70-180), yellow (180-250), red (250+, <70)
   - Meal markers: vertical dotted line + icon at each logged meal time
   - Insulin markers: blue dots for boluses
   - Current reading: large number with direction arrow

2. **Time in Range** (canvas: `time-in-range`)
   - Donut chart: % below / in range / above range
   - Selectable period: today, 7d, 14d, 30d
   - Compare to previous period

3. **Meal Impact** (canvas: `meal-impact`)
   - Overlay multiple post-meal glucose curves
   - X-axis: minutes after meal (0-180)
   - Each curve labeled with meal name + carb count
   - Helps identify which meals cause spikes

4. **IOB + COB Gauges** (canvas: `iob-cob`)
   - Two semicircle gauges
   - Insulin on board (units), estimated from Loop
   - Carbs on board (grams), estimated from Loop

5. **Daily Patterns** (canvas: `glucose-patterns`)
   - Heatmap or spaghetti plot: glucose by time-of-day over 14 days
   - Shows if there are consistent high/low periods

### Data Source

All glucose data comes from `/api/glucose` which reads from D1 (synced from Nightscout). Page triggers a sync on load to get the latest readings.

---

## Recipes (`/recipes`)

Recipe discovery and meal planning.

### Search

- Search bar with filters: diet, intolerances, max carbs, min protein
- "Use my pantry" toggle — includes pantry ingredients in search
- Results as cards: photo, title, time, macros per serving
- Save to favorites, add to meal plan

### Saved Recipes

- Grid of saved recipes with quick-filter by tag
- "Made it" button tracks frequency
- Notes field for adjustments ("use half the rice for fewer carbs")

### Meal Plan Calendar

```
┌─────┬─────┬─────┬─────┬─────┬─────┬─────┐
│ Mon │ Tue │ Wed │ Thu │ Fri │ Sat │ Sun │
├─────┼─────┼─────┼─────┼─────┼─────┼─────┤
│ B:  │ B:  │ B:  │ B:  │ B:  │ B:  │ B:  │
│ Oats│ Oats│ Eggs│ Oats│ Eggs│ —   │ —   │
│     │     │     │     │     │     │     │
│ L:  │ L:  │ L:  │ L:  │ L:  │ L:  │ L:  │
│ Stir│ Left│ Salad│Bowl │ —   │ —   │ —   │
│     │     │     │     │     │     │     │
│ D:  │ D:  │ D:  │ D:  │ D:  │ D:  │ D:  │
│Chkn │Pasta│ Fish│ —   │ —   │ —   │ —   │
├─────┴─────┴─────┴─────┴─────┴─────┴─────┤
│ Weekly: ~1400g carbs, ~12600 kcal        │
│ [Generate Grocery List]                   │
└───────────────────────────────────────────┘
```

Drag-and-drop recipes into slots. "Generate Grocery List" computes what you need, minus what's in the pantry.

---

## Groceries (`/groceries`)

Pantry management and shopping.

### Pantry Tab

- List of what's on hand, grouped by category
- Expiring soon highlighted
- Staples flagged (auto-add when generating grocery list)
- Quick add: "eggs 12" → added

### Shopping List Tab

- Auto-generated from meal plan minus pantry
- Grouped by grocery aisle
- Check off items while shopping
- "Order on Instacart" button → sends to Instacart

### Instacart Tab (when connected)

- Order status tracker
- Past orders
- Connect/disconnect Instacart account

---

## Chat (`/chat`)

AI nutritionist. Same floating drawer pattern as trips repo's coach drawer — available from any page via a FAB button.

### Features

- Persistent conversation history (stored in D1)
- New conversation button
- Context-aware: knows glucose, nutrition, pantry, preferences
- Can suggest recipes (inline cards) and add to grocery list
- Example prompts: "What should I eat?", "Why did I spike?", "Plan my meals for the week"

### UI

```
┌──────────────────────────────────────┐
│  🤖 Nutrition Coach           [New]  │
├──────────────────────────────────────┤
│                                      │
│  You: What should I eat for dinner?  │
│                                      │
│  Coach: You have 93g carbs left and  │
│  chicken + broccoli in the pantry.   │
│  Here's a quick stir-fry:           │
│                                      │
│  ┌────────────────────────────────┐  │
│  │ 🍗 Chicken Broccoli Stir-fry  │  │
│  │ 35g carbs · 42g protein · 310  │  │
│  │ [Save Recipe] [Add to Plan]    │  │
│  └────────────────────────────────┘  │
│                                      │
│  Want me to add the ingredients to   │
│  your grocery list?                  │
│                                      │
├──────────────────────────────────────┤
│  [Type a message...]        [Send]   │
└──────────────────────────────────────┘
```
