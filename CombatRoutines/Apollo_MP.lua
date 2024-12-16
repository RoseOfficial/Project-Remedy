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
        [Apollo.Constants.SPELLS.CURE_III.id] = true,     -- 1500 MP
        [Apollo.Constants.SPELLS.MEDICA.id] = true,       -- 1000 MP
        [Apollo.Constants.SPELLS.MEDICA_II.id] = true,    -- 1000 MP
        [Apollo.Constants.SPELLS.CURE_II.id] = true       -- 1000 MP
    }
}

-- Detect current fight phase based on party state and recent spell usage
function Apollo.MP.DetectFightPhase(party)
    Debug.TrackFunctionStart("Apollo.DetectFightPhase")
    
    if not table.valid(party) then
        Debug.Verbose(Debug.CATEGORIES.COMBAT, "No valid party, assuming normal phase")
        Debug.TrackFunctionEnd("Apollo.DetectFightPhase")
        return "NORMAL"
    end
    
    -- Count party members below AoE threshold
    local membersNeedingHeal = 0
    for _, member in pairs(party) do
        if member.hp.percent <= Apollo.Constants.SETTINGS.CureThreshold then
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
    
    if lowestHP <= Apollo.Constants.SETTINGS.BenedictionThreshold then
        Debug.Info(Debug.CATEGORIES.COMBAT, "Detected emergency phase")
        Debug.TrackFunctionEnd("Apollo.DetectFightPhase")
        return "EMERGENCY"
    end
    
    Debug.Verbose(Debug.CATEGORIES.COMBAT, "Normal combat phase")
    Debug.TrackFunctionEnd("Apollo.DetectFightPhase")
    return "NORMAL"
end

-- Get current MP threshold based on fight phase
function Apollo.MP.GetMPThreshold()
    Debug.TrackFunctionStart("Apollo.GetMPThreshold")
    
    local party = Olympus.GetParty(Apollo.Constants.SETTINGS.HealingRange)
    local phase = Apollo.MP.DetectFightPhase(party)
    
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
function Apollo.MP.ShouldUseThinAir(spellId)
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
function Apollo.MP.HandleMPConservation()
    Debug.TrackFunctionStart("Apollo.HandleMPConservation")

    -- Check if we're below Lucid threshold and it's available
    if Player.mp.percent <= Apollo.MP.THRESHOLDS.LUCID then
        local lucidDreaming = Apollo.Constants.SPELLS.LUCID_DREAMING
        
        Debug.Info(Debug.CATEGORIES.COMBAT, string.format(
            "Checking Lucid - MP: %d%%, Spell Ready: %s, Spell Enabled: %s",
            Player.mp.percent,
            tostring(Olympus.IsReady(lucidDreaming.id, lucidDreaming)),
            tostring(Apollo.IsSpellEnabled("LUCID_DREAMING"))
        ))

        if Apollo.IsSpellEnabled("LUCID_DREAMING") and Olympus.IsReady(lucidDreaming.id, lucidDreaming) then
            return Olympus.CastAction(lucidDreaming)
        end
    end
    
    Debug.TrackFunctionEnd("Apollo.HandleMPConservation")
    return false
end