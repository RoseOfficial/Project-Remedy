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

    -- Known mechanics by dungeon ID
    mechanics = {},

    -- Mechanic handling functions
    handlers = {},

    -- Default safe distances
    SAFE_DISTANCES = {
        STACK = 3,      -- yalms for stack mechanics
        SPREAD = 8,     -- yalms for spread mechanics
        AOE = 15,       -- yalms for large AOE
        KNOCKBACK = 20  -- yalms for knockback mechanics
    }
}

-- Helper Functions
local function calculateDirection(from, to)
    local dir = {
        x = to.x - from.x,
        y = to.y - from.y,
        z = to.z - from.z
    }
    local length = math.sqrt(dir.x * dir.x + dir.y * dir.y + dir.z * dir.z)
    return dir, length
end

local function calculateSafePosition(source, distance)
    local dir, length = calculateDirection(source.pos, Player.pos)
    if length <= 0 then return nil end
    
    return {
        x = source.pos.x + (dir.x / length) * distance,
        y = source.pos.y + (dir.y / length) * distance,
        z = source.pos.z + (dir.z / length) * distance
    }
end

local function getAveragePartyPosition()
    local partyList = EntityList("myparty")
    if not partyList then return nil end

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
    
    return count > 0 and {
        x = avgPos.x / count,
        y = avgPos.y / count,
        z = avgPos.z / count
    } or nil
end

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
    
    local handlers = {
        [Olympus.Dungeons.MECHANIC_TYPES.STACK] = function(mechanic)
            local stackTarget = EntityList:Get(mechanic.targetId)
            if not stackTarget then return false end
            return Player.pos:dist(stackTarget.pos) > Olympus.Dungeons.SAFE_DISTANCES.STACK
        end,
        
        [Olympus.Dungeons.MECHANIC_TYPES.SPREAD] = function(mechanic)
            local partyList = EntityList("myparty")
            if not partyList then return false end
            
            for _, member in pairs(partyList) do
                if member.id ~= Player.id and 
                   Player.pos:dist(member.pos) < Olympus.Dungeons.SAFE_DISTANCES.SPREAD then
                    Debug.Info(Debug.CATEGORIES.DUNGEONS, "Need to spread out")
                    return true
                end
            end
            return false
        end,
        
        [Olympus.Dungeons.MECHANIC_TYPES.AOE] = function(mechanic)
            local source = EntityList:Get(mechanic.sourceId)
            if not source then return false end
            local distance = Player.pos:dist(source.pos)
            return distance < mechanic.radius or distance < Olympus.Dungeons.SAFE_DISTANCES.AOE
        end,
        
        [Olympus.Dungeons.MECHANIC_TYPES.KNOCKBACK] = function(mechanic)
            if Olympus.HasBuff(Player, Olympus.BUFF_IDS.SURECAST) then return false end
            
            local source = EntityList:Get(mechanic.sourceId)
            if not source then return false end
            return Player.pos:dist(source.pos) < Olympus.Dungeons.SAFE_DISTANCES.KNOCKBACK
        end,
        
        [Olympus.Dungeons.MECHANIC_TYPES.TANKBUSTER] = function(mechanic)
            return mechanic.targetId == Player.id and Player.hp.percent < 80
        end,
        
        [Olympus.Dungeons.MECHANIC_TYPES.RAIDWIDE] = function(mechanic)
            local partyList = EntityList("myparty")
            if not partyList then return false end
            
            local lowHealthCount = 0
            for _, member in pairs(partyList) do
                if member.hp.percent < 80 then
                    lowHealthCount = lowHealthCount + 1
                end
            end
            return lowHealthCount >= 2
        end,
        
        [Olympus.Dungeons.MECHANIC_TYPES.DODGE] = function(mechanic)
            if not mechanic.position then return false end
            return Player.pos:dist(mechanic.position) < mechanic.radius
        end
    }
    
    -- Register all handlers
    for mechanicType, handler in pairs(handlers) do
        Olympus.Dungeons.RegisterHandler(mechanicType, handler)
        Debug.Info(Debug.CATEGORIES.DUNGEONS, 
            string.format("Registered handler for mechanic type: %d", mechanicType))
    end
    
    Debug.TrackFunctionEnd("Olympus.Dungeons.RegisterDefaultHandlers")
end

