-- Registry

-- Initialize Olympus if needed
Olympus = Olympus or {}
Olympus.Registry = {}

-- Access Types through Olympus.Dungeons
local MECHANIC_TYPES = Olympus.Dungeons.MECHANIC_TYPES

-- Initialize Registry properties
Olympus.Registry.mechanics = {}
Olympus.Registry.handlers = {
    [MECHANIC_TYPES.STACK] = {
        needsHandling = nil, -- Will be set when Stack handler loads
        getSafePosition = nil
    },
    [MECHANIC_TYPES.SPREAD] = {
        needsHandling = nil, -- Will be set when Spread handler loads
        getSafePosition = nil
    },
    [MECHANIC_TYPES.AOE] = {
        needsHandling = nil, -- Will be set when AOE handler loads
        getSafePosition = nil
    },
    [MECHANIC_TYPES.KNOCKBACK] = {
        needsHandling = nil, -- Will be set when AOE handler loads
        getSafePosition = nil
    },
    [MECHANIC_TYPES.TANKBUSTER] = {
        needsHandling = nil, -- Will be set when Defensive handler loads
        getSafePosition = nil
    },
    [MECHANIC_TYPES.RAIDWIDE] = {
        needsHandling = nil, -- Will be set when Defensive handler loads
        getSafePosition = nil
    },
    [MECHANIC_TYPES.DODGE] = {
        needsHandling = nil, -- Will be set when Dodge handler loads
        getSafePosition = nil
    }
}

---Register mechanics for a dungeon
---@param dungeonId string The dungeon ID
---@param mechanics table Table of mechanic definitions
function Olympus.Registry.RegisterMechanics(dungeonId, mechanics)
    Olympus.Debug.TrackFunctionStart("Olympus.Registry.RegisterMechanics")
    
    if type(mechanics) ~= "table" then
        Olympus.Debug.Error(Olympus.Debug.CATEGORIES.DUNGEONS, "Invalid mechanics table")
        Olympus.Debug.TrackFunctionEnd("Olympus.Registry.RegisterMechanics")
        return
    end
    
    -- Validate each mechanic
    for id, mechanic in pairs(mechanics) do
        if not mechanic.type or not Olympus.Registry.handlers[mechanic.type] then
            Olympus.Debug.Warn(Olympus.Debug.CATEGORIES.DUNGEONS, 
                string.format("Invalid mechanic type for ID %s", tostring(id)))
            mechanics[id] = nil
        end
    end
    
    Olympus.Registry.mechanics[dungeonId] = mechanics
    
    -- Count valid mechanics
    local count = 0
    for _, _ in pairs(mechanics) do
        count = count + 1
    end
    
    Olympus.Debug.Info(Olympus.Debug.CATEGORIES.DUNGEONS, 
        string.format("Registered %d mechanics for dungeon ID: %s", 
            count, dungeonId))
            
    Olympus.Debug.TrackFunctionEnd("Olympus.Registry.RegisterMechanics")
end

---Get handler for a mechanic type
---@param mechanicType number The type of mechanic
---@return table|nil handler The handler for the mechanic type, or nil if not found
function Olympus.Registry.GetHandler(mechanicType)
    return Olympus.Registry.handlers[mechanicType]
end

---Get mechanics for a dungeon
---@param dungeonId string The dungeon ID
---@return table|nil mechanics The mechanics for the dungeon, or nil if not found
function Olympus.Registry.GetMechanics(dungeonId)
    return Olympus.Registry.mechanics[dungeonId]
end

---Check if a mechanic needs handling
---@param mechanic table The mechanic definition
---@return boolean needsHandling Whether the mechanic needs to be handled
function Olympus.Registry.NeedsHandling(mechanic)
    local handler = Olympus.Registry.GetHandler(mechanic.type)
    if not handler or not handler.needsHandling then return false end
    
    return handler.needsHandling(mechanic)
end

---Get safe position for a mechanic
---@param mechanic table The mechanic definition
---@return table|nil position The safe position to move to, or nil if no movement needed
function Olympus.Registry.GetSafePosition(mechanic)
    local handler = Olympus.Registry.GetHandler(mechanic.type)
    if not handler or not handler.getSafePosition then return nil end
    
    return handler.getSafePosition(mechanic)
end

-- Register handler functions
function Olympus.Registry.RegisterHandlerFunctions(mechanicType, needsHandling, getSafePosition)
    if Olympus.Registry.handlers[mechanicType] then
        Olympus.Registry.handlers[mechanicType].needsHandling = needsHandling
        Olympus.Registry.handlers[mechanicType].getSafePosition = getSafePosition
    end
end

-- Make Registry available through Olympus.Dungeons
Olympus.Dungeons.Registry = Olympus.Registry
