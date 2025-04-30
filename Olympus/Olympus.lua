-- Olympus Core System
Olympus = Olympus or {}

-- State Management System
Olympus.State = {
    modules = {},
    lastUpdate = 0,
    isInitialized = false
}

function Olympus.State.Initialize()
    Debug.TrackFunctionStart("Olympus.State.Initialize")
    Olympus.State.modules = {}
    Olympus.State.lastUpdate = Now()
    Olympus.State.isInitialized = true
    Debug.Info(Debug.CATEGORIES.SYSTEM, "State system initialized")
    Debug.TrackFunctionEnd("Olympus.State.Initialize")
end

function Olympus.State.IsModuleRunning(moduleName)
    return Olympus.State.modules[moduleName] and Olympus.State.modules[moduleName].running or false
end

function Olympus.State.SetModuleRunning(moduleName, isRunning)
    Debug.TrackFunctionStart("Olympus.State.SetModuleRunning")
    
    if not Olympus.State.modules[moduleName] then
        Olympus.State.modules[moduleName] = {
            running = false,
            lastUpdate = 0,
            errors = {},
            metrics = {}
        }
    end
    
    Olympus.State.modules[moduleName].running = isRunning
    Olympus.State.modules[moduleName].lastUpdate = Now()
    
    Debug.Info(Debug.CATEGORIES.SYSTEM, string.format(
        "Module %s %s",
        moduleName,
        isRunning and "started" or "stopped"
    ))
    
    Debug.TrackFunctionEnd("Olympus.State.SetModuleRunning")
end

function Olympus.State.GetModuleState(moduleName)
    return Olympus.State.modules[moduleName] or {
        running = false,
        lastUpdate = 0,
        errors = {},
        metrics = {}
    }
end

function Olympus.State.ResetModuleState(moduleName)
    Debug.TrackFunctionStart("Olympus.State.ResetModuleState")
    
    Olympus.State.modules[moduleName] = {
        running = false,
        lastUpdate = Now(),
        errors = {},
        metrics = {}
    }
    
    Debug.Info(Debug.CATEGORIES.SYSTEM, string.format(
        "Module %s state reset",
        moduleName
    ))
    
    Debug.TrackFunctionEnd("Olympus.State.ResetModuleState")
end

function Olympus.State.UpdateModuleMetrics(moduleName, metrics)
    if Olympus.State.modules[moduleName] then
        Olympus.State.modules[moduleName].metrics = metrics
        Olympus.State.modules[moduleName].lastUpdate = Now()
    end
end

-- Error Management System
Olympus.Error = {
    errors = {},
    maxErrors = 100
}

function Olympus.Error.SetError(errorMessage, source)
    Debug.TrackFunctionStart("Olympus.Error.SetError")
    
    table.insert(Olympus.Error.errors, {
        message = errorMessage,
        source = source or "UNKNOWN",
        timestamp = Now()
    })
    
    -- Keep only the last maxErrors
    while #Olympus.Error.errors > Olympus.Error.maxErrors do
        table.remove(Olympus.Error.errors, 1)
    end
    
    Debug.Error(Debug.CATEGORIES.SYSTEM, string.format(
        "[%s] %s",
        source or "UNKNOWN",
        errorMessage
    ))
    
    Debug.TrackFunctionEnd("Olympus.Error.SetError")
end

function Olympus.Error.GetLastError()
    return #Olympus.Error.errors > 0 and Olympus.Error.errors[#Olympus.Error.errors] or nil
end

function Olympus.Error.ClearErrors()
    Olympus.Error.errors = {}
end

-- Initialize State System
Olympus.State.Initialize()

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
    REPOSE = { id = 16560, level = 8, isGCD = true, range = 30, mp = 400 },
    LUCID_DREAMING = { id = 7562, level = 24, isGCD = false, cooldown = 60, mp = 0 }
}

-- MP Management
Olympus.MP = {
    -- Default thresholds that can be overridden by specific ACRs
    THRESHOLDS = {
        LUCID = 80,         -- MP% to trigger Lucid Dreaming
        NORMAL = 30,        -- Normal phase MP threshold
        AOE = 40,          -- AoE phase MP threshold
        EMERGENCY = 30,    -- Emergency phase MP threshold
        CRITICAL = 15      -- Critical MP conservation threshold
    }
}

-- Check if Lucid Dreaming should be used based on MP thresholds
function Olympus.MP.ShouldUseLucidDreaming()
    return Player.mp.percent <= Olympus.MP.THRESHOLDS.LUCID
end

-- Handle MP conservation abilities (like Lucid Dreaming)
function Olympus.MP.HandleConservation()
    Debug.TrackFunctionStart("Olympus.MP.HandleConservation")

    -- Check MP threshold and Lucid Dreaming availability
    if Olympus.MP.ShouldUseLucidDreaming() then
        local lucidDreaming = Olympus.COMMON_SPELLS.LUCID_DREAMING
        if not lucidDreaming then
            Debug.Verbose(Debug.CATEGORIES.COMBAT, "Lucid Dreaming not available in COMMON_SPELLS")
            Debug.TrackFunctionEnd("Olympus.MP.HandleConservation")
            return false
        end
        
        Debug.Info(Debug.CATEGORIES.COMBAT, string.format(
            "Checking Lucid - MP: %d%%, Spell Ready: %s",
            Player.mp.percent,
            tostring(Olympus.Combat.IsReady(lucidDreaming.id, lucidDreaming))
        ))

        if Olympus.Combat.IsReady(lucidDreaming.id, lucidDreaming) then
            return Olympus.CastAction(lucidDreaming)
        end
    end
    
    Debug.TrackFunctionEnd("Olympus.MP.HandleConservation")
    return false
end

-- Ground Targeting System
Olympus.Ground = {
    -- Default settings that can be overridden by specific ACRs
    SETTINGS = {
        DEFAULT_RANGE = 30,     -- Default range for ground targeted abilities
        MIN_TARGETS = 2,        -- Default minimum targets for AoE abilities
        HP_THRESHOLD = 80       -- Default HP threshold for healing abilities
    }
}

-- Calculate optimal position for ground targeted spells based on party member positions
function Olympus.Ground.CalculateOptimalPosition(party, hpThreshold)
    Debug.TrackFunctionStart("Olympus.Ground.CalculateOptimalPosition")
    
    local centerX, centerZ = 0, 0
    local memberCount = 0

    -- Calculate center based on all members provided in the party table
    if not table.valid(party) then
        Debug.Verbose(Debug.CATEGORIES.COMBAT, "No valid party members provided for ground targeting")
        Debug.TrackFunctionEnd("Olympus.Ground.CalculateOptimalPosition")
        return nil
    end

    for _, member in pairs(party) do
        -- Original logic only included members below hpThreshold:
        -- if member.hp.percent <= hpThreshold then
        centerX = centerX + member.pos.x
        centerZ = centerZ + member.pos.z
        memberCount = memberCount + 1
        -- end
    end

    -- This check should now only fail if the input party table was empty
    if memberCount == 0 then 
        Debug.Verbose(Debug.CATEGORIES.COMBAT, "Empty party list provided for ground targeting calculation")
        Debug.TrackFunctionEnd("Olympus.Ground.CalculateOptimalPosition")
        return nil 
    end

    local position = {
        x = centerX / memberCount,
        y = Player.pos.y, -- Still using player's Y, might need adjustment based on terrain?
        z = centerZ / memberCount
    }

    Debug.Info(Debug.CATEGORIES.COMBAT, string.format(
        "Calculated ground target position (based on %d members): (X=%.2f, Y=%.2f, Z=%.2f)",
        memberCount, position.x, position.y, position.z
    ))
    
    Debug.TrackFunctionEnd("Olympus.Ground.CalculateOptimalPosition")
    return position
end

-- Cast a ground targeted spell at the specified position
function Olympus.Ground.CastSpell(spell, position)
    Debug.TrackFunctionStart("Olympus.Ground.CastSpell")
    
    local action = ActionList:Get(1, spell.id)
    if not action or not action:IsReady() then
        Debug.Warn(Debug.CATEGORIES.COMBAT, "Action not ready or invalid")
        Debug.TrackFunctionEnd("Olympus.Ground.CastSpell")
        return false
    end

    Debug.Info(Debug.CATEGORIES.COMBAT, string.format(
        "Casting %s at position (X=%.2f, Y=%.2f, Z=%.2f)", 
        spell.name or "Unknown",
        position.x,
        position.y,
        position.z
    ))
            
    local result = action:Cast(position.x, position.y, position.z)
    Debug.TrackFunctionEnd("Olympus.Ground.CastSpell")
    return result
