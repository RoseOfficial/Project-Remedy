Olympus = Olympus or {}
Olympus.Dungeons = {
    -- Current dungeon state
    current = {
        id = 0,
        name = "",
        inDungeon = false,
        bossActive = false,
        currentBossId = 0,
        mechanicActive = false,
        activeMechanicId = 0,
        lastMechanicTime = 0
    },

    -- Mechanic types
    MECHANIC_TYPES = {
        STACK = 1,
        SPREAD = 2,
        AOE = 3,
        KNOCKBACK = 4,
        TANKBUSTER = 5,
        RAIDWIDE = 6,
        DODGE = 7
    },

    -- Known mechanics by dungeon ID (initialize empty table)
    mechanics = {},

    -- Mechanic handling functions (initialize empty table)
    handlers = {},

    -- Default safe distances
    SAFE_DISTANCES = {
        STACK = 3,      -- yalms for stack mechanics
        SPREAD = 8,     -- yalms for spread mechanics
        AOE = 15,       -- yalms for large AOE
        KNOCKBACK = 20  -- yalms for knockback mechanics
    }
}

-- Initialize tables at module level
Olympus.Dungeons.mechanics = Olympus.Dungeons.mechanics or {}
Olympus.Dungeons.handlers = Olympus.Dungeons.handlers or {}

---Initialize the dungeon module
function Olympus.Dungeons.Initialize()
    Debug.TrackFunctionStart("Olympus.Dungeons.Initialize")
    
    -- Reset state
    Olympus.Dungeons.current.inDungeon = false
    Olympus.Dungeons.current.bossActive = false
    Olympus.Dungeons.current.mechanicActive = false
    
    -- Register default mechanic handlers
    Olympus.Dungeons.RegisterDefaultHandlers()
    
    Debug.Info(Debug.CATEGORIES.DUNGEONS, "Dungeon module initialized")
    Debug.TrackFunctionEnd("Olympus.Dungeons.Initialize")
end

