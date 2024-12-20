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

--[[ Core Settings ]]--
Apollo.THRESHOLDS = {
    -- MP Management Thresholds
    LUCID = 80,         -- MP% to trigger Lucid Dreaming
    NORMAL = 30,        -- Normal phase MP threshold
    AOE = 40,          -- AoE phase MP threshold
    EMERGENCY = 30,    -- Emergency phase MP threshold
    CRITICAL = 15      -- Critical MP conservation threshold
}

--[[ Combat Settings ]]--
Apollo.SETTINGS = {
    -- Resource Management
    MPThreshold = 80,           -- MP threshold for recovery abilities
    HealingRange = 30,          -- Maximum healing range
    
    -- Single Target Healing
    CureThreshold = 85,         -- HP% for Cure
    CureIIThreshold = 65,       -- HP% for Cure II
    CureIIIThreshold = 50,      -- HP% for Cure III
    RegenThreshold = 80,        -- HP% for Regen
    BenedictionThreshold = 25,  -- HP% for Benediction
    TetragrammatonThreshold = 60, -- HP% for Tetragrammaton
    BenisonThreshold = 90,      -- HP% for Divine Benison
    AquaveilThreshold = 85,     -- HP% for Aquaveil
    
    -- AoE Healing
    CureIIIMinTargets = 3,      -- Minimum targets for Cure III
    HolyMinTargets = 2,         -- Minimum targets for Holy
    AsylumThreshold = 80,       -- HP% for Asylum
    AsylumMinTargets = 2,       -- Minimum targets for Asylum
    AssizeMinTargets = 1,       -- Minimum targets for Assize
    PlenaryThreshold = 65,      -- HP% for Plenary Indulgence
    TemperanceThreshold = 70,   -- HP% for Temperance
    LiturgyThreshold = 75,      -- HP% for Liturgy of the Bell
    LiturgyMinTargets = 2       -- Minimum targets for Liturgy
}

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

--[[ State Variables ]]--
Apollo.isRunning = false
Apollo.StrictHealing = false

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
    isRunning = false,
    strictHealing = false,
    lastError = nil,
    performanceMetrics = {
        lastCastTime = 0,
        averageCastTime = 0,
        castCount = 0
    }
}

--[[ Core System Functions ]]--

-- Toggle the Apollo system on/off
function Apollo.Toggle()
    Apollo.State.isRunning = not Apollo.State.isRunning
    Debug.Info(Debug.CATEGORIES.SYSTEM, string.format(
        "Apollo %s", 
        Apollo.State.isRunning and "started" or "stopped"
    ))
end

-- Check if Apollo is currently running
function Apollo.IsRunning()
    return Apollo.State.isRunning
end

--[[ Spell Management ]]--

-- Check if a specific spell is enabled
function Apollo.IsSpellEnabled(spellName)
    if not spellName then
        Debug.Warn(Debug.CATEGORIES.SYSTEM, "Attempted to check enabled status of nil spell")
        return false
    end
    return Apollo.SPELL_TOGGLES.enabled[spellName] == true
end

-- Toggle a spell's enabled status
function Apollo.ToggleSpell(spellName)
    if not Apollo.SPELLS[spellName] then
        Debug.Warn(Debug.CATEGORIES.SYSTEM, string.format("Attempted to toggle invalid spell: %s", tostring(spellName)))
        return false
    end

    Apollo.SPELL_TOGGLES.enabled[spellName] = not Apollo.SPELL_TOGGLES.enabled[spellName]
    Debug.Info(Debug.CATEGORIES.SYSTEM, string.format(
        "Spell %s %s", 
        spellName, 
        Apollo.SPELL_TOGGLES.enabled[spellName] and "enabled" or "disabled"
    ))
    return true
end

-- Get all spells of a specific category
function Apollo.GetSpellsByCategory(category)
    if not category then
        Debug.Warn(Debug.CATEGORIES.SYSTEM, "Attempted to get spells for nil category")
        return {}
    end

    local spells = {}
    for name, spell in pairs(Apollo.SPELLS) do
        if spell.category == category then
            spells[name] = spell
        end
    end
    return spells
end

--[[ Performance Monitoring ]]--

-- Update performance metrics after a cast
function Apollo.UpdatePerformanceMetrics(castTime)
    local metrics = Apollo.State.performanceMetrics
    metrics.castCount = metrics.castCount + 1
    metrics.lastCastTime = castTime
    metrics.averageCastTime = (metrics.averageCastTime * (metrics.castCount - 1) + castTime) / metrics.castCount
end

-- Get current performance metrics
function Apollo.GetPerformanceMetrics()
    return Apollo.State.performanceMetrics
end

--[[ Error Handling ]]--

-- Set the last error that occurred
function Apollo.SetError(errorMessage)
    Apollo.State.lastError = {
        message = errorMessage,
        timestamp = os.time()
    }
    Debug.Error(Debug.CATEGORIES.SYSTEM, errorMessage)
end

-- Get the last error that occurred
function Apollo.GetLastError()
    return Apollo.State.lastError