end

-- Handle ground targeted spell with party member targeting
function Olympus.Ground.HandleSpell(spell, party, hpThreshold, minTargets)
    Debug.TrackFunctionStart("Olympus.Ground.HandleSpell")
    
    -- Check if enough party members need healing
    local membersNeedingHeal, _ = Olympus.Healing.HandleAoEHealCheck(party, hpThreshold, spell.range)
    
    Debug.Info(Debug.CATEGORIES.COMBAT, string.format(
        "Ground AoE check - Spell: %s, Members needing heal: %d, Required: %d", 
        spell.name or "Unknown",
        membersNeedingHeal,
        minTargets or Olympus.Ground.SETTINGS.MIN_TARGETS
    ))

    if membersNeedingHeal >= (minTargets or Olympus.Ground.SETTINGS.MIN_TARGETS) then
        -- Calculate optimal ground target position
        local centerPos = Olympus.Ground.CalculateOptimalPosition(party, hpThreshold)
        if not centerPos then
            Debug.Warn(Debug.CATEGORIES.COMBAT, "Failed to calculate ground target position")
            Debug.TrackFunctionEnd("Olympus.Ground.HandleSpell")
            return false
        end

        -- Cast the ground targeted spell
        local success = Olympus.Ground.CastSpell(spell, centerPos)
        Debug.TrackFunctionEnd("Olympus.Ground.HandleSpell")
        return success
    end
    
    Debug.Verbose(Debug.CATEGORIES.COMBAT, "Not enough targets for ground AoE")
    Debug.TrackFunctionEnd("Olympus.Ground.HandleSpell")
    return false
end

-- Party Management System
Olympus.Party = {
    -- Default settings that can be overridden by specific ACRs
    SETTINGS = {
        DEFAULT_RANGE = 30,     -- Default range for party member checks
        HP_THRESHOLD = 80,      -- Default HP threshold for healing checks
        TANK_PRIORITY = true,   -- Whether to prioritize tanks in healing
        HEALER_PRIORITY = true  -- Whether to prioritize healers in healing
    }
}

-- Validate and get party members within range
function Olympus.Party.ValidateParty(range)
    Debug.TrackFunctionStart("Olympus.Party.ValidateParty")
    local party = Olympus.GetParty(range or Olympus.Party.SETTINGS.DEFAULT_RANGE)
    if not table.valid(party) then 
        Debug.Verbose(Debug.CATEGORIES.PARTY, "No valid party members in range")
        Debug.TrackFunctionEnd("Olympus.Party.ValidateParty")
        return nil
    end
    Debug.TrackFunctionEnd("Olympus.Party.ValidateParty")
    return party
end

-- Find lowest health party member
function Olympus.Party.FindLowestHealthMember(party, range)
    Debug.TrackFunctionStart("Olympus.Party.FindLowestHealthMember")
    local lowestHP = 100
    local lowestMember = nil
    
    for _, member in pairs(party) do
        if member.hp.percent < lowestHP and member.distance2d <= (range or Olympus.Party.SETTINGS.DEFAULT_RANGE) then
            lowestHP = member.hp.percent
            lowestMember = member
        end
    end
    
    if lowestMember then
        Debug.Info(Debug.CATEGORIES.PARTY, 
            string.format("Lowest member: %s (HP: %.1f%%)", 
                lowestMember.name or "Unknown",
                lowestHP))
    end
    
    Debug.TrackFunctionEnd("Olympus.Party.FindLowestHealthMember")
    return lowestMember, lowestHP
end

-- Count party members below HP threshold within range
function Olympus.Party.CountMembersBelowHP(party, hpThreshold, range)
    Debug.TrackFunctionStart("Olympus.Party.CountMembersBelowHP")
    
    local count = 0
    local lowestHP = 100
    local lowestMember = nil
    
    for _, member in pairs(party) do
        if member.hp.percent <= hpThreshold and member.distance2d <= (range or Olympus.Party.SETTINGS.DEFAULT_RANGE) then
            count = count + 1
            if member.hp.percent < lowestHP then
                lowestHP = member.hp.percent
                lowestMember = member
            end
        end
    end
    
    Debug.Info(Debug.CATEGORIES.PARTY, 
        string.format("Members below %.1f%%: %d (Lowest: %.1f%%)", 
            hpThreshold,
            count,
            lowestHP))
    
    Debug.TrackFunctionEnd("Olympus.Party.CountMembersBelowHP")
    return count, lowestMember, lowestHP
end

-- Find tank in party
function Olympus.Party.FindTank(party, range)
    Debug.TrackFunctionStart("Olympus.Party.FindTank")
    
    for _, member in pairs(party) do
        if member.role == "TANK" and member.distance2d <= (range or Olympus.Party.SETTINGS.DEFAULT_RANGE) then
            Debug.Info(Debug.CATEGORIES.PARTY, 
                string.format("Found tank: %s (HP: %.1f%%)", 
                    member.name or "Unknown",
                    member.hp.percent))
            Debug.TrackFunctionEnd("Olympus.Party.FindTank")
            return member
        end
    end
    
    Debug.Verbose(Debug.CATEGORIES.PARTY, "No tank found in range")
    Debug.TrackFunctionEnd("Olympus.Party.FindTank")
    return nil
end

-- Find healer in party
function Olympus.Party.FindHealer(party, range)
    Debug.TrackFunctionStart("Olympus.Party.FindHealer")
    
    for _, member in pairs(party) do
        if member.role == "HEALER" and member.distance2d <= (range or Olympus.Party.SETTINGS.DEFAULT_RANGE) then
            Debug.Info(Debug.CATEGORIES.PARTY, 
                string.format("Found healer: %s (HP: %.1f%%)", 
                    member.name or "Unknown",
                    member.hp.percent))
            Debug.TrackFunctionEnd("Olympus.Party.FindHealer")
            return member
        end
    end
    
    Debug.Verbose(Debug.CATEGORIES.PARTY, "No healer found in range")
    Debug.TrackFunctionEnd("Olympus.Party.FindHealer")
    return nil
end

-- Movement and Positioning System
Olympus.Movement = {
    -- Default settings that can be overridden by specific ACRs
    SETTINGS = {
        DEFAULT_RANGE = 30,          -- Default range for movement abilities
        EXTENDED_RANGE = 45,         -- Extended range for gap closers/teleports
        MOVEMENT_THRESHOLD = 5,      -- Minimum distance to consider movement
        EMERGENCY_HP_THRESHOLD = 30  -- HP threshold for emergency movement
    }
}

-- Check if movement ability should be used to reach a target
function Olympus.Movement.ShouldUseMovementAbility(target, baseRange, extendedRange)
    Debug.TrackFunctionStart("Olympus.Movement.ShouldUseMovementAbility")
    
    if not target then
        Debug.Verbose(Debug.CATEGORIES.MOVEMENT, "No target provided for movement check")
        Debug.TrackFunctionEnd("Olympus.Movement.ShouldUseMovementAbility")
        return false
    end

    local baseRange = baseRange or Olympus.Movement.SETTINGS.DEFAULT_RANGE
    local extendedRange = extendedRange or Olympus.Movement.SETTINGS.EXTENDED_RANGE

    -- Check if target is just out of normal range but within movement ability range
    local shouldMove = target.distance2d > baseRange and target.distance2d <= extendedRange

    if shouldMove then
        Debug.Info(Debug.CATEGORIES.MOVEMENT, string.format(
            "Target %s is at optimal distance for movement ability (%.1f yalms)",
            target.name or "Unknown",
            target.distance2d
        ))
    end

    Debug.TrackFunctionEnd("Olympus.Movement.ShouldUseMovementAbility")
    return shouldMove
end

-- Handle Sprint during movement
function Olympus.Movement.HandleSprint()
    Debug.TrackFunctionStart("Olympus.Movement.HandleSprint")
    
    if not Player:IsMoving() then
        Debug.Verbose(Debug.CATEGORIES.MOVEMENT, "Player not moving, skipping Sprint")
        Debug.TrackFunctionEnd("Olympus.Movement.HandleSprint")
        return false
    end

    local sprint = Olympus.COMMON_SPELLS.SPRINT
    if not sprint then
        Debug.Verbose(Debug.CATEGORIES.MOVEMENT, "Sprint not available in COMMON_SPELLS")
        Debug.TrackFunctionEnd("Olympus.Movement.HandleSprint")
        return false
    end

    if Olympus.Combat.IsReady(sprint.id, sprint) then
        Debug.Info(Debug.CATEGORIES.MOVEMENT, "Using Sprint while moving")
        local result = Olympus.CastAction(sprint)
        Debug.TrackFunctionEnd("Olympus.Movement.HandleSprint")
        return result
    end

    Debug.TrackFunctionEnd("Olympus.Movement.HandleSprint")
    return false
