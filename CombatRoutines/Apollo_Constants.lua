Apollo.Constants = {}

-- Debug categories specific to Apollo
Apollo.Constants.DEBUG_CATEGORIES = {
    LILY = "Lily",
    HEALING_SINGLE = "SingleTargetHealing",
    HEALING_AOE = "AoEHealing",
    HEALING_EMERGENCY = "EmergencyHealing",
    MITIGATION = "Mitigation"
}

-- WHM-specific buff IDs with descriptive comments
Apollo.Constants.BUFFS = {
    FREECURE = 155,      -- Allows free casting of Cure II
    MEDICA_II = 150,     -- AoE HoT effect
    REGEN = 158,         -- Single target HoT effect
    DIVINE_BENISON = 1218, -- Single target shield
    AQUAVEIL = 2708      -- Damage reduction buff
}

-- WHM-specific spell definitions with detailed documentation
Apollo.Constants.SPELLS = {
    -- Damage spells (GCD)
    -- Direct damage spells that evolve as the player levels up
    STONE = { id = 119, mp = 200, instant = false, range = 25, category = "Damage", level = 1, isGCD = true },
    STONE_II = { id = 127, mp = 200, instant = false, range = 25, category = "Damage", level = 18, isGCD = true },
    STONE_III = { id = 3568, mp = 400, instant = false, range = 25, category = "Damage", level = 54, isGCD = true },
    STONE_IV = { id = 7431, mp = 400, instant = false, range = 25, category = "Damage", level = 64, isGCD = true },
    GLARE = { id = 16533, mp = 400, instant = false, range = 25, category = "Damage", level = 72, isGCD = true },
    GLARE_III = { id = 25859, mp = 400, instant = false, range = 25, category = "Damage", level = 82, isGCD = true },

    -- Single target healing (GCD)
    -- Core healing spells for single target healing
    CURE = { id = 120, mp = 400, instant = false, range = 30, category = "Healing", level = 2, isGCD = true },
    CURE_II = { id = 135, mp = 1000, instant = false, range = 30, category = "Healing", level = 30, isGCD = true },
    CURE_III = { id = 131, mp = 1500, instant = false, range = 30, category = "Healing", level = 40, isGCD = true },
    REGEN = { id = 137, mp = 500, instant = true, range = 30, category = "Healing", level = 35, isGCD = true },

    -- Single target healing (oGCD)
    -- Emergency and supplementary healing abilities
    BENEDICTION = { id = 140, mp = 0, instant = true, range = 30, category = "Healing", level = 50, cooldown = 180, isGCD = false },
    TETRAGRAMMATON = { id = 3570, mp = 0, instant = true, range = 30, category = "Healing", level = 60, cooldown = 60, isGCD = false },
    DIVINE_BENISON = { id = 7432, mp = 0, instant = true, range = 30, category = "Healing", level = 66, cooldown = 30, isGCD = false },
    AQUAVEIL = { id = 25861, mp = 0, instant = true, range = 30, category = "Buff", level = 86, cooldown = 60, isGCD = false },

    -- AoE healing (GCD)
    -- Area effect healing spells
    MEDICA = { id = 124, mp = 1000, instant = false, range = 15, category = "Healing", level = 10, isGCD = true },
    MEDICA_II = { id = 133, mp = 1000, instant = false, range = 20, category = "Healing", level = 50, isGCD = true },

    -- AoE healing (oGCD)
    -- Area effect healing abilities and buffs
    ASYLUM = { id = 3569, mp = 0, instant = true, range = 30, category = "Healing", level = 52, cooldown = 90, isGCD = false },
    ASSIZE = { id = 3571, mp = 0, instant = true, range = 15, category = "Hybrid", level = 56, cooldown = 45, isGCD = false },
    PLENARY_INDULGENCE = { id = 7433, mp = 0, instant = true, range = 0, category = "Healing", level = 70, cooldown = 60, isGCD = false },
    LITURGY_OF_THE_BELL = { id = 25862, mp = 0, instant = true, range = 20, category = "Healing", level = 90, cooldown = 180, isGCD = false },
    TEMPERANCE = { id = 16536, mp = 0, instant = true, range = 0, category = "Buff", level = 80, cooldown = 120, isGCD = false },

    -- DoTs and AoE damage (GCD)
    -- Damage over time and area effect damage spells
    AERO = { id = 121, mp = 400, instant = true, range = 25, category = "Damage", level = 4, isGCD = true },
    AERO_II = { id = 132, mp = 400, instant = true, range = 25, category = "Damage", level = 46, isGCD = true },
    DIA = { id = 16532, mp = 400, instant = true, range = 25, category = "Damage", level = 72, isGCD = true },
    HOLY = { id = 139, mp = 400, instant = false, range = 8, category = "Damage", level = 45, isGCD = true },
    HOLY_III = { id = 25860, mp = 400, instant = false, range = 8, category = "Damage", level = 82, isGCD = true },

    -- Utility (oGCD)
    -- Support and utility abilities
    PRESENCE_OF_MIND = { id = 136, mp = 0, instant = true, range = 0, category = "Buff", level = 30, isGCD = false },
    THIN_AIR = { id = 7430, mp = 0, instant = true, range = 0, category = "Buff", level = 58, cooldown = 120, isGCD = false },
    AETHERIAL_SHIFT = { id = 37008, mp = 0, instant = true, range = 0, category = "Movement", level = 40, cooldown = 60, isGCD = false },

    -- Lily system (GCD)
    -- Special healing and damage abilities using the lily gauge
    AFFLATUS_SOLACE = { id = 16531, mp = 0, instant = true, range = 30, category = "Healing", level = 52, isGCD = true },
    AFFLATUS_RAPTURE = { id = 16534, mp = 0, instant = true, range = 20, category = "Healing", level = 76, isGCD = true },
    AFFLATUS_MISERY = { id = 16535, mp = 0, instant = false, range = 25, category = "Damage", level = 74, isGCD = true }
}

