Olympus_Settings = {
    -- Default settings
    frameTimeBudget = 16,
    skipLowPriority = true
}

-- Load settings from file
function Olympus_Settings.Load()
    local settings = FileLoad(GetLuaModsPath() .. "\\Olympus\\Settings.lua")
    if settings then
        -- Merge loaded settings with defaults
        for k, v in pairs(settings) do
            Olympus_Settings[k] = v
        end
        Debug.Info("SYSTEM", "Settings loaded successfully")
    else
        Debug.Warn("SYSTEM", "No saved settings found, using defaults")
    end
end

-- Save settings to file
function Olympus_Settings.Save()
    -- Create directory if it doesn't exist
    local settingsPath = GetLuaModsPath() .. "\\Olympus"
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

-- Initialize settings on load
Olympus_Settings.Load()