end

--[[ System Status ]]--

-- Get the current system status
function Apollo.GetStatus()
    return {
        running = Apollo.State.isRunning,
        strictHealing = Apollo.State.strictHealing,
        lastError = Apollo.State.lastError,
        performance = Apollo.State.performanceMetrics
    }
end

-- Reset the system state
function Apollo.Reset()
    Apollo.State.isRunning = false
    Apollo.State.strictHealing = false
    Apollo.State.lastError = nil
    Apollo.State.performanceMetrics = {
        lastCastTime = 0,
        averageCastTime = 0,
        castCount = 0
    }
    Debug.Info(Debug.CATEGORIES.SYSTEM, "Apollo system state reset")
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
    Debug.TrackFunctionStart("Apollo.DetectCombatPhase")
    
    local party = Olympus.GetParty(Apollo.SETTINGS.HealingRange)
    if not table.valid(party) then
        Debug.Verbose(Debug.CATEGORIES.COMBAT, "No valid party, defaulting to NORMAL phase")
        Debug.TrackFunctionEnd("Apollo.DetectCombatPhase")
        return "NORMAL"
    end
    
    -- Count party members below thresholds
    local membersNeedingHeal = 0
    local lowestHP = 100
    
    for _, member in pairs(party) do
        if member.hp.percent <= Apollo.SETTINGS.CureThreshold then
            membersNeedingHeal = membersNeedingHeal + 1
        end
        if member.hp.percent < lowestHP then
            lowestHP = member.hp.percent
        end
    end
    
    -- Update combat state
    Apollo.CombatState.isAoEPhase = membersNeedingHeal >= 3
    Apollo.CombatState.emergencyMode = lowestHP <= Apollo.SETTINGS.BenedictionThreshold
    
    -- Determine phase based on conditions
    local phase = "NORMAL"
    if Apollo.CombatState.emergencyMode then
        phase = "EMERGENCY"
    elseif Apollo.CombatState.isAoEPhase then
        phase = "AOE"
    end
    
    Debug.Info(Debug.CATEGORIES.COMBAT, string.format(
        "Combat phase detected: %s (AoE: %s, Emergency: %s)",
        phase,
        tostring(Apollo.CombatState.isAoEPhase),
        tostring(Apollo.CombatState.emergencyMode)
    ))
    
    Apollo.CombatState.currentPhase = phase
    Debug.TrackFunctionEnd("Apollo.DetectCombatPhase")
    return phase
end

--[[ MP Management ]]--
function Apollo.GetMPThreshold()
    Debug.TrackFunctionStart("Apollo.GetMPThreshold")
    
    -- Critical MP override
    if Player.mp.percent <= Apollo.THRESHOLDS.CRITICAL then
        Debug.Info(Debug.CATEGORIES.COMBAT, "MP critically low, using emergency threshold")
        Debug.TrackFunctionEnd("Apollo.GetMPThreshold")
        return Apollo.THRESHOLDS.CRITICAL
    end
    
    local phase = Apollo.CombatState.currentPhase
    local threshold = Apollo.THRESHOLDS[phase] or Apollo.THRESHOLDS.NORMAL
    
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
    if not Apollo.State.isRunning then 
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
    if Player.mp.percent > Apollo.THRESHOLDS.EMERGENCY then
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
    
    -- Add damage handling if MP permits
    if Player.mp.percent > Apollo.THRESHOLDS.EMERGENCY then
        table.insert(handlers, { func = Apollo.HandleDamage, name = "Damage" })
    end
    
    -- Execute handlers in priority order
    for _, handler in ipairs(handlers) do
        Debug.Verbose(Debug.CATEGORIES.COMBAT, string.format("Checking %s handler", handler.name))
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
    local tank = nil
    for _, member in pairs(party) do
        if member.role == "TANK" and member.distance2d <= Apollo.SETTINGS.HealingRange then
            tank = member
            break
        end
    end

    if not tank then
        Debug.Verbose(Debug.CATEGORIES.HEALING, "No tank found in range")
        Debug.TrackFunctionEnd("Apollo.HandleTankMitigation")
        return false
    end

    -- Divine Benison
    if Player.level >= Apollo.SPELLS.DIVINE_BENISON.level 
       and tank.hp.percent <= Apollo.SETTINGS.BenisonThreshold
       and not Olympus.Combat.HasBuff(tank, Apollo.BUFFS.DIVINE_BENISON) then
        Debug.Info(Debug.CATEGORIES.HEALING, 
            string.format("Applying Divine Benison to tank %s (HP: %.1f%%)", 
                tank.name or "Unknown",
                tank.hp.percent))
        Apollo.SPELLS.DIVINE_BENISON.isAoE = false
        if Olympus.CastAction(Apollo.SPELLS.DIVINE_BENISON, tank.id) then 
            Debug.TrackFunctionEnd("Apollo.HandleTankMitigation")
            return true 
        end
    end

    -- Aquaveil
    if Player.level >= Apollo.SPELLS.AQUAVEIL.level 
       and tank.hp.percent <= Apollo.SETTINGS.AquaveilThreshold
       and not Olympus.Combat.HasBuff(tank, Apollo.BUFFS.AQUAVEIL) then
        Debug.Info(Debug.CATEGORIES.HEALING, 
            string.format("Applying Aquaveil to tank %s (HP: %.1f%%)", 
                tank.name or "Unknown",
                tank.hp.percent))
        Apollo.SPELLS.AQUAVEIL.isAoE = false
        if Olympus.CastAction(Apollo.SPELLS.AQUAVEIL, tank.id) then 
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
    Debug.TrackFunctionStart("Apollo.ValidateParty")
    local party = Olympus.GetParty(range or Apollo.SETTINGS.HealingRange)
    if not table.valid(party) then 
        Debug.Verbose(Debug.CATEGORIES.HEALING, "No valid party members in range")
        Debug.TrackFunctionEnd("Apollo.ValidateParty")
        return nil
    end
    Debug.TrackFunctionEnd("Apollo.ValidateParty")
    return party