-- Add common spells if they exist
if Olympus and Olympus.COMMON_SPELLS and type(Olympus.COMMON_SPELLS) == "table" then
    if Debug then
        Debug.Info(Debug.CATEGORIES.SYSTEM, "Adding common spells to Apollo spell list")
    end
    for name, spell in pairs(Olympus.COMMON_SPELLS) do
        Apollo.Constants.SPELLS[name] = spell
    end
end

-- Settings with detailed explanatory comments
Apollo.Constants.SETTINGS = {
    -- Resource management
    MPThreshold = 80,           -- MP threshold for using MP recovery abilities
    HealingRange = 30,          -- Maximum range for healing spells

    -- Single target healing thresholds
    CureThreshold = 85,         -- HP threshold for using Cure (only used at low levels or when MP constrained)
    CureIIThreshold = 65,       -- HP threshold for using Cure II (primary single target heal)
    CureIIIThreshold = 50,      -- HP threshold for using Cure III (used for stack healing)
    RegenThreshold = 80,        -- HP threshold for applying Regen (proactive healing)
    BenedictionThreshold = 25,  -- HP threshold for using Benediction (emergency healing)
    TetragrammatonThreshold = 60, -- HP threshold for using Tetragrammaton (instant oGCD heal)
    BenisonThreshold = 90,      -- HP threshold for using Divine Benison (proactive shield)
    AquaveilThreshold = 85,     -- HP threshold for using Aquaveil (tank mitigation)

    -- AoE healing thresholds
    CureIIIMinTargets = 3,      -- Minimum targets for Cure III
    HolyMinTargets = 2,         -- Minimum targets for Holy (reduced for better dungeon efficiency)
    AsylumThreshold = 80,       -- HP threshold for using Asylum (ground AoE regen)
    AsylumMinTargets = 2,       -- Minimum targets for Asylum
    AssizeMinTargets = 1,       -- Minimum targets for Assize (reduced since it's also a damage ability)
    PlenaryThreshold = 65,      -- HP threshold for using Plenary Indulgence
    TemperanceThreshold = 70,   -- HP threshold for using Temperance
    LiturgyThreshold = 75,      -- HP threshold for using Liturgy of the Bell
    LiturgyMinTargets = 2       -- Minimum targets for Liturgy of the Bell
}

if Debug then
    Debug.Info(Debug.CATEGORIES.SYSTEM, "Apollo constants initialized")
end
