--[[
    Apoll - White Mage (WHM) Advanced Combat Routine for MMOMinion
    
    This module provides combat routines for White Mage and Conjurer jobs in FFXIV.
    Features:
    - Dynamic MP management based on fight phase
    - Smart Thin Air usage for expensive spells
    - Emergency MP conservation mode
    - Comprehensive healing and damage systems
    - Proactive mitigation and buff management
    - Optimized movement and positioning
]]

Apollo = {}

Apollo.classes = {
    [FFXIV.JOBS.WHITEMAGE] = true,
    [FFXIV.JOBS.CONJURER] = true,
}

---------------------------------------------------------------------------------------------------
-- Main Cast Priority System
---------------------------------------------------------------------------------------------------

function Apollo.Cast()
    -- Start performance tracking for this frame
    Olympus.StartFrameTimeTracking()

    -- Initialize dungeon system if needed
    --[[if not Apollo.dungeonInitialized then
        Apollo.Dungeons.Initialize()
        Apollo.dungeonInitialized = true
    end]]--

    -- Update and check dungeon mechanics first
    if Olympus.Dungeons.UpdateState() then
        if Olympus.Dungeons.CheckMechanics() then
            -- Handle active mechanic movement
            local safePos = Olympus.Dungeons.GetSafePosition()
            if safePos then
                Player:MoveTo(safePos.x, safePos.y, safePos.z)
                -- Check frame budget before returning
                Olympus.IsFrameBudgetExceeded()
                return true
            end
        end
    end
    
    -- MP Management (highest priority to prevent resource depletion)
    if Apollo.HandleMPConservation() then 
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
    if Olympus.HandleEsuna(Apollo.Settings.HealingRange) then 
        Olympus.IsFrameBudgetExceeded()
        return true 
    end
    if Olympus.HandleRaise(Apollo.Settings.HealingRange) then 
        Olympus.IsFrameBudgetExceeded()
        return true 
    end

    -- Core rotation with optimized priority
    if Apollo.HandleMovement() then 
        Olympus.IsFrameBudgetExceeded()
        return true 
    end
    if Apollo.HandleEmergencyHealing() then 
        Olympus.IsFrameBudgetExceeded()
        return true 
    end -- High priority for emergency response
    if Apollo.HandleBuffs() then 
        Olympus.IsFrameBudgetExceeded()
        return true 
    end
    if Apollo.HandleMitigation() then 
        Olympus.IsFrameBudgetExceeded()
        return true 
    end -- Proactive mitigation
    if Apollo.HandleLilySystem() then 
        Olympus.IsFrameBudgetExceeded()
        return true 
    end -- Free healing resource
    
    -- Only handle non-essential healing if not in emergency MP state
    if Player.mp.percent > Apollo.MP.THRESHOLDS.EMERGENCY then
        if Apollo.HandleAoEHealing() then 
            Olympus.IsFrameBudgetExceeded()
            return true 
        end
        if Apollo.HandleSingleTargetHealing() then 
            Olympus.IsFrameBudgetExceeded()
            return true 
        end
    else
        -- In emergency, only handle critical healing
        if Apollo.StrictHealing then
            local party = Olympus.GetParty(Apollo.Settings.HealingRange)
            if table.valid(party) then
                for _, member in pairs(party) do
                    if member.hp.percent <= Apollo.Settings.BenedictionThreshold then
                        if Apollo.HandleAoEHealing() then 
                            Olympus.IsFrameBudgetExceeded()
                            return true 
                        end
                        if Apollo.HandleSingleTargetHealing() then 
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
        if Apollo.HandleDamage() then 
            Olympus.IsFrameBudgetExceeded()
            return true 
        end
    end

    -- Check frame budget before final return
    Olympus.IsFrameBudgetExceeded()
    return false
end

return Apollo
