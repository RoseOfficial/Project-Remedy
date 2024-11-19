-- Apollo
Apollo = {}

Apollo.classes = {
    [FFXIV.JOBS.WHITEMAGE] = true,
    [FFXIV.JOBS.CONJURER] = true,
}

-- Define Dungeons module first
Apollo.Dungeons = {}

-- Dungeon IDs
Apollo.Dungeons.IDS = {
    SASTASHA = "Sastasha",
    -- Add more dungeon IDs as needed
}

-- Track current duty state
Apollo.Dungeons.currentDuty = nil
Apollo.Dungeons.currentMap = nil
Apollo.Dungeons.lastPulseTime = 0
Apollo.Dungeons.registeredDungeons = {}

-- Initialize Apollo's dungeon mechanics
function Apollo.Dungeons.Initialize()
    Debug.Info("DUNGEONS", "Starting initialization")
    
    -- Initialize Olympus dungeon system
    Olympus.Dungeons.Initialize()
    
    -- Check initial state
    Apollo.Dungeons.CheckAndRegisterDungeon()

    Debug.Info("DUNGEONS", "Initialization complete")
end

-- Unified function to check and register dungeon mechanics
function Apollo.Dungeons.CheckAndRegisterDungeon()
    local currentMap = Player.localmapid
    local activeDuty = Duty:GetActiveDutyInfo()
    local dungeonName = activeDuty and activeDuty.name

    -- Unregister mechanics if we're not in a valid dungeon anymore
    if (currentMap ~= 1036 and Apollo.Dungeons.registeredDungeons.SASTASHA) or 
       (dungeonName ~= "Sastasha" and Apollo.Dungeons.registeredDungeons.SASTASHA) then
        Debug.Info("DUNGEONS", "Left Sastasha, unregistering mechanics")
        Olympus.Dungeons.RegisterMechanics(Apollo.Dungeons.IDS.SASTASHA, {})
        Apollo.Dungeons.registeredDungeons.SASTASHA = false
    end

    -- Register Sastasha mechanics if needed
    if (currentMap == 1036 or dungeonName == "Sastasha") and 
       not Apollo.Dungeons.registeredDungeons.SASTASHA then
        Debug.Info("DUNGEONS", "Registering Sastasha mechanics")
        Apollo.Dungeons.RegisterSastashaMechanics()
        Apollo.Dungeons.registeredDungeons.SASTASHA = true
    end

    -- Update tracking variables
    Apollo.Dungeons.currentMap = currentMap
    Apollo.Dungeons.currentDuty = dungeonName
end

-- Check map and update state on each pulse
function Apollo.Dungeons.Pulse()
    -- Throttle checks to every 1 seconds
    local currentTime = os.time()
    if (currentTime - Apollo.Dungeons.lastPulseTime) >= 1 then
        Apollo.Dungeons.lastPulseTime = currentTime
        
        -- Check for any state changes and register/unregister mechanics as needed
        Apollo.Dungeons.CheckAndRegisterDungeon()
        
        -- Let Olympus system handle mechanic checks and safe positions
        if Olympus.Dungeons.CheckMechanics() then
            Debug.Info("DUNGEONS", "Active mechanic detected")
        end
    end
end

-- Initialize Olympus if not already initialized
if not Apollo.olympusInitialized then
    Olympus.Initialize()
    Apollo.olympusInitialized = true
end

-- Initialize dungeon system if needed
if not Apollo.dungeonInitialized then
    Apollo.Dungeons.Initialize()
    Apollo.dungeonInitialized = true
end

---------------------------------------------------------------------------------------------------
-- Main Cast Priority System
---------------------------------------------------------------------------------------------------

function Apollo.Cast()
    -- Update dungeon mechanics first
    Apollo.Dungeons.Pulse()
    
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
    if Apollo.EmergencyHealing.Handle() then 
        Olympus.IsFrameBudgetExceeded()
        return true 
    end -- High priority for emergency response
    if Apollo.HandleBuffs() then 
        Olympus.IsFrameBudgetExceeded()
        return true 
    end
    if Apollo.Mitigation.Handle() then 
        Olympus.IsFrameBudgetExceeded()
        return true 
    end -- Proactive mitigation
    if Apollo.HandleLilySystem() then 
        Olympus.IsFrameBudgetExceeded()
        return true 
    end -- Free healing resource
    
    -- Only handle non-essential healing if not in emergency MP state
    if Player.mp.percent > Apollo.MP.THRESHOLDS.EMERGENCY then
        if Apollo.AoEHealing.Handle() then 
            Olympus.IsFrameBudgetExceeded()
            return true 
        end
        if Apollo.SingleTargetHealing.Handle() then 
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
