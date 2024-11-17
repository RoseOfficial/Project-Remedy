-- Initialize Olympus if needed
Olympus = Olympus or {}
Olympus.Dungeons = Olympus.Dungeons or {}

local AOE = {}

---Check if AOE mechanic needs to be handled
---@param mechanic table The mechanic definition
---@return boolean needsHandling Whether the mechanic needs to be handled
function AOE.NeedsHandling(mechanic)
    Debug.TrackFunctionStart("AOE.NeedsHandling")
    
    -- Validate mechanic has required fields
    if not mechanic or not mechanic.sourceId then
        Debug.Verbose(Debug.CATEGORIES.DUNGEONS, "Invalid AOE mechanic definition")
        Debug.TrackFunctionEnd("AOE.NeedsHandling")
        return false
    end
    
    -- Get AOE source
    local source = EntityList:Get(mechanic.sourceId)
    if not source then 
        Debug.Verbose(Debug.CATEGORIES.DUNGEONS, "AOE source not found")
        Debug.TrackFunctionEnd("AOE.NeedsHandling")
        return false 
    end
    
    -- Check if we're in AOE range
    local distance = Player.pos:dist(source.pos)
    Debug.Verbose(Debug.CATEGORIES.DUNGEONS, 
        string.format("Distance from AOE source: %.2f yalms", distance))
    
    -- Use mechanic radius if specified, otherwise use default safe distance
    local safeDistance = mechanic.radius or Olympus.Dungeons.SAFE_DISTANCES.AOE
    local needsHandling = distance < safeDistance
    
    Debug.TrackFunctionEnd("AOE.NeedsHandling")
    return needsHandling
end

---Calculate safe position for AOE mechanic
---@param mechanic table The mechanic definition
---@return table|nil position The safe position to move to, or nil if no movement needed
function AOE.GetSafePosition(mechanic)
    Debug.TrackFunctionStart("AOE.GetSafePosition")
    
    -- Get AOE source
    local source = EntityList:Get(mechanic.sourceId)
    if not source then 
        Debug.Verbose(Debug.CATEGORIES.DUNGEONS, "AOE source not found")
        Debug.TrackFunctionEnd("AOE.GetSafePosition")
        return nil
    end
    
    -- Calculate direction away from source
    local dir = {
        x = Player.pos.x - source.pos.x,
        y = Player.pos.y - source.pos.y,
        z = Player.pos.z - source.pos.z
    }
    
    -- Normalize direction vector
    local length = math.sqrt(dir.x * dir.x + dir.y * dir.y + dir.z * dir.z)
    if length == 0 then
        Debug.Warn(Debug.CATEGORIES.DUNGEONS, "Cannot calculate AOE escape direction")
        Debug.TrackFunctionEnd("AOE.GetSafePosition")
        return nil
    end
    
    -- Use mechanic radius if specified, otherwise use default safe distance
    local safeDistance = (mechanic.radius or Olympus.Dungeons.SAFE_DISTANCES.AOE) + 2 -- Add buffer distance
    
    -- Calculate safe position
    local safePos = {
        x = source.pos.x + (dir.x / length) * safeDistance,
        y = source.pos.y + (dir.y / length) * safeDistance,
        z = source.pos.z + (dir.z / length) * safeDistance
    }
    
    Debug.Info(Debug.CATEGORIES.DUNGEONS, 
        string.format("AOE safe position: %.2f, %.2f, %.2f", 
            safePos.x, safePos.y, safePos.z))
    
    Debug.TrackFunctionEnd("AOE.GetSafePosition")
    return safePos
end

---Check if knockback mechanic needs to be handled
---@param mechanic table The mechanic definition
---@return boolean needsHandling Whether the mechanic needs to be handled
function AOE.NeedsKnockbackHandling(mechanic)
    Debug.TrackFunctionStart("AOE.NeedsKnockbackHandling")
    
    -- Check if we have knockback immunity
    if Olympus.HasBuff(Player, Olympus.BUFF_IDS.SURECAST) then
        Debug.Info(Debug.CATEGORIES.DUNGEONS, "Knockback immunity active")
        Debug.TrackFunctionEnd("AOE.NeedsKnockbackHandling")
        return false
    end
    
    -- Use standard AOE handling check with knockback distance
    local originalRadius = mechanic.radius
    mechanic.radius = Olympus.Dungeons.SAFE_DISTANCES.KNOCKBACK
    local needsHandling = AOE.NeedsHandling(mechanic)
    mechanic.radius = originalRadius
    
    Debug.TrackFunctionEnd("AOE.NeedsKnockbackHandling")
    return needsHandling
end

---Calculate safe position for knockback mechanic
---@param mechanic table The mechanic definition
---@return table|nil position The safe position to move to, or nil if no movement needed
function AOE.GetKnockbackSafePosition(mechanic)
    Debug.TrackFunctionStart("AOE.GetKnockbackSafePosition")
    
    -- Use standard AOE position calculation with knockback distance
    local originalRadius = mechanic.radius
    mechanic.radius = Olympus.Dungeons.SAFE_DISTANCES.KNOCKBACK
    local safePos = AOE.GetSafePosition(mechanic)
    mechanic.radius = originalRadius
    
    Debug.TrackFunctionEnd("AOE.GetKnockbackSafePosition")
    return safePos
end

-- Register handler functions with Registry
if Olympus.Dungeons.Registry then
    -- Register AOE handler
    Olympus.Dungeons.Registry.RegisterHandlerFunctions(
        Olympus.Dungeons.MECHANIC_TYPES.AOE,
        AOE.NeedsHandling,
        AOE.GetSafePosition
    )
    
    -- Register Knockback handler
    Olympus.Dungeons.Registry.RegisterHandlerFunctions(
        Olympus.Dungeons.MECHANIC_TYPES.KNOCKBACK,
        AOE.NeedsKnockbackHandling,
        AOE.GetKnockbackSafePosition
    )
end
