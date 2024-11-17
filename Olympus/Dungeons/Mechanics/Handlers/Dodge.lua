-- Initialize Olympus if needed
Olympus = Olympus or {}
Olympus.Dungeons = Olympus.Dungeons or {}

local Dodge = {}

---Check if dodge mechanic needs to be handled
---@param mechanic table The mechanic definition
---@return boolean needsHandling Whether the mechanic needs to be handled
function Dodge.NeedsHandling(mechanic)
    Debug.TrackFunctionStart("Dodge.NeedsHandling")
    
    -- Validate mechanic has required fields
    if not mechanic or not mechanic.position then
        Debug.Verbose(Debug.CATEGORIES.DUNGEONS, "Invalid dodge mechanic definition")
        Debug.TrackFunctionEnd("Dodge.NeedsHandling")
        return false
    end
    
    -- Check if we're in the danger zone
    local dangerPos = mechanic.position
    local distance = Player.pos:dist(dangerPos)
    
    Debug.Verbose(Debug.CATEGORIES.DUNGEONS, 
        string.format("Distance from danger zone: %.2f yalms", distance))
    
    -- Use mechanic radius if specified, otherwise use a default
    local dangerRadius = mechanic.radius or 5
    local needsHandling = distance < dangerRadius
    
    if needsHandling then
        Debug.Info(Debug.CATEGORIES.DUNGEONS, 
            string.format("In danger zone (radius %.2f yalms)", dangerRadius))
    end
    
    Debug.TrackFunctionEnd("Dodge.NeedsHandling")
    return needsHandling
end

---Calculate safe position for dodge mechanic
---@param mechanic table The mechanic definition
---@return table|nil position The safe position to move to, or nil if no movement needed
function Dodge.GetSafePosition(mechanic)
    Debug.TrackFunctionStart("Dodge.GetSafePosition")
    
    -- Validate mechanic has required fields
    if not mechanic or not mechanic.position then
        Debug.Verbose(Debug.CATEGORIES.DUNGEONS, "Invalid dodge mechanic definition")
        Debug.TrackFunctionEnd("Dodge.GetSafePosition")
        return nil
    end
    
    -- Calculate direction away from danger zone
    local dir = {
        x = Player.pos.x - mechanic.position.x,
        y = Player.pos.y - mechanic.position.y,
        z = Player.pos.z - mechanic.position.z
    }
    
    -- Normalize direction vector
    local length = math.sqrt(dir.x * dir.x + dir.y * dir.y + dir.z * dir.z)
    if length == 0 then
        Debug.Warn(Debug.CATEGORIES.DUNGEONS, "Cannot calculate dodge direction")
        Debug.TrackFunctionEnd("Dodge.GetSafePosition")
        return nil
    end
    
    -- Use mechanic radius if specified, otherwise use a default
    local dangerRadius = mechanic.radius or 5
    local safeDistance = dangerRadius + 2 -- Add buffer distance
    
    -- Calculate safe position
    local safePos = {
        x = mechanic.position.x + (dir.x / length) * safeDistance,
        y = mechanic.position.y + (dir.y / length) * safeDistance,
        z = mechanic.position.z + (dir.z / length) * safeDistance
    }
    
    Debug.Info(Debug.CATEGORIES.DUNGEONS, 
        string.format("Dodge safe position: %.2f, %.2f, %.2f", 
            safePos.x, safePos.y, safePos.z))
    
    Debug.TrackFunctionEnd("Dodge.GetSafePosition")
    return safePos
end

-- Register handler functions with Registry
if Olympus.Dungeons.Registry then
    Olympus.Dungeons.Registry.RegisterHandlerFunctions(
        Olympus.Dungeons.MECHANIC_TYPES.DODGE,
        Dodge.NeedsHandling,
        Dodge.GetSafePosition
    )
end
