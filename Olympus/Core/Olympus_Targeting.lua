---Check if an entity can be cleansed with Esuna
---@param entity table The entity to check
---@return boolean isDebuffable Whether the entity has a cleansable debuff
function Olympus.IsDebuffable(entity)
    Debug.TrackFunctionStart("Olympus.IsDebuffable")
    
    if not entity or not entity.buffs then 
        Debug.Verbose(Debug.CATEGORIES.COMBAT, "Invalid entity or no buffs table")
        Debug.TrackFunctionEnd("Olympus.IsDebuffable")
        return false 
    end
    
    for _, buff in pairs(entity.buffs) do
        if buff.dispellable then
            Debug.Info(Debug.CATEGORIES.COMBAT, 
                string.format("Found dispellable debuff on %s", 
                    entity.name or "Unknown"))
            Debug.TrackFunctionEnd("Olympus.IsDebuffable")
            return true
        end
    end
    
    Debug.Verbose(Debug.CATEGORIES.COMBAT, "No dispellable debuffs found")
    Debug.TrackFunctionEnd("Olympus.IsDebuffable")
    return false
end

---Check if a target needs DoT application
---@param target table The target to check
---@param dotBuffIds table Table of valid DoT buff IDs
---@param timeThreshold number Time threshold in seconds to consider refreshing
---@return boolean needsDoT Whether the target needs a DoT
function Olympus.NeedsDoT(target, dotBuffIds, timeThreshold)
    Debug.TrackFunctionStart("Olympus.NeedsDoT")
    
    if not target or not target.buffs then 
        Debug.Verbose(Debug.CATEGORIES.COMBAT, "Invalid target or no buffs table")
        Debug.TrackFunctionEnd("Olympus.NeedsDoT")
        return true 
    end
    
    timeThreshold = timeThreshold or 3
    
    for _, buff in pairs(target.buffs) do
        if dotBuffIds[buff.id] and buff.ownerid == Player.id then
            local needsRefresh = buff.duration <= timeThreshold
            Debug.Info(Debug.CATEGORIES.COMBAT, 
                string.format("DoT check on %s - Duration: %.1fs, Needs refresh: %s", 
                    target.name or "Unknown",
                    buff.duration,
                    tostring(needsRefresh)))
            Debug.TrackFunctionEnd("Olympus.NeedsDoT")
            return needsRefresh
        end
    end
    
    Debug.Verbose(Debug.CATEGORIES.COMBAT, "No existing DoT found")
    Debug.TrackFunctionEnd("Olympus.NeedsDoT")
    return true
end

---Find a target that needs DoT application
---@param dotBuffIds table Table of valid DoT buff IDs
---@param range number Maximum range to search
---@param timeThreshold number Time threshold in seconds to consider refreshing
---@return table|nil target The target that needs a DoT, or nil if none found
function Olympus.FindTargetForDoT(dotBuffIds, range, timeThreshold)
    Debug.TrackFunctionStart("Olympus.FindTargetForDoT")
    
    local targets = EntityList("alive,attackable,incombat,maxdistance=" .. (range or 25))
    if not table.valid(targets) then 
        Debug.Verbose(Debug.CATEGORIES.COMBAT, "No valid targets in range")
        Debug.TrackFunctionEnd("Olympus.FindTargetForDoT")
        return nil 
    end
    
    Debug.Verbose(Debug.CATEGORIES.COMBAT, 
        string.format("Checking %d targets for DoT application", 
            table.size(targets)))
    
    for _, target in pairs(targets) do
        if Olympus.NeedsDoT(target, dotBuffIds, timeThreshold) then
            Debug.Info(Debug.CATEGORIES.COMBAT, 
                string.format("Found DoT target: %s", 
                    target.name or "Unknown"))
            Debug.TrackFunctionEnd("Olympus.FindTargetForDoT")
            return target
        end
    end
    
    Debug.Verbose(Debug.CATEGORIES.COMBAT, "No targets need DoT application")
    Debug.TrackFunctionEnd("Olympus.FindTargetForDoT")
    return nil
end

