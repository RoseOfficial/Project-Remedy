-- Initialize Olympus if needed
Olympus = Olympus or {}
Olympus.Dungeons = Olympus.Dungeons or {}

local Spread = {}

---Check if spread mechanic needs to be handled
---@param mechanic table The mechanic definition
---@return boolean needsHandling Whether the mechanic needs to be handled
function Spread.NeedsHandling(mechanic)
    Debug.TrackFunctionStart("Spread.NeedsHandling")
    
    -- Get party members
    local partyList = EntityList("myparty")
    if not partyList then 
        Debug.Verbose(Debug.CATEGORIES.DUNGEONS, "No party members found")
        Debug.TrackFunctionEnd("Spread.NeedsHandling")
        return false 
    end
    
    -- Check distance to all party members
    for _, member in pairs(partyList) do
        if member.id ~= Player.id then
            local distance = Player.pos:dist(member.pos)
            Debug.Verbose(Debug.CATEGORIES.DUNGEONS, 
                string.format("Distance to party member %d: %.2f yalms", 
                    member.id, distance))
            
            -- If too close to any member, need to spread
            if distance < Olympus.Dungeons.SAFE_DISTANCES.SPREAD then
                Debug.Info(Debug.CATEGORIES.DUNGEONS, "Need to spread out")
                Debug.TrackFunctionEnd("Spread.NeedsHandling")
                return true
            end
        end
    end
    
    Debug.TrackFunctionEnd("Spread.NeedsHandling")
    return false
end

---Calculate safe position for spread mechanic
---@param mechanic table The mechanic definition
---@return table|nil position The safe position to move to, or nil if no movement needed
function Spread.GetSafePosition(mechanic)
    Debug.TrackFunctionStart("Spread.GetSafePosition")
    
    -- Get party members
    local partyList = EntityList("myparty")
    if not partyList then 
        Debug.Verbose(Debug.CATEGORIES.DUNGEONS, "No party members found")
        Debug.TrackFunctionEnd("Spread.GetSafePosition")
        return nil
    end
    
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
    
    if count == 0 then
        Debug.Verbose(Debug.CATEGORIES.DUNGEONS, "No other party members to spread from")
        Debug.TrackFunctionEnd("Spread.GetSafePosition")
        return nil
    end
    
    -- Calculate center of party members
    avgPos.x = avgPos.x / count
    avgPos.y = avgPos.y / count
    avgPos.z = avgPos.z / count
    
    -- Calculate direction away from party center
    local dir = {
        x = Player.pos.x - avgPos.x,
        y = Player.pos.y - avgPos.y,
        z = Player.pos.z - avgPos.z
    }
    
    -- Normalize direction vector
    local length = math.sqrt(dir.x * dir.x + dir.y * dir.y + dir.z * dir.z)
    if length == 0 then
        Debug.Warn(Debug.CATEGORIES.DUNGEONS, "Cannot calculate spread direction")
        Debug.TrackFunctionEnd("Spread.GetSafePosition")
        return nil
    end
    
    -- Calculate safe position
    local safePos = {
        x = Player.pos.x + (dir.x / length) * Olympus.Dungeons.SAFE_DISTANCES.SPREAD,
        y = Player.pos.y + (dir.y / length) * Olympus.Dungeons.SAFE_DISTANCES.SPREAD,
        z = Player.pos.z + (dir.z / length) * Olympus.Dungeons.SAFE_DISTANCES.SPREAD
    }
    
    Debug.Info(Debug.CATEGORIES.DUNGEONS, 
        string.format("Spread safe position: %.2f, %.2f, %.2f", 
            safePos.x, safePos.y, safePos.z))
    
    Debug.TrackFunctionEnd("Spread.GetSafePosition")
    return safePos
end

-- Register handler functions with Registry
if Olympus.Dungeons.Registry then
    Olympus.Dungeons.Registry.RegisterHandlerFunctions(
        Olympus.Dungeons.MECHANIC_TYPES.SPREAD,
        Spread.NeedsHandling,
        Spread.GetSafePosition
    )
end
