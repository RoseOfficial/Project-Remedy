-- MP Management constants
Apollo.MP = {
    -- Phase-based thresholds
    THRESHOLDS = {
        LUCID = 80,         -- Lucid Dreaming usage threshold
        NORMAL = 30,        -- Normal phase threshold (emergency level)
        AOE = 40,          -- AoE intensive phase threshold
        EMERGENCY = 30,    -- Emergency threshold
        CRITICAL = 15      -- Critical threshold - strict conservation
    },
    
    -- Spell MP costs for Thin Air optimization
    EXPENSIVE_SPELLS = {
        [Apollo.SPELLS.CURE_III.id] = true,     -- 1500 MP
        [Apollo.SPELLS.MEDICA.id] = true,       -- 1000 MP
        [Apollo.SPELLS.MEDICA_II.id] = true,    -- 1000 MP
        [Apollo.SPELLS.CURE_II.id] = true       -- 1000 MP
    }
}

-- Detect current fight phase based on party state and recent spell usage
function Apollo.DetectFightPhase(party)
    Debug.TrackFunctionStart("Apollo.DetectFightPhase")
    
    if not table.valid(party) then
        Debug.Verbose(Debug.CATEGORIES.COMBAT, "No valid party, assuming normal phase")
        Debug.TrackFunctionEnd("Apollo.DetectFightPhase")
        return "NORMAL"
    end
    
    -- Count party members below AoE threshold
    local membersNeedingHeal = 0
    for _, member in pairs(party) do
        if member.hp.percent <= Apollo.Settings.CureThreshold then
            membersNeedingHeal = membersNeedingHeal + 1
        end
    end
    
    -- Detect AoE intensive phase
    if membersNeedingHeal >= 3 then
        Debug.Info(Debug.CATEGORIES.COMBAT, "Detected AoE intensive phase")
        Debug.TrackFunctionEnd("Apollo.DetectFightPhase")
        return "AOE"
    end
    
    -- Detect emergency phase
    local lowestHP = 100
    for _, member in pairs(party) do
        if member.hp.percent < lowestHP then
            lowestHP = member.hp.percent
        end
    end
    
    if lowestHP <= Apollo.Settings.BenedictionThreshold then
        Debug.Info(Debug.CATEGORIES.COMBAT, "Detected emergency phase")
        Debug.TrackFunctionEnd("Apollo.DetectFightPhase")
        return "EMERGENCY"
    end
    
    Debug.Verbose(Debug.CATEGORIES.COMBAT, "Normal combat phase")
    Debug.TrackFunctionEnd("Apollo.DetectFightPhase")
    return "NORMAL"
end

-- Get current MP threshold based on fight phase
function Apollo.GetMPThreshold()
    Debug.TrackFunctionStart("Apollo.GetMPThreshold")
    
    local party = Olympus.GetParty(Apollo.Settings.HealingRange)
    local phase = Apollo.DetectFightPhase(party)
    
    -- If MP is critically low, override phase threshold
    if Player.mp.percent <= Apollo.MP.THRESHOLDS.CRITICAL then
        Debug.Info(Debug.CATEGORIES.COMBAT, "MP critically low, using emergency threshold")
        Debug.TrackFunctionEnd("Apollo.GetMPThreshold")
        return Apollo.MP.THRESHOLDS.CRITICAL
    end
    
    local threshold = Apollo.MP.THRESHOLDS[phase] or Apollo.MP.THRESHOLDS.NORMAL
    Debug.Info(Debug.CATEGORIES.COMBAT, string.format("MP threshold for %s phase: %d", phase, threshold))
    
    Debug.TrackFunctionEnd("Apollo.GetMPThreshold")
    return threshold
end

-- Check if spell should use Thin Air
function Apollo.ShouldUseThinAir(spellId)
    Debug.TrackFunctionStart("Apollo.ShouldUseThinAir")
    
    -- Don't use Thin Air if MP is healthy
    if Player.mp.percent > Apollo.MP.THRESHOLDS.LUCID then
        Debug.Verbose(Debug.CATEGORIES.COMBAT, "MP healthy, saving Thin Air")
        Debug.TrackFunctionEnd("Apollo.ShouldUseThinAir")
        return false
    end
    
    -- Prioritize expensive spells
    if Apollo.MP.EXPENSIVE_SPELLS[spellId] then
        Debug.Info(Debug.CATEGORIES.COMBAT, "Using Thin Air for expensive spell")
        Debug.TrackFunctionEnd("Apollo.ShouldUseThinAir")
        return true
    end
    
    -- Emergency MP conservation
    if Player.mp.percent <= Apollo.MP.THRESHOLDS.EMERGENCY then
        Debug.Info(Debug.CATEGORIES.COMBAT, "Emergency MP conservation - using Thin Air")
        Debug.TrackFunctionEnd("Apollo.ShouldUseThinAir")
        return true
    end
    
    Debug.TrackFunctionEnd("Apollo.ShouldUseThinAir")
    return false
end

-- Handle MP conservation mode
function Apollo.HandleMPConservation()
    Debug.TrackFunctionStart("Apollo.HandleMPConservation")
    
    -- Handle Lucid Dreaming
    if Player.mp.percent <= Apollo.MP.THRESHOLDS.LUCID then
        Debug.Info(Debug.CATEGORIES.COMBAT, "MP below Lucid Dreaming threshold")
        if Olympus.HandleLucidDreaming(Apollo.MP.THRESHOLDS.LUCID) then
            Debug.TrackFunctionEnd("Apollo.HandleMPConservation")
            return true
        end
    end
    
    local currentThreshold = Apollo.GetMPThreshold()
    
    -- Check if we need to enter MP conservation mode
    if Player.mp.percent <= currentThreshold then
        Debug.Info(Debug.CATEGORIES.COMBAT, "Entering MP conservation mode")
        
        -- Use Thin Air if available
        if Player.level >= Apollo.SPELLS.THIN_AIR.level then
            local action = ActionList:Get(1, Apollo.SPELLS.THIN_AIR.id)
            if action and action:IsReady() then
                Debug.Info(Debug.CATEGORIES.COMBAT, "Using Thin Air for MP conservation")
                if Olympus.CastAction(Apollo.SPELLS.THIN_AIR) then
                    Debug.TrackFunctionEnd("Apollo.HandleMPConservation")
                    return true
                end
            end
        end
        
        -- Additional MP conservation logic
        if Player.mp.percent <= Apollo.MP.THRESHOLDS.CRITICAL then
            Debug.Info(Debug.CATEGORIES.COMBAT, "Critical MP - strict healing only")
            -- Set global flag for other functions to check
            Apollo.StrictHealing = true
        else
            Apollo.StrictHealing = false
        end
        
        Debug.TrackFunctionEnd("Apollo.HandleMPConservation")
        return true
    end
    
    Apollo.StrictHealing = false
    Debug.Verbose(Debug.CATEGORIES.COMBAT, "MP conservation not needed")
    Debug.TrackFunctionEnd("Apollo.HandleMPConservation")
    return false
end
