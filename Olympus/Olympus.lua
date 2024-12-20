-- Olympus
Olympus = Olympus or {}

-- State variables
local isRunning = false

-- Constants
Olympus.BUFF_IDS = {
    SWIFTCAST = 167,
    -- Add other buff IDs here
}

Olympus.COMMON_SPELLS = {
    SPRINT = { id = 3, level = 1, isGCD = false, mp = 0 },
    SWIFTCAST = { id = 7561, level = 18, isGCD = false, cooldown = 60, mp = 0 },
    SURECAST = { id = 7559, level = 44, isGCD = false, cooldown = 120, mp = 0 },
    RESCUE = { id = 7571, level = 48, isGCD = false, cooldown = 120, range = 30, mp = 0 },
    ESUNA = { id = 7568, level = 10, isGCD = true, range = 30, mp = 400 },
    RAISE = { id = 125, level = 12, isGCD = true, range = 30, mp = 2400 },
    REPOSE = { id = 16560, level = 8, isGCD = true, range = 30, mp = 400 }
}

-- Initialize core systems
function Olympus.Initialize()
    Debug.TrackFunctionStart("Olympus.Initialize")
    Debug.Info(Debug.CATEGORIES.SYSTEM, "Starting Project Remedy initialization...")
    
    -- Add debug status check
    Debug.Info(Debug.CATEGORIES.SYSTEM, string.format("Debug Status - Enabled: %s, Level: %d, Performance Category: %s", 
        tostring(Debug.enabled),
        Debug.level,
        tostring(Debug.categoryEnabled.PERFORMANCE)))
    
    -- Initialize core systems first
    Debug.Info(Debug.CATEGORIES.SYSTEM, "Initializing core systems...")
    
    -- Initialize Performance module
    Olympus.Performance.Initialize()
    -- Set default thresholds (16ms frame budget)
    Olympus.Performance.SetThresholds(0.016, true) -- 16ms in seconds
    -- Start frame time tracking
    Olympus.Performance.StartFrameTimeTracking()
    Debug.Info(Debug.CATEGORIES.SYSTEM, "Performance monitoring initialized")
    
    -- Initialize Combat module
    Olympus.Combat.Initialize()
    Debug.Info(Debug.CATEGORIES.SYSTEM, "Combat system initialized")
    
    -- Initialize features
    Debug.Info(Debug.CATEGORIES.SYSTEM, "Initializing features...")
    
    -- Initialize Party module
    Olympus.Party.Initialize()
    Debug.Info(Debug.CATEGORIES.SYSTEM, "Party system initialized")
    
    -- Initialize Targeting module
    Olympus.Targeting.Initialize()
    Debug.Info(Debug.CATEGORIES.SYSTEM, "Targeting system initialized")
    
    -- Initialize dungeon system if available
    if Olympus.Dungeons then
        Olympus.Dungeons.Initialize()
        Debug.Info(Debug.CATEGORIES.SYSTEM, "Dungeon system initialized")
    end
    
    Debug.Info(Debug.CATEGORIES.SYSTEM, "Project Remedy initialization complete")
    Debug.TrackFunctionEnd("Olympus.Initialize")
end

-- Toggle Olympus on/off
function Olympus.Toggle()
    isRunning = not isRunning
    if isRunning then
        Debug.Info(Debug.CATEGORIES.SYSTEM, "Olympus started")
    else
        Debug.Info(Debug.CATEGORIES.SYSTEM, "Olympus stopped")
    end
end

-- Check if Olympus is running
function Olympus.IsRunning()
    return isRunning
end

-- Draw GUI
function Olympus.OnGUI()
    GUI.Draw()
end

-- Expose Combat functions directly on Olympus for backward compatibility
Olympus.CastAction = function(spell, targetId)
    -- If this is an Apollo spell and Apollo is loaded, check if it's enabled
    if Apollo and spell then
        for spellName, spellData in pairs(Apollo.SPELLS) do
            if spellData.id == spell.id then
                if not Apollo.IsSpellEnabled(spellName) then
                    Debug.Verbose(Debug.CATEGORIES.SPELL_SYSTEM, string.format("Spell %s is disabled", spellName))
                    return false
                end
                break
            end
        end
    end
    
    -- Proceed with normal cast logic
    return Olympus.Combat.CastAction(spell, targetId)
end

return Olympus