end

-- Find lowest health party member
function Apollo.FindLowestHealthMember(party)
    Debug.TrackFunctionStart("Apollo.FindLowestHealthMember")
    local lowestHP = 100
    local lowestMember = nil
    
    for _, member in pairs(party) do
        if member.hp.percent < lowestHP and member.distance2d <= Apollo.SETTINGS.HealingRange then
            lowestHP = member.hp.percent
            lowestMember = member
        end
    end
    
    if lowestMember then
        Debug.Info(Debug.CATEGORIES.HEALING, 
            string.format("Lowest member: %s (HP: %.1f%%)", 
                lowestMember.name or "Unknown",
                lowestHP))
    end
    
    Debug.TrackFunctionEnd("Apollo.FindLowestHealthMember")
    return lowestMember, lowestHP
end

--[[ Single Target Healing ]]--

-- Handle Regen application
function Apollo.HandleRegen(member, memberHP)
    Debug.TrackFunctionStart("Apollo.HandleRegen")
    
    if not Apollo.State.strictHealing 
       and Player.level >= Apollo.SPELLS.REGEN.level 
       and memberHP <= Apollo.SETTINGS.RegenThreshold
       and not Olympus.Combat.HasBuff(member, Apollo.BUFFS.REGEN) then
        if member.role == "TANK" or memberHP <= (Apollo.SETTINGS.RegenThreshold - 10) then
            Debug.Info(Debug.CATEGORIES.HEALING, 
                string.format("Applying Regen to %s (HP: %.1f%%)", 
                    member.name or "Unknown",
                    memberHP))
            Apollo.SPELLS.REGEN.isAoE = false
            local result = Olympus.CastAction(Apollo.SPELLS.REGEN, member.id)
            Debug.TrackFunctionEnd("Apollo.HandleRegen")
            return result
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
    
    for _, spell in ipairs(spellPriority) do
        if Player.level >= spell.level then
            Debug.Info(Debug.CATEGORIES.COMBAT, 
                string.format("Selected damage spell: %s (Level %d)", 
                    spell.name or "Unknown",
                    spell.level))
            Debug.TrackFunctionEnd("Apollo.GetDamageSpell")
            return spell
        end
    end
    
    Debug.TrackFunctionEnd("Apollo.GetDamageSpell")
    return Apollo.SPELLS.STONE -- Fallback to basic Stone
end

function Apollo.GetDoTSpell()
    Debug.TrackFunctionStart("Apollo.GetDoTSpell")
    
    local spellPriority = { 
        Apollo.SPELLS.DIA, 
        Apollo.SPELLS.AERO_II, 
        Apollo.SPELLS.AERO 
    }
    
    for _, spell in ipairs(spellPriority) do
        if Player.level >= spell.level then
            Debug.Info(Debug.CATEGORIES.COMBAT, 
                string.format("Selected DoT spell: %s (Level %d)", 
                    spell.name or "Unknown",
                    spell.level))
            Debug.TrackFunctionEnd("Apollo.GetDoTSpell")
            return spell
        end
    end
    
    Debug.TrackFunctionEnd("Apollo.GetDoTSpell")
    return nil -- No DoT spell available
end

--[[ DoT Management ]]--
function Apollo.ShouldRefreshDoT(target)
    if not target then return false end
    
    -- Check if target has any DoT
    for buffId, _ in pairs(Apollo.DOT_BUFFS) do
        if Olympus.Combat.HasBuff(target, buffId) then
            local buffDuration = Olympus.Combat.GetBuffDuration(target, buffId)
            -- Only refresh if duration is less than 3 seconds AND we have the buff
            if buffDuration and buffDuration <= 3 then
                return true
            end
            -- If we have any valid DoT with more than 3 seconds, don't refresh
            return false
        end
    end
    
    -- No DoT present, should apply
    return true
end

