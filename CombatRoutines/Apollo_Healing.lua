-- Emergency Healing
function Apollo.HandleEmergencyHealing()
    Debug.TrackFunctionStart("Apollo.HandleEmergencyHealing")
    
    local party = Olympus.GetParty(Apollo.Settings.HealingRange)
    if not table.valid(party) then 
        Debug.Verbose(Debug.CATEGORIES.HEALING, "No valid party members in range")
        Debug.TrackFunctionEnd("Apollo.HandleEmergencyHealing")
        return false 
    end

    -- Benediction (free healing, always use in emergencies)
    if Player.level >= Apollo.SPELLS.BENEDICTION.level then
        Debug.Verbose(Debug.CATEGORIES.HEALING, "Checking for Benediction targets")
        for _, member in pairs(party) do
            if member.hp.percent <= Apollo.Settings.BenedictionThreshold 
               and member.distance2d <= Apollo.SPELLS.BENEDICTION.range then
                Debug.Info(Debug.CATEGORIES.HEALING, 
                    string.format("Benediction target found: %s (HP: %.1f%%)", 
                        member.name or "Unknown",
                        member.hp.percent))
                Apollo.SPELLS.BENEDICTION.isAoE = false
                if Olympus.CastAction(Apollo.SPELLS.BENEDICTION, member.id) then 
                    Debug.TrackFunctionEnd("Apollo.HandleEmergencyHealing")
                    return true 
                end
            end
        end
    end

    -- Tetragrammaton (free healing)
    if Player.level >= Apollo.SPELLS.TETRAGRAMMATON.level then
        Debug.Verbose(Debug.CATEGORIES.HEALING, "Checking for Tetragrammaton targets")
        for _, member in pairs(party) do
            if member.hp.percent <= Apollo.Settings.TetragrammatonThreshold 
               and member.distance2d <= Apollo.SPELLS.TETRAGRAMMATON.range then
                Debug.Info(Debug.CATEGORIES.HEALING, 
                    string.format("Tetragrammaton target found: %s (HP: %.1f%%)", 
                        member.name or "Unknown",
                        member.hp.percent))
                Apollo.SPELLS.TETRAGRAMMATON.isAoE = false
                if Olympus.CastAction(Apollo.SPELLS.TETRAGRAMMATON, member.id) then 
                    Debug.TrackFunctionEnd("Apollo.HandleEmergencyHealing")
                    return true 
                end
            end
        end
    end

    Debug.Verbose(Debug.CATEGORIES.HEALING, "No emergency healing needed")
    Debug.TrackFunctionEnd("Apollo.HandleEmergencyHealing")
    return false
end

-- Mitigation
function Apollo.HandleMitigation()
    Debug.TrackFunctionStart("Apollo.HandleMitigation")
    
    if not Player.incombat then 
        Debug.Verbose(Debug.CATEGORIES.HEALING, "Not in combat, skipping mitigation")
        Debug.TrackFunctionEnd("Apollo.HandleMitigation")
        return false 
    end

    local party = Olympus.GetParty(Apollo.Settings.HealingRange)
    if not table.valid(party) then 
        Debug.Verbose(Debug.CATEGORIES.HEALING, "No valid party members in range")
        Debug.TrackFunctionEnd("Apollo.HandleMitigation")
        return false 
    end

    -- Skip non-essential mitigation in strict healing mode
    if Apollo.StrictHealing then
        Debug.Info(Debug.CATEGORIES.HEALING, "Strict healing mode - skipping non-essential mitigation")
        Debug.TrackFunctionEnd("Apollo.HandleMitigation")
        return false
    end

    -- Temperance
    if Player.level >= Apollo.SPELLS.TEMPERANCE.level then
        local membersNeedingHeal, _ = Olympus.HandleAoEHealCheck(party, Apollo.Settings.TemperanceThreshold, Apollo.Settings.HealingRange)
        Debug.Info(Debug.CATEGORIES.HEALING, 
            string.format("Temperance check - Members needing heal: %d", membersNeedingHeal))
        if membersNeedingHeal >= 2 then
            Apollo.SPELLS.TEMPERANCE.isAoE = true
            if Olympus.CastAction(Apollo.SPELLS.TEMPERANCE) then 
                Debug.TrackFunctionEnd("Apollo.HandleMitigation")
                return true 
            end
        end
    end

    -- Aquaveil (prioritize tanks)
    if Player.level >= Apollo.SPELLS.AQUAVEIL.level then
        Debug.Verbose(Debug.CATEGORIES.HEALING, "Checking for Aquaveil targets")
        for _, member in pairs(party) do
            if member.hp.percent <= Apollo.Settings.AquaveilThreshold 
               and member.distance2d <= Apollo.SPELLS.AQUAVEIL.range
               and not Olympus.HasBuff(member, Apollo.BUFFS.AQUAVEIL)
               and member.role == "TANK" then
                Debug.Info(Debug.CATEGORIES.HEALING, 
                    string.format("Aquaveil target found: %s (Tank, HP: %.1f%%)", 
                        member.name or "Unknown",
                        member.hp.percent))
                Apollo.SPELLS.AQUAVEIL.isAoE = false
                if Olympus.CastAction(Apollo.SPELLS.AQUAVEIL, member.id) then 
                    Debug.TrackFunctionEnd("Apollo.HandleMitigation")
                    return true 
                end
            end
        end
    end

    -- Divine Benison (prioritize tanks)
    if Player.level >= Apollo.SPELLS.DIVINE_BENISON.level then
        Debug.Verbose(Debug.CATEGORIES.HEALING, "Checking for Divine Benison targets")
        for _, member in pairs(party) do
            if member.hp.percent <= Apollo.Settings.BenisonThreshold 
               and member.distance2d <= Apollo.SPELLS.DIVINE_BENISON.range
               and not Olympus.HasBuff(member, Apollo.BUFFS.DIVINE_BENISON)
               and member.role == "TANK" then
                Debug.Info(Debug.CATEGORIES.HEALING, 
                    string.format("Divine Benison target found: %s (Tank, HP: %.1f%%)", 
                        member.name or "Unknown",
                        member.hp.percent))
                Apollo.SPELLS.DIVINE_BENISON.isAoE = false
                if Olympus.CastAction(Apollo.SPELLS.DIVINE_BENISON, member.id) then 
                    Debug.TrackFunctionEnd("Apollo.HandleMitigation")
                    return true 
                end
            end
        end
    end

    Debug.Verbose(Debug.CATEGORIES.HEALING, "No mitigation needed")
    Debug.TrackFunctionEnd("Apollo.HandleMitigation")
    return false
