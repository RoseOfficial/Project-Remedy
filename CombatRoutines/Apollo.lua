-- Apollo
Apollo = {}
Apollo.Core = {}

Apollo.classes = {
    [FFXIV.JOBS.WHITEMAGE] = true,
    [FFXIV.JOBS.CONJURER] = true,
}

---------------------------------------------------------------------------------------------------
-- Main Cast Priority System
---------------------------------------------------------------------------------------------------

function Apollo.Cast()
    -- MP Management (highest priority to prevent resource depletion)
    if Apollo.MP.HandleMPConservation() then 
        Olympus.IsFrameBudgetExceeded()
        return true 
    end

    -- Recovery and utility
    if Olympus.HandleSwiftcast() then 
        Olympus.IsFrameBudgetExceeded()
        return true 
    end
    if Olympus.HandleSurecast() then 
        Olympus.IsFrameBudgetExceeded()
        return true
    end
    if Olympus.HandleRescue() then 
        Olympus.IsFrameBudgetExceeded()
        return true 
    end
    if Olympus.HandleEsuna(Apollo.Constants.SETTINGS.HealingRange) then 
        Olympus.IsFrameBudgetExceeded()
        return true 
    end
    if Olympus.HandleRaise(Apollo.Constants.SETTINGS.HealingRange) then 
        Olympus.IsFrameBudgetExceeded()
        return true 
    end

    -- Core rotation with optimized priority
    if Apollo.Movement.Handle() then 
        Olympus.IsFrameBudgetExceeded()
        return true 
    end
    if Apollo.Healing.Emergency.Handle() then 
        Olympus.IsFrameBudgetExceeded()
        return true 
    end -- High priority for emergency response
    if Apollo.Buffs.Handle() then 
        Olympus.IsFrameBudgetExceeded()
        return true 
    end
    if Apollo.Healing.Mitigation.Handle() then 
        Olympus.IsFrameBudgetExceeded()
        return true 
    end -- Proactive mitigation
    if Apollo.Healing.Lily.Handle() then 
        Olympus.IsFrameBudgetExceeded()
        return true 
    end -- Free healing resource
    
    -- Only handle non-essential healing if not in emergency MP state
    if Player.mp.percent > Apollo.MP.THRESHOLDS.EMERGENCY then
        if Apollo.Healing.AoE.Handle() then 
            Olympus.IsFrameBudgetExceeded()
            return true 
        end
        if Apollo.Healing.SingleTarget.Handle() then 
            Olympus.IsFrameBudgetExceeded()
            return true 
        end
    else
        -- In emergency, only handle critical healing
        if Apollo.StrictHealing then
            local party = Olympus.GetParty(Apollo.Constants.SETTINGS.HealingRange)
            if table.valid(party) then
                for _, member in pairs(party) do
                    if member.hp.percent <= Apollo.Constants.SETTINGS.BenedictionThreshold then
                        if Apollo.Healing.AoE.Handle() then 
                            Olympus.IsFrameBudgetExceeded()
                            return true 
                        end
                        if Apollo.Healing.SingleTarget.Handle() then 
                            Olympus.IsFrameBudgetExceeded()
                            return true 
                        end
                        break
                    end
                end
            end
        end
    end
    
    -- Handle damage (continue until emergency threshold)
    if Player.mp.percent > Apollo.MP.THRESHOLDS.EMERGENCY then
        if Apollo.Damage.Handle() then 
            Olympus.IsFrameBudgetExceeded()
            return true 
        end
    end

    -- Check frame budget before final return
    Olympus.IsFrameBudgetExceeded()
    return false
end

return Apollo