function Apollo.HandleDoTs(target)
    Debug.TrackFunctionStart("Apollo.HandleDoTs")
    
    if not target or not Apollo.ShouldRefreshDoT(target) then
        Debug.Verbose(Debug.CATEGORIES.DAMAGE, "No DoT refresh needed")
        Debug.TrackFunctionEnd("Apollo.HandleDoTs")
        return false
    end

    local dotSpell = Apollo.GetDoTSpell()
    if not dotSpell then
        Debug.Verbose(Debug.CATEGORIES.DAMAGE, "No DoT spell available")
        Debug.TrackFunctionEnd("Apollo.HandleDoTs")
        return false
    end

    Debug.Info(Debug.CATEGORIES.DAMAGE, 
        string.format("Applying %s to %s", 
            dotSpell.name or "DoT",
            target.name or "Unknown"))
    
    dotSpell.isAoE = false
    Apollo.DamageState.lastDoTTarget = target
    
    local result = Olympus.CastAction(dotSpell, target.id)
    Debug.TrackFunctionEnd("Apollo.HandleDoTs")
    return result
end

--[[ AoE Damage Management ]]--
function Apollo.UpdateAoEState()
    Debug.TrackFunctionStart("Apollo.UpdateAoEState")
    
    local enemies = EntityList("alive,attackable,incombat,maxdistance=8")
    Apollo.DamageState.aoeTargetsCount = table.valid(enemies) and table.size(enemies) or 0
    Apollo.DamageState.damagePhase = Apollo.DamageState.aoeTargetsCount >= 3 and "AOE" or "SINGLE"
    
    Debug.Info(Debug.CATEGORIES.DAMAGE, 
        string.format("AoE state updated: %d targets, Phase: %s", 
            Apollo.DamageState.aoeTargetsCount,
            Apollo.DamageState.damagePhase))
            
    Debug.TrackFunctionEnd("Apollo.UpdateAoEState")
end

function Apollo.HandleAoE(target)
    Debug.TrackFunctionStart("Apollo.HandleAoE")
    
    Apollo.UpdateAoEState()
    if Apollo.DamageState.damagePhase ~= "AOE" then
        Debug.Verbose(Debug.CATEGORIES.DAMAGE, "Insufficient targets for AoE")
        Debug.TrackFunctionEnd("Apollo.HandleAoE")
        return false
    end
    
    -- Holy/Holy III
    if Player.level >= Apollo.SPELLS.HOLY_III.level then
        Debug.Info(Debug.CATEGORIES.DAMAGE, 
            string.format("Casting Holy III on %d enemies", 
                Apollo.DamageState.aoeTargetsCount))
        Apollo.SPELLS.HOLY_III.isAoE = true
        if Olympus.CastAction(Apollo.SPELLS.HOLY_III) then 
            Apollo.DamageState.lastAoETime = os.clock()
            Debug.TrackFunctionEnd("Apollo.HandleAoE")
            return true 
        end
    elseif Player.level >= Apollo.SPELLS.HOLY.level then
        Debug.Info(Debug.CATEGORIES.DAMAGE, 
            string.format("Casting Holy on %d enemies", 
                Apollo.DamageState.aoeTargetsCount))
        Apollo.SPELLS.HOLY.isAoE = true
        if Olympus.CastAction(Apollo.SPELLS.HOLY) then 
            Apollo.DamageState.lastAoETime = os.clock()
            Debug.TrackFunctionEnd("Apollo.HandleAoE")
            return true 
        end
    end
    
    -- Assize (if available and enemies in range)
    if Player.level >= Apollo.SPELLS.ASSIZE.level then
        local assizeTargets = EntityList("alive,attackable,incombat,maxdistance=15")
        if table.valid(assizeTargets) then
            Debug.Info(Debug.CATEGORIES.DAMAGE, "Casting Assize for damage/healing")
            Apollo.SPELLS.ASSIZE.isAoE = true
            if Olympus.CastAction(Apollo.SPELLS.ASSIZE) then 
                Debug.TrackFunctionEnd("Apollo.HandleAoE")
                return true 
            end
        end
    end
    
    Debug.TrackFunctionEnd("Apollo.HandleAoE")
    return false
end

