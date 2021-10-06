
-- Settings
item_repair_settings = {}

-- Do we log that items were produced? (Great for debugging issues but not so good on a long running production server)
item_repair_settings.log_production = false

-- Do we log deep into the bowels of the repairs?
item_repair_settings.log_deep = false

-- The amount repaired per "tick"
-- This is percent of max durability (65535)
item_repair_settings.repair_percent = 1.0

-- Is it craftable?
item_repair_settings.craft = true