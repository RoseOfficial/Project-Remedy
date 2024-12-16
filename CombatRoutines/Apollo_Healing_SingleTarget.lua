Apollo.Healing.SingleTarget = {}

function Apollo.Healing.SingleTarget.HandleRegen(member, memberHP)
    if not Apollo.StrictHealing and Player.level >= Apollo.Constants.SPELLS.REGEN.level 
       and memberHP <= Apollo.Constants.SETTINGS.RegenThreshold
       and not Olympus.HasBuff(member, Apollo.Constants.BUFFS.REGEN) then
        if member.role == "TANK" or memberHP <= (Apollo.Constants.SETTINGS.RegenThreshold - 10) then
            Debug.Info(Debug.CATEGORIES.HEALING, "Applying Regen")
            Apollo.Constants.SPELLS.REGEN.isAoE = false
            return Olympus.CastAction(Apollo.Constants.SPELLS.REGEN, member.id)
        end
    end
    return false
end

function Apollo.Healing.SingleTarget.HandleCureSpells(member, memberHP)
    -- Cure II (primary single target heal)
    if memberHP <= Apollo.Constants.SETTINGS.CureIIThreshold and Player.level >= Apollo.Constants.SPELLS.CURE_II.level then
        Apollo.Utilities.HandleThinAir(Apollo.Constants.SPELLS.CURE_II.id)
        Debug.Info(Debug.CATEGORIES.HEALING, "Casting Cure II")
        Apollo.Constants.SPELLS.CURE_II.isAoE = false
        if Olympus.CastAction(Apollo.Constants.SPELLS.CURE_II, member.id) then return true end
    end

    -- Cure (only use at low levels or when MP constrained)
    if (Player.level < Apollo.Constants.SPELLS.CURE_II.level or Player.mp.percent < Apollo.Constants.SETTINGS.MPThreshold) 
    and memberHP <= Apollo.Constants.SETTINGS.CureThreshold then
        -- Use Cure II if Freecure proc is active
        if Olympus.HasBuff(Player, Apollo.Constants.BUFFS.FREECURE) and Player.level >= Apollo.Constants.SPELLS.CURE_II.level then
            Debug.Info(Debug.CATEGORIES.HEALING, "Casting Cure II (Freecure)")
            Apollo.Constants.SPELLS.CURE_II.isAoE = false
            if Olympus.CastAction(Apollo.Constants.SPELLS.CURE_II, member.id) then return true end
        else
            Debug.Info(Debug.CATEGORIES.HEALING, "Casting Cure")
            Apollo.Constants.SPELLS.CURE.isAoE = false
            if Olympus.CastAction(Apollo.Constants.SPELLS.CURE, member.id) then return true end
        end
    end
    
    return false
end

function Apollo.Healing.SingleTarget.Handle()
    Debug.TrackFunctionStart("Apollo.SingleTargetHealing.Handle")
    
    local party = Apollo.Utilities.ValidateParty()
    if not party then 
        Debug.TrackFunctionEnd("Apollo.SingleTargetHealing.Handle")
        return false 
    end

    local lowestMember, lowestHP = Apollo.Utilities.FindLowestHealthMember(party)
    if lowestMember then
        -- Handle Regen
        if Apollo.Healing.SingleTarget.HandleRegen(lowestMember, lowestHP) then
            Debug.TrackFunctionEnd("Apollo.SingleTargetHealing.Handle")
            return true
        end

        -- Handle Cure spells
        if Apollo.Healing.SingleTarget.HandleCureSpells(lowestMember, lowestHP) then
            Debug.TrackFunctionEnd("Apollo.SingleTargetHealing.Handle")
            return true
        end
    else
        Debug.Verbose(Debug.CATEGORIES.HEALING, "No healing targets found")
    end

    Debug.TrackFunctionEnd("Apollo.SingleTargetHealing.Handle")
    return false
end
