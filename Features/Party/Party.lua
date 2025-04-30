-- Party
Olympus = Olympus or {}
Olympus.Party = Olympus.Party or {}

-- Store previous party state
local previousParty = {}
local hadPartyMembers = false

---Initialize the Party module
function Olympus.Party.Initialize()
    Debug.TrackFunctionStart("Olympus.Party.Initialize")
    Debug.Info(Debug.CATEGORIES.SYSTEM, "Initializing Party module...")
    
    -- Initialize party tracking
    previousParty = {}
    hadPartyMembers = false
    
    Debug.Info(Debug.CATEGORIES.SYSTEM, "Party module initialized successfully")
    Debug.TrackFunctionEnd("Olympus.Party.Initialize")
end

---Get party members including trust NPCs within range
---@param maxDistance number Maximum distance to consider party members (default: 30)
---@return table party Table of party members keyed by entity ID
function Olympus.GetParty(maxDistance)
    Debug.TrackFunctionStart("Olympus.GetParty")
    
    maxDistance = maxDistance or 30
    local party = {}
    local partyChanged = false
    
    -- Add player to party list
    party[Player.id] = Player
    if not previousParty[Player.id] then
        Debug.Verbose(Debug.CATEGORIES.SYSTEM, "Added player to party list")
        partyChanged = true
    end
    
    -- Add Party members
    local partyMembers = EntityList("myparty,alive,maxdistance=" .. maxDistance)
    local hasPartyMembers = table.valid(partyMembers)
    
    if hasPartyMembers then
        for id, member in pairs(partyMembers) do
            party[id] = member
            if not previousParty[id] then
                Debug.Verbose(Debug.CATEGORIES.SYSTEM, 
                    string.format("Added party member: %s (ID: %d)", 
                        member.name or "Unknown",
                        id))
                partyChanged = true
            end
        end
    elseif hadPartyMembers then
        -- Only log when transitioning from having members to no members
        Debug.Verbose(Debug.CATEGORIES.SYSTEM, "No valid party members found")
        partyChanged = true
    end
    
    -- Update party members state
    hadPartyMembers = hasPartyMembers
    
    -- Add trust NPCs
    local npcTeam = EntityList("alive,chartype=9,targetable,maxdistance=" .. maxDistance)
    if table.valid(npcTeam) then
        for id, entity in pairs(npcTeam) do
            party[id] = entity
            if not previousParty[id] then
                Debug.Verbose(Debug.CATEGORIES.SYSTEM, 
                    string.format("Added trust NPC: %s (ID: %d)", 
                        entity.name or "Unknown",
                        id))
                partyChanged = true
            end
        end
    end
    
    -- Check for removed members
    for id, member in pairs(previousParty) do
        if not party[id] then
            Debug.Verbose(Debug.CATEGORIES.SYSTEM, 
                string.format("Removed member: %s (ID: %d)", 
                    member.name or "Unknown",
                    id))
            partyChanged = true
        end
    end
    
    -- Only log party formation message if the composition changed
    if partyChanged then
        Debug.Verbose(Debug.CATEGORIES.SYSTEM, 
            string.format("Party formed with %d members (Range: %d)", 
                table.size(party),
                maxDistance))
    end
    
    -- Update previous party state
    previousParty = {}
    for id, member in pairs(party) do
        previousParty[id] = member
    end
            
    Debug.TrackFunctionEnd("Olympus.GetParty")
    return party
end

---Check party members for AoE healing requirements
---@param party table Party members to check
---@param threshold number HP threshold to consider for healing
---@param range number Range to check for healing
---@return number count Number of members needing healing
---@return table|nil lowest Lowest HP member within range
function Olympus.HandleAoEHealCheck(party, threshold, range)
    Debug.TrackFunctionStart("Olympus.HandleAoEHealCheck")
    
    if not table.valid(party) then 
        Debug.Verbose(Debug.CATEGORIES.HEALING, "No valid party members to check")
        Debug.TrackFunctionEnd("Olympus.HandleAoEHealCheck")
        return 0, nil 
    end
    
    local count = 0
    local lowestHP = 100
    local lowestMember = nil
    
    Debug.Verbose(Debug.CATEGORIES.HEALING, 
        string.format("Checking party (Threshold: %.1f%%, Range: %d)", 
            threshold,
            range))
    
    for _, member in pairs(party) do
        if member.hp.percent <= threshold and member.distance2d <= range then
            count = count + 1
            Debug.Verbose(Debug.CATEGORIES.HEALING, 
                string.format("Member needs healing: %s (HP: %.1f%%)", 
                    member.name or "Unknown",
                    member.hp.percent))
            
            if member.hp.percent < lowestHP then
                lowestHP = member.hp.percent
                lowestMember = member
                Debug.Verbose(Debug.CATEGORIES.HEALING, 
                    string.format("New lowest member: %s (HP: %.1f%%)", 
                        member.name or "Unknown",
                        member.hp.percent))
            end
        end
    end
    
    Debug.Info(Debug.CATEGORIES.HEALING, 
        string.format("AoE heal check - Members needing heal: %d, Lowest HP: %.1f%%", 
            count,
            lowestMember and lowestMember.hp.percent or 100))
            
    Debug.TrackFunctionEnd("Olympus.HandleAoEHealCheck")
    return count, lowestMember
end
