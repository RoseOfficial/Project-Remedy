-- Initialize Olympus if needed
Olympus = Olympus or {}
Olympus.Dungeons = Olympus.Dungeons or {}

local Defensive = {}

---Check if tankbuster mechanic needs to be handled
---@param mechanic table The mechanic definition
---@return boolean needsHandling Whether the mechanic needs to be handled
function Defensive.NeedsTankbusterHandling(mechanic)
    Debug.TrackFunctionStart("Defensive.NeedsTankbusterHandling")
    
    -- Only react if we're the target
    if not mechanic or mechanic.targetId ~= Player.id then 
        Debug.Verbose(Debug.CATEGORIES.DUNGEONS, "Not tankbuster target")
        Debug.TrackFunctionEnd("Defensive.NeedsTankbusterHandling")
        return false 
    end
    
    -- Check if we need defensive cooldowns
    local healthPercent = Player.hp.percent
    Debug.Info(Debug.CATEGORIES.DUNGEONS, 
        string.format("Tankbuster incoming, health at %.1f%%", healthPercent))
    
    local needsHandling = healthPercent < 80
    
    Debug.TrackFunctionEnd("Defensive.NeedsTankbusterHandling")
    return needsHandling
end

---Check if raidwide mechanic needs to be handled
---@param mechanic table The mechanic definition
---@return boolean needsHandling Whether the mechanic needs to be handled
function Defensive.NeedsRaidwideHandling(mechanic)
    Debug.TrackFunctionStart("Defensive.NeedsRaidwideHandling")
    
    -- Check party health
    local partyList = EntityList("myparty")
    if not partyList then 
        Debug.Verbose(Debug.CATEGORIES.DUNGEONS, "No party members found")
        Debug.TrackFunctionEnd("Defensive.NeedsRaidwideHandling")
        return false 
    end
    
    -- Count party members below health threshold
    local lowHealthCount = 0
    local healthThreshold = 80
    
    for _, member in pairs(partyList) do
        if member.hp.percent < healthThreshold then
            lowHealthCount = lowHealthCount + 1
            Debug.Verbose(Debug.CATEGORIES.DUNGEONS, 
                string.format("Party member %d at %.1f%% health", 
                    member.id, member.hp.percent))
        end
    end
    
    -- Need handling if multiple members are low
    local needsHandling = lowHealthCount >= 2
    
    if needsHandling then
        Debug.Info(Debug.CATEGORIES.DUNGEONS, 
            string.format("%d party members below %d%% health", 
                lowHealthCount, healthThreshold))
    end
    
    Debug.TrackFunctionEnd("Defensive.NeedsRaidwideHandling")
    return needsHandling
end

---Get safe position for defensive mechanics (usually nil as these don't require movement)
---@param mechanic table The mechanic definition
---@return nil Always returns nil as defensive mechanics don't require movement
function Defensive.GetSafePosition(mechanic)
    return nil
end

-- Register handler functions with Registry
if Olympus.Dungeons.Registry then
    -- Register Tankbuster handler
    Olympus.Dungeons.Registry.RegisterHandlerFunctions(
        Olympus.Dungeons.MECHANIC_TYPES.TANKBUSTER,
        Defensive.NeedsTankbusterHandling,
        Defensive.GetSafePosition
    )
    
    -- Register Raidwide handler
    Olympus.Dungeons.Registry.RegisterHandlerFunctions(
        Olympus.Dungeons.MECHANIC_TYPES.RAIDWIDE,
        Defensive.NeedsRaidwideHandling,
        Defensive.GetSafePosition
    )
end
