-- Apollo Combat Routine
-- A White Mage (WHM) combat routine for FFXIV
--------------------------------------------------------------------------------

--[[
    Table of Contents:
    1. Constants and Configuration
    2. Core System
    3. Combat Logic
    4. Healing Systems
    5. Damage Systems
    6. Utility Functions
    7. Event Handlers
    8. Initialization
--]]

--------------------------------------------------------------------------------
-- 1. Constants and Configuration
--------------------------------------------------------------------------------

Apollo = {}

-- Define Apollo's settings schema
Apollo.SETTINGS_SCHEMA = {
    -- Resource Management
    MPThreshold = { type = "number", default = 80, description = "MP threshold for recovery abilities" },
    HealingRange = { type = "number", default = 30, description = "Maximum healing range" },
    
    -- Single Target Healing
    CureThreshold = { type = "number", default = 85, description = "HP% for Cure" },
    CureIIThreshold = { type = "number", default = 65, description = "HP% for Cure II" },
    CureIIIThreshold = { type = "number", default = 50, description = "HP% for Cure III" },
    RegenThreshold = { type = "number", default = 80, description = "HP% for Regen" },
    BenedictionThreshold = { type = "number", default = 25, description = "HP% for Benediction" },
    TetragrammatonThreshold = { type = "number", default = 60, description = "HP% for Tetragrammaton" },
    BenisonThreshold = { type = "number", default = 90, description = "HP% for Divine Benison" },
    AquaveilThreshold = { type = "number", default = 85, description = "HP% for Aquaveil" },
    
    -- AoE Healing
    CureIIIMinTargets = { type = "number", default = 3, description = "Minimum targets for Cure III" },
    HolyMinTargets = { type = "number", default = 2, description = "Minimum targets for Holy" },
    AsylumThreshold = { type = "number", default = 80, description = "HP% for Asylum" },
    AsylumMinTargets = { type = "number", default = 2, description = "Minimum targets for Asylum" },
    AssizeMinTargets = { type = "number", default = 1, description = "Minimum targets for Assize" },
    PlenaryThreshold = { type = "number", default = 65, description = "HP% for Plenary Indulgence" },
    TemperanceThreshold = { type = "number", default = 70, description = "HP% for Temperance" },
    LiturgyThreshold = { type = "number", default = 75, description = "HP% for Liturgy of the Bell" },
    LiturgyMinTargets = { type = "number", default = 2, description = "Minimum targets for Liturgy" }
}

--[[ Core Settings ]]--
Apollo.THRESHOLDS = {}

--[[ Buff IDs ]]--
Apollo.BUFFS = {
    -- Healing Buffs
    FREECURE = 155,      -- Free Cure II proc
    MEDICA_II = 150,     -- AoE HoT
    REGEN = 158,         -- Single target HoT
    
    -- Mitigation Buffs
    DIVINE_BENISON = 1218, -- Single target shield
    AQUAVEIL = 2708       -- Damage reduction
}

--[[ DoT Tracking ]]--
Apollo.DOT_BUFFS = {
    [143] = true,  -- Aero
    [144] = true,  -- Aero II
    [1871] = true  -- Dia
}

--[[ Spell Configuration ]]--
Apollo.SPELLS = {
    -- Direct Damage GCDs (Stone/Glare progression)
    STONE = { id = 119, mp = 200, instant = false, range = 25, category = "Damage", level = 1, isGCD = true },
    STONE_II = { id = 127, mp = 200, instant = false, range = 25, category = "Damage", level = 18, isGCD = true },
    STONE_III = { id = 3568, mp = 400, instant = false, range = 25, category = "Damage", level = 54, isGCD = true },
    STONE_IV = { id = 7431, mp = 400, instant = false, range = 25, category = "Damage", level = 64, isGCD = true },
    GLARE = { id = 16533, mp = 400, instant = false, range = 25, category = "Damage", level = 72, isGCD = true },
    GLARE_III = { id = 25859, mp = 400, instant = false, range = 25, category = "Damage", level = 82, isGCD = true },

    -- Single Target Healing GCDs
    CURE = { id = 120, mp = 400, instant = false, range = 30, category = "Healing", level = 2, isGCD = true },
    CURE_II = { id = 135, mp = 1000, instant = false, range = 30, category = "Healing", level = 30, isGCD = true },
    CURE_III = { id = 131, mp = 1500, instant = false, range = 30, category = "Healing", level = 40, isGCD = true },
    REGEN = { id = 137, mp = 500, instant = true, range = 30, category = "Healing", level = 35, isGCD = true },

    -- Single Target Healing oGCDs
    BENEDICTION = { id = 140, mp = 0, instant = true, range = 30, category = "Healing", level = 50, cooldown = 180, isGCD = false },
    TETRAGRAMMATON = { id = 3570, mp = 0, instant = true, range = 30, category = "Healing", level = 60, cooldown = 60, isGCD = false },
    DIVINE_BENISON = { id = 7432, mp = 0, instant = true, range = 30, category = "Healing", level = 66, cooldown = 30, isGCD = false },
    AQUAVEIL = { id = 25861, mp = 0, instant = true, range = 30, category = "Buff", level = 86, cooldown = 60, isGCD = false },

    -- AoE Healing GCDs
    MEDICA = { id = 124, mp = 1000, instant = false, range = 15, category = "Healing", level = 10, isGCD = true },
    MEDICA_II = { id = 133, mp = 1000, instant = false, range = 20, category = "Healing", level = 50, isGCD = true },

    -- AoE Healing oGCDs
    ASYLUM = { id = 3569, mp = 0, instant = true, range = 30, category = "Healing", level = 52, cooldown = 90, isGCD = false },
    ASSIZE = { id = 3571, mp = 0, instant = true, range = 15, category = "Hybrid", level = 56, cooldown = 45, isGCD = false },
    PLENARY_INDULGENCE = { id = 7433, mp = 0, instant = true, range = 0, category = "Healing", level = 70, cooldown = 60, isGCD = false },
    LITURGY_OF_THE_BELL = { id = 25862, mp = 0, instant = true, range = 20, category = "Healing", level = 90, cooldown = 180, isGCD = false },
    TEMPERANCE = { id = 16536, mp = 0, instant = true, range = 0, category = "Buff", level = 80, cooldown = 120, isGCD = false },

    -- DoTs and AoE Damage GCDs
    AERO = { id = 121, mp = 400, instant = true, range = 25, category = "Damage", level = 4, isGCD = true },
    AERO_II = { id = 132, mp = 400, instant = true, range = 25, category = "Damage", level = 46, isGCD = true },
    DIA = { id = 16532, mp = 400, instant = true, range = 25, category = "Damage", level = 72, isGCD = true },
    HOLY = { id = 139, mp = 400, instant = false, range = 8, category = "Damage", level = 45, isGCD = true },
    HOLY_III = { id = 25860, mp = 400, instant = false, range = 8, category = "Damage", level = 82, isGCD = true },

    -- Utility oGCDs
    PRESENCE_OF_MIND = { id = 136, mp = 0, instant = true, range = 0, category = "Buff", level = 30, isGCD = false },
    THIN_AIR = { id = 7430, mp = 0, instant = true, range = 0, category = "Buff", level = 58, cooldown = 120, isGCD = false },
    AETHERIAL_SHIFT = { id = 37008, mp = 0, instant = true, range = 0, category = "Movement", level = 40, cooldown = 60, isGCD = false },

    -- Lily System GCDs
    AFFLATUS_SOLACE = { id = 16531, mp = 0, instant = true, range = 30, category = "Healing", level = 52, isGCD = true },
    AFFLATUS_RAPTURE = { id = 16534, mp = 0, instant = true, range = 20, category = "Healing", level = 76, isGCD = true },
    AFFLATUS_MISERY = { id = 16535, mp = 0, instant = false, range = 25, category = "Damage", level = 74, isGCD = true },

    -- Resource Management
    LUCID_DREAMING = { id = 7562, mp = 0, instant = true, range = 0, category = "Utility", level = 70, cooldown = 60, isGCD = false }
}

--[[ MP Cost Optimization ]]--
Apollo.EXPENSIVE_SPELLS = {
    [Apollo.SPELLS.CURE_III.id] = true,     -- 1500 MP
    [Apollo.SPELLS.MEDICA.id] = true,       -- 1000 MP
    [Apollo.SPELLS.MEDICA_II.id] = true,    -- 1000 MP
    [Apollo.SPELLS.CURE_II.id] = true       -- 1000 MP
}

