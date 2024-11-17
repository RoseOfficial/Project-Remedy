-- Initialize Olympus if needed
Olympus = Olympus or {}
Olympus.Dungeons = Olympus.Dungeons or {}

local Stack = {}

---Check if stack mechanic needs to be handled
---@param mechanic table The mechanic definition
---@return boolean needsHandling Whether the mechanic needs to be handled
function Stack.NeedsHandling(mechanic)
    Debug.TrackFunctionStart("Stack.NeedsHandling")
    
    -- Validate mechanic has required fields
    if not mechanic or not mechanic.targetId then
        Debug.Verbose(Debug.CATEGORIES.DUNGEONS, "Invalid stack mechanic definition")
        Debug.TrackFunctionEnd("Stack.NeedsHandling")
        return false
    end
    
    -- Get stack target
    local stackTarget = EntityList:Get(mechanic.targetId)
    if not stackTarget then 
        Debug.Verbose(Debug.CATEGORIES.DUNGEONS, "Stack target not found")
        Debug.TrackFunctionEnd("Stack.NeedsHandling")
        return false 
    end
    
    -- Check if we need to stack
    local distance = Player.pos:dist(stackTarget.pos)
    Debug.Verbose(Debug.CATEGORIES.DUNGEONS, 
        string.format("Stack distance: %.2f yalms", distance))
    
    local needsHandling = distance > Olympus.Dungeons.SAFE_DISTANCES.STACK
    
    Debug.TrackFunctionEnd("Stack.NeedsHandling")
    return needsHandling
end

---Calculate safe position for stack mechanic
---@param mechanic table The mechanic definition
---@return table|nil position The safe position to move to, or nil if no movement needed
function Stack.GetSafePosition(mechanic)
    Debug.TrackFunctionStart("Stack.GetSafePosition")
    
    -- Get stack target
    local stackTarget = EntityList:Get(mechanic.targetId)
    if not stackTarget then 
        Debug.Verbose(Debug.CATEGORIES.DUNGEONS, "Stack target not found")
        Debug.TrackFunctionEnd("Stack.GetSafePosition")
        return nil
    end
    
    -- Return target's position as safe position
    local safePos = {
        x = stackTarget.pos.x,
        y = stackTarget.pos.y,
        z = stackTarget.pos.z
    }
    
    Debug.Info(Debug.CATEGORIES.DUNGEONS, 
        string.format("Stack safe position: %.2f, %.2f, %.2f", 
            safePos.x, safePos.y, safePos.z))
    
    Debug.TrackFunctionEnd("Stack.GetSafePosition")
    return safePos
end

-- Register handler functions with Registry
if Olympus.Dungeons.Registry then
    Olympus.Dungeons.Registry.RegisterHandlerFunctions(
        Olympus.Dungeons.MECHANIC_TYPES.STACK,
        Stack.NeedsHandling,
        Stack.GetSafePosition
    )
end