--[[ Main Damage Handler ]]--
function Apollo.HandleDamage()
    Debug.TrackFunctionStart("Apollo.HandleDamage")
    
    -- Combat and state validation (removed Player.incombat check)
    if Apollo.State.strictHealing then
        Debug.Info(Debug.CATEGORIES.DAMAGE, "Strict healing mode - skipping damage")
        Debug.TrackFunctionEnd("Apollo.HandleDamage")
        return false
    end
    
    -- MP conservation check
    if Player.mp.percent <= Apollo.THRESHOLDS.EMERGENCY then
        Apollo.DamageState.damagePhase = "CONSERVATION"
        Debug.Info(Debug.CATEGORIES.DAMAGE, "MP Conservation mode - skipping damage")
        Debug.TrackFunctionEnd("Apollo.HandleDamage")
        return false
    end

    -- Get all valid targets in range (enemies just need to be in combat)
    local targets = EntityList("alive,attackable,incombat,maxdistance=25")
    if not table.valid(targets) then
        Debug.Verbose(Debug.CATEGORIES.DAMAGE, "No valid targets in range")
        Debug.TrackFunctionEnd("Apollo.HandleDamage")
        return false
    end

    -- First priority: Apply DoTs to all targets that need them
    for _, target in pairs(targets) do
        if Apollo.ShouldRefreshDoT(target) then
            Debug.Info(Debug.CATEGORIES.DAMAGE, string.format(
                "Found target %s needing DoT refresh",
                target.name or "Unknown"
            ))
            if Apollo.HandleDoTs(target) then
                Debug.TrackFunctionEnd("Apollo.HandleDamage")
                return true
            end
        end
    end
    
    -- After all DoTs are applied, proceed with other damage priorities
    local mainTarget = Olympus.FindTargetForDamage(Apollo.DOT_BUFFS, 25)
    if not mainTarget then
        Debug.Verbose(Debug.CATEGORIES.DAMAGE, "No valid main target for damage")
        Debug.TrackFunctionEnd("Apollo.HandleDamage")
        return false
    end
    
    Apollo.DamageState.lastDamageTarget = mainTarget
    
    -- Handle AoE damage if multiple targets
    if Apollo.HandleAoE(mainTarget) then
        Debug.TrackFunctionEnd("Apollo.HandleDamage")
        return true
    end
    
    -- Single target damage
    local damageSpell = Apollo.GetDamageSpell()
    if damageSpell then
        Debug.Info(Debug.CATEGORIES.DAMAGE, 
            string.format("Casting %s on %s", 
                damageSpell.name or "damage spell",
                mainTarget.name or "Unknown"))
        damageSpell.isAoE = false
        if Olympus.CastAction(damageSpell, mainTarget.id) then
            Debug.TrackFunctionEnd("Apollo.HandleDamage")
            return true
        end
    end
    
    Debug.Verbose(Debug.CATEGORIES.DAMAGE, "No damage actions needed")
    Debug.TrackFunctionEnd("Apollo.HandleDamage")
    return false
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
    
    -- Handle Sprint during movement
    if Player:IsMoving() then
        Debug.Verbose(Debug.CATEGORIES.MOVEMENT, "Player is moving, checking Sprint")
        if Olympus.HandleSprint() then 
            Debug.Info(Debug.CATEGORIES.MOVEMENT, "Sprint activated")
            Debug.TrackFunctionEnd("Apollo.HandleMovement")
            return true 
        end
    end

    -- Skip Aetherial Shift if not available
    if Player.level < Apollo.SPELLS.AETHERIAL_SHIFT.level then
        Debug.Verbose(Debug.CATEGORIES.MOVEMENT, "Level too low for Aetherial Shift")
        Debug.TrackFunctionEnd("Apollo.HandleMovement")
        return false 
    end
    
    -- Skip if player is bound
    if Player.bound then
        Debug.Verbose(Debug.CATEGORIES.MOVEMENT, "Player is bound, cannot use Aetherial Shift")
        Debug.TrackFunctionEnd("Apollo.HandleMovement")
        return false 
    end

    -- Check for party members needing emergency movement
    local party = Olympus.GetParty(45)
    if table.valid(party) then
        Debug.Verbose(Debug.CATEGORIES.MOVEMENT, "Checking party members for Aetherial Shift")
        for _, member in pairs(party) do
            -- Check if member needs emergency healing and is just out of range
            if Apollo.ShouldUseAetherialShift(member) then
                Debug.Info(Debug.CATEGORIES.MOVEMENT, 
                    string.format("Using Aetherial Shift to reach %s (HP: %.1f%%, Distance: %.1f)", 
                        member.name or "Unknown",
                        member.hp.percent,
                        member.distance2d))
                local result = Olympus.CastAction(Apollo.SPELLS.AETHERIAL_SHIFT)
                Debug.TrackFunctionEnd("Apollo.HandleMovement")
                return result
            end
        end
    else
        Debug.Verbose(Debug.CATEGORIES.MOVEMENT, "No valid party members in extended range")
    end

    Debug.Verbose(Debug.CATEGORIES.MOVEMENT, "No movement actions needed")
    Debug.TrackFunctionEnd("Apollo.HandleMovement")
    return false
end

function Apollo.ShouldUseAetherialShift(member)
    return member.hp.percent <= Apollo.SETTINGS.CureIIThreshold 
        and member.distance2d > Apollo.SETTINGS.HealingRange 
        and member.distance2d <= (Apollo.SETTINGS.HealingRange + 15)
end

