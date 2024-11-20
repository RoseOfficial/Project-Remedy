-- Olympus Constants
Olympus = {}

-- Debug categories specific to Olympus core functionality
Olympus.DEBUG_CATEGORIES = {
    SPELL_SYSTEM = "SpellSystem",
    BUFF_SYSTEM = "BuffSystem",
    TIMING = "Timing",
    WEAVING = "Weaving"
}

-- Common spell definitions shared across jobs
-- Each spell includes detailed information for the spell system
Olympus.COMMON_SPELLS = {
    SPRINT = { 
        id = 3, 
        mp = 0, 
        instant = true, 
        range = 0, 
        category = "Movement", 
        level = 1, 
        cooldown = 60, 
        isGCD = false,
        description = "Increases movement speed" -- Added for debug clarity
    },
    LUCID_DREAMING = { 
        id = 7562, 
        mp = 0, 
        instant = true, 
        range = 0, 
        category = "Utility", 
        level = 24, 
        cooldown = 60, 
        isGCD = false,
        description = "Gradually restores MP"
    },
    SWIFTCAST = { 
        id = 7561, 
        mp = 0, 
        instant = true, 
        range = 0, 
        category = "Utility", 
        level = 18, 
        cooldown = 60, 
        isGCD = false,
        description = "Next spell is instant cast"
    },
    ESUNA = { 
        id = 7568, 
        mp = 400, 
        instant = false, 
        range = 30, 
        category = "Healing", 
        level = 10, 
        isGCD = true,
        description = "Removes a detrimental effect"
    },
    RAISE = { 
        id = 125, 
        mp = 2400, 
        instant = false, 
        range = 30, 
        category = "Healing", 
        level = 12, 
        isGCD = true,
        description = "Resurrects target to a weakened state"
    },
    RESCUE = { 
        id = 7571, 
        mp = 0, 
        instant = true, 
        range = 30, 
        category = "Utility", 
        level = 48, 
        cooldown = 120, 
        isGCD = false,
        description = "Quickly draws target party member to you"
    },
    SURECAST = { 
        id = 7559, 
        mp = 0, 
        instant = true, 
        range = 0, 
        category = "Utility", 
        level = 44, 
        cooldown = 120, 
        isGCD = false,
        description = "Prevents most knockback and draw-in effects"
    }
}

-- Common buff IDs used across jobs
-- These are used for buff tracking and condition checking
Olympus.BUFF_IDS = {
    SWIFTCAST = 167,      -- Next spell is instant cast
    LUCID_DREAMING = 1204, -- Gradually restores MP
    RAISE = 148           -- Resurrection sickness
}

-- Timing constants for the weaving system
-- These values are critical for proper spell weaving and animation handling
Olympus.WEAVE_WINDOW = 0.7     -- Reduced from 1.0 to 0.7 for better oGCD weaving
Olympus.HEALING_LOCKOUT = 0.8   -- Time in seconds to prevent healing spell spam
Olympus.MIN_SPELL_SPACING = 0.5 -- Minimum time between spell casts
Olympus.OGCD_WINDOW_START = 0.3 -- Start of oGCD weaving window after GCD
Olympus.OGCD_WINDOW_END = 0.7   -- End of oGCD weaving window before next GCD

-- Log initial configuration
Debug.Info(Debug.CATEGORIES.SYSTEM, "Olympus constants initialized")
Debug.Verbose(Olympus.DEBUG_CATEGORIES.TIMING, 
    string.format("Weaving windows configured - Start: %.1fs, End: %.1fs", 
        Olympus.OGCD_WINDOW_START,
        Olympus.OGCD_WINDOW_END))

return Olympus