--[[ Job Compatibility ]]--
Apollo.classes = {
    [FFXIV.JOBS.WHITEMAGE] = true,
    [FFXIV.JOBS.CONJURER] = true,
}

-- Add common spells if they exist
if Olympus and Olympus.COMMON_SPELLS and type(Olympus.COMMON_SPELLS) == "table" then
    if Debug then
        Debug.Info(Debug.CATEGORIES.SYSTEM, "Adding common spells to Apollo spell list")
    end
    for name, spell in pairs(Olympus.COMMON_SPELLS) do
        Apollo.SPELLS[name] = spell
    end
end

-- Initialize settings and systems
Apollo.SETTINGS = Olympus.Settings.CreateSchema(Apollo.SETTINGS_SCHEMA)
Olympus.SpellToggles.Initialize(Apollo.SPELLS)

-- Update spell toggle functions to use Olympus system
function Apollo.IsSpellEnabled(spellName)
    return Olympus.SpellToggles.IsEnabled(spellName)
end

function Apollo.ToggleSpell(spellName)
    return Olympus.SpellToggles.Toggle(spellName, Apollo.SPELLS[spellName])
end

-- Update performance monitoring
function Apollo.UpdatePerformanceMetrics(castTime, wasSuccessful)
    Olympus.Performance.UpdateCastMetrics(castTime, wasSuccessful)
end

function Apollo.GetPerformanceMetrics()
    return Olympus.Performance.GetMetrics()
end

-- Update combat phase detection
function Apollo.DetectCombatPhase()
    return Olympus.Combat.DetectPhase({
        range = Apollo.SETTINGS.HealingRange,
        threshold = Apollo.SETTINGS.CureThreshold,
        aoeThreshold = 3,
        emergencyThreshold = Apollo.SETTINGS.BenedictionThreshold,
        mpThreshold = Apollo.SETTINGS.MPThreshold
    })
end

--[[ Core Settings ]]--
Apollo.THRESHOLDS = {}

--[[ Buff IDs ]]--
Apollo.BUFFS = {
    -- Healing Buffs
    FREECURE = 155,      -- Free Cure II proc
    MEDICA_II = 150,     -- AoE HoT
    REGEN = 158,         -- Single target HoT
    
    -- Mitigation Buffs
    DIVINE_BENISON = 1218, -- Single target shield
    AQUAVEIL = 2708       -- Damage reduction
}

--[[ DoT Tracking ]]--
Apollo.DOT_BUFFS = {
    [143] = true,  -- Aero
    [144] = true,  -- Aero II
    [1871] = true  -- Dia
}

--[[ Spell Configuration ]]--
Apollo.SPELLS = {
    -- Direct Damage GCDs (Stone/Glare progression)
    STONE = { id = 119, mp = 200, instant = false, range = 25, category = "Damage", level = 1, isGCD = true },
    STONE_II = { id = 127, mp = 200, instant = false, range = 25, category = "Damage", level = 18, isGCD = true },
    STONE_III = { id = 3568, mp = 400, instant = false, range = 25, category = "Damage", level = 54, isGCD = true },
    STONE_IV = { id = 7431, mp = 400, instant = false, range = 25, category = "Damage", level = 64, isGCD = true },
    GLARE = { id = 16533, mp = 400, instant = false, range = 25, category = "Damage", level = 72, isGCD = true },
    GLARE_III = { id = 25859, mp = 400, instant = false, range = 25, category = "Damage", level = 82, isGCD = true },

    -- Single Target Healing GCDs
    CURE = { id = 120, mp = 400, instant = false, range = 30, category = "Healing", level = 2, isGCD = true },
    CURE_II = { id = 135, mp = 1000, instant = false, range = 30, category = "Healing", level = 30, isGCD = true },
    CURE_III = { id = 131, mp = 1500, instant = false, range = 30, category = "Healing", level = 40, isGCD = true },
    REGEN = { id = 137, mp = 500, instant = true, range = 30, category = "Healing", level = 35, isGCD = true },

    -- Single Target Healing oGCDs
    BENEDICTION = { id = 140, mp = 0, instant = true, range = 30, category = "Healing", level = 50, cooldown = 180, isGCD = false },
    TETRAGRAMMATON = { id = 3570, mp = 0, instant = true, range = 30, category = "Healing", level = 60, cooldown = 60, isGCD = false },
    DIVINE_BENISON = { id = 7432, mp = 0, instant = true, range = 30, category = "Healing", level = 66, cooldown = 30, isGCD = false },
    AQUAVEIL = { id = 25861, mp = 0, instant = true, range = 30, category = "Buff", level = 86, cooldown = 60, isGCD = false },

    -- AoE Healing GCDs
    MEDICA = { id = 124, mp = 1000, instant = false, range = 15, category = "Healing", level = 10, isGCD = true },
    MEDICA_II = { id = 133, mp = 1000, instant = false, range = 20, category = "Healing", level = 50, isGCD = true },

    -- AoE Healing oGCDs
    ASYLUM = { id = 3569, mp = 0, instant = true, range = 30, category = "Healing", level = 52, cooldown = 90, isGCD = false },
    ASSIZE = { id = 3571, mp = 0, instant = true, range = 15, category = "Hybrid", level = 56, cooldown = 45, isGCD = false },
    PLENARY_INDULGENCE = { id = 7433, mp = 0, instant = true, range = 0, category = "Healing", level = 70, cooldown = 60, isGCD = false },
    LITURGY_OF_THE_BELL = { id = 25862, mp = 0, instant = true, range = 20, category = "Healing", level = 90, cooldown = 180, isGCD = false },
    TEMPERANCE = { id = 16536, mp = 0, instant = true, range = 0, category = "Buff", level = 80, cooldown = 120, isGCD = false },

    -- DoTs and AoE Damage GCDs
    AERO = { id = 121, mp = 400, instant = true, range = 25, category = "Damage", level = 4, isGCD = true },
    AERO_II = { id = 132, mp = 400, instant = true, range = 25, category = "Damage", level = 46, isGCD = true },
    DIA = { id = 16532, mp = 400, instant = true, range = 25, category = "Damage", level = 72, isGCD = true },
    HOLY = { id = 139, mp = 400, instant = false, range = 8, category = "Damage", level = 45, isGCD = true },
    HOLY_III = { id = 25860, mp = 400, instant = false, range = 8, category = "Damage", level = 82, isGCD = true },

    -- Utility oGCDs
    PRESENCE_OF_MIND = { id = 136, mp = 0, instant = true, range = 0, category = "Buff", level = 30, isGCD = false },
    THIN_AIR = { id = 7430, mp = 0, instant = true, range = 0, category = "Buff", level = 58, cooldown = 120, isGCD = false },
    AETHERIAL_SHIFT = { id = 37008, mp = 0, instant = true, range = 0, category = "Movement", level = 40, cooldown = 60, isGCD = false },

    -- Lily System GCDs
    AFFLATUS_SOLACE = { id = 16531, mp = 0, instant = true, range = 30, category = "Healing", level = 52, isGCD = true },
    AFFLATUS_RAPTURE = { id = 16534, mp = 0, instant = true, range = 20, category = "Healing", level = 76, isGCD = true },
    AFFLATUS_MISERY = { id = 16535, mp = 0, instant = false, range = 25, category = "Damage", level = 74, isGCD = true },

    -- Resource Management
    LUCID_DREAMING = { id = 7562, mp = 0, instant = true, range = 0, category = "Utility", level = 70, cooldown = 60, isGCD = false }
}

--[[ Spell Categories and Toggles ]]--
Apollo.SPELL_TOGGLES = {
    enabled = {}, -- Will be initialized with all spells enabled
    categories = {
        ["Damage"] = true,
        ["Healing"] = true,
        ["Buff"] = true,
        ["Utility"] = true,
        ["Movement"] = true
    }
}

-- Initialize all spells as enabled by default
for spellName, _ in pairs(Apollo.SPELLS) do
    Apollo.SPELL_TOGGLES.enabled[spellName] = true
end