--[[ Ground Targeting Utilities ]]--
function Apollo.HandleGroundTargetedSpell(spell, party, hpThreshold, minTargets)
    Debug.TrackFunctionStart("Apollo.HandleGroundTargetedSpell")
    
    -- Check if enough party members need healing
    local membersNeedingHeal, _ = Olympus.HandleAoEHealCheck(party, hpThreshold, spell.range)
    
    Debug.Info(Debug.CATEGORIES.HEALING, 
        string.format("Ground AoE check - Spell: %s, Members needing heal: %d, Required: %d", 
            spell.name or "Unknown",
            membersNeedingHeal,
            minTargets))

    if membersNeedingHeal >= minTargets then
        -- Calculate optimal ground target position
        local centerPos = Apollo.CalculateOptimalGroundTargetPosition(party, hpThreshold)
        if not centerPos then
            Debug.Warn(Debug.CATEGORIES.HEALING, "Failed to calculate ground target position")
            Debug.TrackFunctionEnd("Apollo.HandleGroundTargetedSpell")
            return false
        end

        -- Cast the ground targeted spell
        local success = Apollo.CastGroundTargetedSpell(spell, centerPos)
        Debug.TrackFunctionEnd("Apollo.HandleGroundTargetedSpell")
        return success
    end
    
    Debug.Verbose(Debug.CATEGORIES.HEALING, "Not enough targets for ground AoE")
    Debug.TrackFunctionEnd("Apollo.HandleGroundTargetedSpell")
    return false
end

function Apollo.CalculateOptimalGroundTargetPosition(party, hpThreshold)
    local centerX, centerZ = 0, 0
    local memberCount = 0

    for _, member in pairs(party) do
        if member.hp.percent <= hpThreshold then
            centerX = centerX + member.pos.x
            centerZ = centerZ + member.pos.z
            memberCount = memberCount + 1
        end
    end

    if memberCount == 0 then return nil end

    return {
        x = centerX / memberCount,
        y = Player.pos.y,
        z = centerZ / memberCount
    }
end

function Apollo.CastGroundTargetedSpell(spell, position)
    local action = ActionList:Get(1, spell.id)
    if not action or not action:IsReady() then
        Debug.Warn(Debug.CATEGORIES.HEALING, "Action not ready or invalid")
        return false
    end

    Debug.Info(Debug.CATEGORIES.HEALING, 
        string.format("Casting %s at position (X=%.2f, Y=%.2f, Z=%.2f)", 
            spell.name or "Unknown",
            position.x,
            position.y,
            position.z))
            
    return action:Cast(position.x, position.y, position.z)
end

--[[ MP Management Utilities ]]--
function Apollo.HandleThinAir(spellId)
    Debug.TrackFunctionStart("Apollo.HandleThinAir")
    
    -- Check if Thin Air should be used
    if Player.level >= Apollo.SPELLS.THIN_AIR.level 
        and Apollo.ShouldUseThinAir(spellId) 
        and Olympus.Combat.IsReady(Apollo.SPELLS.THIN_AIR.id, Apollo.SPELLS.THIN_AIR) then
        Debug.Info(Debug.CATEGORIES.COMBAT, "Using Thin Air before expensive spell")
        Olympus.CastAction(Apollo.SPELLS.THIN_AIR)
    end
    
    Debug.TrackFunctionEnd("Apollo.HandleThinAir")
end

function Apollo.HandleMPConservation()
    Debug.TrackFunctionStart("Apollo.HandleMPConservation")

    -- Check MP threshold and Lucid Dreaming availability
    if Apollo.ShouldUseLucidDreaming() then
        local lucidDreaming = Apollo.SPELLS.LUCID_DREAMING
        
        Debug.Info(Debug.CATEGORIES.COMBAT, string.format(
            "Checking Lucid - MP: %d%%, Spell Ready: %s, Spell Enabled: %s",
            Player.mp.percent,
            tostring(Olympus.Combat.IsReady(lucidDreaming.id, lucidDreaming)),
            tostring(Apollo.IsSpellEnabled("LUCID_DREAMING"))
        ))

        if Apollo.IsSpellEnabled("LUCID_DREAMING") and Olympus.Combat.IsReady(lucidDreaming.id, lucidDreaming) then
            return Olympus.CastAction(lucidDreaming)
        end
    end
    
    Debug.TrackFunctionEnd("Apollo.HandleMPConservation")
    return false
end

function Apollo.ShouldUseLucidDreaming()
    return Player.mp.percent <= Apollo.THRESHOLDS.LUCID
end

--------------------------------------------------------------------------------
-- 7. Event Handlers
--------------------------------------------------------------------------------

--[[ Event Handler State ]]--
Apollo.EventState = {
    lastDrawTime = 0,
    lastUpdateTime = 0,
    frameCount = 0,
    eventMetrics = {
        drawTime = 0,
        updateTime = 0,
        averageFrameTime = 0
    }
}

--[[ Core Event Handlers ]]--

-- Main draw event handler for UI updates
function Apollo.OnDraw()
    Debug.TrackFunctionStart("Apollo.OnDraw")
    
    -- Skip if system is not running
    if not Apollo.State.isRunning then 
        Debug.Verbose(Debug.CATEGORIES.SYSTEM, "Apollo not running, skipping draw")
        Debug.TrackFunctionEnd("Apollo.OnDraw")
        return 
    end
    
    local startTime = os.clock()
    
    -- Update frame metrics
    Apollo.EventState.frameCount = Apollo.EventState.frameCount + 1
    Apollo.EventState.lastDrawTime = startTime
    
    -- Draw UI elements here
    -- TODO: Add UI drawing code when implementing GUI
    
    -- Update performance metrics
    local endTime = os.clock()
    Apollo.EventState.eventMetrics.drawTime = endTime - startTime
    Apollo.EventState.eventMetrics.averageFrameTime = 
        (Apollo.EventState.eventMetrics.averageFrameTime * (Apollo.EventState.frameCount - 1) + 
        Apollo.EventState.eventMetrics.drawTime) / Apollo.EventState.frameCount
    
    Debug.TrackFunctionEnd("Apollo.OnDraw")