end

-- Handle emergency movement to reach a target
function Olympus.Movement.HandleEmergencyMovement(target, movementAbility, baseRange)
    Debug.TrackFunctionStart("Olympus.Movement.HandleEmergencyMovement")
    
    if not target or not movementAbility then
        Debug.Verbose(Debug.CATEGORIES.MOVEMENT, "Missing target or movement ability")
        Debug.TrackFunctionEnd("Olympus.Movement.HandleEmergencyMovement")
        return false
    end

    -- Check if target needs emergency attention
    if target.hp.percent > Olympus.Movement.SETTINGS.EMERGENCY_HP_THRESHOLD then
        Debug.Verbose(Debug.CATEGORIES.MOVEMENT, "Target HP above emergency threshold")
        Debug.TrackFunctionEnd("Olympus.Movement.HandleEmergencyMovement")
        return false
    end

    -- Check if movement ability would help reach the target
    if Olympus.Movement.ShouldUseMovementAbility(target, baseRange, movementAbility.range) then
        Debug.Info(Debug.CATEGORIES.MOVEMENT, string.format(
            "Using %s to reach target %s (HP: %.1f%%, Distance: %.1f)",
            movementAbility.name or "movement ability",
            target.name or "Unknown",
            target.hp.percent,
            target.distance2d
        ))
        local result = Olympus.CastAction(movementAbility)
        Debug.TrackFunctionEnd("Olympus.Movement.HandleEmergencyMovement")
        return result
    end

    Debug.TrackFunctionEnd("Olympus.Movement.HandleEmergencyMovement")
    return false
end

-- Buff Management System
Olympus.Buff = {
    -- Default settings that can be overridden by specific ACRs
    SETTINGS = {
        REFRESH_THRESHOLD = 3,    -- Time in seconds to consider refreshing a buff
        MAX_DURATION = 60,        -- Maximum duration to track for buffs
        STACK_THRESHOLD = 3       -- Default threshold for stack-based buffs
    },
    
    -- Common buff categories
    CATEGORIES = {
        DAMAGE = "DAMAGE",
        HEALING = "HEALING",
        MITIGATION = "MITIGATION",
        UTILITY = "UTILITY",
        MOVEMENT = "MOVEMENT"
    }
}

-- Check if a target has a specific buff
function Olympus.Buff.HasBuff(target, buffId)
    Debug.TrackFunctionStart("Olympus.Buff.HasBuff")
    
    if not target or not buffId then
        Debug.Verbose(Debug.CATEGORIES.BUFFS, "Missing target or buff ID")
        Debug.TrackFunctionEnd("Olympus.Buff.HasBuff")
        return false
    end

    local hasBuff = Olympus.Combat.HasBuff(target, buffId)
    
    Debug.Verbose(Debug.CATEGORIES.BUFFS, string.format(
        "Buff check - Target: %s, BuffID: %d, Has Buff: %s",
        target.name or "Unknown",
        buffId,
        tostring(hasBuff)
    ))
    
    Debug.TrackFunctionEnd("Olympus.Buff.HasBuff")
    return hasBuff
end

-- Get remaining duration of a buff on a target
function Olympus.Buff.GetDuration(target, buffId)
    Debug.TrackFunctionStart("Olympus.Buff.GetDuration")
    
    if not target or not buffId then
        Debug.Verbose(Debug.CATEGORIES.BUFFS, "Missing target or buff ID")
        Debug.TrackFunctionEnd("Olympus.Buff.GetDuration")
        return 0
    end

    local duration = Olympus.Combat.GetBuffDuration(target, buffId)
    
    Debug.Verbose(Debug.CATEGORIES.BUFFS, string.format(
        "Buff duration - Target: %s, BuffID: %d, Duration: %.1f",
        target.name or "Unknown",
        buffId,
        duration or 0
    ))
    
    Debug.TrackFunctionEnd("Olympus.Buff.GetDuration")
    return duration or 0
end

-- Check if a buff should be refreshed based on duration
function Olympus.Buff.ShouldRefresh(target, buffId, threshold)
    Debug.TrackFunctionStart("Olympus.Buff.ShouldRefresh")
    
    local threshold = threshold or Olympus.Buff.SETTINGS.REFRESH_THRESHOLD
    local hasBuff = Olympus.Buff.HasBuff(target, buffId)
    
    -- If no buff, it should be applied
    if not hasBuff then
        Debug.Info(Debug.CATEGORIES.BUFFS, string.format(
            "Buff %d not present on %s, should be applied",
            buffId,
            target.name or "Unknown"
        ))
        Debug.TrackFunctionEnd("Olympus.Buff.ShouldRefresh")
        return true
    end
    
    -- Check remaining duration
    local duration = Olympus.Buff.GetDuration(target, buffId)
    local shouldRefresh = duration <= threshold
    
    Debug.Info(Debug.CATEGORIES.BUFFS, string.format(
        "Buff refresh check - Target: %s, BuffID: %d, Duration: %.1f, Threshold: %.1f, Should Refresh: %s",
        target.name or "Unknown",
        buffId,
        duration,
        threshold,
        tostring(shouldRefresh)
    ))
    
    Debug.TrackFunctionEnd("Olympus.Buff.ShouldRefresh")
    return shouldRefresh
end

-- Handle application of a buff
function Olympus.Buff.HandleApplication(target, spell, buffId, threshold)
    Debug.TrackFunctionStart("Olympus.Buff.HandleApplication")
    
    if not target or not spell or not buffId then
        Debug.Verbose(Debug.CATEGORIES.BUFFS, "Missing required parameters for buff application")
        Debug.TrackFunctionEnd("Olympus.Buff.HandleApplication")
        return false
    end

    -- Check if buff needs to be applied/refreshed
    if Olympus.Buff.ShouldRefresh(target, buffId, threshold) then
        Debug.Info(Debug.CATEGORIES.BUFFS, string.format(
            "Applying %s to %s",
            spell.name or "buff",
            target.name or "Unknown"
        ))
        
        -- Set AoE flag if spell has it
        if spell.isAoE ~= nil then
            spell.isAoE = false
        end
        
        local result = Olympus.CastAction(spell, target.id)
        Debug.TrackFunctionEnd("Olympus.Buff.HandleApplication")
        return result
    end
    
    Debug.Verbose(Debug.CATEGORIES.BUFFS, "Buff doesn't need refresh")
    Debug.TrackFunctionEnd("Olympus.Buff.HandleApplication")
    return false
end

-- Handle role-specific buffs (like Swiftcast, Surecast)
function Olympus.Buff.HandleRoleBuffs()
    Debug.TrackFunctionStart("Olympus.Buff.HandleRoleBuffs")
    
    -- Handle Swiftcast
    if Olympus.HandleSwiftcast() then
        Debug.TrackFunctionEnd("Olympus.Buff.HandleRoleBuffs")
        return true
    end
    
    -- Handle Surecast
    if Olympus.HandleSurecast() then
        Debug.TrackFunctionEnd("Olympus.Buff.HandleRoleBuffs")
        return true
    end
    
    Debug.Verbose(Debug.CATEGORIES.BUFFS, "No role buffs needed")
    Debug.TrackFunctionEnd("Olympus.Buff.HandleRoleBuffs")
    return false
end

-- Damage System
Olympus.Damage = {
    -- Default settings that can be overridden by specific ACRs
    SETTINGS = {
        DEFAULT_RANGE = 25,          -- Default range for damage abilities
        AOE_RANGE = 8,              -- Default range for AoE abilities
        MIN_AOE_TARGETS = 3,        -- Minimum targets for AoE priority
        DOT_REFRESH_THRESHOLD = 3,   -- Time in seconds to refresh DoTs
        MAX_DOT_TARGETS = 5         -- Maximum targets to maintain DoTs on
    },
    
    -- Combat phases
    PHASES = {
        SINGLE = "SINGLE",   -- Single target phase
        AOE = "AOE",        -- AoE phase
        DOT = "DOT",        -- DoT application phase
        BURST = "BURST"     -- Burst phase
    }
}

