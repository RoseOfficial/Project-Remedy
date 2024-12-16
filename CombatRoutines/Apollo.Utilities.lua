Apollo.Utilities = {}

-- DoT buff IDs for tracking
Apollo.Utilities.DOT_BUFFS = {
    [143] = true,  -- Aero
    [144] = true,  -- Aero II
    [1871] = true  -- Dia
}

-- Party validation functions
function Apollo.Utilities.ValidateParty(range)
    Debug.TrackFunctionStart("ValidateParty")
    local party = Olympus.GetParty(range or Apollo.Constants.SETTINGS.HealingRange)
    if not table.valid(party) then 
        Debug.Verbose(Debug.CATEGORIES.HEALING, "No valid party members in range")
        Debug.TrackFunctionEnd("ValidateParty")
        return nil
    end
    Debug.TrackFunctionEnd("ValidateParty")
    return party
end

function Apollo.Utilities.FindLowestHealthMember(party)
    Debug.TrackFunctionStart("FindLowestHealthMember")
    local lowestHP = 100
    local lowestMember = nil
    
    for _, member in pairs(party) do
        if member.hp.percent < lowestHP and member.distance2d <= Apollo.Constants.SETTINGS.HealingRange then
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
    
    Debug.TrackFunctionEnd("FindLowestHealthMember")
    return lowestMember, lowestHP
end

-- Spell selection functions
function Apollo.Utilities.GetDamageSpell()
    Debug.TrackFunctionStart("Apollo.GetDamageSpell")
    
    local spells = { 
        Apollo.Constants.SPELLS.GLARE_III, 
        Apollo.Constants.SPELLS.GLARE, 
        Apollo.Constants.SPELLS.STONE_IV, 
        Apollo.Constants.SPELLS.STONE_III, 
        Apollo.Constants.SPELLS.STONE_II, 
        Apollo.Constants.SPELLS.STONE 
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

function Apollo.Utilities.GetDoTSpell()
    Debug.TrackFunctionStart("Apollo.GetDoTSpell")
    
    local spells = { 
        Apollo.Constants.SPELLS.DIA, 
        Apollo.Constants.SPELLS.AERO_II, 
        Apollo.Constants.SPELLS.AERO 
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

-- Spell casting utility functions
function Apollo.Utilities.HandleThinAir(spellId)
    if Apollo.MP.ShouldUseThinAir(spellId) then
        return Olympus.CastAction(Apollo.Constants.SPELLS.THIN_AIR)
    end
    return false
end

function Apollo.Utilities.HandleGroundTargetedSpell(spell, party, hpThreshold, minTargets)
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