end

-- AoE Healing
function Apollo.HandleAoEHealing()
    Debug.TrackFunctionStart("Apollo.HandleAoEHealing")
    
    local party = Olympus.GetParty(Apollo.Settings.HealingRange)
    if not table.valid(party) then 
        Debug.Verbose(Debug.CATEGORIES.HEALING, "No valid party members in range")
        Debug.TrackFunctionEnd("Apollo.HandleAoEHealing")
        return false 
    end

    -- Skip non-essential AoE healing in strict healing mode
    if Apollo.StrictHealing then
        Debug.Info(Debug.CATEGORIES.HEALING, "Strict healing mode - skipping non-essential AoE healing")
        Debug.TrackFunctionEnd("Apollo.HandleAoEHealing")
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
                Debug.TrackFunctionEnd("Apollo.HandleAoEHealing")
                return true 
            end
        end
    end

    -- Cure III for stack healing
    if Player.level >= Apollo.SPELLS.CURE_III.level then
        local closeParty = Olympus.GetParty(10)
        local membersNeedingHeal, lowestMember = Olympus.HandleAoEHealCheck(closeParty, Apollo.Settings.CureIIIThreshold, 10)
        Debug.Info(Debug.CATEGORIES.HEALING, 
            string.format("Cure III check - Close members needing heal: %d", membersNeedingHeal))
        if membersNeedingHeal >= Apollo.Settings.CureIIIMinTargets and lowestMember then
            -- Use Thin Air for Cure III if appropriate
            if Apollo.ShouldUseThinAir(Apollo.SPELLS.CURE_III.id) then
                Olympus.CastAction(Apollo.SPELLS.THIN_AIR)
            end
            Debug.Info(Debug.CATEGORIES.HEALING, 
                string.format("Cure III target found: %s", lowestMember.name or "Unknown"))
            Apollo.SPELLS.CURE_III.isAoE = true
            if Olympus.CastAction(Apollo.SPELLS.CURE_III, lowestMember.id) then 
                Debug.TrackFunctionEnd("Apollo.HandleAoEHealing")
                return true 
            end
        end
    end

    -- Asylum
    if Player.level >= Apollo.SPELLS.ASYLUM.level then
        Debug.Verbose(Debug.CATEGORIES.HEALING, "Checking Asylum conditions")
        Apollo.SPELLS.ASYLUM.isAoE = true
        if Apollo.HandleGroundTargetedSpell(Apollo.SPELLS.ASYLUM, party, Apollo.Settings.AsylumThreshold, Apollo.Settings.AsylumMinTargets) then
            Debug.TrackFunctionEnd("Apollo.HandleAoEHealing")
            return true
        end
    end

    -- Liturgy of the Bell
    if Player.level >= Apollo.SPELLS.LITURGY_OF_THE_BELL.level then
        Debug.Verbose(Debug.CATEGORIES.HEALING, "Checking Liturgy conditions")
        Apollo.SPELLS.LITURGY_OF_THE_BELL.isAoE = true
        if Apollo.HandleGroundTargetedSpell(Apollo.SPELLS.LITURGY_OF_THE_BELL, party, Apollo.Settings.LiturgyThreshold, Apollo.Settings.LiturgyMinTargets) then
            Debug.TrackFunctionEnd("Apollo.HandleAoEHealing")
            return true
        end
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
            -- Use Thin Air for Medica II if appropriate
            if Apollo.ShouldUseThinAir(Apollo.SPELLS.MEDICA_II.id) then
                Olympus.CastAction(Apollo.SPELLS.THIN_AIR)
            end
            Debug.Info(Debug.CATEGORIES.HEALING, "Casting Medica II")
            Apollo.SPELLS.MEDICA_II.isAoE = true
            if Olympus.CastAction(Apollo.SPELLS.MEDICA_II) then 
                Debug.TrackFunctionEnd("Apollo.HandleAoEHealing")
                return true 
            end
        elseif hasMedicaII and Player.level >= Apollo.SPELLS.MEDICA.level then
            -- Use Thin Air for Medica if appropriate
            if Apollo.ShouldUseThinAir(Apollo.SPELLS.MEDICA.id) then
                Olympus.CastAction(Apollo.SPELLS.THIN_AIR)
            end
            Debug.Info(Debug.CATEGORIES.HEALING, "Casting Medica")
            Apollo.SPELLS.MEDICA.isAoE = true
            if Olympus.CastAction(Apollo.SPELLS.MEDICA) then 
                Debug.TrackFunctionEnd("Apollo.HandleAoEHealing")
                return true 
            end
        end
    end

    Debug.Verbose(Debug.CATEGORIES.HEALING, "No AoE healing needed")
    Debug.TrackFunctionEnd("Apollo.HandleAoEHealing")
    return false