-- State tracking for damage system
Olympus.Damage.State = {
    currentPhase = Olympus.Damage.PHASES.SINGLE,
    lastDamageTarget = nil,
    lastDoTTarget = nil,
    lastAoETime = 0,
    aoeTargetsCount = 0
}

-- Update AoE state based on nearby enemies
function Olympus.Damage.UpdateAoEState(range)
    Debug.TrackFunctionStart("Olympus.Damage.UpdateAoEState")
    
    local range = range or Olympus.Damage.SETTINGS.AOE_RANGE
    local enemies = EntityList("alive,attackable,incombat,maxdistance=" .. range)
    Olympus.Damage.State.aoeTargetsCount = table.valid(enemies) and table.size(enemies) or 0
    
    -- Update phase based on target count
    if Olympus.Damage.State.aoeTargetsCount >= Olympus.Damage.SETTINGS.MIN_AOE_TARGETS then
        Olympus.Damage.State.currentPhase = Olympus.Damage.PHASES.AOE
    else
        Olympus.Damage.State.currentPhase = Olympus.Damage.PHASES.SINGLE
    end
    
    Debug.Info(Debug.CATEGORIES.DAMAGE, string.format(
        "AoE state updated: %d targets, Phase: %s",
        Olympus.Damage.State.aoeTargetsCount,
        Olympus.Damage.State.currentPhase
    ))
    
    Debug.TrackFunctionEnd("Olympus.Damage.UpdateAoEState")
    return Olympus.Damage.State.aoeTargetsCount
end

-- Find best target for damage
function Olympus.Damage.FindTarget(dotBuffs, range)
    Debug.TrackFunctionStart("Olympus.Damage.FindTarget")
    
    local range = range or Olympus.Damage.SETTINGS.DEFAULT_RANGE
    local targets = EntityList("alive,attackable,incombat,maxdistance=" .. range)
    
    if not table.valid(targets) then
        Debug.Verbose(Debug.CATEGORIES.DAMAGE, "No valid targets in range")
        Debug.TrackFunctionEnd("Olympus.Damage.FindTarget")
        return nil
    end
    
    -- First priority: Target missing DoTs (if DoTs provided)
    if dotBuffs then
        for _, target in pairs(targets) do
            local hasAllDoTs = true
            for buffId, _ in pairs(dotBuffs) do
                if not Olympus.Buff.HasBuff(target, buffId) then
                    hasAllDoTs = false
                    break
                end
            end
            if not hasAllDoTs then
                Debug.Info(Debug.CATEGORIES.DAMAGE, string.format(
                    "Found target %s missing DoTs",
                    target.name or "Unknown"
                ))
                Debug.TrackFunctionEnd("Olympus.Damage.FindTarget")
                return target
            end
        end
    end
    
    -- Second priority: Current target if valid
    if Player.target and Player.target.valid and Player.target.attackable and 
       Player.target.alive and Player.target.distance2d <= range then
        Debug.Info(Debug.CATEGORIES.DAMAGE, "Using current target")
        Debug.TrackFunctionEnd("Olympus.Damage.FindTarget")
        return Player.target
    end
    
    -- Third priority: Closest valid target
    local closest = nil
    local minDistance = range
    for _, target in pairs(targets) do
        if target.distance2d < minDistance then
            closest = target
            minDistance = target.distance2d
        end
    end
    
    if closest then
        Debug.Info(Debug.CATEGORIES.DAMAGE, string.format(
            "Selected closest target: %s (%.1f yalms)",
            closest.name or "Unknown",
            minDistance
        ))
    end
    
    Debug.TrackFunctionEnd("Olympus.Damage.FindTarget")
    return closest
end

-- Handle DoT application and refresh
function Olympus.Damage.HandleDoTs(target, dotSpell, dotBuffId)
    Debug.TrackFunctionStart("Olympus.Damage.HandleDoTs")
    
    if not target or not dotSpell or not dotBuffId then
        Debug.Verbose(Debug.CATEGORIES.DAMAGE, "Missing required parameters for DoT handling")
        Debug.TrackFunctionEnd("Olympus.Damage.HandleDoTs")
        return false
    end

    -- Check if DoT needs to be applied/refreshed
    if Olympus.Buff.ShouldRefresh(target, dotBuffId, Olympus.Damage.SETTINGS.DOT_REFRESH_THRESHOLD) then
        Debug.Info(Debug.CATEGORIES.DAMAGE, string.format(
            "Applying %s to %s",
            dotSpell.name or "DoT",
            target.name or "Unknown"
        ))
        
        -- Set AoE flag if spell has it
        if dotSpell.isAoE ~= nil then
            dotSpell.isAoE = false
        end
        
        Olympus.Damage.State.lastDoTTarget = target
        local result = Olympus.CastAction(dotSpell, target.id)
        Debug.TrackFunctionEnd("Olympus.Damage.HandleDoTs")
        return result
    end
    
    Debug.Verbose(Debug.CATEGORIES.DAMAGE, "DoT doesn't need refresh")
    Debug.TrackFunctionEnd("Olympus.Damage.HandleDoTs")
    return false
end

-- Handle AoE damage
function Olympus.Damage.HandleAoE(spell, minTargets, range)
    Debug.TrackFunctionStart("Olympus.Damage.HandleAoE")
    
    local range = range or Olympus.Damage.SETTINGS.AOE_RANGE
    local minTargets = minTargets or Olympus.Damage.SETTINGS.MIN_AOE_TARGETS
    
    -- Update AoE state
    local targetCount = Olympus.Damage.UpdateAoEState(range)
    
    if targetCount >= minTargets then
        Debug.Info(Debug.CATEGORIES.DAMAGE, string.format(
            "Casting AoE spell %s on %d targets",
            spell.name or "Unknown",
            targetCount
        ))
        
        if spell.isAoE ~= nil then
            spell.isAoE = true
        end
        
        local result = Olympus.CastAction(spell)
        if result then
            Olympus.Damage.State.lastAoETime = os.clock()
        end
        Debug.TrackFunctionEnd("Olympus.Damage.HandleAoE")
        return result
    end
    
    Debug.Verbose(Debug.CATEGORIES.DAMAGE, "Not enough targets for AoE")
    Debug.TrackFunctionEnd("Olympus.Damage.HandleAoE")
    return false
end

-- Spell Selection System
Olympus.Damage.GetSpellByPriority = function(spellPriority)
    Debug.TrackFunctionStart("Olympus.Damage.GetSpellByPriority")
    
    for _, spell in ipairs(spellPriority) do
        if Player.level >= spell.level then
            Debug.Info(Debug.CATEGORIES.COMBAT, 
                string.format("Selected spell: %s (Level %d)", 
                    spell.name or "Unknown",
                    spell.level))
            Debug.TrackFunctionEnd("Olympus.Damage.GetSpellByPriority")
            return spell
        end
    end
    
    Debug.TrackFunctionEnd("Olympus.Damage.GetSpellByPriority")
    return nil
end

-- DoT Management Extensions
Olympus.Damage.ShouldRefreshDoT = function(target, dotBuffs)
    Debug.TrackFunctionStart("Olympus.Damage.ShouldRefreshDoT")
    
    if not target or not dotBuffs then 
        Debug.TrackFunctionEnd("Olympus.Damage.ShouldRefreshDoT")
        return false 
    end
    
    -- Check if target has any DoT
    for buffId, _ in pairs(dotBuffs) do
        if Olympus.Buff.HasBuff(target, buffId) then
            -- If we have a DoT, only refresh if duration is less than threshold
            local duration = Olympus.Buff.GetDuration(target, buffId)
            local shouldRefresh = duration <= Olympus.Damage.SETTINGS.DOT_REFRESH_THRESHOLD
            
            Debug.Info(Debug.CATEGORIES.DAMAGE, string.format(
                "DoT refresh check - Target: %s, BuffID: %d, Duration: %.1f, Should Refresh: %s",
                target.name or "Unknown",
                buffId,
                duration,
                tostring(shouldRefresh)
            ))
            
            Debug.TrackFunctionEnd("Olympus.Damage.ShouldRefreshDoT")
            return shouldRefresh
        end
    end
    
    -- If we get here, no DoTs are present, so we should apply one
    Debug.Info(Debug.CATEGORIES.DAMAGE, "No DoTs present, should apply")
    Debug.TrackFunctionEnd("Olympus.Damage.ShouldRefreshDoT")
    return true
end

