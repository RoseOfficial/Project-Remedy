Apollo.Healing.Mitigation = {}

function Apollo.Healing.Mitigation.HandleTankMitigation(party)
    -- Aquaveil
    if Player.level >= Apollo.Constants.SPELLS.AQUAVEIL.level then
        Debug.Verbose(Debug.CATEGORIES.HEALING, "Checking for Aquaveil targets")
        for _, member in pairs(party) do
            if member.hp.percent <= Apollo.Constants.SETTINGS.AquaveilThreshold 
               and member.distance2d <= Apollo.Constants.SPELLS.AQUAVEIL.range
               and not Olympus.HasBuff(member, Apollo.Constants.BUFFS.AQUAVEIL)
               and member.role == "TANK" then
                Debug.Info(Debug.CATEGORIES.HEALING, 
                    string.format("Aquaveil target found: %s (Tank, HP: %.1f%%)", 
                        member.name or "Unknown",
                        member.hp.percent))
                Apollo.Constants.SPELLS.AQUAVEIL.isAoE = false
                if Olympus.CastAction(Apollo.Constants.SPELLS.AQUAVEIL, member.id) then return true end
            end
        end
    end

    -- Divine Benison
    if Player.level >= Apollo.Constants.SPELLS.DIVINE_BENISON.level then
        Debug.Verbose(Debug.CATEGORIES.HEALING, "Checking for Divine Benison targets")
        for _, member in pairs(party) do
            if member.hp.percent <= Apollo.Constants.SETTINGS.BenisonThreshold 
               and member.distance2d <= Apollo.Constants.SPELLS.DIVINE_BENISON.range
               and not Olympus.HasBuff(member, Apollo.Constants.BUFFS.DIVINE_BENISON)
               and member.role == "TANK" then
                Debug.Info(Debug.CATEGORIES.HEALING, 
                    string.format("Divine Benison target found: %s (Tank, HP: %.1f%%)", 
                        member.name or "Unknown",
                        member.hp.percent))
                Apollo.Constants.SPELLS.DIVINE_BENISON.isAoE = false
                if Olympus.CastAction(Apollo.Constants.SPELLS.DIVINE_BENISON, member.id) then return true end
            end
        end
    end
    
    return false
end

function Apollo.Healing.Mitigation.Handle()
    Debug.TrackFunctionStart("Apollo.Mitigation.Handle")
    
    if not Player.incombat then 
        Debug.Verbose(Debug.CATEGORIES.HEALING, "Not in combat, skipping mitigation")
        Debug.TrackFunctionEnd("Apollo.Mitigation.Handle")
        return false 
    end

    local party = Apollo.Utilities.ValidateParty()
    if not party then 
        Debug.TrackFunctionEnd("Apollo.Mitigation.Handle")
        return false 
    end

    -- Skip non-essential mitigation in strict healing mode
    if Apollo.StrictHealing then
        Debug.Info(Debug.CATEGORIES.HEALING, "Strict healing mode - skipping non-essential mitigation")
        Debug.TrackFunctionEnd("Apollo.Mitigation.Handle")
        return false
    end

    -- Temperance
    if Player.level >= Apollo.Constants.SPELLS.TEMPERANCE.level then
        local membersNeedingHeal, _ = Olympus.HandleAoEHealCheck(party, Apollo.Constants.SETTINGS.TemperanceThreshold, Apollo.Constants.SETTINGS.HealingRange)
        Debug.Info(Debug.CATEGORIES.HEALING, 
            string.format("Temperance check - Members needing heal: %d", membersNeedingHeal))
        if membersNeedingHeal >= 2 then
            Apollo.Constants.SPELLS.TEMPERANCE.isAoE = true
            if Olympus.CastAction(Apollo.Constants.SPELLS.TEMPERANCE) then 
                Debug.TrackFunctionEnd("Apollo.Mitigation.Handle")
                return true 
            end
        end
    end

    -- Handle tank-specific mitigation
    if Apollo.Healing.Mitigation.HandleTankMitigation(party) then
        Debug.TrackFunctionEnd("Apollo.Mitigation.Handle")
        return true
    end

    Debug.Verbose(Debug.CATEGORIES.HEALING, "No mitigation needed")
    Debug.TrackFunctionEnd("Apollo.Mitigation.Handle")
    return false
end
