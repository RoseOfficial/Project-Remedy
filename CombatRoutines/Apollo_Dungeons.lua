-- Sastasha dungeon mechanics for Apollo combat routine
local Apollo = Apollo or {}
Apollo.Dungeons = {}

-- Sastasha dungeon name
local SASTASHA_ID = "Sastasha"

-- Register mechanics when the module loads
function Apollo.Dungeons.Initialize()
    Debug.Info("DUNGEONS", "Initializing Sastasha dungeon mechanics")
    
    -- Sastasha mechanics
    local sastashaMechanics = {
        -- Captain Madison's mechanics
        [1] = {
            type = Olympus.Dungeons.MECHANIC_TYPES.DODGE,
            name = "Slashing Resistance Down",
            castId = 569,
            position = nil, -- Will be set during combat
            radius = 5
        },
        
        -- Chopper's mechanics
        [2] = {
            type = Olympus.Dungeons.MECHANIC_TYPES.TANKBUSTER,
            name = "Clamp",
            castId = 570,
            targetId = 0 -- Will be set during combat
        },
        
        -- Denn the Orcatoothed's mechanics
        [3] = {
            type = Olympus.Dungeons.MECHANIC_TYPES.AOE,
            name = "Sahagin Call",
            castId = 571,
            sourceId = 0, -- Will be set during combat
            radius = 8
        },
        
        -- Bubble Bomb mechanic
        [4] = {
            type = Olympus.Dungeons.MECHANIC_TYPES.SPREAD,
            name = "Bubble Bomb",
            castId = 572,
            radius = 5
        },
        
        -- Clamp target mechanic
        [5] = {
            type = Olympus.Dungeons.MECHANIC_TYPES.STACK,
            name = "Clamp Target",
            castId = 573,
            targetId = 0 -- Will be set during combat
        }
    }
    
    -- Register mechanics with the dungeon handler
    Olympus.Dungeons.RegisterMechanics(SASTASHA_ID, sastashaMechanics)
    Debug.Info("DUNGEONS", string.format("Registered %d mechanics for Sastasha", #sastashaMechanics))
end

-- Update mechanic data during combat
function Apollo.Dungeons.UpdateMechanics()
    Debug.TrackFunctionStart("Apollo.Dungeons.UpdateMechanics")
    
    -- Only process if we're in Sastasha
    if Olympus.Dungeons.current.id ~= SASTASHA_ID then
        Debug.TrackFunctionEnd("Apollo.Dungeons.UpdateMechanics")
        return
    end
    
    local currentTarget = Player:GetTarget()
    if not currentTarget then 
        Debug.Verbose("DUNGEONS", "No current target found")
        Debug.TrackFunctionEnd("Apollo.Dungeons.UpdateMechanics")
        return 
    end
    
    -- Check for casting mechanics
    if currentTarget.castinginfo then
        local castId = currentTarget.castinginfo.castingid
        Debug.Info("DUNGEONS", string.format("Detected cast ID %d from target %s", castId, currentTarget.name))
        
        local mechanics = Olympus.Dungeons.mechanics[SASTASHA_ID]
        
        -- Update mechanic data based on cast
        for _, mechanic in pairs(mechanics) do
            if mechanic.castId == castId then
                Debug.Info("DUNGEONS", string.format("Processing mechanic: %s", mechanic.name))
                
                -- Update mechanic data based on type
                if mechanic.type == Olympus.Dungeons.MECHANIC_TYPES.DODGE then
                    -- For dodge mechanics, set position to boss location
                    mechanic.position = {
                        x = currentTarget.pos.x,
                        y = currentTarget.pos.y,
                        z = currentTarget.pos.z
                    }
                    Debug.Info("DUNGEONS", string.format("Updated dodge position for %s: x=%.2f, y=%.2f, z=%.2f", 
                        mechanic.name, mechanic.position.x, mechanic.position.y, mechanic.position.z))
                    
                elseif mechanic.type == Olympus.Dungeons.MECHANIC_TYPES.TANKBUSTER or
                       mechanic.type == Olympus.Dungeons.MECHANIC_TYPES.STACK then
                    -- For targeted mechanics, find the marked player
                    local partyList = EntityList("myparty")
                    if (partyList) then
                        for _, member in pairs(partyList) do
                            if member.marked then
                                mechanic.targetId = member.id
                                Debug.Info("DUNGEONS", string.format("Updated target for %s: ID=%d", mechanic.name, member.id))
                                break
                            end
                        end
                    end
                    
                elseif mechanic.type == Olympus.Dungeons.MECHANIC_TYPES.AOE then
                    -- For AOE mechanics, set source to caster
                    mechanic.sourceId = currentTarget.id
                    Debug.Info("DUNGEONS", string.format("Updated AOE source for %s: ID=%d", mechanic.name, currentTarget.id))
                end
                break
            end
        end
    end
    
    Debug.TrackFunctionEnd("Apollo.Dungeons.UpdateMechanics")
end

-- Handle specific Sastasha events
function Apollo.Dungeons.HandleSastastaEvents()
    Debug.TrackFunctionStart("Apollo.Dungeons.HandleSastastaEvents")
    
    -- Only process if we're in Sastasha
    if Olympus.Dungeons.current.id ~= SASTASHA_ID then
        Debug.TrackFunctionEnd("Apollo.Dungeons.HandleSastastaEvents")
        return
    end
    
    -- Check for Bubble Bombs
    local entityList = EntityList("targetable,maxdistance=30")
    if (entityList) then
        for _, entity in pairs(entityList) do
            -- Check for Bubble Bomb adds
            if entity.name == "Bubble Bomb" then
                Debug.Info("DUNGEONS", string.format("Detected Bubble Bomb at position: x=%.2f, y=%.2f, z=%.2f", 
                    entity.pos.x, entity.pos.y, entity.pos.z))
                
                -- Trigger spread mechanic
                local mechanics = Olympus.Dungeons.mechanics[SASTASHA_ID]
                for _, mechanic in pairs(mechanics) do
                    if mechanic.name == "Bubble Bomb" then
                        Olympus.Dungeons.current.mechanicActive = true
                        Olympus.Dungeons.current.activeMechanicId = 4 -- Bubble Bomb mechanic ID
                        Debug.Info("DUNGEONS", "Activated Bubble Bomb spread mechanic")
                        break
                    end
                end
                break
            end
        end
    end
    
    Debug.TrackFunctionEnd("Apollo.Dungeons.HandleSastastaEvents")
end

return Apollo.Dungeons