-- MP Management Extensions
Olympus.MP.HandleMPSaver = function(spell, mpSaverSpell, mpThreshold)
    Debug.TrackFunctionStart("Olympus.MP.HandleMPSaver")
    
    if not spell or not mpSaverSpell then
        Debug.Verbose(Debug.CATEGORIES.COMBAT, "Missing required parameters for MP saver")
        Debug.TrackFunctionEnd("Olympus.MP.HandleMPSaver")
        return false
    end
    
    -- Skip if MP is healthy
    if Player.mp.percent > mpThreshold then
        Debug.Verbose(Debug.CATEGORIES.COMBAT, "MP healthy, saving MP saver ability")
        Debug.TrackFunctionEnd("Olympus.MP.HandleMPSaver")
        return false
    end
    
    -- Check if MP saver ability is ready
    if Olympus.Combat.IsReady(mpSaverSpell.id, mpSaverSpell) then
        Debug.Info(Debug.CATEGORIES.COMBAT, string.format(
            "Using %s for MP conservation before %s",
            mpSaverSpell.name or "MP saver",
            spell.name or "spell"
        ))
        return Olympus.CastAction(mpSaverSpell)
    end
    
    Debug.TrackFunctionEnd("Olympus.MP.HandleMPSaver")
    return false
end

-- Enhanced DoT Management
Olympus.Damage.HandleDoTSpell = function(target, dotSpell, dotBuffs)
    Debug.TrackFunctionStart("Olympus.Damage.HandleDoTSpell")
    
    if not target or not dotSpell or not dotBuffs then
        Debug.Verbose(Debug.CATEGORIES.DAMAGE, "Missing required parameters for DoT handling")
        Debug.TrackFunctionEnd("Olympus.Damage.HandleDoTSpell")
        return false
    end

    if not Olympus.Damage.ShouldRefreshDoT(target, dotBuffs) then
        Debug.Verbose(Debug.CATEGORIES.DAMAGE, "No DoT refresh needed")
        Debug.TrackFunctionEnd("Olympus.Damage.HandleDoTSpell")
        return false
    end

    -- Find the appropriate DoT buff ID for the spell
    local dotBuffId = nil
    for buffId, _ in pairs(dotBuffs) do
        dotBuffId = buffId
        break
    end

    if not dotBuffId then
        Debug.Verbose(Debug.CATEGORIES.DAMAGE, "No DoT buff ID found")
        Debug.TrackFunctionEnd("Olympus.Damage.HandleDoTSpell")
        return false
    end

    return Olympus.Damage.HandleDoTs(target, dotSpell, dotBuffId)
end

-- Enhanced Movement System
Olympus.Movement.HandleJobMovement = function(movementSpell, healingRange, hpThreshold, extendedRange)
    Debug.TrackFunctionStart("Olympus.Movement.HandleJobMovement")
    
    -- Skip if not available
    if not movementSpell or Player.level < movementSpell.level then
        Debug.Verbose(Debug.CATEGORIES.MOVEMENT, "Movement ability not available")
        Debug.TrackFunctionEnd("Olympus.Movement.HandleJobMovement")
        return false 
    end
    
    -- Skip if player is bound
    if Player.bound then
        Debug.Verbose(Debug.CATEGORIES.MOVEMENT, "Player is bound, cannot use movement ability")
        Debug.TrackFunctionEnd("Olympus.Movement.HandleJobMovement")
        return false 
    end

    -- Handle Sprint during movement
    if Player:IsMoving() then
        Debug.Verbose(Debug.CATEGORIES.MOVEMENT, "Player is moving, checking Sprint")
        if Olympus.Movement.HandleSprint() then 
            Debug.Info(Debug.CATEGORIES.MOVEMENT, "Sprint activated")
            Debug.TrackFunctionEnd("Olympus.Movement.HandleJobMovement")
            return true 
        end
    end

    -- Check for party members needing emergency movement
    local party = Olympus.GetParty(extendedRange or 45)
    if table.valid(party) then
        Debug.Verbose(Debug.CATEGORIES.MOVEMENT, "Checking party members for movement ability")
        for _, member in pairs(party) do
            if member.hp.percent <= (hpThreshold or 50) then
                return Olympus.Movement.HandleEmergencyMovement(
                    member, 
                    movementSpell, 
                    healingRange or Olympus.Movement.SETTINGS.DEFAULT_RANGE
                )
            end
        end
    else
        Debug.Verbose(Debug.CATEGORIES.MOVEMENT, "No valid party members in extended range")
    end

    Debug.Verbose(Debug.CATEGORIES.MOVEMENT, "No movement actions needed")
    Debug.TrackFunctionEnd("Olympus.Movement.HandleJobMovement")
    return false
end

-- Performance Metrics System
Olympus.Performance = Olympus.Performance or {}
Olympus.Performance.Metrics = {
    lastDrawTime = 0,
    lastUpdateTime = 0,
    frameCount = 0,
    metrics = {
        drawTime = 0,
        updateTime = 0,
        averageFrameTime = 0
    }
}

function Olympus.Performance.UpdateDrawMetrics(startTime)
    local metrics = Olympus.Performance.Metrics
    metrics.frameCount = metrics.frameCount + 1
    metrics.lastDrawTime = startTime
    
    local endTime = os.clock()
    metrics.metrics.drawTime = endTime - startTime
    metrics.metrics.averageFrameTime = 
        (metrics.metrics.averageFrameTime * (metrics.frameCount - 1) + 
        metrics.metrics.drawTime) / metrics.frameCount
end

function Olympus.Performance.UpdateUpdateMetrics(startTime)
    local metrics = Olympus.Performance.Metrics
    metrics.lastUpdateTime = startTime
    
    local endTime = os.clock()
    metrics.metrics.updateTime = endTime - startTime
end

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

-- Enhanced Damage System
Olympus.Damage.HandleDamageCycle = function(config)
    Debug.TrackFunctionStart("Olympus.Damage.HandleDamageCycle")
    
    -- Validate config
    if not config then
        Debug.Verbose(Debug.CATEGORIES.DAMAGE, "Missing damage cycle configuration")
        Debug.TrackFunctionEnd("Olympus.Damage.HandleDamageCycle")
        return false
    end

    -- Skip if in strict healing mode
    if config.strictHealing then
        Debug.Info(Debug.CATEGORIES.DAMAGE, "Strict healing mode - skipping damage")
        Debug.TrackFunctionEnd("Olympus.Damage.HandleDamageCycle")
        return false
    end
    
    -- MP conservation check
    if Player.mp.percent <= Olympus.MP.THRESHOLDS.EMERGENCY then
        if config.onMPConservation then config.onMPConservation() end
        Debug.Info(Debug.CATEGORIES.DAMAGE, "MP Conservation mode - skipping damage")
        Debug.TrackFunctionEnd("Olympus.Damage.HandleDamageCycle")
        return false
    end

    -- Get all valid targets in range
    local mainTarget = Olympus.Damage.FindTarget(config.dotBuffs, config.range or 25)
    if not mainTarget then
        Debug.Verbose(Debug.CATEGORIES.DAMAGE, "No valid targets in range")
        Debug.TrackFunctionEnd("Olympus.Damage.HandleDamageCycle")
        return false
    end
    
    -- Update state if callback provided
    if config.onTargetFound then config.onTargetFound(mainTarget) end
    
    -- First priority: Apply DoTs
    if config.handleDoTs and config.handleDoTs(mainTarget) then
        Debug.TrackFunctionEnd("Olympus.Damage.HandleDamageCycle")
        return true
    end
    
    -- Second priority: Handle AoE damage
    if config.handleAoE and config.handleAoE(mainTarget) then
        Debug.TrackFunctionEnd("Olympus.Damage.HandleDamageCycle")
        return true
    end
    
    -- Third priority: Single target damage
    if config.handleSingleTarget then
        local result = config.handleSingleTarget(mainTarget)
        Debug.TrackFunctionEnd("Olympus.Damage.HandleDamageCycle")
        return result
    end
    
    Debug.Verbose(Debug.CATEGORIES.DAMAGE, "No damage actions needed")
    Debug.TrackFunctionEnd("Olympus.Damage.HandleDamageCycle")
    return false
end