end

-- Main update event handler for combat logic
function Apollo.OnUpdate()
    Debug.TrackFunctionStart("Apollo.OnUpdate")
    
    -- Skip if system is not running
    if not Apollo.State.isRunning then 
        Debug.Verbose(Debug.CATEGORIES.SYSTEM, "Apollo not running, skipping update")
        Debug.TrackFunctionEnd("Apollo.OnUpdate")
        return 
    end
    
    local startTime = os.clock()
    Debug.Verbose(Debug.CATEGORIES.SYSTEM, "Running Apollo update cycle")
    
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
            Apollo.SetError(string.format("Error in combat cycle: %s", tostring(err)))
            Debug.Error(Debug.CATEGORIES.SYSTEM, string.format("Combat cycle error: %s", tostring(err)))
        end
    )
    
    -- Update metrics
    local endTime = os.clock()
    Apollo.EventState.lastUpdateTime = endTime
    Apollo.EventState.eventMetrics.updateTime = endTime - startTime
    
    -- Update performance metrics
    Apollo.UpdatePerformanceMetrics(endTime - startTime)
    
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
    
    -- Save current state and settings
    local saveSuccess = Apollo.SaveSettings()
    if not saveSuccess then
        Debug.Warn(Debug.CATEGORIES.SYSTEM, "Failed to save settings during unload")
    end
    
    -- Reset system state
    Apollo.Reset()
    
    -- Clean up event handlers
    Debug.Info(Debug.CATEGORIES.SYSTEM, "Unregistering event handlers")
    local events = {
        { name = "Gameloop.Draw", handler = "Apollo.OnDraw" },
        { name = "Gameloop.Update", handler = "Apollo.OnUpdate" },
        { name = "Module.Unload", handler = "Apollo.OnUnload" }
    }
    
    for _, event in ipairs(events) do
        xpcall(
            function()
                UnregisterEventHandler(event.name, event.handler)
                Debug.Verbose(Debug.CATEGORIES.SYSTEM, 
                    string.format("Unregistered event handler: %s", event.handler))
            end,
            function(err)
                Debug.Error(Debug.CATEGORIES.SYSTEM, 
                    string.format("Failed to unregister %s: %s", event.handler, tostring(err)))
            end
        )
    end
    
    -- Clear event state
    Apollo.EventState = {
        lastDrawTime = 0,
        lastUpdateTime = 0,
        frameCount = 0,
        eventMetrics = {
            drawTime = 0,
            updateTime = 0,
            averageFrameTime = 0
        }
    }
    
    Debug.Info(Debug.CATEGORIES.SYSTEM, "Apollo unloaded successfully")
    Debug.TrackFunctionEnd("Apollo.OnUnload")
end

--[[ Event Metrics ]]--

-- Get current event performance metrics
function Apollo.GetEventMetrics()
    return {
        frameCount = Apollo.EventState.frameCount,
        lastDrawTime = Apollo.EventState.lastDrawTime,
        lastUpdateTime = Apollo.EventState.lastUpdateTime,
        metrics = Apollo.EventState.eventMetrics
    }
end

-- Reset event metrics
function Apollo.ResetEventMetrics()
    Apollo.EventState = {
        lastDrawTime = 0,
        lastUpdateTime = 0,
        frameCount = 0,
        eventMetrics = {
            drawTime = 0,
            updateTime = 0,
            averageFrameTime = 0
        }
    }
end

--------------------------------------------------------------------------------
-- 8. Initialization
--------------------------------------------------------------------------------

--[[ Settings Management ]]--
function Apollo.LoadSettings()
    Debug.TrackFunctionStart("Apollo.LoadSettings")
    
    -- Validate Olympus_Settings exists
    if not Olympus_Settings then
        Debug.Warn(Debug.CATEGORIES.SYSTEM, "Olympus_Settings not found, using default settings")
        return false
    end
    
    -- Load or initialize Apollo settings
    if Olympus_Settings.Apollo then
        -- Validate loaded settings
        local validationResult = Apollo.ValidateSettings(Olympus_Settings.Apollo)
        if not validationResult.isValid then
            Debug.Warn(Debug.CATEGORIES.SYSTEM, string.format(
                "Invalid settings detected: %s. Using defaults", 
                validationResult.error
            ))
            return false
        end
        
        -- Apply loaded settings
        Apollo.SETTINGS = Olympus_Settings.Apollo
        Debug.Info(Debug.CATEGORIES.SYSTEM, "Settings loaded successfully from Olympus_Settings")
        return true
    else
        -- Initialize default settings
        Olympus_Settings.Apollo = Apollo.SETTINGS
        Debug.Info(Debug.CATEGORIES.SYSTEM, "Initialized default Apollo settings")
        return true
    end