---Register default mechanic handlers
function Olympus.Dungeons.RegisterDefaultHandlers()
    Debug.TrackFunctionStart("Olympus.Dungeons.RegisterDefaultHandlers")
    
    -- Stack mechanic handler
    Olympus.Dungeons.RegisterHandler(Olympus.Dungeons.MECHANIC_TYPES.STACK, function(mechanic)
        local stackTarget = EntityList:Get(mechanic.targetId)
        if not stackTarget then 
            Debug.Verbose(Debug.CATEGORIES.DUNGEONS, "Stack target not found")
            return false 
        end
        
        -- Check if we need to stack
        local distance = Player.pos:dist(stackTarget.pos)
        Debug.Verbose(Debug.CATEGORIES.DUNGEONS, string.format("Stack distance: %.2f yalms", distance))
        return distance > Olympus.Dungeons.SAFE_DISTANCES.STACK
    end)
    
    -- Spread mechanic handler
    Olympus.Dungeons.RegisterHandler(Olympus.Dungeons.MECHANIC_TYPES.SPREAD, function(mechanic)
        -- Check distance to all party members
        local partyList = EntityList("myparty")
        if not partyList then 
            Debug.Verbose(Debug.CATEGORIES.DUNGEONS, "No party members found")
            return false 
        end
        
        for _, member in pairs(partyList) do
            if member.id ~= Player.id then
                local distance = Player.pos:dist(member.pos)
                Debug.Verbose(Debug.CATEGORIES.DUNGEONS, 
                    string.format("Distance to party member %d: %.2f yalms", 
                        member.id, distance))
                if distance < Olympus.Dungeons.SAFE_DISTANCES.SPREAD then
                    Debug.Info(Debug.CATEGORIES.DUNGEONS, "Need to spread out")
                    return true
                end
            end
        end
        return false
    end)
    
    -- AOE dodge handler
    Olympus.Dungeons.RegisterHandler(Olympus.Dungeons.MECHANIC_TYPES.AOE, function(mechanic)
        local source = EntityList:Get(mechanic.sourceId)
        if not source then 
            Debug.Verbose(Debug.CATEGORIES.DUNGEONS, "AOE source not found")
            return false 
        end
        
        -- Check if in AOE range
        local distance = Player.pos:dist(source.pos)
        Debug.Verbose(Debug.CATEGORIES.DUNGEONS, 
            string.format("Distance from AOE source: %.2f yalms", distance))
        return distance < mechanic.radius or distance < Olympus.Dungeons.SAFE_DISTANCES.AOE
    end)
    
    -- Knockback handler
    Olympus.Dungeons.RegisterHandler(Olympus.Dungeons.MECHANIC_TYPES.KNOCKBACK, function(mechanic)
        local source = EntityList:Get(mechanic.sourceId)
        if not source then 
            Debug.Verbose(Debug.CATEGORIES.DUNGEONS, "Knockback source not found")
            return false 
        end
        
        -- Check if we have knockback immunity
        if Olympus.HasBuff(Player, Olympus.BUFF_IDS.SURECAST) then
            Debug.Info(Debug.CATEGORIES.DUNGEONS, "Knockback immunity active")
            return false
        end
        
        -- Check if in knockback range
        local distance = Player.pos:dist(source.pos)
        Debug.Verbose(Debug.CATEGORIES.DUNGEONS, 
            string.format("Distance from knockback source: %.2f yalms", distance))
        return distance < Olympus.Dungeons.SAFE_DISTANCES.KNOCKBACK
    end)
    
    -- Tankbuster handler
    Olympus.Dungeons.RegisterHandler(Olympus.Dungeons.MECHANIC_TYPES.TANKBUSTER, function(mechanic)
        -- Only react if we're the target
        if mechanic.targetId ~= Player.id then 
            Debug.Verbose(Debug.CATEGORIES.DUNGEONS, "Not tankbuster target")
            return false 
        end
        
        -- Check if we need defensive cooldowns
        local healthPercent = Player.hp.percent
        Debug.Info(Debug.CATEGORIES.DUNGEONS, 
            string.format("Tankbuster incoming, health at %.1f%%", healthPercent))
        return healthPercent < 80
    end)
    
    -- Raidwide handler
    Olympus.Dungeons.RegisterHandler(Olympus.Dungeons.MECHANIC_TYPES.RAIDWIDE, function(mechanic)
        -- Check party health
        local partyList = EntityList("myparty")
        if not partyList then 
            Debug.Verbose(Debug.CATEGORIES.DUNGEONS, "No party members found")
            return false 
        end
        
        local lowHealthCount = 0
        for _, member in pairs(partyList) do
            if member.hp.percent < 80 then
                lowHealthCount = lowHealthCount + 1
                Debug.Verbose(Debug.CATEGORIES.DUNGEONS, 
                    string.format("Party member %d at %.1f%% health", 
                        member.id, member.hp.percent))
            end
        end
        
        if lowHealthCount >= 2 then
            Debug.Info(Debug.CATEGORIES.DUNGEONS, 
                string.format("%d party members below 80%% health", lowHealthCount))
        end
        return lowHealthCount >= 2
    end)
    
    -- Dodge handler
    Olympus.Dungeons.RegisterHandler(Olympus.Dungeons.MECHANIC_TYPES.DODGE, function(mechanic)
        -- Check if we're in the danger zone
        local dangerPos = mechanic.position
        if not dangerPos then 
            Debug.Verbose(Debug.CATEGORIES.DUNGEONS, "No danger position defined")
            return false 
        end
        
        local distance = Player.pos:dist(dangerPos)
        Debug.Verbose(Debug.CATEGORIES.DUNGEONS, 
            string.format("Distance from danger zone: %.2f yalms", distance))
        return distance < mechanic.radius
    end)
    
    Debug.Info(Debug.CATEGORIES.DUNGEONS, "Registered default mechanic handlers")
    Debug.TrackFunctionEnd("Olympus.Dungeons.RegisterDefaultHandlers")
end