-- Enhanced AoE System
Olympus.Damage.HandleAoECycle = function(config)
    Debug.TrackFunctionStart("Olympus.Damage.HandleAoECycle")
    
    -- Validate config
    if not config or not config.spells or not config.minTargets then
        Debug.Verbose(Debug.CATEGORIES.DAMAGE, "Missing AoE cycle configuration")
        Debug.TrackFunctionEnd("Olympus.Damage.HandleAoECycle")
        return false
    end
    
    -- Update AoE state
    if config.updateState then config.updateState() end
    
    -- Check if we should use AoE
    if config.shouldUseAoE and not config.shouldUseAoE() then
        Debug.Verbose(Debug.CATEGORIES.DAMAGE, "AoE conditions not met")
        Debug.TrackFunctionEnd("Olympus.Damage.HandleAoECycle")
        return false
    end
    
    -- Try each AoE spell in priority order
    for _, spellConfig in ipairs(config.spells) do
        if Player.level >= spellConfig.spell.level then
            local result = Olympus.Damage.HandleAoE(
                spellConfig.spell,
                spellConfig.minTargets or config.minTargets,
                spellConfig.range or config.range
            )
            if result then
                Debug.TrackFunctionEnd("Olympus.Damage.HandleAoECycle")
                return true
            end
        end
    end
    
    Debug.TrackFunctionEnd("Olympus.Damage.HandleAoECycle")
    return false
end

-- Event Management System
Olympus.Event = Olympus.Event or {}
Olympus.Event.Handlers = {}

