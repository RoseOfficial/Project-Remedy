-- Apollo AoE Healing

Apollo = Apollo or {}
Apollo.AoEHealing = {}

local function HandleStackHealing(party)
    if Player.level >= Apollo.SPELLS.CURE_III.level then
        local closeParty = Olympus.GetParty(10)
        local membersNeedingHeal, lowestMember = Olympus.HandleAoEHealCheck(closeParty, Apollo.Settings.CureIIIThreshold, 10)
        Debug.Info(Debug.CATEGORIES.HEALING, 
            string.format("Cure III check - Close members needing heal: %d", membersNeedingHeal))
        if membersNeedingHeal >= Apollo.Settings.CureIIIMinTargets and lowestMember then
            Apollo.HealingUtils.HandleThinAir(Apollo.SPELLS.CURE_III.id)
            Debug.Info(Debug.CATEGORIES.HEALING, 
                string.format("Cure III target found: %s", lowestMember.name or "Unknown"))
            Apollo.SPELLS.CURE_III.isAoE = true
            if Olympus.CastAction(Apollo.SPELLS.CURE_III, lowestMember.id) then return true end
        end
    end
    return false
end

local function HandleGroundTargetedHealing(party)
    -- Asylum
    if Player.level >= Apollo.SPELLS.ASYLUM.level then
        Debug.Verbose(Debug.CATEGORIES.HEALING, "Checking Asylum conditions")
        Apollo.SPELLS.ASYLUM.isAoE = true
        if Apollo.HandleGroundTargetedSpell(Apollo.SPELLS.ASYLUM, party, Apollo.Settings.AsylumThreshold, Apollo.Settings.AsylumMinTargets) then
            return true
        end
    end

    -- Liturgy of the Bell
    if Player.level >= Apollo.SPELLS.LITURGY_OF_THE_BELL.level then
        Debug.Verbose(Debug.CATEGORIES.HEALING, "Checking Liturgy conditions")
        Apollo.SPELLS.LITURGY_OF_THE_BELL.isAoE = true
        if Apollo.HandleGroundTargetedSpell(Apollo.SPELLS.LITURGY_OF_THE_BELL, party, Apollo.Settings.LiturgyThreshold, Apollo.Settings.LiturgyMinTargets) then
            return true
        end
    end
    
    return false
end

function Apollo.AoEHealing.Handle()
    Debug.TrackFunctionStart("Apollo.AoEHealing.Handle")
    
    local party = Apollo.HealingUtils.ValidateParty()
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
    if Player.level >= Apollo.SPELLS.PLENARY_INDULGENCE.level then
        local membersNeedingHeal, _ = Olympus.HandleAoEHealCheck(party, Apollo.Settings.PlenaryThreshold, Apollo.Settings.HealingRange)
        Debug.Info(Debug.CATEGORIES.HEALING, 
            string.format("Plenary check - Members needing heal: %d", membersNeedingHeal))
        if membersNeedingHeal >= 2 then
            Apollo.SPELLS.PLENARY_INDULGENCE.isAoE = true
            if Olympus.CastAction(Apollo.SPELLS.PLENARY_INDULGENCE) then 
                Debug.TrackFunctionEnd("Apollo.AoEHealing.Handle")
                return true 
            end
        end
    end

    -- Handle stack healing (Cure III)
    if HandleStackHealing(party) then
        Debug.TrackFunctionEnd("Apollo.AoEHealing.Handle")
        return true
    end

    -- Handle ground targeted healing (Asylum, Liturgy)
    if HandleGroundTargetedHealing(party) then
        Debug.TrackFunctionEnd("Apollo.AoEHealing.Handle")
        return true
    end

    -- Medica II and Medica
    local hasMedicaII = Olympus.HasBuff(Player, Apollo.BUFFS.MEDICA_II)
    local membersNeedingHeal, _ = Olympus.HandleAoEHealCheck(party, Apollo.Settings.CureThreshold, Apollo.SPELLS.MEDICA_II.range)
    
    Debug.Info(Debug.CATEGORIES.HEALING, 
        string.format("Medica check - Members needing heal: %d, Medica II active: %s", 
            membersNeedingHeal,
            tostring(hasMedicaII)))

    if membersNeedingHeal >= 3 then
        if not hasMedicaII and Player.level >= Apollo.SPELLS.MEDICA_II.level then
            Apollo.HealingUtils.HandleThinAir(Apollo.SPELLS.MEDICA_II.id)
            Debug.Info(Debug.CATEGORIES.HEALING, "Casting Medica II")
            Apollo.SPELLS.MEDICA_II.isAoE = true
            if Olympus.CastAction(Apollo.SPELLS.MEDICA_II) then 
                Debug.TrackFunctionEnd("Apollo.AoEHealing.Handle")
                return true 
            end
        elseif hasMedicaII and Player.level >= Apollo.SPELLS.MEDICA.level then
            Apollo.HealingUtils.HandleThinAir(Apollo.SPELLS.MEDICA.id)
            Debug.Info(Debug.CATEGORIES.HEALING, "Casting Medica")
            Apollo.SPELLS.MEDICA.isAoE = true
            if Olympus.CastAction(Apollo.SPELLS.MEDICA) then 
                Debug.TrackFunctionEnd("Apollo.AoEHealing.Handle")
                return true 
            end
        end
    end

    Debug.Verbose(Debug.CATEGORIES.HEALING, "No AoE healing needed")
    Debug.TrackFunctionEnd("Apollo.AoEHealing.Handle")
    return false
end
