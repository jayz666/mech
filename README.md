# Vehicle Mechanic System

A comprehensive vehicle inspection and repair system for FiveM using ox_lib and ox_target. This script provides detailed vehicle part health monitoring, tire wear simulation, and interactive repair mechanics.

## Features

### 🔧 **Vehicle Inspection System**
- Real-time visual overlay showing vehicle part health
- Color-coded indicators (green for good condition, red for damaged)
- Interactive bone-based part detection
- Support for engine, doors, and wheels

### 🛞 **Advanced Tire Wear Simulation**
- Realistic tire degradation based on:
  - Driving speed
  - Wheel slip/drifting
  - Braking intensity
- Grip penalty system for worn tires
- Configurable wear rates and thresholds
- Tire burst at zero health option

### ⚙️ **Repair Mechanics**
- Part-by-part repair system
- Synchronizes custom health with GTA native vehicle state
- Requires wrench item (configurable)
- Animated repair process with configurable timing
- Proper door closing and visual cleanup

### 📊 **Health Management**
- Custom health system (0-100 scale)
- Native GTA health synchronization
- Body and engine damage tracking
- Per-part damage modeling

## Requirements

- **ox_lib** - Core framework
- **ox_target** - Targeting system
- **ox_inventory** - Item management

## Installation

1. Place the `mech` folder in your server's `resources` directory
2. Add `ensure mech` to your `server.cfg`
3. Configure the wrench item in `config.lua` (default: 'water')
4. Restart your server

## Configuration

### Basic Settings
```lua
-- Distances
Config.TargetDistance = 3.0      -- Interaction distance
Config.ViewDistance = 10.0      -- Visual overlay distance
Config.RepairDistance = 1.6     -- Repair interaction distance

-- Items & Timing
Config.WrenchItem = 'water'      -- Required item for repairs
Config.RepairTime = 45000        -- Repair time in milliseconds
```

### Tire Wear Configuration
```lua
Config.TireWear = {
  Enabled = true,
  TickMs = 500,                 -- Update interval
  BaseWearPerSecond = 0.010,    -- Constant wear while moving
  SpeedWearFactor = 0.00035,    -- Extra wear per km/h per second
  SlipWearFactor = 0.050,       -- Extra wear during slip
  BrakeWearPerSecond = 0.020,   -- Extra wear when braking
  GripPenaltyBelow = 30,        -- Grip reduction threshold
  BurstAtZero = true            -- Tires burst at 0% health
}
```

### Visual Settings
```lua
Config.Sprite = {
  dict = 'commonmenu',          -- Sprite dictionary
  good = 'shop_tick_icon',      -- Good condition icon
  bad = 'shop_lock',            -- Bad condition icon
  size = 0.020                  -- Icon size
}
```

## Usage

### Inspection
1. Approach any vehicle
2. Look at vehicle parts within view distance
3. Health indicators will appear automatically
4. Green checkmarks = good condition (>50%)
5. Red locks = damaged condition (≤50%)

### Repairs
1. Equip the required wrench item
2. Approach damaged vehicle part
3. Use ox_target to interact
4. Wait for the repair timer to complete
5. Part will be fully restored

### Supported Parts
- **Engine** - Core vehicle engine
- **Doors** - All 4 doors (LF, RF, LR, RR)
- **Wheels** - All 4 wheels (LF, RF, LR, RR)

## API

### Client Exports
```lua
-- Check if player has wrench
exports.mech:hasWrench()

-- Get part health percentage
exports.mech:getPartPercent(vehicle, part)

-- Repair specific part
exports.mech:repairPart(vehicle, part)
```

### Server Events
```lua
-- Force stop inspection
TriggerClientEvent('my_vehicle_inspect:client:stop', playerId)
```

## Customization

### Adding New Parts
Edit `config.lua` to add new vehicle parts:
```lua
Config.Parts = {
  -- Existing parts...
  { id='new_part', bone='bone_name', type='part_type', label='Display Name' }
}
```

### Damage Model Tuning
Adjust damage sensitivity in config:
```lua
Config.BodyDeltaToPartDamage = 0.15   -- Body damage → part damage
Config.EngineDeltaToPartDamage = 0.08  -- Engine damage → engine parts
```

## Troubleshooting

### Icons Not Showing
- Ensure ox_lib is properly initialized
- Check sprite dictionary loading
- Verify ViewDistance configuration

### Repairs Not Working
- Confirm player has required wrench item
- Check ox_target setup
- Verify repair distance settings

### Tire Wear Not Active
- Ensure `Config.TireWear.Enabled = true`
- Check if player is in vehicle
- Verify tick interval settings

## Future Development Roadmap

This script provides a solid **mechanic framework** that can be extended in multiple directions. Here are the planned upgrade paths:

### 🏁 **1. Performance Degradation Per Part (Realism Upgrade)**
- Engine damage affects torque output, max speed, acceleration
- Random stalling based on damage levels
- Live handling modification with `SetVehicleEnginePowerMultiplier()`
- Progressive power loss: 70% → slight loss, 40% → misfires, 20% → smoke + stalling

### 🛞 **2. Tire Compounds (Simulation Upgrade)**
- Multiple tire types: Street, Sport, Track, Drift, Offroad
- Different wear rates and grip characteristics
- Temperature system affecting performance
- Burnouts increase temperature, affecting grip and wear

### 🛠️ **3. Mechanic Skill System (RPG Layer)**
- Mechanic XP and progression
- Faster repair times with higher skill
- Repair failure chance at low skill levels
- Quality limitations (untrained mechanics can only restore to 80%)

### 💰 **4. Economy Layer (Server Depth)**
- Material-based repairs (metal, oil, etc.)
- Cost system for parts and labor
- Insurance integration
- Salvage system for heavily damaged vehicles

### 🔧 **5. Advanced Damage Types (Deep Simulation)**
- Radiator (engine overheating)
- Suspension (ride height + bounce effects)
- Transmission (gear shift delays)
- Brake wear (stopping distance)
- Alignment (vehicle pulling)

### 🧠 **6. Diagnostic Tablet UI (Professional Feel)**
- NUI tablet interface with 3D vehicle diagrams
- Click-to-inspect functionality
- Detailed statistics display
- Live temperature and pressure monitoring

### 🚓 **7. Persistent Damage (Hardcore Mode)**
- Server-side damage persistence
- Tire wear saves across server restarts
- Engine and suspension damage persistence
- Long-term consequences for vehicle abuse

### 🏎️ **8. Driving Behavior Damage Model**
- Physics-based damage calculation
- Impact speed and angle consideration
- Raycast-based part detection
- Realistic crash consequences (120 km/h wall hit = front suspension + radiator damage)

## Version History

- **v6.0** - Full rewrite with improved sync and tire wear
- Fixed custom health and GTA native state synchronization
- Added comprehensive tire wear simulation
- Improved visual feedback system

## Support

For issues and feature requests, please visit the GitHub repository.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Credits

Created for the FiveM community using modern ox frameworks.
