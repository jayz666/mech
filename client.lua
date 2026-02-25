-- client.lua
-- Vehicle Mechanic System v6 (FULL REWRITE)
-- Fixes: repairing now syncs BOTH custom health AND GTA native vehicle state

local inspecting = false
local veh = 0

-- Custom health (0..100)
local partHealth = {}          -- engine + doors
local tireHealth = {}          -- [vehicleEntity] = { [0..3] = 0..100 }

-- Native delta tracking
local lastBody = nil
local lastEngine = nil

-- Tire wear timing
local lastWearTick = 0

-- =========================
-- Utility
-- =========================

local function clamp(v, mn, mx)
    if v < mn then return mn end
    if v > mx then return mx end
    return v
end

local function hasWrench()
    return exports.ox_inventory:Search('count', Config.WrenchItem) > 0
end

local function loadTxd(dict)
    if not HasStreamedTextureDictLoaded(dict) then
        RequestStreamedTextureDict(dict, true)
    end
end

local function drawSpriteIcon(x, y, good)
    loadTxd(Config.Sprite.dict)
    local tex = good and Config.Sprite.good or Config.Sprite.bad
    local s = Config.Sprite.size
    DrawSprite(Config.Sprite.dict, tex, x, y, s, s, 0.0, 255, 255, 255, 220)
end

local function drawText2D(x, y, text)
    SetTextScale(0.28, 0.28)
    SetTextFont(4)
    SetTextOutline()
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

local function getBonePos(vehicle, boneName)
    local idx = GetEntityBoneIndexByName(vehicle, boneName)
    if idx == -1 then return nil end
    return GetWorldPositionOfEntityBone(vehicle, idx)
end

-- =========================
-- Init
-- =========================

local function initPartHealth()
    partHealth = {}
    for _, p in ipairs(Config.Parts) do
        if p.type == "engine" or p.type == "door" then
            partHealth[p.id] = 100
        end
    end
    lastBody = nil
    lastEngine = nil
end

local function ensureTires(vehicle)
    if tireHealth[vehicle] then return end
    tireHealth[vehicle] = {}
    for i = 0, 3 do
        tireHealth[vehicle][i] = 100
    end
end

-- =========================
-- Custom Part Damage (doors from BODY delta)
-- =========================

local function getNearestPartId(vehicle, point)
    local best, bestDist = nil, 999999.0
    for _, p in ipairs(Config.Parts) do
        local pos = getBonePos(vehicle, p.bone)
        if pos then
            local d = #(vec3(pos.x, pos.y, pos.z) - point)
            if d < bestDist then
                bestDist = d
                best = p.id
            end
        end
    end
    return best
end

local function applyCustomDamage(partId, dmg)
    if not partId then return end
    if partHealth[partId] == nil then return end
    partHealth[partId] = clamp((partHealth[partId] or 100) - dmg, 0, 100)
end

local function updateCustomPartDamage(vehicle)
    local bodyNow = GetVehicleBodyHealth(vehicle)    -- ~0..1000
    local engNow  = GetVehicleEngineHealth(vehicle)  -- ~0..1000

    if not lastBody then lastBody = bodyNow end
    if not lastEngine then lastEngine = engNow end

    local bodyDelta = lastBody - bodyNow
    local engDelta  = lastEngine - engNow

    local impactPoint = GetEntityCoords(PlayerPedId())

    if bodyDelta > 0.0 then
        local target = getNearestPartId(vehicle, impactPoint)
        applyCustomDamage(target, bodyDelta * Config.BodyDeltaToPartDamage)
    end

    if engDelta > 0.0 then
        applyCustomDamage("engine", engDelta * Config.EngineDeltaToPartDamage)
    end

    lastBody = bodyNow
    lastEngine = engNow
end

-- =========================
-- Tire Wear (drivetrain-aware)
-- =========================

