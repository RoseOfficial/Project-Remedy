Apollo.Buffs = {}

function Apollo.Buffs.Handle()
    Debug.TrackFunctionStart("Apollo.Buffs.Handle")
    
    if not Player.incombat then 
        Debug.Verbose(Debug.CATEGORIES.BUFFS, "Not in combat, skipping buffs")
        Debug.TrackFunctionEnd("Apollo.Buffs.Handle")
        return false 
    end

    -- Presence of Mind
    if Player.level >= Apollo.Constants.SPELLS.PRESENCE_OF_MIND.level then
        local enemies = EntityList("alive,attackable,incombat,maxdistance=25")
        if table.valid(enemies) then
            Debug.Info(Debug.CATEGORIES.BUFFS, "Attempting to cast Presence of Mind")
            if Olympus.CastAction(Apollo.Constants.SPELLS.PRESENCE_OF_MIND) then 
                Debug.TrackFunctionEnd("Apollo.Buffs.Handle")
                return true 
            end
        else
            Debug.Verbose(Debug.CATEGORIES.BUFFS, "No valid enemies for Presence of Mind")
        end
    else
        Debug.Verbose(Debug.CATEGORIES.BUFFS, "Level too low for Presence of Mind")
    end

    -- Thin Air
    if Player.level >= Apollo.Constants.SPELLS.THIN_AIR.level then
        if Player.mp.percent <= Apollo.Constants.SETTINGS.MPThreshold then
            Debug.Info(Debug.CATEGORIES.BUFFS, 
                string.format("MP below threshold (%.1f%%), attempting Thin Air", 
                    Player.mp.percent))
            if Olympus.CastAction(Apollo.Constants.SPELLS.THIN_AIR) then 
                Debug.TrackFunctionEnd("Apollo.Buffs.Handle")
                return true 
            end
        else
            Debug.Verbose(Debug.CATEGORIES.BUFFS, 
                string.format("MP sufficient (%.1f%%), skipping Thin Air", 
                    Player.mp.percent))
        end
    else
        Debug.Verbose(Debug.CATEGORIES.BUFFS, "Level too low for Thin Air")
    end

    Debug.Verbose(Debug.CATEGORIES.BUFFS, "No buffs needed")
    Debug.TrackFunctionEnd("Apollo.Buffs.Handle")
    return false
end