--[[ MP Cost Optimization ]]--
Apollo.EXPENSIVE_SPELLS = {
    [Apollo.SPELLS.CURE_III.id] = true,     -- 1500 MP
    [Apollo.SPELLS.MEDICA.id] = true,       -- 1000 MP
    [Apollo.SPELLS.MEDICA_II.id] = true,    -- 1000 MP
    [Apollo.SPELLS.CURE_II.id] = true       -- 1000 MP
}

--[[ Job Compatibility ]]--
Apollo.classes = {
    [FFXIV.JOBS.WHITEMAGE] = true,
    [FFXIV.JOBS.CONJURER] = true,
}

-- Add common spells if they exist
if Olympus and Olympus.COMMON_SPELLS and type(Olympus.COMMON_SPELLS) == "table" then
    if Debug then
        Debug.Info(Debug.CATEGORIES.SYSTEM, "Adding common spells to Apollo spell list")
    end
    for name, spell in pairs(Olympus.COMMON_SPELLS) do
        Apollo.SPELLS[name] = spell
    end
end

--------------------------------------------------------------------------------
-- 2. Core System
--------------------------------------------------------------------------------

--[[ Core State Management ]]--
Apollo.State = {
    strictHealing = false,
    performanceMetrics = {
        lastCastTime = 0,
        averageCastTime = 0,
        castCount = 0
    }
}

--[[ Core System Functions ]]--

-- Toggle the Apollo system on/off
function Apollo.Toggle()
    Debug.TrackFunctionStart("Apollo.Toggle")
    
    local newState = not Apollo.IsRunning()
    Olympus.State.SetModuleRunning("Apollo", newState)
    
    Debug.Info(Debug.CATEGORIES.SYSTEM, string.format(
        "Apollo %s",
        newState and "started" or "stopped"
    ))
    
    Debug.TrackFunctionEnd("Apollo.Toggle")
end

-- Check if Apollo is currently running
function Apollo.IsRunning()
    return Olympus.State.IsModuleRunning("Apollo")
end

--[[ Spell Management ]]--

-- Check if a specific spell is enabled
function Apollo.IsSpellEnabled(spellName)
    return Olympus.SpellToggles.IsEnabled(spellName)
end

-- Toggle a spell's enabled status
function Apollo.ToggleSpell(spellName)
    return Olympus.SpellToggles.Toggle(spellName, Apollo.SPELLS[spellName])
end

-- Get all spells of a specific category
function Apollo.GetSpellsByCategory(category)
    local spells = {}
    for spellName, spell in pairs(Apollo.SPELLS) do
        if spell.category == category then
            spells[spellName] = spell
        end
    end
    return spells
end

--[[ Performance Monitoring ]]--

-- Update performance metrics after a cast
function Apollo.UpdatePerformanceMetrics(castTime, wasSuccessful)
    Olympus.Performance.UpdateCastMetrics(castTime, wasSuccessful)
    
    -- Update module metrics
    local metrics = Olympus.Performance.GetMetrics()
    Olympus.State.UpdateModuleMetrics("Apollo", metrics)
end

-- Get current performance metrics
function Apollo.GetPerformanceMetrics()
    return Olympus.Performance.GetMetrics()
end

--[[ Error Handling ]]--

-- Set the last error that occurred
function Apollo.SetError(errorMessage)
    Olympus.Error.SetError(errorMessage, "Apollo")
end

-- Get the last error that occurred
function Apollo.GetLastError()
    return Olympus.Error.GetLastError()
end

--[[ System Status ]]--

-- Get the current system status
function Apollo.GetStatus()
    local moduleState = Olympus.State.GetModuleState("Apollo")
    return {
        running = moduleState.running,
        strictHealing = Apollo.State.strictHealing,
        lastError = Apollo.GetLastError(),
        performance = moduleState.metrics
    }
end

-- Reset the system state
function Apollo.Reset()
    Debug.TrackFunctionStart("Apollo.Reset")
    
    -- Reset module state
    Olympus.State.ResetModuleState("Apollo")
    
    -- Reset local state
    Apollo.State.strictHealing = false
    Apollo.State.performanceMetrics = {
        lastCastTime = 0,
        averageCastTime = 0,
        castCount = 0
    }
    
    -- Reset performance metrics
    Olympus.Performance.ResetMetrics()
    
    Debug.Info(Debug.CATEGORIES.SYSTEM, "Apollo system state reset")
    Debug.TrackFunctionEnd("Apollo.Reset")
end

-- Toggle strict healing mode
function Apollo.ToggleStrictHealing()
    Apollo.State.strictHealing = not Apollo.State.strictHealing
    Debug.Info(Debug.CATEGORIES.SYSTEM, string.format(
        "Strict healing mode %s",
        Apollo.State.strictHealing and "enabled" or "disabled"
    ))
end

--------------------------------------------------------------------------------
-- 3. Combat Logic
--------------------------------------------------------------------------------

--[[ Combat State Management ]]--
Apollo.CombatState = {
    currentPhase = "NORMAL",
    lastCastTime = 0,
    lastTarget = nil,
    isAoEPhase = false,
    emergencyMode = false
}

function Apollo.HandleBuffs()
    Debug.TrackFunctionStart("Apollo.HandleBuffs")
    
    if not Player.incombat then 
        Debug.Verbose(Debug.CATEGORIES.BUFFS, "Not in combat, skipping buffs")
        Debug.TrackFunctionEnd("Apollo.HandleBuffs")
        return false 
    end

    -- Handle role-specific buffs first
    if Olympus.Buff.HandleRoleBuffs() then
        Debug.TrackFunctionEnd("Apollo.HandleBuffs")
        return true
    end

    -- Presence of Mind
    if Player.level >= Apollo.SPELLS.PRESENCE_OF_MIND.level then
        local enemies = EntityList("alive,attackable,incombat,maxdistance=25")
        if table.valid(enemies) then
            Debug.Info(Debug.CATEGORIES.BUFFS, "Attempting to cast Presence of Mind")
            if Olympus.CastAction(Apollo.SPELLS.PRESENCE_OF_MIND) then 
                Debug.TrackFunctionEnd("Apollo.HandleBuffs")
                return true 
            end
        else
            Debug.Verbose(Debug.CATEGORIES.BUFFS, "No valid enemies for Presence of Mind")
        end
    else
        Debug.Verbose(Debug.CATEGORIES.BUFFS, "Level too low for Presence of Mind")
    end

    -- Thin Air
    if Player.level >= Apollo.SPELLS.THIN_AIR.level then
        if Player.mp.percent <= Apollo.SETTINGS.MPThreshold then
            Debug.Info(Debug.CATEGORIES.BUFFS, 
                string.format("MP below threshold (%.1f%%), attempting Thin Air", 
                    Player.mp.percent))
            if Olympus.CastAction(Apollo.SPELLS.THIN_AIR) then 
                Debug.TrackFunctionEnd("Apollo.HandleBuffs")
                return true 
            end
        else
            Debug.Verbose(Debug.CATEGORIES.BUFFS, 
                string.format("MP sufficient (%.1f%%), skipping Thin Air", 
                    Player.mp.percent))
        end
    else
        Debug.Verbose(Debug.CATEGORIES.BUFFS, "Level too low for Thin Air")
    end

    Debug.Verbose(Debug.CATEGORIES.BUFFS, "No buffs needed")
    Debug.TrackFunctionEnd("Apollo.HandleBuffs")
    return false
end

--[[ Combat Phase Detection ]]--
function Apollo.DetectCombatPhase()
    return Olympus.Combat.DetectPhase({
        range = Apollo.SETTINGS.HealingRange,
        threshold = Apollo.SETTINGS.CureThreshold,
        aoeThreshold = 3,
        emergencyThreshold = Apollo.SETTINGS.BenedictionThreshold,
        mpThreshold = Apollo.SETTINGS.MPThreshold
    })
end

--[[ MP Management ]]--
function Apollo.HandleMPConservation()
    Debug.TrackFunctionStart("Apollo.HandleMPConservation")
    
    -- Use Olympus's MP conservation handler
    local result = Olympus.MP.HandleConservation()
    
    Debug.TrackFunctionEnd("Apollo.HandleMPConservation")
    return result
end

function Apollo.ShouldUseLucidDreaming()
    return Olympus.MP.ShouldUseLucidDreaming()
end

