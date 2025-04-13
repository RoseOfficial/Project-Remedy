-- Olympus Settings System
Olympus_Settings = Olympus_Settings or {
    -- Default settings
    frameTimeBudget = 16,
    skipLowPriority = true,
    
    -- Debug settings
    debug = {
        level = 4, -- Default to VERBOSE
        categoryEnabled = {
            COMBAT = false,
            HEALING = false,
            DAMAGE = false,
            MOVEMENT = false,
            BUFFS = false,
            PERFORMANCE = false,
            SYSTEM = true,
            DUNGEONS = true
        }
    },

    -- Apollo settings
    Apollo = {
        -- Resource Management
        MPThreshold = 80,           -- MP threshold for recovery abilities
        HealingRange = 30,          -- Maximum healing range
        
        -- Single Target Healing
        CureThreshold = 85,         -- HP% for Cure
        CureIIThreshold = 65,       -- HP% for Cure II
        CureIIIThreshold = 50,      -- HP% for Cure III
        RegenThreshold = 80,        -- HP% for Regen
        BenedictionThreshold = 25,  -- HP% for Benediction
        TetragrammatonThreshold = 60, -- HP% for Tetragrammaton
        BenisonThreshold = 90,      -- HP% for Divine Benison
        AquaveilThreshold = 85,     -- HP% for Aquaveil
        
        -- AoE Healing
        CureIIIMinTargets = 3,      -- Minimum targets for Cure III
        HolyMinTargets = 2,         -- Minimum targets for Holy
        AsylumThreshold = 80,       -- HP% for Asylum
        AsylumMinTargets = 2,       -- Minimum targets for Asylum
        AssizeMinTargets = 1,       -- Minimum targets for Assize
        PlenaryThreshold = 65,      -- HP% for Plenary Indulgence
        TemperanceThreshold = 70,   -- HP% for Temperance
        LiturgyThreshold = 75,      -- HP% for Liturgy of the Bell
        LiturgyMinTargets = 2       -- Minimum targets for Liturgy
    }
}

-- Only define these functions if they don't already exist
if not Olympus_Settings.Load then
    -- Load settings from file
    function Olympus_Settings.Load()
        local settings = FileLoad(GetLuaModsPath() .. "\\Config\\Settings.lua")
        if settings then
            -- Merge loaded settings with defaults
            for k, v in pairs(settings) do
                Olympus_Settings[k] = v
            end
            
            -- Apply debug settings
            if settings.debug then
                Debug.level = settings.debug.level
                for category, enabled in pairs(settings.debug.categoryEnabled) do
                    Debug.categoryEnabled[category] = enabled
                end
            end
            
            Debug.Info("SYSTEM", "Settings loaded successfully")
        else
            Debug.Warn("SYSTEM", "No saved settings found, using defaults")
        end
    end
end

if not Olympus_Settings.Save then
    -- Save settings to file
    function Olympus_Settings.Save()
        -- Update debug settings before saving
        Olympus_Settings.debug.level = Debug.level
        for category, enabled in pairs(Debug.categoryEnabled) do
            Olympus_Settings.debug.categoryEnabled[category] = enabled
        end
        
        -- Create directory if it doesn't exist
        local settingsPath = GetLuaModsPath() .. "\\Config"
        if not FolderExists(settingsPath) then
            Debug.Info("SYSTEM", "Creating settings directory: " .. settingsPath)
            FolderCreate(settingsPath)
        end

        -- Save settings file
        local success = FileSave(settingsPath .. "\\Settings.lua", Olympus_Settings)
        if success then
            Debug.Info("SYSTEM", "Settings saved successfully")
        else
            Debug.Error("SYSTEM", "Failed to save settings")
        end
    end
end

-- Only initialize if not already done
if not Olympus_Settings._initialized then
    Olympus_Settings.Load()
    Olympus_Settings._initialized = true
end

return Olympus_Settings 