end

function Apollo.ValidateSettings(settings)
    if type(settings) ~= "table" then
        return { isValid = false, error = "Settings must be a table" }
    end
    
    -- Required threshold validations
    local requiredThresholds = {
        "MPThreshold", "HealingRange", "CureThreshold", "CureIIThreshold",
        "CureIIIThreshold", "RegenThreshold", "BenedictionThreshold"
    }
    
    for _, threshold in ipairs(requiredThresholds) do
        if type(settings[threshold]) ~= "number" then
            return { isValid = false, error = string.format("Missing or invalid %s", threshold) }
        end
    end
    
    return { isValid = true }
end

function Apollo.SaveSettings()
    Debug.TrackFunctionStart("Apollo.SaveSettings")
    
    if not Olympus_Settings then
        Debug.Error(Debug.CATEGORIES.SYSTEM, "Cannot save settings: Olympus_Settings not available")
        return false
    end
    
    -- Validate current settings before saving
    local validationResult = Apollo.ValidateSettings(Apollo.SETTINGS)
    if not validationResult.isValid then
        Debug.Error(Debug.CATEGORIES.SYSTEM, string.format(
            "Cannot save invalid settings: %s",
            validationResult.error
        ))
        return false
    end
    
    -- Save settings
    Olympus_Settings.Apollo = Apollo.SETTINGS
    
    -- Trigger Olympus settings save if available
    if type(Olympus_Settings.Save) == "function" then
        xpcall(
            Olympus_Settings.Save,
            function(err)
                Debug.Error(Debug.CATEGORIES.SYSTEM, string.format(
                    "Failed to save Olympus settings: %s",
                    tostring(err)
                ))
            end
        )
    end
    
    Debug.Info(Debug.CATEGORIES.SYSTEM, "Settings saved successfully")
    Debug.TrackFunctionEnd("Apollo.SaveSettings")
    return true
end

--[[ Event Registration ]]--
function Apollo.RegisterEvents()
    Debug.TrackFunctionStart("Apollo.RegisterEvents")
    
    local events = {
        { name = "Gameloop.Draw", handler = Apollo.OnDraw },
        { name = "Gameloop.Update", handler = Apollo.OnUpdate },
        { name = "Module.Unload", handler = Apollo.OnUnload }
    }
    
    local success = true
    for _, event in ipairs(events) do
        xpcall(
            function()
                RegisterEventHandler(event.name, event.handler, "Apollo")
                Debug.Verbose(Debug.CATEGORIES.SYSTEM, string.format(
                    "Registered event handler: %s",
                    event.name
                ))
            end,
            function(err)
                success = false
                Debug.Error(Debug.CATEGORIES.SYSTEM, string.format(
                    "Failed to register %s: %s",
                    event.name,
                    tostring(err)
                ))
            end
        )
    end
    
    Debug.TrackFunctionEnd("Apollo.RegisterEvents")
    return success
end

--[[ Main Initialization ]]--
function Apollo.Initialize()
    Debug.TrackFunctionStart("Apollo.Initialize")
    
    Debug.Info(Debug.CATEGORIES.SYSTEM, "Starting Apollo White Mage combat routine initialization")

    -- Step 2: Register Event Handlers
    if not Apollo.RegisterEvents() then
        Debug.Error(Debug.CATEGORIES.SYSTEM, "Event registration failed")
        Debug.TrackFunctionEnd("Apollo.Initialize")
        return false
    end
    
    -- Step 3: Initialize System State
    Debug.Info(Debug.CATEGORIES.SYSTEM, "Initializing system state")
    Apollo.Reset()
    
    -- Step 4: Load Settings
    local settingsLoaded = Apollo.LoadSettings()
    if not settingsLoaded then
        Debug.Warn(Debug.CATEGORIES.SYSTEM, "Failed to load settings, using defaults")
    end
    
    -- Step 5: Perform Final Validation
    local finalValidation = xpcall(
        function()
            -- Add any final validation checks here
            return true
        end,
        function(err)
            Debug.Error(Debug.CATEGORIES.SYSTEM, string.format(
                "Final validation failed: %s",
                tostring(err)
            ))
            return false
        end
    )
    
    if not finalValidation then
        Debug.Error(Debug.CATEGORIES.SYSTEM, "Final validation failed")
        Debug.TrackFunctionEnd("Apollo.Initialize")
        return false
    end
    
    Debug.Info(Debug.CATEGORIES.SYSTEM, "Apollo initialization completed successfully")
    Debug.TrackFunctionEnd("Apollo.Initialize")
    return true
end

-- Initialize Apollo when the file is loaded
local init_success = Apollo.Initialize()
if not init_success then
    Debug.Error(Debug.CATEGORIES.SYSTEM, "Apollo failed to initialize properly")
end

return Apollo