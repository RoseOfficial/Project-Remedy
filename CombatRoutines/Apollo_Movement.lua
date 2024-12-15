Apollo.Movement = {}

function Apollo.Movement.Handle()
    Debug.TrackFunctionStart("Apollo.HandleMovement")
    
    -- Handle Sprint (now only requires movement)
    if Player:IsMoving() then
        Debug.Verbose(Debug.CATEGORIES.MOVEMENT, "Player is moving, checking Sprint")
        if Olympus.HandleSprint() then 
            Debug.Info(Debug.CATEGORIES.MOVEMENT, "Sprint activated")
            Debug.TrackFunctionEnd("Apollo.HandleMovement")
            return true 
        end
    end

    -- Handle Aetherial Shift for emergency movement
    if Player.level < Apollo.Constants.SPELLS.AETHERIAL_SHIFT.level then
        Debug.Verbose(Debug.CATEGORIES.MOVEMENT, "Level too low for Aetherial Shift")
        Debug.TrackFunctionEnd("Apollo.HandleMovement")
        return false 
    end
    
    if Player.bound then
        Debug.Verbose(Debug.CATEGORIES.MOVEMENT, "Player is bound, cannot use Aetherial Shift")
        Debug.TrackFunctionEnd("Apollo.HandleMovement")
        return false 
    end

    local party = Olympus.GetParty(45)
    if table.valid(party) then
        Debug.Verbose(Debug.CATEGORIES.MOVEMENT, "Checking party members for Aetherial Shift")
        for _, member in pairs(party) do
            if member.hp.percent <= Apollo.Constants.SETTINGS.CureIIThreshold 
                and member.distance2d > Apollo.Constants.SETTINGS.HealingRange 
            and member.distance2d <= (Apollo.Constants.SETTINGS.HealingRange + 15) then
                Debug.Info(Debug.CATEGORIES.MOVEMENT, 
                    string.format("Using Aetherial Shift to reach %s (HP: %.1f%%, Distance: %.1f)", 
                        member.name or "Unknown",
                        member.hp.percent,
                        member.distance2d))
                local result = Olympus.CastAction(Apollo.Constants.SPELLS.AETHERIAL_SHIFT)
                Debug.TrackFunctionEnd("Apollo.HandleMovement")
                return result
            end
        end
    else
        Debug.Verbose(Debug.CATEGORIES.MOVEMENT, "No valid party members in extended range")
    end

    Debug.Verbose(Debug.CATEGORIES.MOVEMENT, "No movement actions needed")
    Debug.TrackFunctionEnd("Apollo.HandleMovement")
    return false
end
