-- config.lua
Config = {}

-- Distances
Config.TargetDistance = 3.0
Config.ViewDistance   = 10.0
Config.RepairDistance = 1.6

-- Items / timings
Config.WrenchItem = 'water'
Config.RepairTime = 45000 -- ms

-- Sprite icons (built-in GTA UI)
Config.Sprite = {
  dict = 'commonmenu',
  good = 'shop_tick_icon',
  bad  = 'shop_lock',
  size = 0.020
}

-- Threshold for “good/bad” icon (percent)
Config.GoodThreshold = 50

-- Custom per-part damage model (doors get damage from BODY health loss)
Config.BodyDeltaToPartDamage   = 0.15  -- BODY delta -> part damage
Config.EngineDeltaToPartDamage = 0.08  -- ENGINE delta -> engine part damage

-- Tire wear model (custom 0..100 per wheel)
Config.TireWear = {
  Enabled = true,

  TickMs = 500,                 -- update interval
  BaseWearPerSecond = 0.010,    -- constant wear while moving
  SpeedWearFactor = 0.00035,    -- extra wear per km/h per second
  SlipWearFactor = 0.050,       -- extra wear per slip amount per second
  BrakeWearPerSecond = 0.020,   -- extra wear when braking

  SlipStart = 0.12,             -- slip amount where “drift” starts
  DriftMultiplier = 3.5,        -- multiplier when slipping past SlipStart
  BrakeMultiplier = 2.0,        -- multiplier when braking

  GripPenaltyBelow = 30,        -- % threshold to reduce grip
  BurstAtZero = true
}

-- Parts (bones)
Config.Parts = {
  { id='engine',   bone='engine',        type='engine', label='Engine' },

  { id='door_lf',  bone='door_dside_f',  type='door',   label='Door LF', doorIndex=0 },
  { id='door_rf',  bone='door_pside_f',  type='door',   label='Door RF', doorIndex=1 },
  { id='door_lr',  bone='door_dside_r',  type='door',   label='Door LR', doorIndex=2 },
  { id='door_rr',  bone='door_pside_r',  type='door',   label='Door RR', doorIndex=3 },

  { id='wheel_lf', bone='wheel_lf',      type='wheel',  label='Wheel LF', wheelIndex=0 },
  { id='wheel_rf', bone='wheel_rf',      type='wheel',  label='Wheel RF', wheelIndex=1 },
  { id='wheel_lr', bone='wheel_lr',      type='wheel',  label='Wheel LR', wheelIndex=2 },
  { id='wheel_rr', bone='wheel_rr',      type='wheel',  label='Wheel RR', wheelIndex=3 },
}