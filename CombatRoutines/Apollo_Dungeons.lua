-- Apollo Dungeons
local Apollo = Apollo or {}
Apollo.Dungeons = {}

-- Dungeon IDs
Apollo.Dungeons.IDS = {
    SASTASHA = "Sastasha",
    -- Add more dungeon IDs as needed
}

-- Track current duty state
Apollo.Dungeons.currentDuty = nil
Apollo.Dungeons.currentMap = nil
Apollo.Dungeons.lastPulseTime = 0
Apollo.Dungeons.registeredDungeons = {}

-- Initialize Apollo's dungeon mechanics
function Apollo.Dungeons.Initialize()
    Debug.Info("DUNGEONS", "Starting initialization")
    
    -- Initialize Olympus dungeon system
    Olympus.Dungeons.Initialize()
    
    -- Check initial state
    Apollo.Dungeons.CheckAndRegisterDungeon()

    Debug.Info("DUNGEONS", "Initialization complete")
end

-- Unified function to check and register dungeon mechanics
function Apollo.Dungeons.CheckAndRegisterDungeon()
    local currentMap = Player.localmapid
    local activeDuty = Duty:GetActiveDutyInfo()
    local dungeonName = activeDuty and activeDuty.name

    -- Unregister mechanics if we're not in a valid dungeon anymore
    if (currentMap ~= 1036 and Apollo.Dungeons.registeredDungeons.SASTASHA) or 
       (dungeonName ~= "Sastasha" and Apollo.Dungeons.registeredDungeons.SASTASHA) then
        Debug.Info("DUNGEONS", "Left Sastasha, unregistering mechanics")
        Olympus.Dungeons.RegisterMechanics(Apollo.Dungeons.IDS.SASTASHA, {})
        Apollo.Dungeons.registeredDungeons.SASTASHA = false
    end

    -- Register Sastasha mechanics if needed
    if (currentMap == 1036 or dungeonName == "Sastasha") and 
       not Apollo.Dungeons.registeredDungeons.SASTASHA then
        Debug.Info("DUNGEONS", "Registering Sastasha mechanics")
        Apollo.Dungeons.RegisterSastashaMechanics()
        Apollo.Dungeons.registeredDungeons.SASTASHA = true
    end

    -- Update tracking variables
    Apollo.Dungeons.currentMap = currentMap
    Apollo.Dungeons.currentDuty = dungeonName
end

-- Check map and update state on each pulse
function Apollo.Dungeons.Pulse()
    -- Throttle checks to every 1 seconds
    local currentTime = os.time()
    if (currentTime - Apollo.Dungeons.lastPulseTime) >= 1 then
        Apollo.Dungeons.lastPulseTime = currentTime
        
        -- Check for any state changes and register/unregister mechanics as needed
        Apollo.Dungeons.CheckAndRegisterDungeon()
        
        -- Let Olympus system handle mechanic checks and safe positions
        if Olympus.Dungeons.CheckMechanics() then
            Debug.Info("DUNGEONS", "Active mechanic detected")
        end
    end
end

-- Register Sastasha mechanics
function Apollo.Dungeons.RegisterSastashaMechanics()
    Debug.Info("DUNGEONS", "Starting Sastasha mechanics registration")
    
    local sastashaMechanics = {
        -- Captain Madison's mechanics
        [1] = {
            type = Olympus.Dungeons.MECHANIC_TYPES.DODGE,
            name = "Slashing Resistance Down",
            castId = 569,
            position = nil, -- Will be set during combat
            radius = 5
        },
        
        -- Chopper's mechanics
        [2] = {
            type = Olympus.Dungeons.MECHANIC_TYPES.TANKBUSTER,
            name = "Clamp",
            castId = 570,
            targetId = 0 -- Will be set during combat
        },
        
        -- Denn the Orcatoothed's mechanics
        [3] = {
            type = Olympus.Dungeons.MECHANIC_TYPES.AOE,
            name = "Sahagin Call",
            castId = 571,
            sourceId = 0, -- Will be set during combat
            radius = 8
        },
        
        -- Bubble Bomb mechanic
        [4] = {
            type = Olympus.Dungeons.MECHANIC_TYPES.SPREAD,
            name = "Bubble Bomb",
            castId = 572,
            radius = 5
        },
        
        -- Clamp target mechanic
        [5] = {
            type = Olympus.Dungeons.MECHANIC_TYPES.STACK,
            name = "Clamp Target",
            castId = 573,
            targetId = 0 -- Will be set during combat
        }
    }
    
    -- Register mechanics with the Olympus system
    Olympus.Dungeons.RegisterMechanics(Apollo.Dungeons.IDS.SASTASHA, sastashaMechanics)
    Debug.Info("DUNGEONS", string.format("Registered %d mechanics for Sastasha", #sastashaMechanics))
end

return Apollo.Dungeons