---Find a target for damage spells
---@param dotBuffIds table Table of valid DoT buff IDs
---@param range number Maximum range to search
---@return table|nil target The target for damage spells, or nil if none found
function Olympus.FindTargetForDamage(dotBuffIds, range)
    Debug.TrackFunctionStart("Olympus.FindTargetForDamage")
    
    -- Log input parameters
    Debug.Verbose(Debug.CATEGORIES.DAMAGE, 
        string.format("FindTargetForDamage called with range: %s, DoT IDs: %s",
            tostring(range or 25),
            tostring(table.valid(dotBuffIds) and table.size(dotBuffIds) or "none")))

    -- First check for enemies with aggro
    local searchRange = range or 25
    local filterString = "lowesthealth,alive,attackable,incombat,maxdistance=" .. searchRange
    Debug.Verbose(Debug.CATEGORIES.DAMAGE, 
        string.format("Searching for targets with filter: %s", filterString))
    
    local targets = EntityList(filterString)
    if not table.valid(targets) then
        Debug.Info(Debug.CATEGORIES.DAMAGE, "No valid targets found matching filter criteria")
        Debug.TrackFunctionEnd("Olympus.FindTargetForDamage")
        return nil
    end

    Debug.Info(Debug.CATEGORIES.DAMAGE, 
        string.format("Found %d potential targets in range %d", 
            table.size(targets), searchRange))
    
    -- Log details about each potential target
    for _, target in pairs(targets) do
        -- Debug the distance value
        Debug.Verbose(Debug.CATEGORIES.DAMAGE,
            string.format("Distance debug - Type: %s, Raw value: %s",
                type(target.distance2d),
                tostring(target.distance2d)))
        
        -- Try to get a safe distance value
        local distance = 0
        if target.distance2d then
            if type(target.distance2d) == "number" then
                distance = target.distance2d
            elseif type(target.distance2d) == "function" then
                local status, result = pcall(function() return target.distance2d() end)
                if status and type(result) == "number" then
                    distance = result
                end
            end
        end

        -- Use pcall to safely format the string
        local status, formattedString = pcall(string.format,
            "Potential target: %s (ID: %d) - HP: %.1f%%, Distance: %.1f, Has Aggro: %s",
            target.name or "Unknown",
            target.id or 0,
            target.hp or 0,
            distance,
            tostring(target.aggro or false))
            
        if status then
            Debug.Verbose(Debug.CATEGORIES.DAMAGE, formattedString)
        else
            Debug.Verbose(Debug.CATEGORIES.DAMAGE,
                string.format("Basic target info: %s (ID: %d)",
                    target.name or "Unknown",
                    target.id or 0))
        end
    end
        
    -- Prefer targets that already have DoTs
    Debug.Info(Debug.CATEGORIES.DAMAGE, "Checking for targets with existing DoTs")
    for _, target in pairs(targets) do
        if not Olympus.NeedsDoT(target, dotBuffIds) then
            -- Try to get a safe distance value
            local distance = 0
            if target.distance2d then
                if type(target.distance2d) == "number" then
                    distance = target.distance2d
                elseif type(target.distance2d) == "function" then
                    local status, result = pcall(function() return target.distance2d() end)
                    if status and type(result) == "number" then
                        distance = result
                    end
                end
            end

            -- Use pcall to safely format the string
            local status, formattedString = pcall(string.format,
                "Selected target with DoT: %s (ID: %d) - HP: %.1f%%, Distance: %.1f",
                target.name or "Unknown",
                target.id or 0,
                target.hp or 0,
                distance)
                
            if status then
                Debug.Info(Debug.CATEGORIES.DAMAGE, formattedString)
            else
                Debug.Info(Debug.CATEGORIES.DAMAGE,
                    string.format("Selected target with DoT: %s (ID: %d)",
                        target.name or "Unknown",
                        target.id or 0))
            end
            
            Debug.TrackFunctionEnd("Olympus.FindTargetForDamage")
            return target
        end
    end
    
    -- If no targets with DoTs, return first target
    Debug.Info(Debug.CATEGORIES.DAMAGE, "No targets with DoTs found, selecting first available target")
    for _, target in pairs(targets) do
        -- Try to get a safe distance value
        local distance = 0
        if target.distance2d then
            if type(target.distance2d) == "number" then
                distance = target.distance2d
            elseif type(target.distance2d) == "function" then
                local status, result = pcall(function() return target.distance2d() end)
                if status and type(result) == "number" then
                    distance = result
                end
            end
        end

        -- Use pcall to safely format the string
        local status, formattedString = pcall(string.format,
            "Selected first available target: %s (ID: %d) - HP: %.1f%%, Distance: %.1f",
            target.name or "Unknown",
            target.id or 0,
            target.hp or 0,
            distance)
            
        if status then
            Debug.Info(Debug.CATEGORIES.DAMAGE, formattedString)
        else
            Debug.Info(Debug.CATEGORIES.DAMAGE,
                string.format("Selected first available target: %s (ID: %d)",
                    target.name or "Unknown",
                    target.id or 0))
        end
        
        Debug.TrackFunctionEnd("Olympus.FindTargetForDamage")
        return target
    end

    Debug.Info(Debug.CATEGORIES.DAMAGE, "No valid damage targets found after all checks")
    Debug.TrackFunctionEnd("Olympus.FindTargetForDamage")
    return nil
end
