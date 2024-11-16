Apollo.HandleLilySystem = function()
    Debug.TrackFunctionStart("Apollo.HandleLilySystem")
    
    -- Afflatus Misery (Blood Lily)
    if Player.level >= Apollo.SPELLS.AFFLATUS_MISERY.level then
        local bloodLilyStacks = Player.gauge[3]
        Debug.Info(Debug.CATEGORIES.COMBAT, 
            string.format("Blood Lily stacks: %d", bloodLilyStacks))
            
        if bloodLilyStacks >= 3 and Player.incombat then
            Debug.Info(Debug.CATEGORIES.COMBAT, "Blood Lily ready, looking for target")
            local target = Olympus.FindTargetForDamage(Apollo.DOT_BUFFS, Apollo.SPELLS.AFFLATUS_MISERY.range)
            if target then
                Debug.Info(Debug.CATEGORIES.COMBAT, 
                    string.format("Casting Afflatus Misery on %s", 
                        target.name or "Unknown"))
                if Olympus.CastAction(Apollo.SPELLS.AFFLATUS_MISERY, target.id) then 
                    Debug.TrackFunctionEnd("Apollo.HandleLilySystem")
                    return true 
                end
            else
                Debug.Verbose(Debug.CATEGORIES.COMBAT, "No valid target for Afflatus Misery")
            end
        end
    end

    -- Afflatus Rapture (AoE Lily)
    if Player.level >= Apollo.SPELLS.AFFLATUS_RAPTURE.level then
        local lilyStacks = Player.gauge[2]
        Debug.Info(Debug.CATEGORIES.HEALING, 
            string.format("Lily stacks: %d", lilyStacks))
            
        if lilyStacks >= 1 then
            local party = Olympus.GetParty(Apollo.SPELLS.AFFLATUS_RAPTURE.range)
            local membersNeedingHeal, _ = Olympus.HandleAoEHealCheck(party, Apollo.Settings.CureThreshold, Apollo.SPELLS.AFFLATUS_RAPTURE.range)
            
            Debug.Info(Debug.CATEGORIES.HEALING, 
                string.format("Afflatus Rapture check - Members needing heal: %d", 
                    membersNeedingHeal))
                    
            if membersNeedingHeal >= 3 then
                Debug.Info(Debug.CATEGORIES.HEALING, "Casting Afflatus Rapture")
                if Olympus.CastAction(Apollo.SPELLS.AFFLATUS_RAPTURE) then 
                    Debug.TrackFunctionEnd("Apollo.HandleLilySystem")
                    return true 
                end
            end
        end
    end

    -- Afflatus Solace (Single Target Lily)
    if Player.level >= Apollo.SPELLS.AFFLATUS_SOLACE.level then
        local lilyStacks = Player.gauge[2]
        if lilyStacks >= 1 then
            Debug.Verbose(Debug.CATEGORIES.HEALING, "Checking for Afflatus Solace targets")
            
            local party = Olympus.GetParty(Apollo.Settings.HealingRange)
            if table.valid(party) then
                local lowestHP = 100
                local lowestMember = nil
                for _, member in pairs(party) do
                    if member.hp.percent < lowestHP and member.distance2d <= Apollo.SPELLS.AFFLATUS_SOLACE.range then
                        lowestHP = member.hp.percent
                        lowestMember = member
                    end
                end
                
                -- Prioritize Afflatus Solace over Cure II when lilies are available
                if lowestMember and lowestHP <= Apollo.Settings.CureIIThreshold then
                    Debug.Info(Debug.CATEGORIES.HEALING, 
                        string.format("Casting Afflatus Solace on %s (HP: %.1f%%)", 
                            lowestMember.name or "Unknown",
                            lowestHP))
                    if Olympus.CastAction(Apollo.SPELLS.AFFLATUS_SOLACE, lowestMember.id) then 
                        Debug.TrackFunctionEnd("Apollo.HandleLilySystem")
                        return true 
                    end
                else
                    Debug.Verbose(Debug.CATEGORIES.HEALING, "No suitable target for Afflatus Solace")
                end
            else
                Debug.Verbose(Debug.CATEGORIES.HEALING, "No valid party members in range")
            end
        else
            Debug.Verbose(Debug.CATEGORIES.HEALING, "No lily stacks available")
        end
    end

    Debug.Verbose(Debug.CATEGORIES.HEALING, "No lily actions needed")
    Debug.TrackFunctionEnd("Apollo.HandleLilySystem")
    return false
end