function Olympus.Event.RegisterHandler(eventName, handler, identifier)
    Debug.TrackFunctionStart("Olympus.Event.RegisterHandler")
    
    if not eventName or not handler then
        Debug.Error(Debug.CATEGORIES.SYSTEM, "Missing event name or handler")
        Debug.TrackFunctionEnd("Olympus.Event.RegisterHandler")
        return false
    end
    
    -- Store handler info
    Olympus.Event.Handlers[eventName] = Olympus.Event.Handlers[eventName] or {}
    Olympus.Event.Handlers[eventName][identifier or #Olympus.Event.Handlers[eventName] + 1] = handler
    
    -- Register with game system
    local success = xpcall(
        function()
            RegisterEventHandler(eventName, handler, identifier)
            Debug.Info(Debug.CATEGORIES.SYSTEM, string.format(
                "Registered event handler: %s (%s)",
                eventName,
                identifier or "anonymous"
            ))
            return true
        end,
        function(err)
            Debug.Error(Debug.CATEGORIES.SYSTEM, string.format(
                "Failed to register event handler: %s",
                tostring(err)
            ))
            return false
        end
    )
    
    Debug.TrackFunctionEnd("Olympus.Event.RegisterHandler")
    return success
end

function Olympus.Event.UnregisterHandler(eventName, identifier)
    Debug.TrackFunctionStart("Olympus.Event.UnregisterHandler")
    
    if not eventName or not Olympus.Event.Handlers[eventName] then
        Debug.Verbose(Debug.CATEGORIES.SYSTEM, "No handlers found for event")
        Debug.TrackFunctionEnd("Olympus.Event.UnregisterHandler")
        return false
    end
    
    local handler = Olympus.Event.Handlers[eventName][identifier]
    if not handler then
        Debug.Verbose(Debug.CATEGORIES.SYSTEM, "Handler not found")
        Debug.TrackFunctionEnd("Olympus.Event.UnregisterHandler")
        return false
    end
    
    -- Unregister from game system
    local success = xpcall(
        function()
            UnregisterEventHandler(eventName, handler)
            Olympus.Event.Handlers[eventName][identifier] = nil
            Debug.Info(Debug.CATEGORIES.SYSTEM, string.format(
                "Unregistered event handler: %s (%s)",
                eventName,
                identifier
            ))
            return true
        end,
        function(err)
            Debug.Error(Debug.CATEGORIES.SYSTEM, string.format(
                "Failed to unregister event handler: %s",
                tostring(err)
            ))
            return false
        end
    )
    
    Debug.TrackFunctionEnd("Olympus.Event.UnregisterHandler")
    return success
end

function Olympus.Event.UnregisterAllHandlers()
    Debug.TrackFunctionStart("Olympus.Event.UnregisterAllHandlers")
    
    local success = true
    for eventName, handlers in pairs(Olympus.Event.Handlers) do
        for identifier, _ in pairs(handlers) do
            if not Olympus.Event.UnregisterHandler(eventName, identifier) then
                success = false
            end
        end
    end
    
    Olympus.Event.Handlers = {}
    Debug.TrackFunctionEnd("Olympus.Event.UnregisterAllHandlers")
    return success
end

-- Settings Management System
Olympus.Settings = Olympus.Settings or {}

function Olympus.Settings.CreateSchema(schema)
    Debug.TrackFunctionStart("Olympus.Settings.CreateSchema")
    
    local settings = {}
    for key, definition in pairs(schema) do
        settings[key] = definition.default
    end
    
    Debug.Info(Debug.CATEGORIES.SYSTEM, "Created settings schema")
    Debug.TrackFunctionEnd("Olympus.Settings.CreateSchema")
    return settings
end

function Olympus.Settings.Validate(settings, schema)
    Debug.TrackFunctionStart("Olympus.Settings.Validate")
    
    if type(settings) ~= "table" then
        Debug.Error(Debug.CATEGORIES.SYSTEM, "Settings must be a table")
        Debug.TrackFunctionEnd("Olympus.Settings.Validate")
        return false
    end
    
    for key, definition in pairs(schema) do
        if settings[key] == nil then
            settings[key] = definition.default
        elseif type(settings[key]) ~= definition.type then
            Debug.Error(Debug.CATEGORIES.SYSTEM, string.format(
                "Invalid type for setting %s: expected %s, got %s",
                key,
                definition.type,
                type(settings[key])
            ))
            Debug.TrackFunctionEnd("Olympus.Settings.Validate")
            return false
        end
    end
    
    Debug.Info(Debug.CATEGORIES.SYSTEM, "Settings validated successfully")
    Debug.TrackFunctionEnd("Olympus.Settings.Validate")
    return true
end

-- Enhanced Spell Toggle System
Olympus.SpellToggles = {
    enabled = {},
    categories = {
        ["Damage"] = true,
        ["Healing"] = true,
        ["Buff"] = true,
        ["Utility"] = true,
        ["Movement"] = true,
        ["Mitigation"] = true
    }
}

function Olympus.SpellToggles.Initialize(spells)
    Debug.TrackFunctionStart("Olympus.SpellToggles.Initialize")
    
    for spellName, _ in pairs(spells) do
        Olympus.SpellToggles.enabled[spellName] = true
    end
    
    Debug.Info(Debug.CATEGORIES.SYSTEM, "Spell toggles initialized")
    Debug.TrackFunctionEnd("Olympus.SpellToggles.Initialize")
end

function Olympus.SpellToggles.IsEnabled(spellName)
    return Olympus.SpellToggles.enabled[spellName] ~= false
end

function Olympus.SpellToggles.Toggle(spellName, spellData)
    Debug.TrackFunctionStart("Olympus.SpellToggles.Toggle")
    
    if not spellData then
        Debug.Error(Debug.CATEGORIES.SYSTEM, string.format(
            "Attempted to toggle invalid spell: %s",
            tostring(spellName)
        ))
        Debug.TrackFunctionEnd("Olympus.SpellToggles.Toggle")
        return false
    end
    
    Olympus.SpellToggles.enabled[spellName] = not Olympus.SpellToggles.enabled[spellName]
    
    Debug.Info(Debug.CATEGORIES.SYSTEM, string.format(
        "Spell %s %s",
        spellName,
        Olympus.SpellToggles.enabled[spellName] and "enabled" or "disabled"
    ))
    
    Debug.TrackFunctionEnd("Olympus.SpellToggles.Toggle")
    return true
end

-- Combat Phase System
Olympus.Combat = Olympus.Combat or {}
Olympus.Combat.Phases = {
    NORMAL = "NORMAL",
    AOE = "AOE",
    EMERGENCY = "EMERGENCY",
    CONSERVATION = "CONSERVATION"
}

Olympus.Combat.State = {
    currentPhase = Olympus.Combat.Phases.NORMAL,
    lastCastTime = 0,
    lastTarget = nil,
    isAoEPhase = false,
    emergencyMode = false
}

function Olympus.Combat.DetectPhase(config)
    Debug.TrackFunctionStart("Olympus.Combat.DetectPhase")
    
    if not config then
        Debug.Error(Debug.CATEGORIES.COMBAT, "Missing phase detection configuration")
        Debug.TrackFunctionEnd("Olympus.Combat.DetectPhase")
        return Olympus.Combat.Phases.NORMAL
    end
    
    local party = Olympus.Party.ValidateParty(config.range)
    if not party then
        Debug.Verbose(Debug.CATEGORIES.COMBAT, "No valid party, defaulting to NORMAL phase")
        Debug.TrackFunctionEnd("Olympus.Combat.DetectPhase")
        return Olympus.Combat.Phases.NORMAL
    end
    
    -- Count party members below thresholds
    local membersNeedingAction, _, lowestValue = Olympus.Party.CountMembersBelowHP(
        party, 
        config.threshold or 80,
        config.range or 30
    )
    
    -- Update combat state
    Olympus.Combat.State.isAoEPhase = membersNeedingAction >= (config.aoeThreshold or 3)
    Olympus.Combat.State.emergencyMode = lowestValue <= (config.emergencyThreshold or 30)
    
    -- Determine phase based on conditions
    local phase = Olympus.Combat.Phases.NORMAL
    if Olympus.Combat.State.emergencyMode then
        phase = Olympus.Combat.Phases.EMERGENCY
    elseif Olympus.Combat.State.isAoEPhase then
        phase = Olympus.Combat.Phases.AOE
    elseif Player.mp.percent <= (config.mpThreshold or 30) then
        phase = Olympus.Combat.Phases.CONSERVATION
    end
    
    Debug.Info(Debug.CATEGORIES.COMBAT, string.format(
        "Combat phase detected: %s (AoE: %s, Emergency: %s)",
        phase,
        tostring(Olympus.Combat.State.isAoEPhase),
        tostring(Olympus.Combat.State.emergencyMode)
    ))
    
    Olympus.Combat.State.currentPhase = phase
    Debug.TrackFunctionEnd("Olympus.Combat.DetectPhase")
    return phase
end

-- Enhanced Performance Monitoring
Olympus.Performance = Olympus.Performance or {}
Olympus.Performance.Metrics = {
    castMetrics = {
        lastCastTime = 0,
        averageCastTime = 0,
        castCount = 0,
        successfulCasts = 0,
        failedCasts = 0,
        castHistory = {}
    },
    frameMetrics = {
        frameCount = 0,
        lastFrameTime = 0,
        averageFrameTime = 0,
        frameTimeHistory = {}
    },
    resourceMetrics = {
        memoryUsage = 0,
        peakMemoryUsage = 0,
        lastGarbageCollection = 0
    }
}

function Olympus.Performance.UpdateCastMetrics(castTime, wasSuccessful)
    Debug.TrackFunctionStart("Olympus.Performance.UpdateCastMetrics")
    
    local metrics = Olympus.Performance.Metrics.castMetrics
    metrics.castCount = metrics.castCount + 1
    metrics.lastCastTime = castTime
    
    if wasSuccessful then
        metrics.successfulCasts = metrics.successfulCasts + 1
    else
        metrics.failedCasts = metrics.failedCasts + 1
    end
    
    -- Keep a history of the last 100 casts
    table.insert(metrics.castHistory, {
        time = castTime,
        success = wasSuccessful
    })
    if #metrics.castHistory > 100 then
        table.remove(metrics.castHistory, 1)
    end
    
    -- Update average cast time
    local sum = 0
    for _, cast in ipairs(metrics.castHistory) do
        sum = sum + cast.time
    end
    metrics.averageCastTime = sum / #metrics.castHistory
    
    Debug.TrackFunctionEnd("Olympus.Performance.UpdateCastMetrics")
end

function Olympus.Performance.UpdateFrameMetrics(frameTime)
    Debug.TrackFunctionStart("Olympus.Performance.UpdateFrameMetrics")
    
    local metrics = Olympus.Performance.Metrics.frameMetrics
    metrics.frameCount = metrics.frameCount + 1
    metrics.lastFrameTime = frameTime
    
    -- Keep a history of the last 100 frame times
    table.insert(metrics.frameTimeHistory, frameTime)
    if #metrics.frameTimeHistory > 100 then
        table.remove(metrics.frameTimeHistory, 1)
    end
    
    -- Calculate running average
    local sum = 0
    for _, time in ipairs(metrics.frameTimeHistory) do
        sum = sum + time
    end
    metrics.averageFrameTime = sum / #metrics.frameTimeHistory
    
    Debug.TrackFunctionEnd("Olympus.Performance.UpdateFrameMetrics")
end

function Olympus.Performance.UpdateResourceMetrics()
    Debug.TrackFunctionStart("Olympus.Performance.UpdateResourceMetrics")
    
    local metrics = Olympus.Performance.Metrics.resourceMetrics
    local currentMemory = collectgarbage("count") * 1024 -- Convert KB to bytes
    
    metrics.memoryUsage = currentMemory
    metrics.peakMemoryUsage = math.max(metrics.peakMemoryUsage, currentMemory)
    
    -- Perform garbage collection if memory usage is too high
    if currentMemory > metrics.peakMemoryUsage * 0.9 then
        metrics.lastGarbageCollection = os.clock()
        collectgarbage("collect")
    end
    
    Debug.TrackFunctionEnd("Olympus.Performance.UpdateResourceMetrics")
end

function Olympus.Performance.GetMetrics()
    return Olympus.Performance.Metrics
end

function Olympus.Performance.ResetMetrics()
    Olympus.Performance.Metrics = {
        castMetrics = {
            lastCastTime = 0,
            averageCastTime = 0,
            castCount = 0,
            successfulCasts = 0,
            failedCasts = 0,
            castHistory = {}
        },
        frameMetrics = {
            frameCount = 0,
            lastFrameTime = 0,
            averageFrameTime = 0,
            frameTimeHistory = {}
        },
        resourceMetrics = {
            memoryUsage = 0,
            peakMemoryUsage = 0,
            lastGarbageCollection = 0
        }
    }
end

-- Module Registration System
Olympus.Modules = {
    registered = {},
    initialized = {}
}

function Olympus.RegisterModule(moduleName, moduleData)
    Debug.TrackFunctionStart("Olympus.RegisterModule")
    
    if not moduleData then
        Debug.Error(Debug.CATEGORIES.SYSTEM, string.format(
            "Invalid module data for %s",
            moduleName
        ))
        Debug.TrackFunctionEnd("Olympus.RegisterModule")
        return false
    end
    
    -- Register the module
    Olympus.Modules.registered[moduleName] = moduleData
    
    -- Initialize module state
    Olympus.State.ResetModuleState(moduleName)
    
    Debug.Info(Debug.CATEGORIES.SYSTEM, string.format(
        "Module %s registered successfully",
        moduleName
    ))
    
    Debug.TrackFunctionEnd("Olympus.RegisterModule")
    return true
end

function Olympus.InitializeModule(moduleName)
    Debug.TrackFunctionStart("Olympus.InitializeModule")
    
    local moduleData = Olympus.Modules.registered[moduleName]
    if not moduleData then
        Debug.Error(Debug.CATEGORIES.SYSTEM, string.format(
            "Module %s not registered",
            moduleName
        ))
        Debug.TrackFunctionEnd("Olympus.InitializeModule")
        return false
    end
    
    -- Initialize the module
    if type(moduleData.initialize) == "function" then
        local success, err = pcall(moduleData.initialize)
        if not success then
            Debug.Error(Debug.CATEGORIES.SYSTEM, string.format(
                "Failed to initialize module %s: %s",
                moduleName,
                tostring(err)
            ))
            Debug.TrackFunctionEnd("Olympus.InitializeModule")
            return false
        end
    end
    
    Olympus.Modules.initialized[moduleName] = true
    
    Debug.Info(Debug.CATEGORIES.SYSTEM, string.format(
        "Module %s initialized successfully",
        moduleName
    ))
    
    Debug.TrackFunctionEnd("Olympus.InitializeModule")
    return true
end

function Olympus.IsModuleRegistered(moduleName)
    return Olympus.Modules.registered[moduleName] ~= nil
end

function Olympus.IsModuleInitialized(moduleName)
    return Olympus.Modules.initialized[moduleName] == true
end

function Olympus.GetModuleData(moduleName)
    return Olympus.Modules.registered[moduleName]
end

-- Spell Category System
Olympus.SpellSystem = Olympus.SpellSystem or {}

function Olympus.SpellSystem.GetSpellsByCategory(spells, category)
    Debug.TrackFunctionStart("Olympus.SpellSystem.GetSpellsByCategory")
    
    local result = {}
    for spellName, spell in pairs(spells) do
        if spell.category == category then
            result[spellName] = spell
        end
    end
    
    Debug.TrackFunctionEnd("Olympus.SpellSystem.GetSpellsByCategory")
    return result
end

-- Enhanced State Management
Olympus.ACRState = {
    -- Default state schema that can be extended by ACRs
    DEFAULT_STATE = {
        strictMode = false,
        performanceMetrics = {
            lastCastTime = 0,
            averageCastTime = 0,
            castCount = 0
        }
    }
}

function Olympus.ACRState.Initialize(acrName, customState)
    Debug.TrackFunctionStart("Olympus.ACRState.Initialize")
    
    -- Merge custom state with default state
    local state = {}
    for k, v in pairs(Olympus.ACRState.DEFAULT_STATE) do
        state[k] = type(v) == "table" and table.deepcopy(v) or v
    end
    if customState then
        for k, v in pairs(customState) do
            state[k] = type(v) == "table" and table.deepcopy(v) or v
        end
    end
    
    -- Store in module state
    if not Olympus.State.modules[acrName] then
        Olympus.State.modules[acrName] = {}
    end
    Olympus.State.modules[acrName].state = state
    
    Debug.Info(Debug.CATEGORIES.SYSTEM, string.format(
        "Initialized state for ACR: %s",
        acrName
    ))
    
    Debug.TrackFunctionEnd("Olympus.ACRState.Initialize")
    return state
end

function Olympus.ACRState.Get(acrName)
    return Olympus.State.modules[acrName] and 
           Olympus.State.modules[acrName].state or 
           table.deepcopy(Olympus.ACRState.DEFAULT_STATE)
end

function Olympus.ACRState.Update(acrName, updates)
    Debug.TrackFunctionStart("Olympus.ACRState.Update")
    
    if not Olympus.State.modules[acrName] or 
       not Olympus.State.modules[acrName].state then
        Debug.Error(Debug.CATEGORIES.SYSTEM, string.format(
            "Cannot update state for uninitialized ACR: %s",
            acrName
        ))
        Debug.TrackFunctionEnd("Olympus.ACRState.Update")
        return false
    end
    
    local state = Olympus.State.modules[acrName].state
    for k, v in pairs(updates) do
        state[k] = v
    end
    
    Debug.TrackFunctionEnd("Olympus.ACRState.Update")
    return true
end

-- Standard Event Handlers
Olympus.EventHandlers = {
    registered = {}
}

function Olympus.EventHandlers.RegisterACR(acrName, handlers)
    Debug.TrackFunctionStart("Olympus.EventHandlers.RegisterACR")
    
    if not handlers then
        Debug.Error(Debug.CATEGORIES.SYSTEM, string.format(
            "No handlers provided for ACR: %s",
            acrName
        ))
        Debug.TrackFunctionEnd("Olympus.EventHandlers.RegisterACR")
        return false
    end
    
    -- Register standard event handlers
    local standardEvents = {
        ["Gameloop.Draw"] = function()
            if Olympus.State.IsModuleRunning(acrName) and handlers.onDraw then
                handlers.onDraw()
            end
        end,
        ["Gameloop.Update"] = function()
            if Olympus.State.IsModuleRunning(acrName) and handlers.onUpdate then
                handlers.onUpdate()
            end
        end
    }
    
    -- Store handlers for cleanup
    Olympus.EventHandlers.registered[acrName] = {}
    
    -- Register each handler
    for event, handler in pairs(standardEvents) do
        local identifier = string.format("%s.%s", acrName, event)
        if Olympus.Event.RegisterHandler(event, handler, identifier) then
            table.insert(Olympus.EventHandlers.registered[acrName], {
                event = event,
                identifier = identifier
            })
        end
    end
    
    Debug.Info(Debug.CATEGORIES.SYSTEM, string.format(
        "Registered event handlers for ACR: %s",
        acrName
    ))
    
    Debug.TrackFunctionEnd("Olympus.EventHandlers.RegisterACR")
    return true
end

function Olympus.EventHandlers.UnregisterACR(acrName)
    Debug.TrackFunctionStart("Olympus.EventHandlers.UnregisterACR")
    
    if not Olympus.EventHandlers.registered[acrName] then
        Debug.Verbose(Debug.CATEGORIES.SYSTEM, string.format(
            "No handlers registered for ACR: %s",
            acrName
        ))
        Debug.TrackFunctionEnd("Olympus.EventHandlers.UnregisterACR")
        return true
    end
    
    -- Unregister all handlers for this ACR
    for _, handler in ipairs(Olympus.EventHandlers.registered[acrName]) do
        Olympus.Event.UnregisterHandler(handler.event, handler.identifier)
    end
    
    Olympus.EventHandlers.registered[acrName] = nil
    
    Debug.Info(Debug.CATEGORIES.SYSTEM, string.format(
        "Unregistered event handlers for ACR: %s",
        acrName
    ))
    
    Debug.TrackFunctionEnd("Olympus.EventHandlers.UnregisterACR")
    return true
end

-- Healing System
Olympus.Healing = {
    -- Default settings that can be overridden by specific ACRs
    SETTINGS = {
        DEFAULT_RANGE = 30,     -- Default range for healing abilities
        MIN_TARGETS = 2,        -- Default minimum targets for AoE healing
        HP_THRESHOLD = 80,      -- Default HP threshold for healing
        GROUND_TARGET_DELAY = 0.5  -- Delay for ground targeted abilities
    }
}

-- Handle ground targeted healing spell
function Olympus.Healing.HandleGroundTargetedSpell(spell, party, hpThreshold, minTargets)
    Debug.TrackFunctionStart("Olympus.Healing.HandleGroundTargetedSpell")
    
    if not spell or not party then
        Debug.Verbose(Debug.CATEGORIES.HEALING, "Missing required parameters")
        Debug.TrackFunctionEnd("Olympus.Healing.HandleGroundTargetedSpell")
        return false
    end

    -- Check if enough party members need healing
    local membersNeedingHeal, _ = Olympus.Healing.HandleAoEHealCheck(party, hpThreshold, spell.range)
    
    Debug.Info(Debug.CATEGORIES.HEALING, string.format(
        "Ground heal check - Spell: %s, Members needing heal: %d, Required: %d",
        spell.name or "Unknown",
        membersNeedingHeal,
        minTargets or Olympus.Healing.SETTINGS.MIN_TARGETS
    ))

    if membersNeedingHeal >= (minTargets or Olympus.Healing.SETTINGS.MIN_TARGETS) then
        -- Calculate optimal ground target position
        local position = Olympus.Ground.CalculateOptimalPosition(party, hpThreshold)
        if not position then
            Debug.Warn(Debug.CATEGORIES.HEALING, "Failed to calculate ground target position")
            Debug.TrackFunctionEnd("Olympus.Healing.HandleGroundTargetedSpell")
            return false
        end

        -- Cast the ground targeted spell
        local success = Olympus.Ground.CastSpell(spell, position)
        Debug.TrackFunctionEnd("Olympus.Healing.HandleGroundTargetedSpell")
        return success
    end
    
    Debug.Verbose(Debug.CATEGORIES.HEALING, "Not enough targets for ground heal")
    Debug.TrackFunctionEnd("Olympus.Healing.HandleGroundTargetedSpell")
    return false
end

-- Check party members for AoE healing
function Olympus.Healing.HandleAoEHealCheck(party, hpThreshold, range)
    Debug.TrackFunctionStart("Olympus.Healing.HandleAoEHealCheck")
    
    if not party then
        Debug.Verbose(Debug.CATEGORIES.HEALING, "No valid party for AoE heal check")
        Debug.TrackFunctionEnd("Olympus.Healing.HandleAoEHealCheck")
        return 0, nil
    end

    local count = 0
    local lowestMember = nil
    local lowestHP = 100

    for _, member in pairs(party) do
        if member.hp.percent <= hpThreshold and member.distance2d <= (range or Olympus.Healing.SETTINGS.DEFAULT_RANGE) then
            count = count + 1
            if member.hp.percent < lowestHP then
                lowestHP = member.hp.percent
                lowestMember = member
            end
        end
    end

    Debug.Info(Debug.CATEGORIES.HEALING, string.format(
        "AoE heal check - Members below %.1f%%: %d (Lowest: %.1f%%)",
        hpThreshold,
        count,
        lowestHP
    ))

    Debug.TrackFunctionEnd("Olympus.Healing.HandleAoEHealCheck")
    return count, lowestMember
end

return Olympus