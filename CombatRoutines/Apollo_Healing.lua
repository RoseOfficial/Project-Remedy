-- Apollo Healing
-- Main healing coordinator that orchestrates different healing strategies

Apollo.Healing = {}

-- Order of healing priority:
-- 1. Emergency healing (Benediction, Tetragrammaton)
-- 2. Mitigation (Aquaveil, Divine Benison, Temperance)
-- 3. AoE healing (Cure III, Asylum, Liturgy, Medica)
-- 4. Single target healing (Regen, Cure spells)

function Apollo.Healing.Handle()
    Debug.TrackFunctionStart("Apollo.HandleHealing")

    -- Emergency healing takes highest priority
    if Apollo.Healing.Emergency.Handle() then
        Debug.TrackFunctionEnd("Apollo.HandleHealing")
        return true
    end

    -- Mitigation is second priority
    if Apollo.Healing.Mitigation.Handle() then
        Debug.TrackFunctionEnd("Apollo.HandleHealing")
        return true
    end

    -- AoE healing is third priority
    if Apollo.Healing.AoE.Handle() then
        Debug.TrackFunctionEnd("Apollo.HandleHealing")
        return true
    end

    -- Single target healing is lowest priority
    if Apollo.Healing.SingleTarget.Handle() then
        Debug.TrackFunctionEnd("Apollo.HandleHealing")
        return true
    end

    Debug.Verbose(Debug.CATEGORIES.HEALING, "No healing actions needed")
    Debug.TrackFunctionEnd("Apollo.HandleHealing")
    return false
end