local function getSlip(vehicle)
    local vel = vec3(table.unpack(GetEntityVelocity(vehicle)))
    local speed = #vel
    if speed < 1.0 then return 0.0 end

    local fwd = vec3(table.unpack(GetEntityForwardVector(vehicle)))
    local forwardSpeed = vel.x * fwd.x + vel.y * fwd.y + vel.z * fwd.z
    local lateral = vel - (fwd * forwardSpeed)

    return clamp(#lateral / speed, 0.0, 1.0)
end

local function isWheelDriven(vehicle, wheelIndex)
    local bias = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fDriveBiasFront") or 0.5

    -- Bias: 0.0=RWD, 1.0=FWD, 0.5=AWD-ish
    if bias < 0.45 then
        return (wheelIndex == 2 or wheelIndex == 3) -- rear
    elseif bias > 0.55 then
        return (wheelIndex == 0 or wheelIndex == 1) -- front
    else
        return true -- AWD
    end
end

local function applyTireWear(vehicle, dt)
    if not Config.TireWear.Enabled then return end
    ensureTires(vehicle)

    local speedKmh = GetEntitySpeed(vehicle) * 3.6
    if speedKmh < 2.0 then return end

    local slip = getSlip(vehicle)
    local braking = IsControlPressed(0, 72) or IsControlPressed(0, 76)

    local wear = 0.0
    wear = wear + (Config.TireWear.BaseWearPerSecond * dt)
    wear = wear + ((speedKmh * Config.TireWear.SpeedWearFactor) * dt)
    wear = wear + ((slip * Config.TireWear.SlipWearFactor) * dt)

    if slip >= Config.TireWear.SlipStart then
        wear = wear * Config.TireWear.DriftMultiplier
    end

    if braking then
        wear = wear + (Config.TireWear.BrakeWearPerSecond * dt)
        wear = wear * Config.TireWear.BrakeMultiplier
    end

    for wheel = 0, 3 do
        local driven = isWheelDriven(vehicle, wheel)
        local applied = driven and wear or (wear * 0.25)

        local cur = tireHealth[vehicle][wheel] or 100
        local newVal = clamp(cur - applied, 0, 100)
        tireHealth[vehicle][wheel] = newVal

        if Config.TireWear.BurstAtZero and newVal <= 0 then
            if not IsVehicleTyreBurst(vehicle, wheel, false) then
                SetVehicleTyreBurst(vehicle, wheel, true, 1000.0)
            end
        end
    end
end

local function updateGrip(vehicle)
    if not Config.TireWear.Enabled then return end
    if not tireHealth[vehicle] then return end

    local lowest = 100
    for i = 0, 3 do
        lowest = math.min(lowest, tireHealth[vehicle][i] or 100)
    end

    SetVehicleReduceGrip(vehicle, lowest < Config.TireWear.GripPenaltyBelow)
end

CreateThread(function()
    lastWearTick = GetGameTimer()

    while true do
        Wait(Config.TireWear.TickMs)

        local ped = PlayerPedId()
        if not IsPedInAnyVehicle(ped, false) then
            lastWearTick = GetGameTimer()
            goto continue
        end

        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle == 0 or not DoesEntityExist(vehicle) then
            lastWearTick = GetGameTimer()
            goto continue
        end

        local now = GetGameTimer()
        local dt = (now - lastWearTick) / 1000.0
        lastWearTick = now

        applyTireWear(vehicle, dt)
        updateGrip(vehicle)

        ::continue::
    end
end)

-- =========================
-- Percent getters
-- =========================

local function getPartPercent(vehicle, part)
    if part.type == "engine" or part.type == "door" then
        return math.floor((partHealth[part.id] or 100) + 0.5)
    end

    if part.type == "wheel" then
        ensureTires(vehicle)
        return math.floor((tireHealth[vehicle][part.wheelIndex] or 100) + 0.5)
    end

    return 100
end

-- =========================
-- Repair (SYNC CUSTOM + GTA NATIVE)
-- =========================

local function repairPart(vehicle, part)

    if part.type == "engine" then
        partHealth[part.id] = 100

        SetVehicleEngineHealth(vehicle, 1000.0)
        SetVehicleUndriveable(vehicle, false)
        SetVehicleEngineOn(vehicle, true, true, false)

    elseif part.type == "door" then
        partHealth[part.id] = 100

        -- Close the door properly
        if part.doorIndex ~= nil then
            SetVehicleDoorShut(vehicle, part.doorIndex, false)
        end

        -- Restore body integrity (fix dents affecting door)
        SetVehicleBodyHealth(vehicle, 1000.0)

    elseif part.type == "wheel" then
        ensureTires(vehicle)
        tireHealth[vehicle][part.wheelIndex] = 100

        SetVehicleTyreFixed(vehicle, part.wheelIndex)
    end

    -- General visual cleanup
    SetVehiclePetrolTankHealth(vehicle, 1000.0)
end

-- =========================
-- Inspect toggle
-- =========================

local function stopInspect()
    inspecting = false
    veh = 0
    initPartHealth()
    if lib and lib.hideTextUI then lib.hideTextUI() end
end

local function startInspect(vehicle)
    inspecting = true
    veh = vehicle
    initPartHealth()
    ensureTires(vehicle)
    if lib and lib.showTextUI then lib.showTextUI("Inspecting vehicle (toggle again to close)") end
end

local function toggleInspect(vehicle)
    if inspecting then
        stopInspect()
        return
    end

    if vehicle ~= 0 and DoesEntityExist(vehicle) then
        startInspect(vehicle)
    end
end

-- =========================
-- ox_target option
-- =========================

CreateThread(function()
    exports.ox_target:addGlobalVehicle({
        {
            name = "vehicle_inspect_toggle",
            label = "Inspect vehicle",
            icon = "fa-solid fa-magnifying-glass",
            distance = Config.TargetDistance,
            canInteract = function(entity)
                return not IsPedInAnyVehicle(PlayerPedId(), false)
            end,
            onSelect = function(data)
                toggleInspect(data.entity)
            end
        }
    })
end)

-- =========================
-- Inspect overlay loop
-- =========================

CreateThread(function()
    while true do
        if inspecting and veh ~= 0 and DoesEntityExist(veh) then
            local ped = PlayerPedId()
            local pCoords = GetEntityCoords(ped)
            local vCoords = GetEntityCoords(veh)

            if #(pCoords - vCoords) > Config.ViewDistance then
                Wait(250)
            else
                updateCustomPartDamage(veh)

                for _, part in ipairs(Config.Parts) do
                    local pos = getBonePos(veh, part.bone)
                    if pos then
                        local percent = getPartPercent(veh, part)
                        local good = (percent >= Config.GoodThreshold)

                        local onScreen, sx, sy = GetScreenCoordFromWorldCoord(pos.x, pos.y, pos.z + 0.15)
                        if onScreen then
                            drawSpriteIcon(sx, sy, good)
                            drawText2D(sx + 0.012, sy - 0.008, (("%s %d%%"):format(part.label, percent)))
                        end

                        local dist = #(pCoords - vec3(pos.x, pos.y, pos.z))
                        if percent < 100 and dist <= Config.RepairDistance and hasWrench() then
                            if onScreen then
                                drawText2D(sx, sy + 0.020, "[E] Repair")
                            end

                            if IsControlJustPressed(0, 38) then -- E
                                if lib.progressBar({
                                    duration = Config.RepairTime,
                                    label = ("Repairing %s"):format(part.label),
                                    canCancel = true,
                                    disable = { move = true, combat = true }
                                }) then
                                    repairPart(veh, part)
                                end
                            end
                        end
                    end
                end

                Wait(0)
            end
        else
            Wait(400)
        end
    end
end)