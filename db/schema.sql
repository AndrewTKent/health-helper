-- Health Helper — D1 Schema
-- Run: npx wrangler d1 execute health-helper-db --remote --file=db/schema.sql

-- ── Users ──

CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  email TEXT UNIQUE,
  password_hash TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_settings (
  user_id INTEGER PRIMARY KEY REFERENCES users(id),
  -- Glucose targets (mg/dL)
  glucose_low INTEGER DEFAULT 70,
  glucose_high INTEGER DEFAULT 180,
  glucose_target INTEGER DEFAULT 110,
  -- Macro targets (grams per day)
  calories_target INTEGER DEFAULT 2000,
  carbs_target INTEGER DEFAULT 200,
  protein_target INTEGER DEFAULT 150,
  fat_target INTEGER DEFAULT 80,
  fiber_target INTEGER DEFAULT 30,
  -- Dietary restrictions (comma-separated: gluten-free, dairy-free, etc.)
  dietary_restrictions TEXT,
  -- Timezone
  timezone TEXT DEFAULT 'America/Los_Angeles',
  -- Nightscout config (stored here for simplicity; move to KV for production)
  nightscout_url TEXT,
  -- Instacart connected
  instacart_connected INTEGER DEFAULT 0,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ── Foods ──

CREATE TABLE IF NOT EXISTS foods (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  brand TEXT,
  -- Nutrition per serving
  serving_size REAL,
  serving_unit TEXT,            -- 'g', 'oz', 'cup', 'slice', 'each'
  calories REAL,
  carbs REAL,                   -- grams
  protein REAL,
  fat REAL,
  fiber REAL,
  sugar REAL,
  sodium REAL,                  -- mg
  glycemic_index INTEGER,       -- 0-100, NULL if unknown
  -- Source tracking
  source TEXT DEFAULT 'manual', -- 'manual', 'usda', 'spoonacular', 'barcode'
  external_id TEXT,             -- USDA FDC ID or barcode
  barcode TEXT,
  -- Flags
  is_custom INTEGER DEFAULT 0,
  created_by INTEGER REFERENCES users(id),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_foods_name ON foods(name);
CREATE INDEX IF NOT EXISTS idx_foods_barcode ON foods(barcode);
CREATE INDEX IF NOT EXISTS idx_foods_external_id ON foods(external_id);

-- ── Meals ──

CREATE TABLE IF NOT EXISTS meals (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL REFERENCES users(id),
  date TEXT NOT NULL,            -- YYYY-MM-DD
  time TEXT,                     -- HH:MM (local)
  meal_type TEXT NOT NULL,       -- 'breakfast', 'lunch', 'dinner', 'snack'
  name TEXT,                     -- optional label ("Chipotle bowl")
  notes TEXT,
  photo_url TEXT,                -- R2 URL
  -- Aggregated nutrition (computed from meal_items)
  total_calories REAL,
  total_carbs REAL,
  total_protein REAL,
  total_fat REAL,
  total_fiber REAL,
  -- Glucose context (snapshot from CGM at meal time)
  glucose_at_meal INTEGER,       -- mg/dL
  glucose_1h_after INTEGER,      -- mg/dL 1h post
  glucose_2h_after INTEGER,      -- mg/dL 2h post
  insulin_bolus REAL,            -- units bolused for this meal
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_meals_user_date ON meals(user_id, date);

CREATE TABLE IF NOT EXISTS meal_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  meal_id INTEGER NOT NULL REFERENCES meals(id) ON DELETE CASCADE,
  food_id INTEGER REFERENCES foods(id),
  -- If food_id is NULL, store nutrition inline (quick-log)
  name TEXT,
  quantity REAL DEFAULT 1,
  serving_size REAL,
  serving_unit TEXT,
  calories REAL,
  carbs REAL,
  protein REAL,
  fat REAL,
  fiber REAL
);

CREATE INDEX IF NOT EXISTS idx_meal_items_meal ON meal_items(meal_id);

-- ── Glucose Readings ──

CREATE TABLE IF NOT EXISTS glucose_readings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL REFERENCES users(id),
  timestamp DATETIME NOT NULL,   -- UTC
  value INTEGER NOT NULL,        -- mg/dL
  direction TEXT,                -- 'Flat', 'FortyFiveUp', 'SingleUp', 'DoubleUp', etc.
  source TEXT DEFAULT 'nightscout', -- 'nightscout', 'tidepool', 'manual'
  external_id TEXT,              -- Nightscout _id for dedup
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_glucose_external ON glucose_readings(external_id);
CREATE INDEX IF NOT EXISTS idx_glucose_user_time ON glucose_readings(user_id, timestamp);

-- ── Loop / Insulin Data ──

CREATE TABLE IF NOT EXISTS insulin_doses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL REFERENCES users(id),
  timestamp DATETIME NOT NULL,
  dose_type TEXT NOT NULL,       -- 'bolus', 'basal', 'correction'
  units REAL NOT NULL,
  duration_minutes INTEGER,      -- for temp basals
  source TEXT DEFAULT 'nightscout',
  external_id TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_insulin_external ON insulin_doses(external_id);

-- ── Recipes ──

CREATE TABLE IF NOT EXISTS saved_recipes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL REFERENCES users(id),
  external_id TEXT,              -- Spoonacular recipe ID
  title TEXT NOT NULL,
  image_url TEXT,
  source_url TEXT,
  servings INTEGER,
  ready_in_minutes INTEGER,
  -- Per-serving nutrition
  calories REAL,
  carbs REAL,
  protein REAL,
  fat REAL,
  fiber REAL,
  glycemic_load REAL,
  -- Tags
  tags TEXT,                     -- JSON array: ["low-carb", "quick", "high-protein"]
  is_favorite INTEGER DEFAULT 0,
  times_made INTEGER DEFAULT 0,
  last_made TEXT,                -- YYYY-MM-DD
  notes TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_recipes_user ON saved_recipes(user_id);

CREATE TABLE IF NOT EXISTS recipe_ingredients (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  recipe_id INTEGER NOT NULL REFERENCES saved_recipes(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  amount REAL,
  unit TEXT,
  aisle TEXT                     -- grocery aisle for Instacart mapping
);

-- ── Meal Plans ──

CREATE TABLE IF NOT EXISTS meal_plans (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL REFERENCES users(id),
  date TEXT NOT NULL,
  meal_type TEXT NOT NULL,       -- 'breakfast', 'lunch', 'dinner', 'snack'
  recipe_id INTEGER REFERENCES saved_recipes(id),
  custom_name TEXT,              -- if not from a recipe
  servings INTEGER DEFAULT 1,
  notes TEXT,
  is_completed INTEGER DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_meal_plans_user_date ON meal_plans(user_id, date);

-- ── Pantry ──

CREATE TABLE IF NOT EXISTS pantry (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL REFERENCES users(id),
  name TEXT NOT NULL,
  category TEXT,                 -- 'produce', 'dairy', 'protein', 'grain', 'condiment', 'other'
  quantity REAL,
  unit TEXT,
  expiry_date TEXT,              -- YYYY-MM-DD
  is_staple INTEGER DEFAULT 0,  -- auto-reorder when low
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_pantry_user ON pantry(user_id);

-- ── Grocery Orders ──

CREATE TABLE IF NOT EXISTS grocery_orders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL REFERENCES users(id),
  instacart_order_id TEXT,
  status TEXT DEFAULT 'draft',   -- 'draft', 'submitted', 'shopping', 'delivered', 'cancelled'
  total_items INTEGER,
  estimated_total REAL,
  delivery_date TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS grocery_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id INTEGER REFERENCES grocery_orders(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id),
  name TEXT NOT NULL,
  quantity REAL DEFAULT 1,
  unit TEXT,
  category TEXT,
  from_recipe_id INTEGER REFERENCES saved_recipes(id),
  is_checked INTEGER DEFAULT 0,  -- manual shopping list use
  instacart_product_id TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_grocery_items_order ON grocery_items(order_id);

-- ── WHOOP Data ──

CREATE TABLE IF NOT EXISTS whoop_recoveries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL REFERENCES users(id),
  date TEXT NOT NULL,              -- YYYY-MM-DD
  recovery_score REAL,             -- 0-100%
  hrv_rmssd REAL,                  -- HRV in ms
  resting_hr REAL,                 -- bpm
  spo2 REAL,                       -- blood oxygen %
  skin_temp REAL,                  -- Celsius
  external_id TEXT,                -- WHOOP cycle_id for dedup
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_whoop_recovery_ext ON whoop_recoveries(external_id);
CREATE INDEX IF NOT EXISTS idx_whoop_recovery_user_date ON whoop_recoveries(user_id, date);

CREATE TABLE IF NOT EXISTS whoop_cycles (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL REFERENCES users(id),
  date TEXT NOT NULL,
  strain REAL,                     -- 0-21 scale
  avg_hr REAL,                     -- bpm
  max_hr REAL,
  calories REAL,                   -- kcal
  external_id TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_whoop_cycle_ext ON whoop_cycles(external_id);
CREATE INDEX IF NOT EXISTS idx_whoop_cycle_user_date ON whoop_cycles(user_id, date);

CREATE TABLE IF NOT EXISTS whoop_workouts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL REFERENCES users(id),
  date TEXT NOT NULL,
  start_time DATETIME,
  end_time DATETIME,
  sport_id INTEGER,                -- WHOOP sport type ID
  sport_name TEXT,                 -- human-readable sport name
  type TEXT,                       -- normalized: 'run', 'bike', 'swim', 'strength', 'other'
  strain REAL,                     -- workout strain
  avg_hr REAL,
  max_hr REAL,
  calories REAL,
  duration_minutes REAL,
  distance_meters REAL,
  zone_1_ms INTEGER,               -- HR zone durations in milliseconds
  zone_2_ms INTEGER,
  zone_3_ms INTEGER,
  zone_4_ms INTEGER,
  zone_5_ms INTEGER,
  external_id TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_whoop_workout_ext ON whoop_workouts(external_id);
CREATE INDEX IF NOT EXISTS idx_whoop_workout_user_date ON whoop_workouts(user_id, date);

CREATE TABLE IF NOT EXISTS whoop_sleep (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL REFERENCES users(id),
  date TEXT NOT NULL,              -- date sleep started
  sleep_score REAL,                -- 0-100%
  total_minutes REAL,
  rem_minutes REAL,
  sws_minutes REAL,                -- slow wave (deep) sleep
  light_minutes REAL,
  awake_minutes REAL,
  sleep_efficiency REAL,           -- % of time in bed actually sleeping
  respiratory_rate REAL,
  external_id TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_whoop_sleep_ext ON whoop_sleep(external_id);
CREATE INDEX IF NOT EXISTS idx_whoop_sleep_user_date ON whoop_sleep(user_id, date);

-- ── Chat History ──

CREATE TABLE IF NOT EXISTS chat_conversations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL REFERENCES users(id),
  title TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS chat_messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  conversation_id INTEGER NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,
  role TEXT NOT NULL,             -- 'user', 'assistant'
  content TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_convo ON chat_messages(conversation_id);