end

-- Single Target Healing
function Apollo.HandleSingleTargetHealing()
    Debug.TrackFunctionStart("Apollo.HandleSingleTargetHealing")
    
    local party = Olympus.GetParty(Apollo.Settings.HealingRange)
    if not table.valid(party) then 
        Debug.Verbose(Debug.CATEGORIES.HEALING, "No valid party members in range")
        Debug.TrackFunctionEnd("Apollo.HandleSingleTargetHealing")
        return false 
    end

    -- Find lowest HP party member
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

        -- Regen (prioritize tanks)
        if not Apollo.StrictHealing and Player.level >= Apollo.SPELLS.REGEN.level 
           and lowestHP <= Apollo.Settings.RegenThreshold
           and not Olympus.HasBuff(lowestMember, Apollo.BUFFS.REGEN) then
            if lowestMember.role == "TANK" or lowestHP <= (Apollo.Settings.RegenThreshold - 10) then
                Debug.Info(Debug.CATEGORIES.HEALING, "Applying Regen")
                Apollo.SPELLS.REGEN.isAoE = false
                if Olympus.CastAction(Apollo.SPELLS.REGEN, lowestMember.id) then 
                    Debug.TrackFunctionEnd("Apollo.HandleSingleTargetHealing")
                    return true 
                end
            end
        end

        -- Cure II (primary single target heal)
        if lowestHP <= Apollo.Settings.CureIIThreshold and Player.level >= Apollo.SPELLS.CURE_II.level then
            -- Use Thin Air for Cure II if appropriate
            if Apollo.ShouldUseThinAir(Apollo.SPELLS.CURE_II.id) then
                Olympus.CastAction(Apollo.SPELLS.THIN_AIR)
            end
            Debug.Info(Debug.CATEGORIES.HEALING, "Casting Cure II")
            Apollo.SPELLS.CURE_II.isAoE = false
            if Olympus.CastAction(Apollo.SPELLS.CURE_II, lowestMember.id) then 
                Debug.TrackFunctionEnd("Apollo.HandleSingleTargetHealing")
                return true 
            end
        end

        -- Cure (only use at low levels or when MP constrained)
        if (Player.level < Apollo.SPELLS.CURE_II.level or Player.mp.percent < Apollo.MP.THRESHOLDS.EMERGENCY) 
           and lowestHP <= Apollo.Settings.CureThreshold then
            -- Use Cure II if Freecure proc is active
            if Olympus.HasBuff(Player, Apollo.BUFFS.FREECURE) and Player.level >= Apollo.SPELLS.CURE_II.level then
                Debug.Info(Debug.CATEGORIES.HEALING, "Casting Cure II (Freecure)")
                Apollo.SPELLS.CURE_II.isAoE = false
                if Olympus.CastAction(Apollo.SPELLS.CURE_II, lowestMember.id) then 
                    Debug.TrackFunctionEnd("Apollo.HandleSingleTargetHealing")
                    return true 
                end
            else
                Debug.Info(Debug.CATEGORIES.HEALING, "Casting Cure")
                Apollo.SPELLS.CURE.isAoE = false
                if Olympus.CastAction(Apollo.SPELLS.CURE, lowestMember.id) then 
                    Debug.TrackFunctionEnd("Apollo.HandleSingleTargetHealing")
                    return true 
                end
            end
        end
    else
        Debug.Verbose(Debug.CATEGORIES.HEALING, "No healing targets found")
    end

    Debug.TrackFunctionEnd("Apollo.HandleSingleTargetHealing")
    return false
end
