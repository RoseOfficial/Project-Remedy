Apollo.Damage = {}

function Apollo.Damage.Handle()
    Debug.TrackFunctionStart("Apollo.HandleDamage")
    
    -- Assize (AoE damage + healing)
    if Player.level >= Apollo.Constants.SPELLS.ASSIZE.level then
        Debug.Verbose(Debug.CATEGORIES.DAMAGE, "Checking Assize conditions")
        
        local party = Olympus.GetParty(Apollo.Constants.SPELLS.ASSIZE.range)
        local membersNeedingHeal, _ = Olympus.HandleAoEHealCheck(party, Apollo.Constants.SETTINGS.CureThreshold, Apollo.Constants.SPELLS.ASSIZE.range)

        local enemies = EntityList("alive,attackable,incombat,maxdistance=" .. Apollo.Constants.SPELLS.ASSIZE.range)
        local enemyCount = table.valid(enemies) and table.size(enemies) or 0

        Debug.Info(Debug.CATEGORIES.DAMAGE, 
            string.format("Assize check - Healing targets: %d, Enemy count: %d", 
                membersNeedingHeal, 
                enemyCount))

        -- Use Assize more aggressively since it's both damage and healing
        if (membersNeedingHeal + enemyCount) >= Apollo.Constants.SETTINGS.AssizeMinTargets then
            Debug.Info(Debug.CATEGORIES.DAMAGE, "Attempting to cast Assize")
            if Olympus.CastAction(Apollo.Constants.SPELLS.ASSIZE) then 
                Debug.TrackFunctionEnd("Apollo.HandleDamage")
                return true 
            end
        else
            Debug.Verbose(Debug.CATEGORIES.DAMAGE, "Not enough targets for Assize")
        end
    end

    -- DoT application
    local dotTarget = Olympus.FindTargetForDoT(Apollo.DOT_BUFFS, 25, 3)
    if dotTarget then
        Debug.Info(Debug.CATEGORIES.DAMAGE, 
            string.format("Found DoT target: %s (ID: %d)", 
                dotTarget.name or "Unknown",
                dotTarget.id))
        if Olympus.CastAction(Apollo.Utilities.GetDoTSpell(), dotTarget.id) then 
            Debug.TrackFunctionEnd("Apollo.HandleDamage")
            return true 
        end
    else
        Debug.Verbose(Debug.CATEGORIES.DAMAGE, "No valid DoT targets found")
    end

    -- Holy/Holy III for AoE damage
    if Player.level >= Apollo.Constants.SPELLS.HOLY.level then
        local enemies = EntityList("alive,attackable,incombat,maxdistance=" .. Apollo.Constants.SPELLS.HOLY.range)
        local enemyCount = table.valid(enemies) and table.size(enemies) or 0
        
        Debug.Info(Debug.CATEGORIES.DAMAGE, 
            string.format("AoE check - Enemy count: %d, Required: %d", 
                enemyCount, 
                Apollo.Constants.SETTINGS.HolyMinTargets))
                
        if enemyCount >= Apollo.Constants.SETTINGS.HolyMinTargets then
            if Player.level >= Apollo.Constants.SPELLS.HOLY_III.level then
                Debug.Info(Debug.CATEGORIES.DAMAGE, "Attempting to cast Holy III")
                if Olympus.CastAction(Apollo.Constants.SPELLS.HOLY_III) then 
                    Debug.TrackFunctionEnd("Apollo.HandleDamage")
                    return true 
                end
            else
                Debug.Info(Debug.CATEGORIES.DAMAGE, "Attempting to cast Holy")
                if Olympus.CastAction(Apollo.Constants.SPELLS.HOLY) then 
                    Debug.TrackFunctionEnd("Apollo.HandleDamage")
                    return true 
                end
            end
        else
            Debug.Verbose(Debug.CATEGORIES.DAMAGE, "Not enough targets for AoE")
        end
    end

    -- Single target damage
    local damageTarget = Olympus.FindTargetForDamage(Apollo.DOT_BUFFS, 25)
    if damageTarget then
        Debug.Info(Debug.CATEGORIES.DAMAGE, 
            string.format("Found damage target: %s (ID: %d)", 
                damageTarget.name or "Unknown",
                damageTarget.id))
        if Olympus.CastAction(Apollo.Utilities.GetDamageSpell(), damageTarget.id) then 
            Debug.TrackFunctionEnd("Apollo.HandleDamage")
            return true 
        end
    else
        Debug.Verbose(Debug.CATEGORIES.DAMAGE, "No valid damage targets found")
    end

    Debug.Verbose(Debug.CATEGORIES.DAMAGE, "No damage actions taken")
    Debug.TrackFunctionEnd("Apollo.HandleDamage")
    return false
end