function Apollo.GetMPThreshold()
    Debug.TrackFunctionStart("Apollo.GetMPThreshold")
    
    -- Critical MP override
    if Player.mp.percent <= Olympus.MP.THRESHOLDS.CRITICAL then
        Debug.Info(Debug.CATEGORIES.COMBAT, "MP critically low, using emergency threshold")
        Debug.TrackFunctionEnd("Apollo.GetMPThreshold")
        return Olympus.MP.THRESHOLDS.CRITICAL
    end
    
    local phase = Apollo.CombatState.currentPhase
    local threshold = Olympus.MP.THRESHOLDS[phase] or Olympus.MP.THRESHOLDS.NORMAL
    
    Debug.Info(Debug.CATEGORIES.COMBAT, string.format(
        "MP threshold for %s phase: %d%%",
        phase,
        threshold
    ))
    
    Debug.TrackFunctionEnd("Apollo.GetMPThreshold")
    return threshold
end

--[[ Resource Management ]]--
function Apollo.ShouldUseThinAir(spellId)
    Debug.TrackFunctionStart("Apollo.ShouldUseThinAir")
    
    -- Skip if MP is healthy
    if Player.mp.percent > Apollo.THRESHOLDS.LUCID then
        Debug.Verbose(Debug.CATEGORIES.COMBAT, "MP healthy, saving Thin Air")
        Debug.TrackFunctionEnd("Apollo.ShouldUseThinAir")
        return false
    end
    
    -- Emergency MP conservation
    if Player.mp.percent <= Apollo.THRESHOLDS.EMERGENCY then
        Debug.Info(Debug.CATEGORIES.COMBAT, "Emergency MP conservation - using Thin Air")
        Debug.TrackFunctionEnd("Apollo.ShouldUseThinAir")
        return true
    end
    
    -- Prioritize expensive spells
    if Apollo.EXPENSIVE_SPELLS[spellId] then
        Debug.Info(Debug.CATEGORIES.COMBAT, string.format(
            "Using Thin Air for expensive spell (ID: %d)",
            spellId
        ))
        Debug.TrackFunctionEnd("Apollo.ShouldUseThinAir")
        return true
    end
    
    Debug.TrackFunctionEnd("Apollo.ShouldUseThinAir")
    return false
end

--[[ Main Combat Loop ]]--
function Apollo.Cast()
    Debug.TrackFunctionStart("Apollo.Cast")

    -- System state validation
    if not Olympus.State.IsModuleRunning("Apollo") then
        Debug.Verbose(Debug.CATEGORIES.SYSTEM, "Apollo is not running")
        Debug.TrackFunctionEnd("Apollo.Cast")
        return false
    end

    -- Update combat phase
    Apollo.DetectCombatPhase()

    Debug.Info(Debug.CATEGORIES.COMBAT, string.format(
        "Starting cast loop - Phase: %s, MP: %.1f%%, Combat: %s, Strict: %s",
        Apollo.CombatState.currentPhase,
        Player.mp.percent,
        tostring(Player.incombat),
        tostring(Apollo.State.strictHealing)
    ))

    -- Priority-based action handling
    local handlers = {
        -- Resource Management (Highest Priority)
        { func = Apollo.HandleMPConservation, name = "MP Conservation" },
        
        -- Recovery and Utility
        { func = Olympus.HandleSwiftcast, name = "Swiftcast" },
        { func = Olympus.HandleSurecast, name = "Surecast" },
        { func = Olympus.HandleRescue, name = "Rescue" },
        { func = function() return Olympus.HandleEsuna(Apollo.SETTINGS.HealingRange) end, name = "Esuna" },
        { func = function() return Olympus.HandleRaise(Apollo.SETTINGS.HealingRange) end, name = "Raise" },
        
        -- Core Combat Functions
        { func = Apollo.HandleMovement, name = "Movement" },
        { func = Apollo.HandleEmergencyHealing, name = "Emergency Healing" },
        { func = Apollo.HandleBuffs, name = "Buffs" },
        { func = Apollo.HandleMitigation, name = "Mitigation" },
        { func = Apollo.HandleLilySystem, name = "Lily System" }
    }
    
    -- Process non-essential healing if MP permits
    if Player.mp.percent > Olympus.MP.THRESHOLDS.EMERGENCY then
        table.insert(handlers, { func = Apollo.HandleAoEHealing, name = "AoE Healing" })
        table.insert(handlers, { func = Apollo.HandleSingleTargetHealing, name = "Single Target Healing" })
    else
        Debug.Info(Debug.CATEGORIES.COMBAT, "MP in emergency state - skipping non-essential healing")
        -- Handle critical healing in strict mode
        if Apollo.State.strictHealing then
            Debug.Info(Debug.CATEGORIES.HEALING, "Checking critical healing needs")
            local party = Olympus.GetParty(Apollo.SETTINGS.HealingRange)
            if table.valid(party) then
                for _, member in pairs(party) do
                    if member.hp.percent <= Apollo.SETTINGS.BenedictionThreshold then
                        table.insert(handlers, { func = Apollo.HandleAoEHealing, name = "Critical AoE Healing" })
                        table.insert(handlers, { func = Apollo.HandleSingleTargetHealing, name = "Critical Single Healing" })
                        break
                    end
                end
            end
        end
    end
    
    -- Add damage handling if MP permits and not in strict healing mode
    if Player.mp.percent > Olympus.MP.THRESHOLDS.EMERGENCY and not Apollo.State.strictHealing then
        Debug.Info(Debug.CATEGORIES.COMBAT, "Adding damage handler - MP sufficient and not in strict healing")
        table.insert(handlers, { func = Apollo.HandleDamage, name = "Damage" })
    end
    
    -- Execute handlers in priority order
    for _, handler in ipairs(handlers) do
        Debug.Info(Debug.CATEGORIES.COMBAT, string.format("Checking %s handler", handler.name))
        if handler.func() then
            Debug.Info(Debug.CATEGORIES.COMBAT, string.format("%s handled successfully", handler.name))
            -- Update performance metrics
            Apollo.CombatState.lastCastTime = os.clock()
            -- Check frame budget
            Olympus.Performance.IsFrameBudgetExceeded()
            Debug.TrackFunctionEnd("Apollo.Cast")
            return true
        end
    end

    Debug.Verbose(Debug.CATEGORIES.COMBAT, "No actions needed this tick")
    Olympus.Performance.IsFrameBudgetExceeded()
    Debug.TrackFunctionEnd("Apollo.Cast")
    return false
end

--------------------------------------------------------------------------------
-- 4. Healing Systems
--------------------------------------------------------------------------------

--[[ Healing State Management ]]--
Apollo.HealingState = {
    lastHealTarget = nil,
    lastHealTime = 0,
    aoeHealingNeeded = false,
    emergencyHealingNeeded = false,
    healingPriority = "NORMAL" -- NORMAL, AOE, EMERGENCY
}

--[[ Core Healing Utilities ]]--

function Apollo.HandleMitigation()
    Debug.TrackFunctionStart("Apollo.Mitigation.Handle")
    
    if not Player.incombat then 
        Debug.Verbose(Debug.CATEGORIES.HEALING, "Not in combat, skipping mitigation")
        Debug.TrackFunctionEnd("Apollo.Mitigation.Handle")
        return false 
    end

    local party = Apollo.ValidateParty()
    if not party then 
        Debug.TrackFunctionEnd("Apollo.Mitigation.Handle")
        return false 
    end

    -- Skip non-essential mitigation in strict healing mode
    if Apollo.State.strictHealing then
        Debug.Info(Debug.CATEGORIES.HEALING, "Strict healing mode - skipping non-essential mitigation")
        Debug.TrackFunctionEnd("Apollo.Mitigation.Handle")
        return false
    end

    -- Temperance
    if Player.level >= Apollo.SPELLS.TEMPERANCE.level then
        local membersNeedingHeal, _ = Olympus.HandleAoEHealCheck(party, Apollo.SETTINGS.TemperanceThreshold, Apollo.SETTINGS.HealingRange)
        Debug.Info(Debug.CATEGORIES.HEALING, 
            string.format("Temperance check - Members needing heal: %d", membersNeedingHeal))
        if membersNeedingHeal >= 2 then
            Apollo.SPELLS.TEMPERANCE.isAoE = true
            if Olympus.CastAction(Apollo.SPELLS.TEMPERANCE) then 
                Debug.TrackFunctionEnd("Apollo.Mitigation.Handle")
                return true 
            end
        end
    end

    -- Handle tank-specific mitigation
    if Apollo.HandleTankMitigation(party) then
        Debug.TrackFunctionEnd("Apollo.Mitigation.Handle")
        return true
    end

    Debug.Verbose(Debug.CATEGORIES.HEALING, "No mitigation needed")
    Debug.TrackFunctionEnd("Apollo.Mitigation.Handle")
    return false