---Update dungeon state
---@return boolean stateChanged Whether the dungeon state changed
function Olympus.Dungeons.UpdateState()
    Debug.TrackFunctionStart("Olympus.Dungeons.UpdateState")
    
    local stateChanged = false
    local player = Player
    
    if not player then
        Debug.Warn(Debug.CATEGORIES.DUNGEONS, "Invalid player object")
        Debug.TrackFunctionEnd("Olympus.Dungeons.UpdateState")
        return false
    end
    
    -- Check if we're in a dungeon
    local newInDungeon = player.incombat and player.ininstance
    if newInDungeon ~= Olympus.Dungeons.current.inDungeon then
        Olympus.Dungeons.current.inDungeon = newInDungeon
        stateChanged = true
        Debug.Info(Debug.CATEGORIES.DUNGEONS, 
            string.format("Dungeon state changed: %s", 
                newInDungeon and "Entered dungeon" or "Left dungeon"))
    end
    
    -- Update boss state if in dungeon
    if Olympus.Dungeons.current.inDungeon then
        local currentTarget = Player:GetTarget()
        if currentTarget and currentTarget.type == 2 then -- Boss type
            if currentTarget.id ~= Olympus.Dungeons.current.currentBossId then
                Olympus.Dungeons.current.currentBossId = currentTarget.id
                Olympus.Dungeons.current.bossActive = true
                stateChanged = true
                Debug.Info(Debug.CATEGORIES.DUNGEONS, 
                    string.format("New boss encountered: %s (ID: %d)", 
                        currentTarget.name or "Unknown", currentTarget.id))
            end
        else
            if Olympus.Dungeons.current.bossActive then
                Olympus.Dungeons.current.bossActive = false
                Olympus.Dungeons.current.currentBossId = 0
                stateChanged = true
                Debug.Info(Debug.CATEGORIES.DUNGEONS, "Boss fight ended")
            end
        end
    end
    
    Debug.TrackFunctionEnd("Olympus.Dungeons.UpdateState")
    return stateChanged
end

---Check for active mechanics
---@return boolean mechanicActive Whether a mechanic is currently active
function Olympus.Dungeons.CheckMechanics()
    Debug.TrackFunctionStart("Olympus.Dungeons.CheckMechanics")
    
    if not Olympus.Dungeons.current.inDungeon then
        Debug.Verbose(Debug.CATEGORIES.DUNGEONS, "Not in dungeon")
        Debug.TrackFunctionEnd("Olympus.Dungeons.CheckMechanics")
        return false
    end
    
    -- Check for mechanic triggers
    local currentTime = os.clock()
    if currentTime - Olympus.Dungeons.current.lastMechanicTime < 1.5 then
        Debug.Verbose(Debug.CATEGORIES.DUNGEONS, "Mechanic check cooldown active")
        Debug.TrackFunctionEnd("Olympus.Dungeons.CheckMechanics")
        return Olympus.Dungeons.current.mechanicActive
    end
    
    -- Reset mechanic state for new checks
    Olympus.Dungeons.current.mechanicActive = false
    Olympus.Dungeons.current.activeMechanicId = 0
    
    -- Get current dungeon mechanics
    local dungeonMechanics = Olympus.Dungeons.mechanics[Olympus.Dungeons.current.id]
    if not dungeonMechanics then
        Debug.Verbose(Debug.CATEGORIES.DUNGEONS, 
            string.format("No mechanics defined for dungeon ID: %s", 
                Olympus.Dungeons.current.id))
        Debug.TrackFunctionEnd("Olympus.Dungeons.CheckMechanics")
        return false
    end
    
    -- Check each mechanic
    for id, mechanic in pairs(dungeonMechanics) do
        if mechanic then  -- Add nil check
            Debug.Verbose(Debug.CATEGORIES.DUNGEONS, 
                string.format("Checking mechanic ID %d of type %d", 
                    id, mechanic.type))
            if Olympus.Dungeons.handlers[mechanic.type] then
                if Olympus.Dungeons.handlers[mechanic.type](mechanic) then
                    Olympus.Dungeons.current.mechanicActive = true
                    Olympus.Dungeons.current.activeMechanicId = id
                    Olympus.Dungeons.current.lastMechanicTime = currentTime
                    Debug.Info(Debug.CATEGORIES.DUNGEONS, 
                        string.format("Mechanic activated: %d (Type: %d)", 
                            id, mechanic.type))
                    break
                end
            end
        end
    end
    
    Debug.TrackFunctionEnd("Olympus.Dungeons.CheckMechanics")
    return Olympus.Dungeons.current.mechanicActive
