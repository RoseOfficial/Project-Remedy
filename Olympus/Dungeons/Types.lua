-- Initialize Olympus if needed
Olympus = Olympus or {}
Olympus.Dungeons = Olympus.Dungeons or {}

local Types = {
    -- Mechanic types
    MECHANIC_TYPES = {
        STACK = 1,
        SPREAD = 2,
        AOE = 3,
        KNOCKBACK = 4,
        TANKBUSTER = 5,
        RAIDWIDE = 6,
        DODGE = 7
    },

    -- Default safe distances
    SAFE_DISTANCES = {
        STACK = 3,      -- yalms for stack mechanics
        SPREAD = 8,     -- yalms for spread mechanics
        AOE = 15,       -- yalms for large AOE
        KNOCKBACK = 20  -- yalms for knockback mechanics
    }
}

-- Mechanic base structure
Types.MechanicBase = {
    type = nil,         -- One of MECHANIC_TYPES
    name = "",          -- Descriptive name
    castId = nil,       -- Optional cast ID
    targetId = nil,     -- Optional target entity ID
    sourceId = nil,     -- Optional source entity ID
    position = nil,     -- Optional position {x, y, z}
    radius = nil        -- Optional radius for area effects
}

-- Make types directly available through Olympus.Dungeons
Olympus.Dungeons.MECHANIC_TYPES = Types.MECHANIC_TYPES
Olympus.Dungeons.SAFE_DISTANCES = Types.SAFE_DISTANCES
Olympus.Dungeons.MechanicBase = Types.MechanicBase

-- Store full Types module
Olympus.Dungeons.Types = Types