end

function Apollo.HandleTankMitigation(party)
    Debug.TrackFunctionStart("Apollo.HandleTankMitigation")
    
    if not table.valid(party) then
        Debug.Verbose(Debug.CATEGORIES.HEALING, "No valid party for tank mitigation")
        Debug.TrackFunctionEnd("Apollo.HandleTankMitigation")
        return false
    end

    -- Find the tank
    local tank = Olympus.Party.FindTank(party, Apollo.SETTINGS.HealingRange)

    if not tank then
        Debug.Verbose(Debug.CATEGORIES.HEALING, "No tank found in range")
        Debug.TrackFunctionEnd("Apollo.HandleTankMitigation")
        return false
    end

    -- Divine Benison
    if Player.level >= Apollo.SPELLS.DIVINE_BENISON.level 
       and tank.hp.percent <= Apollo.SETTINGS.BenisonThreshold then
        local result = Olympus.Buff.HandleApplication(
            tank,
            Apollo.SPELLS.DIVINE_BENISON,
            Apollo.BUFFS.DIVINE_BENISON,
            Olympus.Buff.SETTINGS.REFRESH_THRESHOLD
        )
        if result then
            Debug.TrackFunctionEnd("Apollo.HandleTankMitigation")
            return true
        end
    end

    -- Aquaveil
    if Player.level >= Apollo.SPELLS.AQUAVEIL.level 
       and tank.hp.percent <= Apollo.SETTINGS.AquaveilThreshold then
        local result = Olympus.Buff.HandleApplication(
            tank,
            Apollo.SPELLS.AQUAVEIL,
            Apollo.BUFFS.AQUAVEIL,
            Olympus.Buff.SETTINGS.REFRESH_THRESHOLD
        )
        if result then
            Debug.TrackFunctionEnd("Apollo.HandleTankMitigation")
            return true
        end
    end

    Debug.Verbose(Debug.CATEGORIES.HEALING, "No tank mitigation needed")
    Debug.TrackFunctionEnd("Apollo.HandleTankMitigation")
    return false
end

function Apollo.HandleLilySystem()
    Debug.TrackFunctionStart("Apollo.HandleLilySystem")
    
    -- Afflatus Misery (Blood Lily)
    if Player.level >= Apollo.SPELLS.AFFLATUS_MISERY.level then
        local bloodLilyStacks = Player.gauge[3]
        Debug.Info(Debug.CATEGORIES.COMBAT, 
            string.format("Blood Lily stacks: %d", bloodLilyStacks))
            
        if bloodLilyStacks >= 3 and Player.incombat then
            Debug.Info(Debug.CATEGORIES.COMBAT, "Blood Lily ready, looking for target")
            local target = Olympus.FindTargetForDamage(Apollo.DOT_BUFFS, Apollo.SPELLS.AFFLATUS_MISERY.range)
            if target then
                Debug.Info(Debug.CATEGORIES.COMBAT, 
                    string.format("Casting Afflatus Misery on %s", 
                        target.name or "Unknown"))
                if Olympus.CastAction(Apollo.SPELLS.AFFLATUS_MISERY, target.id) then 
                    Debug.TrackFunctionEnd("Apollo.HandleLilySystem")
                    return true 
                end
            else
                Debug.Verbose(Debug.CATEGORIES.COMBAT, "No valid target for Afflatus Misery")
            end
        end
    end

    -- Afflatus Rapture (AoE Lily)
    if Player.level >= Apollo.SPELLS.AFFLATUS_RAPTURE.level then
        local lilyStacks = Player.gauge[2]
        Debug.Info(Debug.CATEGORIES.HEALING, 
            string.format("Lily stacks: %d", lilyStacks))
            
        if lilyStacks >= 1 then
            local party = Olympus.GetParty(Apollo.SPELLS.AFFLATUS_RAPTURE.range)
            local membersNeedingHeal, _ = Olympus.HandleAoEHealCheck(party, Apollo.SETTINGS.CureThreshold, Apollo.SPELLS.AFFLATUS_RAPTURE.range)
            
            Debug.Info(Debug.CATEGORIES.HEALING, 
                string.format("Afflatus Rapture check - Members needing heal: %d", 
                    membersNeedingHeal))
                    
            if membersNeedingHeal >= 3 then
                Debug.Info(Debug.CATEGORIES.HEALING, "Casting Afflatus Rapture")
                if Olympus.CastAction(Apollo.SPELLS.AFFLATUS_RAPTURE) then 
                    Debug.TrackFunctionEnd("Apollo.HandleLilySystem")
                    return true 
                end
            end
        end
    end

    -- Afflatus Solace (Single Target Lily)
    if Player.level >= Apollo.SPELLS.AFFLATUS_SOLACE.level then
        local lilyStacks = Player.gauge[2]
        if lilyStacks >= 1 then
            Debug.Verbose(Debug.CATEGORIES.HEALING, "Checking for Afflatus Solace targets")
            
            local party = Olympus.GetParty(Apollo.SETTINGS.HealingRange)
            if table.valid(party) then
                local lowestHP = 100
                local lowestMember = nil
                for _, member in pairs(party) do
                    if member.hp.percent < lowestHP and member.distance2d <= Apollo.SPELLS.AFFLATUS_SOLACE.range then
                        lowestHP = member.hp.percent
                        lowestMember = member
                    end
                end
                
                -- Prioritize Afflatus Solace over Cure II when lilies are available
                if lowestMember and lowestHP <= Apollo.SETTINGS.CureIIThreshold then
                    Debug.Info(Debug.CATEGORIES.HEALING, 
                        string.format("Casting Afflatus Solace on %s (HP: %.1f%%)", 
                            lowestMember.name or "Unknown",
                            lowestHP))
                    if Olympus.CastAction(Apollo.SPELLS.AFFLATUS_SOLACE, lowestMember.id) then 
                        Debug.TrackFunctionEnd("Apollo.HandleLilySystem")
                        return true 
                    end
                else
                    Debug.Verbose(Debug.CATEGORIES.HEALING, "No suitable target for Afflatus Solace")
                end
            else
                Debug.Verbose(Debug.CATEGORIES.HEALING, "No valid party members in range")
            end
        else
            Debug.Verbose(Debug.CATEGORIES.HEALING, "No lily stacks available")
        end
    end

    Debug.Verbose(Debug.CATEGORIES.HEALING, "No lily actions needed")
    Debug.TrackFunctionEnd("Apollo.HandleLilySystem")
    return false
end

-- Validate and get party members within range
function Apollo.ValidateParty(range)
    return Olympus.Party.ValidateParty(range or Apollo.SETTINGS.HealingRange)
end

-- Find lowest health party member
function Apollo.FindLowestHealthMember(party)
    return Olympus.Party.FindLowestHealthMember(party, Apollo.SETTINGS.HealingRange)
end

--[[ Single Target Healing ]]--

-- Handle Regen application
function Apollo.HandleRegen(member, memberHP)
    Debug.TrackFunctionStart("Apollo.HandleRegen")
    
    if not Apollo.State.strictHealing 
       and Player.level >= Apollo.SPELLS.REGEN.level 
       and memberHP <= Apollo.SETTINGS.RegenThreshold then
        if member.role == "TANK" or memberHP <= (Apollo.SETTINGS.RegenThreshold - 10) then
            return Olympus.Buff.HandleApplication(
                member,
                Apollo.SPELLS.REGEN,
                Apollo.BUFFS.REGEN,
                Olympus.Buff.SETTINGS.REFRESH_THRESHOLD
            )
        end
    end
    
    Debug.TrackFunctionEnd("Apollo.HandleRegen")
    return false
end

