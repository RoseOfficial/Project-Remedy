---Get party members including trust NPCs within range
---@param maxDistance number Maximum distance to consider party members (default: 30)
---@return table party Table of party members keyed by entity ID
function Olympus.GetParty(maxDistance)
    Debug.TrackFunctionStart("Olympus.GetParty")
    
    maxDistance = maxDistance or 30
    local party = {}
    
    -- Add player to party list
    party[Player.id] = Player
    Debug.Verbose(Debug.CATEGORIES.SYSTEM, "Added player to party list")
    
    -- Add Party members
    local partyMembers = EntityList("myparty,alive,maxdistance=" .. maxDistance)
    if table.valid(partyMembers) then
        for id, member in pairs(partyMembers) do
            party[id] = member
            Debug.Verbose(Debug.CATEGORIES.SYSTEM, 
                string.format("Added party member: %s (ID: %d)", 
                    member.name or "Unknown",
                    id))
        end
    else
        Debug.Verbose(Debug.CATEGORIES.SYSTEM, "No valid party members found")
    end
    
    -- Add trust NPCs
    local npcTeam = EntityList("alive,chartype=9,targetable,maxdistance=" .. maxDistance)
    if table.valid(npcTeam) then
        for id, entity in pairs(npcTeam) do
            party[id] = entity
            Debug.Verbose(Debug.CATEGORIES.SYSTEM, 
                string.format("Added trust NPC: %s (ID: %d)", 
                    entity.name or "Unknown",
                    id))
        end
    else
        Debug.Verbose(Debug.CATEGORIES.SYSTEM, "No trust NPCs found")
    end
    
    Debug.Info(Debug.CATEGORIES.SYSTEM, 
        string.format("Party formed with %d members (Range: %d)", 
            table.size(party),
            maxDistance))
            
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