end

---Register a mechanic handler
---@param mechanicType number The type of mechanic
---@param handler function The handler function
function Olympus.Dungeons.RegisterHandler(mechanicType, handler)
    Debug.TrackFunctionStart("Olympus.Dungeons.RegisterHandler")
    
    if type(handler) ~= "function" then
        Debug.Error(Debug.CATEGORIES.DUNGEONS, "Invalid handler function")
        Debug.TrackFunctionEnd("Olympus.Dungeons.RegisterHandler")
        return
    end
    
    Olympus.Dungeons.handlers[mechanicType] = handler
    Debug.Info(Debug.CATEGORIES.DUNGEONS, 
        string.format("Registered handler for mechanic type: %d", 
            mechanicType))
            
    Debug.TrackFunctionEnd("Olympus.Dungeons.RegisterHandler")
end

---Register mechanics for a dungeon
---@param dungeonId string The dungeon ID
---@param mechanics table Table of mechanic definitions
function Olympus.Dungeons.RegisterMechanics(dungeonId, mechanics)
    Debug.TrackFunctionStart("Olympus.Dungeons.RegisterMechanics")
    
    if type(mechanics) ~= "table" then
        Debug.Error(Debug.CATEGORIES.DUNGEONS, "Invalid mechanics table")
        Debug.TrackFunctionEnd("Olympus.Dungeons.RegisterMechanics")
        return
    end
    
    Olympus.Dungeons.mechanics[dungeonId] = mechanics
    
    -- Count valid mechanics
    local count = 0
    for _, _ in pairs(mechanics) do
        count = count + 1
    end
    
    Debug.Info(Debug.CATEGORIES.DUNGEONS, 
        string.format("Registered %d mechanics for dungeon ID: %s", 
            count, dungeonId))
            
    Debug.TrackFunctionEnd("Olympus.Dungeons.RegisterMechanics")
end

