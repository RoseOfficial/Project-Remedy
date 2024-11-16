-- DoT buff IDs for tracking
Apollo.DOT_BUFFS = {
    [143] = true,  -- Aero
    [144] = true,  -- Aero II
    [1871] = true  -- Dia
}

-- Get highest level damage spell available
Apollo.GetDamageSpell = function()
    Debug.TrackFunctionStart("Apollo.GetDamageSpell")
    
    local spells = { 
        Apollo.SPELLS.GLARE_III, 
        Apollo.SPELLS.GLARE, 
        Apollo.SPELLS.STONE_IV, 
        Apollo.SPELLS.STONE_III, 
        Apollo.SPELLS.STONE_II, 
        Apollo.SPELLS.STONE 
    }
    
    Debug.Verbose(Debug.CATEGORIES.COMBAT, "Getting highest level damage spell")
    local spell = Olympus.GetHighestLevelSpell(spells)
    
    Debug.Info(Debug.CATEGORIES.COMBAT, 
        string.format("Selected damage spell: %s (Level %d)", 
            spell.name or "Unknown",
            spell.level))
            
    Debug.TrackFunctionEnd("Apollo.GetDamageSpell")
    return spell
end

-- Get highest level DoT spell available
Apollo.GetDoTSpell = function()
    Debug.TrackFunctionStart("Apollo.GetDoTSpell")
    
    local spells = { 
        Apollo.SPELLS.DIA, 
        Apollo.SPELLS.AERO_II, 
        Apollo.SPELLS.AERO 
    }
    
    Debug.Verbose(Debug.CATEGORIES.COMBAT, "Getting highest level DoT spell")
    local spell = Olympus.GetHighestLevelSpell(spells)
    
    Debug.Info(Debug.CATEGORIES.COMBAT, 
        string.format("Selected DoT spell: %s (Level %d)", 
            spell.name or "Unknown",
            spell.level))
            
    Debug.TrackFunctionEnd("Apollo.GetDoTSpell")
    return spell
end

-- Handle ground-targeted AoE spell placement
Apollo.HandleGroundTargetedSpell = function(spell, party, hpThreshold, minTargets)
    Debug.TrackFunctionStart("Apollo.HandleGroundTargetedSpell")
    
    local membersNeedingHeal, _ = Olympus.HandleAoEHealCheck(party, hpThreshold, spell.range)
    
    Debug.Info(Debug.CATEGORIES.HEALING, 
        string.format("Ground AoE check - Spell: %s, Members needing heal: %d, Required: %d", 
            spell.name or "Unknown",
            membersNeedingHeal,
            minTargets))

    if membersNeedingHeal >= minTargets then
        local centerX, centerZ = 0, 0
        local memberCount = 0

        for _, member in pairs(party) do
            if member.hp.percent <= hpThreshold then
                centerX = centerX + member.pos.x
                centerZ = centerZ + member.pos.z
                memberCount = memberCount + 1
            end
        end

        centerX = centerX / memberCount
        centerZ = centerZ / memberCount

        Debug.Info(Debug.CATEGORIES.HEALING, 
            string.format("Calculated AoE center position: X=%.2f, Z=%.2f", 
                centerX, 
                centerZ))

        local action = ActionList:Get(1, spell.id)
        if action and action:IsReady() then
            Debug.Info(Debug.CATEGORIES.HEALING, 
                string.format("Casting %s at calculated position", 
                    spell.name or "Unknown"))
            local result = action:Cast(centerX, Player.pos.y, centerZ)
            Debug.TrackFunctionEnd("Apollo.HandleGroundTargetedSpell")
            return result
        else
            Debug.Warn(Debug.CATEGORIES.HEALING, "Action not ready or invalid")
        end
    else
        Debug.Verbose(Debug.CATEGORIES.HEALING, "Not enough targets for ground AoE")
    end
    
    Debug.TrackFunctionEnd("Apollo.HandleGroundTargetedSpell")
    return false
end