-- Handle Cure spell selection and casting
function Apollo.HandleCureSpells(member, memberHP)
    Debug.TrackFunctionStart("Apollo.HandleCureSpells")
    
    -- Cure II (primary single target heal)
    if memberHP <= Apollo.SETTINGS.CureIIThreshold and Player.level >= Apollo.SPELLS.CURE_II.level then
        Apollo.HandleThinAir(Apollo.SPELLS.CURE_II.id)
        Debug.Info(Debug.CATEGORIES.HEALING, 
            string.format("Casting Cure II on %s (HP: %.1f%%)", 
                member.name or "Unknown",
                memberHP))
        Apollo.SPELLS.CURE_II.isAoE = false
        if Olympus.CastAction(Apollo.SPELLS.CURE_II, member.id) then 
            Debug.TrackFunctionEnd("Apollo.HandleCureSpells")
            return true 
        end
    end

    -- Cure (only use at low levels or when MP constrained)
    if (Player.level < Apollo.SPELLS.CURE_II.level or Player.mp.percent < Apollo.SETTINGS.MPThreshold) 
        and memberHP <= Apollo.SETTINGS.CureThreshold then
        -- Use Cure II if Freecure proc is active
        if Olympus.Combat.HasBuff(Player, Apollo.BUFFS.FREECURE) and Player.level >= Apollo.SPELLS.CURE_II.level then
            Debug.Info(Debug.CATEGORIES.HEALING, 
                string.format("Casting Cure II (Freecure) on %s (HP: %.1f%%)", 
                    member.name or "Unknown",
                    memberHP))
            Apollo.SPELLS.CURE_II.isAoE = false
            if Olympus.CastAction(Apollo.SPELLS.CURE_II, member.id) then 
                Debug.TrackFunctionEnd("Apollo.HandleCureSpells")
                return true 
            end
        else
            Debug.Info(Debug.CATEGORIES.HEALING, 
                string.format("Casting Cure on %s (HP: %.1f%%)", 
                    member.name or "Unknown",
                    memberHP))
            Apollo.SPELLS.CURE.isAoE = false
            if Olympus.CastAction(Apollo.SPELLS.CURE, member.id) then 
                Debug.TrackFunctionEnd("Apollo.HandleCureSpells")
                return true 
            end
        end
    end
    
    Debug.TrackFunctionEnd("Apollo.HandleCureSpells")
    return false
end

-- Main single target healing handler
function Apollo.HandleSingleTargetHealing()
    Debug.TrackFunctionStart("Apollo.SingleTargetHealing.Handle")
    
    local party = Apollo.ValidateParty()
    if not party then 
        Debug.TrackFunctionEnd("Apollo.SingleTargetHealing.Handle")
        return false 
    end

    local lowestMember, lowestHP = Apollo.FindLowestHealthMember(party)
    if not lowestMember then
        Debug.Verbose(Debug.CATEGORIES.HEALING, "No healing targets found")
        Debug.TrackFunctionEnd("Apollo.SingleTargetHealing.Handle")
        return false
    end

    -- Update healing state
    Apollo.HealingState.lastHealTarget = lowestMember
    Apollo.HealingState.lastHealTime = os.clock()

    -- Handle healing priority
    if lowestHP <= Apollo.SETTINGS.BenedictionThreshold then
        Apollo.HealingState.healingPriority = "EMERGENCY"
        Debug.TrackFunctionEnd("Apollo.SingleTargetHealing.Handle")
        return false -- Let emergency healing handle this
    end

    -- Handle Regen
    if Apollo.HandleRegen(lowestMember, lowestHP) then
        Debug.TrackFunctionEnd("Apollo.SingleTargetHealing.Handle")
        return true
    end

    -- Handle Cure spells
    if Apollo.HandleCureSpells(lowestMember, lowestHP) then
        Debug.TrackFunctionEnd("Apollo.SingleTargetHealing.Handle")
        return true
    end

    Debug.TrackFunctionEnd("Apollo.SingleTargetHealing.Handle")
    return false
end

--[[ AoE Healing ]]--

-- Handle stack-based healing (Cure III)
function Apollo.HandleStackHealing(party)
    Debug.TrackFunctionStart("Apollo.HandleStackHealing")
    
    if Player.level >= Apollo.SPELLS.CURE_III.level then
        local closeParty = Olympus.GetParty(10)
        local membersNeedingHeal, lowestMember = Olympus.HandleAoEHealCheck(closeParty, Apollo.SETTINGS.CureIIIThreshold, 10)
        
        Debug.Info(Debug.CATEGORIES.HEALING, 
            string.format("Cure III check - Close members needing heal: %d", membersNeedingHeal))
            
        if membersNeedingHeal >= Apollo.SETTINGS.CureIIIMinTargets and lowestMember then
            Apollo.HandleThinAir(Apollo.SPELLS.CURE_III.id)
            Debug.Info(Debug.CATEGORIES.HEALING, 
                string.format("Cure III target found: %s", lowestMember.name or "Unknown"))
            Apollo.SPELLS.CURE_III.isAoE = true
            local result = Olympus.CastAction(Apollo.SPELLS.CURE_III, lowestMember.id)
            Debug.TrackFunctionEnd("Apollo.HandleStackHealing")
            return result
        end
    end
    
    Debug.TrackFunctionEnd("Apollo.HandleStackHealing")
    return false
end

-- Handle ground-targeted healing abilities
function Apollo.HandleGroundTargetedHealing(party)
    Debug.TrackFunctionStart("Apollo.HandleGroundTargetedHealing")
    
    -- Asylum
    if Player.level >= Apollo.SPELLS.ASYLUM.level then
        Debug.Verbose(Debug.CATEGORIES.HEALING, "Checking Asylum conditions")
        Apollo.SPELLS.ASYLUM.isAoE = true
        if Apollo.HandleGroundTargetedSpell(Apollo.SPELLS.ASYLUM, party, Apollo.SETTINGS.AsylumThreshold, Apollo.SETTINGS.AsylumMinTargets) then
            Debug.TrackFunctionEnd("Apollo.HandleGroundTargetedHealing")
            return true
        end
    end

    -- Liturgy of the Bell
    if Player.level >= Apollo.SPELLS.LITURGY_OF_THE_BELL.level then
        Debug.Verbose(Debug.CATEGORIES.HEALING, "Checking Liturgy conditions")
        Apollo.SPELLS.LITURGY_OF_THE_BELL.isAoE = true
        if Apollo.HandleGroundTargetedSpell(Apollo.SPELLS.LITURGY_OF_THE_BELL, party, Apollo.SETTINGS.LiturgyThreshold, Apollo.SETTINGS.LiturgyMinTargets) then
            Debug.TrackFunctionEnd("Apollo.HandleGroundTargetedHealing")
            return true
        end
    end
    
    Debug.TrackFunctionEnd("Apollo.HandleGroundTargetedHealing")
    return false
end

