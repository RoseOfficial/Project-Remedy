Apollo.Healing.AoE = {}

function Apollo.Healing.AoE.HandleStackHealing(party)
    if Player.level >= Apollo.Constants.SPELLS.CURE_III.level then
        local closeParty = Olympus.GetParty(10)
        local membersNeedingHeal, lowestMember = Olympus.HandleAoEHealCheck(closeParty, Apollo.Constants.SETTINGS.CureIIIThreshold, 10)
        Debug.Info(Debug.CATEGORIES.HEALING, 
            string.format("Cure III check - Close members needing heal: %d", membersNeedingHeal))
        if membersNeedingHeal >= Apollo.Constants.SETTINGS.CureIIIMinTargets and lowestMember then
            Apollo.Healing.Utils.HandleThinAir(Apollo.Constants.SPELLS.CURE_III.id)
            Debug.Info(Debug.CATEGORIES.HEALING, 
                string.format("Cure III target found: %s", lowestMember.name or "Unknown"))
            Apollo.Constants.SPELLS.CURE_III.isAoE = true
            if Olympus.CastAction(Apollo.Constants.SPELLS.CURE_III, lowestMember.id) then return true end
        end
    end
    return false
end

function Apollo.Healing.AoE.HandleGroundTargetedHealing(party)
    -- Asylum
    if Player.level >= Apollo.Constants.SPELLS.ASYLUM.level then
        Debug.Verbose(Debug.CATEGORIES.HEALING, "Checking Asylum conditions")
        Apollo.Constants.SPELLS.ASYLUM.isAoE = true
        if Apollo.Utilities.HandleGroundTargetedSpell(Apollo.Constants.SPELLS.ASYLUM, party, Apollo.Constants.SETTINGS.AsylumThreshold, Apollo.Constants.SETTINGS.AsylumMinTargets) then
            return true
        end
    end

    -- Liturgy of the Bell
    if Player.level >= Apollo.Constants.SPELLS.LITURGY_OF_THE_BELL.level then
        Debug.Verbose(Debug.CATEGORIES.HEALING, "Checking Liturgy conditions")
        Apollo.Constants.SPELLS.LITURGY_OF_THE_BELL.isAoE = true
        if Apollo.Utilities.HandleGroundTargetedSpell(Apollo.Constants.SPELLS.LITURGY_OF_THE_BELL, party, Apollo.Constants.SETTINGS.LiturgyThreshold, Apollo.Constants.SETTINGS.LiturgyMinTargets) then
            return true
        end
    end
    
    return false
end

function Apollo.Healing.AoE.Handle()
    Debug.TrackFunctionStart("Apollo.AoEHealing.Handle")
    
    local party = Apollo.Utilities.ValidateParty()
    if not party then 
        Debug.TrackFunctionEnd("Apollo.AoEHealing.Handle")
        return false 
    end

    -- Skip non-essential AoE healing in strict healing mode
    if Apollo.StrictHealing then
        Debug.Info(Debug.CATEGORIES.HEALING, "Strict healing mode - skipping non-essential AoE healing")
        Debug.TrackFunctionEnd("Apollo.AoEHealing.Handle")
        return false
    end

    -- Plenary Indulgence
    if Player.level >= Apollo.Constants.SPELLS.PLENARY_INDULGENCE.level then
        local membersNeedingHeal, _ = Olympus.HandleAoEHealCheck(party, Apollo.Constants.SETTINGS.PlenaryThreshold, Apollo.Constants.SETTINGS.HealingRange)
        Debug.Info(Debug.CATEGORIES.HEALING, 
            string.format("Plenary check - Members needing heal: %d", membersNeedingHeal))
        if membersNeedingHeal >= 2 then
            Apollo.Constants.SPELLS.PLENARY_INDULGENCE.isAoE = true
            if Olympus.CastAction(Apollo.Constants.SPELLS.PLENARY_INDULGENCE) then 
                Debug.TrackFunctionEnd("Apollo.AoEHealing.Handle")
                return true 
            end
        end
    end

    -- Handle stack healing (Cure III)
    if Apollo.Healing.AoE.HandleStackHealing(party) then
        Debug.TrackFunctionEnd("Apollo.AoEHealing.Handle")
        return true
    end

    -- Handle ground targeted healing (Asylum, Liturgy)
    if Apollo.Healing.AoE.HandleGroundTargetedHealing(party) then
        Debug.TrackFunctionEnd("Apollo.AoEHealing.Handle")
        return true
    end

    -- Medica II and Medica
    local hasMedicaII = Olympus.HasBuff(Player, Apollo.Constants.BUFFS.MEDICA_II)
    local membersNeedingHeal, _ = Olympus.HandleAoEHealCheck(party, Apollo.Constants.SETTINGS.CureThreshold, Apollo.Constants.SPELLS.MEDICA_II.range)
    
    Debug.Info(Debug.CATEGORIES.HEALING, 
        string.format("Medica check - Members needing heal: %d, Medica II active: %s", 
            membersNeedingHeal,
            tostring(hasMedicaII)))

    if membersNeedingHeal >= 3 then
        if not hasMedicaII and Player.level >= Apollo.Constants.SPELLS.MEDICA_II.level then
            Apollo.HealingUtils.HandleThinAir(Apollo.Constants.SPELLS.MEDICA_II.id)
            Debug.Info(Debug.CATEGORIES.HEALING, "Casting Medica II")
            Apollo.Constants.SPELLS.MEDICA_II.isAoE = true
            if Olympus.CastAction(Apollo.Constants.SPELLS.MEDICA_II) then 
                Debug.TrackFunctionEnd("Apollo.AoEHealing.Handle")
                return true 
            end
        elseif hasMedicaII and Player.level >= Apollo.Constants.SPELLS.MEDICA.level then
            Apollo.HealingUtils.HandleThinAir(Apollo.Constants.SPELLS.MEDICA.id)
            Debug.Info(Debug.CATEGORIES.HEALING, "Casting Medica")
            Apollo.Constants.SPELLS.MEDICA.isAoE = true
            if Olympus.CastAction(Apollo.Constants.SPELLS.MEDICA) then 
                Debug.TrackFunctionEnd("Apollo.AoEHealing.Handle")
                return true 
            end
        end
    end

    Debug.Verbose(Debug.CATEGORIES.HEALING, "No AoE healing needed")
    Debug.TrackFunctionEnd("Apollo.AoEHealing.Handle")
    return false
end
