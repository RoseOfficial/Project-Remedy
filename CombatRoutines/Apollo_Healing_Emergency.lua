Apollo.Healing.Emergency = {}

function Apollo.Healing.Emergency.Handle()
    Debug.TrackFunctionStart("Apollo.EmergencyHealing.Handle")
    
    local party = Apollo.Utilities.ValidateParty()
    if not party then 
        Debug.TrackFunctionEnd("Apollo.EmergencyHealing.Handle")
        return false 
    end

    -- Benediction
    if Player.level >= Apollo.Constants.SPELLS.BENEDICTION.level then
        Debug.Verbose(Debug.CATEGORIES.HEALING, "Checking for Benediction targets")
        for _, member in pairs(party) do
            if member.hp.percent <= Apollo.Constants.SETTINGS.BenedictionThreshold 
               and member.distance2d <= Apollo.Constants.SPELLS.BENEDICTION.range then
                Debug.Info(Debug.CATEGORIES.HEALING, 
                    string.format("Benediction target found: %s (HP: %.1f%%)", 
                        member.name or "Unknown",
                        member.hp.percent))
                Apollo.Constants.SPELLS.BENEDICTION.isAoE = false
                if Olympus.CastAction(Apollo.Constants.SPELLS.BENEDICTION, member.id) then 
                    Debug.TrackFunctionEnd("Apollo.EmergencyHealing.Handle")
                    return true 
                end
            end
        end
    end

    -- Tetragrammaton
    if Player.level >= Apollo.Constants.SPELLS.TETRAGRAMMATON.level then
        Debug.Verbose(Debug.CATEGORIES.HEALING, "Checking for Tetragrammaton targets")
        for _, member in pairs(party) do
            if member.hp.percent <= Apollo.Constants.SETTINGS.TetragrammatonThreshold 
               and member.distance2d <= Apollo.Constants.SPELLS.TETRAGRAMMATON.range then
                Debug.Info(Debug.CATEGORIES.HEALING, 
                    string.format("Tetragrammaton target found: %s (HP: %.1f%%)", 
                        member.name or "Unknown",
                        member.hp.percent))
                Apollo.Constants.SPELLS.TETRAGRAMMATON.isAoE = false
                if Olympus.CastAction(Apollo.Constants.SPELLS.TETRAGRAMMATON, member.id) then 
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