---Get safe position for current mechanic
---@return table|nil position The safe position to move to, or nil if no movement needed
function Olympus.Dungeons.GetSafePosition()
    Debug.TrackFunctionStart("Olympus.Dungeons.GetSafePosition")
    
    if not Olympus.Dungeons.current.mechanicActive then
        Debug.Verbose(Debug.CATEGORIES.DUNGEONS, "No active mechanic")
        Debug.TrackFunctionEnd("Olympus.Dungeons.GetSafePosition")
        return nil
    end
    
    local mechanic = Olympus.Dungeons.mechanics[Olympus.Dungeons.current.id] and
                    Olympus.Dungeons.mechanics[Olympus.Dungeons.current.id][Olympus.Dungeons.current.activeMechanicId]
    
    if not mechanic then
        Debug.Warn(Debug.CATEGORIES.DUNGEONS, "Invalid active mechanic")
        Debug.TrackFunctionEnd("Olympus.Dungeons.GetSafePosition")
        return nil
    end
    
    Debug.Info(Debug.CATEGORIES.DUNGEONS, 
        string.format("Calculating safe position for mechanic type: %d", 
            mechanic.type))
    
    -- Calculate safe position based on mechanic type
    local safePos = nil
    
    if mechanic.type == Olympus.Dungeons.MECHANIC_TYPES.STACK then
        local stackTarget = EntityList:Get(mechanic.targetId)
        if stackTarget then
            safePos = stackTarget.pos
            Debug.Info(Debug.CATEGORIES.DUNGEONS, "Stack target position found")
        end
    elseif mechanic.type == Olympus.Dungeons.MECHANIC_TYPES.SPREAD then
        -- Find position away from party members
        local partyList = EntityList("myparty")
        if partyList then
            -- Calculate average party position
            local avgPos = { x = 0, y = 0, z = 0 }
            local count = 0
            for _, member in pairs(partyList) do
                if member.id ~= Player.id then
                    avgPos.x = avgPos.x + member.pos.x
                    avgPos.y = avgPos.y + member.pos.y
                    avgPos.z = avgPos.z + member.pos.z
                    count = count + 1
                end
            end
            if count > 0 then
                avgPos.x = avgPos.x / count
                avgPos.y = avgPos.y / count
                avgPos.z = avgPos.z / count
                
                -- Move in opposite direction of party
                local dir = {
                    x = Player.pos.x - avgPos.x,
                    y = Player.pos.y - avgPos.y,
                    z = Player.pos.z - avgPos.z
                }
                local length = math.sqrt(dir.x * dir.x + dir.y * dir.y + dir.z * dir.z)
                if length > 0 then
                    safePos = {
                        x = Player.pos.x + (dir.x / length) * Olympus.Dungeons.SAFE_DISTANCES.SPREAD,
                        y = Player.pos.y + (dir.y / length) * Olympus.Dungeons.SAFE_DISTANCES.SPREAD,
                        z = Player.pos.z + (dir.z / length) * Olympus.Dungeons.SAFE_DISTANCES.SPREAD
                    }
                    Debug.Info(Debug.CATEGORIES.DUNGEONS, "Spread position calculated")
                end
            end
        end
    elseif mechanic.type == Olympus.Dungeons.MECHANIC_TYPES.AOE or 
           mechanic.type == Olympus.Dungeons.MECHANIC_TYPES.KNOCKBACK then
        local source = EntityList:Get(mechanic.sourceId)
        if source then
            -- Move away from source
            local dir = {
                x = Player.pos.x - source.pos.x,
                y = Player.pos.y - source.pos.y,
                z = Player.pos.z - source.pos.z
            }
            local length = math.sqrt(dir.x * dir.x + dir.y * dir.y + dir.z * dir.z)
            if length > 0 then
                local safeDistance = mechanic.type == Olympus.Dungeons.MECHANIC_TYPES.AOE and
                    Olympus.Dungeons.SAFE_DISTANCES.AOE or
                    Olympus.Dungeons.SAFE_DISTANCES.KNOCKBACK
                safePos = {
                    x = source.pos.x + (dir.x / length) * safeDistance,
                    y = source.pos.y + (dir.y / length) * safeDistance,
                    z = source.pos.z + (dir.z / length) * safeDistance
                }
                Debug.Info(Debug.CATEGORIES.DUNGEONS, 
                    string.format("%s safe position calculated", 
                        mechanic.type == Olympus.Dungeons.MECHANIC_TYPES.AOE and "AOE" or "Knockback"))
            end
        end
    elseif mechanic.type == Olympus.Dungeons.MECHANIC_TYPES.DODGE then
        if mechanic.position then
            -- Move away from danger zone
            local dir = {
                x = Player.pos.x - mechanic.position.x,
                y = Player.pos.y - mechanic.position.y,
                z = Player.pos.z - mechanic.position.z
            }
            local length = math.sqrt(dir.x * dir.x + dir.y * dir.y + dir.z * dir.z)
            if length > 0 then
                safePos = {
                    x = mechanic.position.x + (dir.x / length) * (mechanic.radius + 2),
                    y = mechanic.position.y + (dir.y / length) * (mechanic.radius + 2),
                    z = mechanic.position.z + (dir.z / length) * (mechanic.radius + 2)
                }
                Debug.Info(Debug.CATEGORIES.DUNGEONS, "Dodge safe position calculated")
            end
        end
    end
    
    if safePos then
        Debug.Info(Debug.CATEGORIES.DUNGEONS, 
            string.format("Safe position: %.2f, %.2f, %.2f", 
                safePos.x, safePos.y, safePos.z))
    else
        Debug.Verbose(Debug.CATEGORIES.DUNGEONS, "No safe position needed")
    end
    
    Debug.TrackFunctionEnd("Olympus.Dungeons.GetSafePosition")
    return safePos
end

return Olympus.Dungeons
