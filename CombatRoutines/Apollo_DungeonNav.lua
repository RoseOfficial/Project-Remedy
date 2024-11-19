Apollo = Apollo or {}

Apollo.DungeonNav = {
    -- Navigation state
    state = {
        followingTank = false,
        tankId = 0,
        lastTankPos = nil,
        stuckTimer = 0,
        lastPosition = nil,
        stuckThreshold = 3, -- seconds before considering stuck
        followDistance = 3  -- yalms to maintain from tank
    },

    -- Constants
    TANK_ROLES = {
        PALADIN = 19,
        WARRIOR = 21,
        DARK_KNIGHT = 32,
        GUNBREAKER = 37
    }
}

-- Find and validate tank in party
function Apollo.DungeonNav.FindTank()
    Debug.TrackFunctionStart("Apollo.DungeonNav.FindTank")
    
    local party = EntityList("myparty")
    if not table.valid(party) then
        Debug.Warn(Debug.CATEGORIES.DUNGEONS, "No valid party")
        Debug.TrackFunctionEnd("Apollo.DungeonNav.FindTank")
        return nil
    end
    
    for _, member in pairs(party) do
        -- Check if member is a tank role
        for _, role in pairs(Apollo.DungeonNav.TANK_ROLES) do
            if member.job == role then
                Debug.Info(Debug.CATEGORIES.DUNGEONS, 
                    string.format("Tank found: %s", member.name))
                return member
            end
        end
    end
    
    Debug.Warn(Debug.CATEGORIES.DUNGEONS, "No tank found in party")
    Debug.TrackFunctionEnd("Apollo.DungeonNav.FindTank")
    return nil
end

-- Check if player is stuck
function Apollo.DungeonNav.CheckStuck()
    if not Apollo.DungeonNav.state.lastPosition then
        Apollo.DungeonNav.state.lastPosition = {
            x = Player.pos.x,
            y = Player.pos.y,
            z = Player.pos.z
        }
        Apollo.DungeonNav.state.stuckTimer = os.clock()
        return false
    end

    local currentPos = Player.pos
    local lastPos = Apollo.DungeonNav.state.lastPosition
    local distance = math.sqrt(
        (currentPos.x - lastPos.x)^2 +
        (currentPos.y - lastPos.y)^2 +
        (currentPos.z - lastPos.z)^2
    )

    -- If barely moved and trying to move
    if distance < 0.1 and Player:IsMoving() then
        if os.clock() - Apollo.DungeonNav.state.stuckTimer > Apollo.DungeonNav.state.stuckThreshold then
            Debug.Info(Debug.CATEGORIES.DUNGEONS, "Detected stuck state")
            return true
        end
    else
        -- Reset stuck timer if moving
        Apollo.DungeonNav.state.stuckTimer = os.clock()
        Apollo.DungeonNav.state.lastPosition = {
            x = currentPos.x,
            y = currentPos.y,
            z = currentPos.z
        }
    end
    
    return false
end

-- Handle navigation when stuck
function Apollo.DungeonNav.HandleStuckState()
    Debug.Info(Debug.CATEGORIES.DUNGEONS, "Attempting to resolve stuck state")
    
    -- Try to move slightly to the side
    local currentPos = Player.pos
    local offset = 2 -- yalms
    local newPos = {
        x = currentPos.x + offset,
        y = currentPos.y,
        z = currentPos.z
    }
    
    Player:MoveTo(newPos.x, newPos.y, newPos.z)
    return true
end

-- Main navigation function
function Apollo.DungeonNav.Navigate()
    Debug.TrackFunctionStart("Apollo.DungeonNav.Navigate")
    
    -- First priority: Handle active mechanics using Olympus system
    if Olympus.Dungeons.CheckMechanics() then
        local safePos = Olympus.Dungeons.GetSafePosition()
        if safePos then
            Debug.Info(Debug.CATEGORIES.DUNGEONS, "Moving to safe position for mechanic")
            Player:MoveTo(safePos.x, safePos.y, safePos.z)
            Debug.TrackFunctionEnd("Apollo.DungeonNav.Navigate")
            return true
        end
    end
    
    -- Check if stuck
    if Apollo.DungeonNav.CheckStuck() then
        Debug.TrackFunctionEnd("Apollo.DungeonNav.Navigate")
        return Apollo.DungeonNav.HandleStuckState()
    end
    
    -- Find and follow tank
    local tank = Apollo.DungeonNav.FindTank()
    if tank then
        Apollo.DungeonNav.state.tankId = tank.id
        Apollo.DungeonNav.state.lastTankPos = tank.pos
        
        local distance = Player.pos:dist(tank.pos)
        if distance > Apollo.DungeonNav.state.followDistance then
            Debug.Info(Debug.CATEGORIES.DUNGEONS, 
                string.format("Following tank at distance: %.2f", distance))
            Player:MoveTo(tank.pos.x, tank.pos.y, tank.pos.z)
            Apollo.DungeonNav.state.followingTank = true
            Debug.TrackFunctionEnd("Apollo.DungeonNav.Navigate")
            return true
        else
            Apollo.DungeonNav.state.followingTank = false
        end
    else
        -- Fallback: If no tank, try to stay with party
        local partyPos = Olympus.Dungeons.GetAveragePartyPosition()
        if partyPos then
            local distance = Player.pos:dist2d(partyPos)
            if distance > Apollo.DungeonNav.state.followDistance then
                Debug.Info(Debug.CATEGORIES.DUNGEONS, "Following party average position")
                Player:MoveTo(partyPos.x, partyPos.y, partyPos.z)
                Debug.TrackFunctionEnd("Apollo.DungeonNav.Navigate")
                return true
            end
        end
    end
    
    Debug.Verbose(Debug.CATEGORIES.DUNGEONS, "No navigation needed")
    Debug.TrackFunctionEnd("Apollo.DungeonNav.Navigate")
    return false
end

return Apollo.DungeonNav
