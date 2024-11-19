-- Apollo Healing Utilities

Apollo = Apollo or {}
Apollo.HealingUtils = {}

function Apollo.HealingUtils.ValidateParty(range)
    Debug.TrackFunctionStart("ValidateParty")
    local party = Olympus.GetParty(range or Apollo.Settings.HealingRange)
    if not table.valid(party) then 
        Debug.Verbose(Debug.CATEGORIES.HEALING, "No valid party members in range")
        Debug.TrackFunctionEnd("ValidateParty")
        return nil
    end
    Debug.TrackFunctionEnd("ValidateParty")
    return party
end

function Apollo.HealingUtils.HandleThinAir(spellId)
    if Apollo.ShouldUseThinAir(spellId) then
        return Olympus.CastAction(Apollo.SPELLS.THIN_AIR)
    end
    return false
end

function Apollo.HealingUtils.FindLowestHealthMember(party)
    Debug.TrackFunctionStart("FindLowestHealthMember")
    local lowestHP = 100
    local lowestMember = nil
    
    for _, member in pairs(party) do
        if member.hp.percent < lowestHP and member.distance2d <= Apollo.Settings.HealingRange then
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