-- Main AoE healing handler
function Apollo.HandleAoEHealing()
    Debug.TrackFunctionStart("Apollo.HandleAoEHealing")
    
    local party = Apollo.ValidateParty()
    if not party then 
        Debug.TrackFunctionEnd("Apollo.HandleAoEHealing")
        return false 
    end

    -- Skip non-essential AoE healing in strict healing mode
    if Apollo.State.strictHealing then
        Debug.Info(Debug.CATEGORIES.HEALING, "Strict healing mode - skipping non-essential AoE healing")
        Debug.TrackFunctionEnd("Apollo.HandleAoEHealing")
        return false
    end

    -- Update AoE healing state
    local membersNeedingHeal, _ = Olympus.HandleAoEHealCheck(party, Apollo.SETTINGS.CureThreshold, Apollo.SETTINGS.HealingRange)
    Apollo.HealingState.aoeHealingNeeded = membersNeedingHeal >= 3

    -- Plenary Indulgence
    if Player.level >= Apollo.SPELLS.PLENARY_INDULGENCE.level then
        local plenaryTargets, _ = Olympus.HandleAoEHealCheck(party, Apollo.SETTINGS.PlenaryThreshold, Apollo.SETTINGS.HealingRange)
        Debug.Info(Debug.CATEGORIES.HEALING, 
            string.format("Plenary check - Members needing heal: %d", plenaryTargets))
        if plenaryTargets >= 2 then
            Apollo.SPELLS.PLENARY_INDULGENCE.isAoE = true
            if Olympus.CastAction(Apollo.SPELLS.PLENARY_INDULGENCE) then 
                Debug.TrackFunctionEnd("Apollo.HandleAoEHealing")
                return true 
            end
        end
    end

    -- Handle stack healing (Cure III)
    if Apollo.HandleStackHealing(party) then
        Debug.TrackFunctionEnd("Apollo.HandleAoEHealing")
        return true
    end

    -- Handle ground targeted healing (Asylum, Liturgy)
    if Apollo.HandleGroundTargetedHealing(party) then
        Debug.TrackFunctionEnd("Apollo.HandleAoEHealing")
        return true
    end

    -- Handle Medica II and Medica
    local hasMedicaII = Olympus.Combat.HasBuff(Player, Apollo.BUFFS.MEDICA_II)
    
    if membersNeedingHeal >= 3 then
        if not hasMedicaII and Player.level >= Apollo.SPELLS.MEDICA_II.level then
            Apollo.HandleThinAir(Apollo.SPELLS.MEDICA_II.id)
            Debug.Info(Debug.CATEGORIES.HEALING, "Casting Medica II")
            Apollo.SPELLS.MEDICA_II.isAoE = true
            if Olympus.CastAction(Apollo.SPELLS.MEDICA_II) then 
                Debug.TrackFunctionEnd("Apollo.HandleAoEHealing")
                return true 
            end
        elseif hasMedicaII and Player.level >= Apollo.SPELLS.MEDICA.level then
            Apollo.HandleThinAir(Apollo.SPELLS.MEDICA.id)
            Debug.Info(Debug.CATEGORIES.HEALING, "Casting Medica")
            Apollo.SPELLS.MEDICA.isAoE = true
            if Olympus.CastAction(Apollo.SPELLS.MEDICA) then 
                Debug.TrackFunctionEnd("Apollo.HandleAoEHealing")
                return true 
            end
        end
    end

    Debug.Verbose(Debug.CATEGORIES.HEALING, "No AoE healing needed")
    Debug.TrackFunctionEnd("Apollo.HandleAoEHealing")
    return false
end

--[[ Emergency Healing ]]--

-- Main emergency healing handler
function Apollo.HandleEmergencyHealing()
    Debug.TrackFunctionStart("Apollo.EmergencyHealing.Handle")
    
    local party = Apollo.ValidateParty()
    if not party then 
        Debug.TrackFunctionEnd("Apollo.EmergencyHealing.Handle")
        return false 
    end

    -- Update emergency state
    local hasEmergencyTarget = false
    for _, member in pairs(party) do
        if member.hp.percent <= Apollo.SETTINGS.BenedictionThreshold then
            hasEmergencyTarget = true
            break
        end
    end
    Apollo.HealingState.emergencyHealingNeeded = hasEmergencyTarget

    -- Benediction
    if Player.level >= Apollo.SPELLS.BENEDICTION.level then
        Debug.Verbose(Debug.CATEGORIES.HEALING, "Checking for Benediction targets")
        for _, member in pairs(party) do
            if member.hp.percent <= Apollo.SETTINGS.BenedictionThreshold 
               and member.distance2d <= Apollo.SPELLS.BENEDICTION.range then
                Debug.Info(Debug.CATEGORIES.HEALING, 
                    string.format("Benediction target found: %s (HP: %.1f%%)", 
                        member.name or "Unknown",
                        member.hp.percent))
                Apollo.SPELLS.BENEDICTION.isAoE = false
                if Olympus.CastAction(Apollo.SPELLS.BENEDICTION, member.id) then 
                    Debug.TrackFunctionEnd("Apollo.EmergencyHealing.Handle")
                    return true 
                end
            end
        end
    end

    -- Tetragrammaton
    if Player.level >= Apollo.SPELLS.TETRAGRAMMATON.level then
        Debug.Verbose(Debug.CATEGORIES.HEALING, "Checking for Tetragrammaton targets")
        for _, member in pairs(party) do
            if member.hp.percent <= Apollo.SETTINGS.TetragrammatonThreshold 
               and member.distance2d <= Apollo.SPELLS.TETRAGRAMMATON.range then
                Debug.Info(Debug.CATEGORIES.HEALING, 
                    string.format("Tetragrammaton target found: %s (HP: %.1f%%)", 
                        member.name or "Unknown",
                        member.hp.percent))
                Apollo.SPELLS.TETRAGRAMMATON.isAoE = false
                if Olympus.CastAction(Apollo.SPELLS.TETRAGRAMMATON, member.id) then 
                    Debug.TrackFunctionEnd("Apollo.EmergencyHealing.Handle")
                    return true 
                end
            end
        end
    end

    Debug.Verbose(Debug.CATEGORIES.HEALING, "No emergency healing needed")
    Debug.TrackFunctionEnd("Apollo.EmergencyHealing.Handle")
    return false
end

--------------------------------------------------------------------------------
-- 5. Damage Systems
--------------------------------------------------------------------------------

--[[ Damage State Management ]]--
Apollo.DamageState = {
    lastDamageTarget = nil,
    lastDoTTarget = nil,
    lastAoETime = 0,
    aoeTargetsCount = 0,
    damagePhase = "SINGLE" -- SINGLE, AOE, CONSERVATION
}

--[[ Spell Selection Logic ]]--
function Apollo.GetDamageSpell()
    Debug.TrackFunctionStart("Apollo.GetDamageSpell")
    
    local spellPriority = { 
        Apollo.SPELLS.GLARE_III, 
        Apollo.SPELLS.GLARE, 
        Apollo.SPELLS.STONE_IV, 
        Apollo.SPELLS.STONE_III, 
        Apollo.SPELLS.STONE_II, 
        Apollo.SPELLS.STONE 
    }
    
    local spell = Olympus.Damage.GetSpellByPriority(spellPriority)
    Debug.TrackFunctionEnd("Apollo.GetDamageSpell")
    return spell or Apollo.SPELLS.STONE -- Fallback to basic Stone
end

function Apollo.GetDoTSpell()
    Debug.TrackFunctionStart("Apollo.GetDoTSpell")
    
    local spellPriority = { 
        Apollo.SPELLS.DIA, 
        Apollo.SPELLS.AERO_II, 
        Apollo.SPELLS.AERO 
    }
    
    local spell = Olympus.Damage.GetSpellByPriority(spellPriority)
    Debug.TrackFunctionEnd("Apollo.GetDoTSpell")
    return spell
end

--[[ DoT Management ]]--
function Apollo.ShouldRefreshDoT(target)
    return target and Olympus.Damage.ShouldRefreshDoT(target, Apollo.DOT_BUFFS)
end

function Apollo.HandleDoTs(target)
    Debug.TrackFunctionStart("Apollo.HandleDoTs")
    local dotSpell = Apollo.GetDoTSpell()
    local result = Olympus.Damage.HandleDoTSpell(target, dotSpell, Apollo.DOT_BUFFS)
    Debug.TrackFunctionEnd("Apollo.HandleDoTs")
    return result
end

--[[ AoE Damage Management ]]--
function Apollo.UpdateAoEState()
    Debug.TrackFunctionStart("Apollo.UpdateAoEState")
    local targetCount = Olympus.Damage.UpdateAoEState(8) -- Holy/Holy III range
    Apollo.DamageState.aoeTargetsCount = targetCount
    Apollo.DamageState.damagePhase = targetCount >= Apollo.SETTINGS.HolyMinTargets and "AOE" or "SINGLE"
    Debug.TrackFunctionEnd("Apollo.UpdateAoEState")
end

function Apollo.HandleAoE(target)
    Debug.TrackFunctionStart("Apollo.HandleAoE")
    
    return Olympus.Damage.HandleAoECycle({
        spells = {
            { spell = Apollo.SPELLS.HOLY_III, range = 8 },
            { spell = Apollo.SPELLS.HOLY, range = 8 },
            { spell = Apollo.SPELLS.ASSIZE, range = 15, minTargets = Apollo.SETTINGS.AssizeMinTargets }
        },
        minTargets = Apollo.SETTINGS.HolyMinTargets,
        range = 8,
        updateState = Apollo.UpdateAoEState,
        shouldUseAoE = function() return Apollo.DamageState.damagePhase == "AOE" end
    })
end