---Update dungeon state
---@return boolean stateChanged Whether the dungeon state changed
function Olympus.Dungeons.UpdateState()
    Debug.TrackFunctionStart("Olympus.Dungeons.UpdateState")
    
    if not Player then
        Debug.Warn(Debug.CATEGORIES.DUNGEONS, "Invalid player object")
        Debug.TrackFunctionEnd("Olympus.Dungeons.UpdateState")
        return false
    end
    
    local stateChanged = false
    
    -- Check dungeon state
    local newInDungeon = Player.incombat and Player.ininstance
    if newInDungeon ~= Olympus.Dungeons.current.inDungeon then
        Olympus.Dungeons.current.inDungeon = newInDungeon
        stateChanged = true
        Debug.Info(Debug.CATEGORIES.DUNGEONS, 
            newInDungeon and "Entered dungeon" or "Left dungeon")
    end
    
    -- Update boss state
    if Olympus.Dungeons.current.inDungeon then
        local currentTarget = Player:GetTarget()
        local isBossTarget = currentTarget and currentTarget.type == 2
        
        if isBossTarget and currentTarget.id ~= Olympus.Dungeons.current.currentBossId then
            Olympus.Dungeons.current.currentBossId = currentTarget.id
            Olympus.Dungeons.current.bossActive = true
            stateChanged = true
            Debug.Info(Debug.CATEGORIES.DUNGEONS, 
                string.format("New boss encountered: %s (ID: %d)", 
                    currentTarget.name or "Unknown", currentTarget.id))
        elseif not isBossTarget and Olympus.Dungeons.current.bossActive then
            Olympus.Dungeons.current.bossActive = false
            Olympus.Dungeons.current.currentBossId = 0
            stateChanged = true
            Debug.Info(Debug.CATEGORIES.DUNGEONS, "Boss fight ended")
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
    
    local currentTime = os.clock()
    if currentTime - Olympus.Dungeons.current.lastMechanicTime < 1.5 then
        Debug.Verbose(Debug.CATEGORIES.DUNGEONS, "Mechanic check cooldown active")
        Debug.TrackFunctionEnd("Olympus.Dungeons.CheckMechanics")
        return Olympus.Dungeons.current.mechanicActive
    end
    
    -- Reset mechanic state
    Olympus.Dungeons.current.mechanicActive = false
    Olympus.Dungeons.current.activeMechanicId = 0
    
    local dungeonMechanics = Olympus.Dungeons.mechanics[Olympus.Dungeons.current.id]
    if not dungeonMechanics then
        Debug.Verbose(Debug.CATEGORIES.DUNGEONS, 
            string.format("No mechanics defined for dungeon ID: %s", 
                Olympus.Dungeons.current.id))
        Debug.TrackFunctionEnd("Olympus.Dungeons.CheckMechanics")
        return false
    end
    
    -- Check mechanics
    for id, mechanic in pairs(dungeonMechanics) do
        if mechanic and Olympus.Dungeons.handlers[mechanic.type] then
            Debug.Verbose(Debug.CATEGORIES.DUNGEONS, 
                string.format("Checking mechanic ID %d of type %d", id, mechanic.type))
                
            if Olympus.Dungeons.handlers[mechanic.type](mechanic) then
                Olympus.Dungeons.current.mechanicActive = true
                Olympus.Dungeons.current.activeMechanicId = id
                Olympus.Dungeons.current.lastMechanicTime = currentTime
                Debug.Info(Debug.CATEGORIES.DUNGEONS, 
                    string.format("Mechanic activated: %d (Type: %d)", id, mechanic.type))
                break
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
        string.format("Registered handler for mechanic type: %d", mechanicType))
    
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
    local count = 0
    for _, _ in pairs(mechanics) do count = count + 1 end
    
    Debug.Info(Debug.CATEGORIES.DUNGEONS, 
        string.format("Registered %d mechanics for dungeon ID: %s", count, dungeonId))
    
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
        string.format("Calculating safe position for mechanic type: %d", mechanic.type))
    
    local safePos = nil
    
    -- Calculate safe position based on mechanic type
    if mechanic.type == Olympus.Dungeons.MECHANIC_TYPES.STACK then
        local stackTarget = EntityList:Get(mechanic.targetId)
        safePos = stackTarget and stackTarget.pos
        
    elseif mechanic.type == Olympus.Dungeons.MECHANIC_TYPES.SPREAD then
        local avgPos = getAveragePartyPosition()
        if avgPos then
            safePos = calculateSafePosition({ pos = avgPos }, Olympus.Dungeons.SAFE_DISTANCES.SPREAD)
        end
        
    elseif mechanic.type == Olympus.Dungeons.MECHANIC_TYPES.AOE or 
           mechanic.type == Olympus.Dungeons.MECHANIC_TYPES.KNOCKBACK then
        local source = EntityList:Get(mechanic.sourceId)
        if source then
            local safeDistance = mechanic.type == Olympus.Dungeons.MECHANIC_TYPES.AOE and
                Olympus.Dungeons.SAFE_DISTANCES.AOE or
                Olympus.Dungeons.SAFE_DISTANCES.KNOCKBACK
            safePos = calculateSafePosition(source, safeDistance)
        end
        
    elseif mechanic.type == Olympus.Dungeons.MECHANIC_TYPES.DODGE and mechanic.position then
        safePos = calculateSafePosition({ pos = mechanic.position }, mechanic.radius + 2)
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