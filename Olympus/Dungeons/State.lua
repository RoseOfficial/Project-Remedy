-- Initialize Olympus if needed
Olympus = Olympus or {}
Olympus.Dungeons = Olympus.Dungeons or {}

local State = {
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
    }
}

---Initialize or reset the dungeon state
function State.Initialize()
    Debug.TrackFunctionStart("State.Initialize")
    
    -- Reset state to defaults
    State.current.id = 0
    State.current.name = ""
    State.current.inDungeon = false
    State.current.bossActive = false
    State.current.currentBossId = 0
    State.current.mechanicActive = false
    State.current.activeMechanicId = 0
    State.current.lastMechanicTime = 0
    
    Debug.Info(Debug.CATEGORIES.DUNGEONS, "Dungeon state initialized")
    Debug.TrackFunctionEnd("State.Initialize")
end

---Update the current dungeon state
---@return boolean stateChanged Whether the dungeon state changed
function State.Update()
    Debug.TrackFunctionStart("State.Update")
    
    local stateChanged = false
    local player = Player
    
    if not player then
        Debug.Warn(Debug.CATEGORIES.DUNGEONS, "Invalid player object")
        Debug.TrackFunctionEnd("State.Update")
        return false
    end
    
    -- Check if we're in a dungeon
    local newInDungeon = player.incombat and player.ininstance
    if newInDungeon ~= State.current.inDungeon then
        State.current.inDungeon = newInDungeon
        stateChanged = true
        Debug.Info(Debug.CATEGORIES.DUNGEONS, 
            string.format("Dungeon state changed: %s", 
                newInDungeon and "Entered dungeon" or "Left dungeon"))
    end
    
    -- Update boss state if in dungeon
    if State.current.inDungeon then
        local currentTarget = Player:GetTarget()
        if currentTarget and currentTarget.type == 2 then -- Boss type
            if currentTarget.id ~= State.current.currentBossId then
                State.current.currentBossId = currentTarget.id
                State.current.bossActive = true
                stateChanged = true
                Debug.Info(Debug.CATEGORIES.DUNGEONS, 
                    string.format("New boss encountered: %s (ID: %d)", 
                        currentTarget.name or "Unknown", currentTarget.id))
            end
        else
            if State.current.bossActive then
                State.current.bossActive = false
                State.current.currentBossId = 0
                stateChanged = true
                Debug.Info(Debug.CATEGORIES.DUNGEONS, "Boss fight ended")
            end
        end
    end
    
    Debug.TrackFunctionEnd("State.Update")
    return stateChanged
end

---Set active mechanic state
---@param mechanicId number The ID of the active mechanic
function State.SetActiveMechanic(mechanicId)
    Debug.TrackFunctionStart("State.SetActiveMechanic")
    
    State.current.mechanicActive = true
    State.current.activeMechanicId = mechanicId
    State.current.lastMechanicTime = os.clock()
    
    Debug.Info(Debug.CATEGORIES.DUNGEONS, 
        string.format("Set active mechanic: %d", mechanicId))
    
    Debug.TrackFunctionEnd("State.SetActiveMechanic")
end

---Clear active mechanic state
function State.ClearActiveMechanic()
    Debug.TrackFunctionStart("State.ClearActiveMechanic")
    
    State.current.mechanicActive = false
    State.current.activeMechanicId = 0
    
    Debug.Info(Debug.CATEGORIES.DUNGEONS, "Cleared active mechanic")
    
    Debug.TrackFunctionEnd("State.ClearActiveMechanic")
end

---Check if mechanic checks are on cooldown
---@return boolean onCooldown Whether mechanic checks are on cooldown
function State.IsMechanicCheckOnCooldown()
    return os.clock() - State.current.lastMechanicTime < 1.5
end

-- Make State available through Olympus.Dungeons
Olympus.Dungeons.State = State

-- Make current state directly accessible through Olympus.Dungeons
Olympus.Dungeons.current = State.current