--[[ Main Damage Handler ]]--
function Apollo.HandleDamage()
    Debug.TrackFunctionStart("Apollo.HandleDamage")
    Debug.Info(Debug.CATEGORIES.DAMAGE, "Starting damage handling")
    
    local result = Olympus.Damage.HandleDamageCycle({
        strictHealing = Apollo.State.strictHealing,
        dotBuffs = Apollo.DOT_BUFFS,
        range = 25,
        onMPConservation = function()
            Apollo.DamageState.damagePhase = "CONSERVATION"
            Debug.Info(Debug.CATEGORIES.DAMAGE, "Entering MP conservation phase")
        end,
        onTargetFound = function(target)
            Apollo.DamageState.lastDamageTarget = target
            Debug.Info(Debug.CATEGORIES.DAMAGE, string.format("Target found: %s", target.name or "Unknown"))
        end,
        handleDoTs = function(target)
            Debug.Info(Debug.CATEGORIES.DAMAGE, "Attempting DoT application")
            return Apollo.HandleDoTs(target)
        end,
        handleAoE = function(target)
            Debug.Info(Debug.CATEGORIES.DAMAGE, "Checking AoE conditions")
            return Apollo.HandleAoE(target)
        end,
        handleSingleTarget = function(target)
            local damageSpell = Apollo.GetDamageSpell()
            if damageSpell then
                Debug.Info(Debug.CATEGORIES.DAMAGE, string.format(
                    "Casting %s on %s", 
                    damageSpell.name or "damage spell",
                    target.name or "Unknown"
                ))
                damageSpell.isAoE = false
                return Olympus.CastAction(damageSpell, target.id)
            end
            Debug.Info(Debug.CATEGORIES.DAMAGE, "No suitable damage spell found")
            return false
        end
    })
    
    Debug.TrackFunctionEnd("Apollo.HandleDamage")
    return result
end

--------------------------------------------------------------------------------
-- 6. Utility Functions
--------------------------------------------------------------------------------

--[[ Movement Utilities ]]--
function Apollo.HandleMovement()
    Debug.TrackFunctionStart("Apollo.HandleMovement")
    
    -- Skip if not running
    if not Apollo.State.isRunning then
        Debug.Verbose(Debug.CATEGORIES.MOVEMENT, "Apollo not running, skipping movement")
        Debug.TrackFunctionEnd("Apollo.HandleMovement")
        return false
    end
    
    local result = Olympus.Movement.HandleJobMovement(
        Apollo.SPELLS.AETHERIAL_SHIFT,
        Apollo.SETTINGS.HealingRange,
        Apollo.SETTINGS.CureIIThreshold,
        45
    )
    
    Debug.TrackFunctionEnd("Apollo.HandleMovement")
    return result
end

function Apollo.ShouldUseAetherialShift(member)
    return Olympus.Movement.ShouldUseMovementAbility(member, Apollo.SETTINGS.HealingRange)
end

--[[ Ground Targeting Utilities ]]--
function Apollo.HandleGroundTargetedSpell(spell, party, hpThreshold, minTargets)
    Debug.TrackFunctionStart("Apollo.HandleGroundTargetedSpell")
    return Olympus.Ground.HandleSpell(spell, party, hpThreshold, minTargets)
end

function Apollo.CalculateOptimalGroundTargetPosition(party, hpThreshold)
    return Olympus.Ground.CalculateOptimalPosition(party, hpThreshold)
end

function Apollo.CastGroundTargetedSpell(spell, position)
    return Olympus.Ground.CastSpell(spell, position)
end

--[[ MP Management Utilities ]]--
function Apollo.HandleThinAir(spellId)
    Debug.TrackFunctionStart("Apollo.HandleThinAir")
    
    -- Check if Thin Air should be used
    if Player.level >= Apollo.SPELLS.THIN_AIR.level then
        local spell = ActionList:Get(1, spellId)
        return Olympus.MP.HandleMPSaver(spell, Apollo.SPELLS.THIN_AIR, Apollo.THRESHOLDS.LUCID)
    end
    
    Debug.TrackFunctionEnd("Apollo.HandleThinAir")
    return false
end

--------------------------------------------------------------------------------
-- 7. Event Handlers
--------------------------------------------------------------------------------

-- Main draw event handler for UI updates
function Apollo.OnDraw()
    Debug.TrackFunctionStart("Apollo.OnDraw")
    
    -- Skip if system is not running
    if not Olympus.State.IsModuleRunning("Apollo") then 
        Debug.Verbose(Debug.CATEGORIES.SYSTEM, "Apollo not running, skipping draw")
        Debug.TrackFunctionEnd("Apollo.OnDraw")
        return 
    end
    
    -- Draw UI elements here
    -- TODO: Add UI drawing code when implementing GUI
    
    Debug.TrackFunctionEnd("Apollo.OnDraw")
end

-- Main update event handler for combat logic
function Apollo.OnUpdate()
    Debug.TrackFunctionStart("Apollo.OnUpdate")
    
    -- Skip if system is not running
    if not Olympus.State.IsModuleRunning("Apollo") then 
        Debug.Verbose(Debug.CATEGORIES.SYSTEM, "Apollo not running, skipping update")
        Debug.TrackFunctionEnd("Apollo.OnUpdate")
        return 
    end
    
    -- Validate player state
    if not Player then
        Debug.Warn(Debug.CATEGORIES.SYSTEM, "Invalid player state detected")
        Debug.TrackFunctionEnd("Apollo.OnUpdate")
        return
    end
    
    -- Execute combat cycle
    local success = false
    local errorOccurred = false
    
    -- Protected call to prevent crashes
    xpcall(
        function()
            success = Apollo.Cast()
        end,
        function(err)
            errorOccurred = true
            Olympus.Error.SetError(string.format("Error in combat cycle: %s", tostring(err)))
            Debug.Error(Debug.CATEGORIES.SYSTEM, string.format("Combat cycle error: %s", tostring(err)))
        end
    )
    
    -- Log cycle completion
    if not success and not errorOccurred then
        Debug.Verbose(Debug.CATEGORIES.SYSTEM, "Cast cycle completed with no actions taken")
    end
    
    Debug.TrackFunctionEnd("Apollo.OnUpdate")
end

-- Cleanup handler for module unload
function Apollo.OnUnload()
    Debug.TrackFunctionStart("Apollo.OnUnload")
    Debug.Info(Debug.CATEGORIES.SYSTEM, "Unloading Apollo")
    
    -- Reset system state
    Olympus.State.ResetModuleState("Apollo")
    
    -- Clean up event handlers
    Debug.Info(Debug.CATEGORIES.SYSTEM, "Unregistering event handlers")
    Olympus.Event.UnregisterAllHandlers()
    
    Debug.Info(Debug.CATEGORIES.SYSTEM, "Apollo unloaded successfully")
    Debug.TrackFunctionEnd("Apollo.OnUnload")
end

--------------------------------------------------------------------------------
-- 8. Initialization
--------------------------------------------------------------------------------

-- Register Apollo with Olympus
local moduleData = {
    name = "Apollo",
    version = "1.0",
    description = "White Mage (WHM) combat routine",
    author = "Project Remedy",
    initialize = function()
        -- Initialize settings
        Apollo.SETTINGS = Olympus.Settings.CreateSchema(Apollo.SETTINGS_SCHEMA)
        
        -- Initialize spell toggles
        Olympus.SpellToggles.Initialize(Apollo.SPELLS)
        
        -- Reset state
        Apollo.Reset()
        
        -- Register event handlers
        RegisterEventHandler("Gameloop.Draw", Apollo.OnDraw, "Apollo.OnDraw")
        RegisterEventHandler("Gameloop.Update", Apollo.OnUpdate, "Apollo.OnUpdate")
        
        return true
    end,
    onEnable = function()
        Debug.Info(Debug.CATEGORIES.SYSTEM, "Apollo enabled")
        return true
    end,
    onDisable = function()
        Debug.Info(Debug.CATEGORIES.SYSTEM, "Apollo disabled")
        return true
    end
}

-- Register the module
if not Olympus.RegisterModule("Apollo", moduleData) then
    Debug.Error(Debug.CATEGORIES.SYSTEM, "Failed to register Apollo module")
    return false
end

-- Initialize the module
if not Olympus.InitializeModule("Apollo") then
    Debug.Error(Debug.CATEGORIES.SYSTEM, "Failed to initialize Apollo module")
    return false
end

return Apollo