Debug = {
    -- Debug categories
    CATEGORIES = {
        COMBAT = "COMBAT",
        HEALING = "HEALING",
        DAMAGE = "DAMAGE",
        MOVEMENT = "MOVEMENT",
        BUFFS = "BUFFS",
        PERFORMANCE = "PERFORMANCE",
        SYSTEM = "SYSTEM",
        DUNGEONS = "DUNGEONS"  -- Added new DUNGEONS category
    },

    -- Debug levels
    LEVELS = {
        ERROR = 1,
        WARN = 2,
        INFO = 3,
        VERBOSE = 4
    },

    -- Configuration
    enabled = true,
    level = 4,
    functionTracking = false,
    performanceTracking = true,
    
    -- Category-specific enable flags
    categoryEnabled = {
        COMBAT = false,
        HEALING = false,
        DAMAGE = false,
        MOVEMENT = false,
        BUFFS = false,
        PERFORMANCE = false,
        SYSTEM = true,  -- Keep system enabled by default for critical messages
        DUNGEONS = true  -- Added DUNGEONS category (disabled by default)
    },
    
    -- Performance tracking
    performance = {
        functionTimes = {},
        startTimes = {},
        minTimes = {},
        maxTimes = {}
    }
}

-- Initialize tables at module level
Debug.performance.functionTimes = Debug.performance.functionTimes or {}
Debug.performance.startTimes = Debug.performance.startTimes or {}
Debug.performance.minTimes = Debug.performance.minTimes or {}
Debug.performance.maxTimes = Debug.performance.maxTimes or {}

---Format message with timestamp and category
---@param category string The debug category
---@param level number The debug level
---@param msg string The message to format
---@return string formatted The formatted message
local function formatMessage(category, level, msg)
    local levelStr = ""
    for name, val in pairs(Debug.LEVELS) do
        if val == level then
            levelStr = name
            break
        end
    end
    
    return string.format("[%s][%s][%s] %s", 
        os.date("%H:%M:%S"),
        category,
        levelStr,
        msg)
end

---Log a debug message if enabled and level is sufficient
---@param category string The debug category
---@param level number The debug level
---@param msg string The message to log
function Debug.Log(category, level, msg)
    if not Debug.enabled then return end
    if level > Debug.level then return end
    if not Debug.categoryEnabled[category] then return end
    
    d(formatMessage(category, level, msg))
end

---Enable debug messages for specific categories
---@param categories table Array of category names to enable
function Debug.EnableCategories(categories)
    for _, category in ipairs(categories) do
        if Debug.CATEGORIES[category] then
            Debug.categoryEnabled[category] = true
        end
    end
end

---Disable debug messages for specific categories
---@param categories table Array of category names to disable
function Debug.DisableCategories(categories)
    for _, category in ipairs(categories) do
        if Debug.CATEGORIES[category] then
            Debug.categoryEnabled[category] = false
        end
    end
end

---Start tracking function execution time
---@param funcName string The function name
function Debug.TrackFunctionStart(funcName)
    if not Debug.enabled or not Debug.functionTracking then return end
    Debug.performance.startTimes[funcName] = os.clock()
    Debug.Log("SYSTEM", Debug.LEVELS.VERBOSE, "Entering: " .. funcName)
end

---End tracking function execution time
---@param funcName string The function name
function Debug.TrackFunctionEnd(funcName)
    if not Debug.enabled or not Debug.functionTracking then return end
    
    local startTime = Debug.performance.startTimes[funcName]
    if startTime then
        local duration = os.clock() - startTime
        Debug.performance.functionTimes[funcName] = Debug.performance.functionTimes[funcName] or {}
        table.insert(Debug.performance.functionTimes[funcName], duration)
        
        -- Update min/max times
        if not Debug.performance.minTimes[funcName] or duration < Debug.performance.minTimes[funcName] then
            Debug.performance.minTimes[funcName] = duration
        end
        if not Debug.performance.maxTimes[funcName] or duration > Debug.performance.maxTimes[funcName] then
            Debug.performance.maxTimes[funcName] = duration
        end
        
        -- Keep last 100 measurements
        if #Debug.performance.functionTimes[funcName] > 100 then
            table.remove(Debug.performance.functionTimes[funcName], 1)
        end
        
        Debug.Log("SYSTEM", Debug.LEVELS.VERBOSE, 
            string.format("Exiting: %s (%.3fms)", funcName, duration * 1000))
    end
end

---Get average execution time for a function
---@param funcName string The function name
---@return number|nil avgTime The average execution time in seconds
function Debug.GetAverageFunctionTime(funcName)
    local times = Debug.performance.functionTimes[funcName]
    if not times or #times == 0 then return nil end
    
    local sum = 0
    for _, time in ipairs(times) do
        sum = sum + time
    end
    return sum / #times
end

---Print performance statistics for tracked functions
function Debug.PrintPerformanceStats()
    if not Debug.enabled or not Debug.performanceTracking then return end
    
    Debug.Log("PERFORMANCE", Debug.LEVELS.INFO, "Performance Statistics:")
    for funcName, times in pairs(Debug.performance.functionTimes) do
        local avgTime = Debug.GetAverageFunctionTime(funcName)
        if avgTime then
            local minTime = Debug.performance.minTimes[funcName] or 0
            local maxTime = Debug.performance.maxTimes[funcName] or 0
            Debug.Log("PERFORMANCE", Debug.LEVELS.INFO,
                string.format("%s: Avg %.3fms (Min: %.3fms, Max: %.3fms) over %d calls",
                    funcName,
                    avgTime * 1000,
                    minTime * 1000,
                    maxTime * 1000,
                    #times))
        end
    end
end

-- Convenience logging methods
function Debug.Error(category, msg) Debug.Log(category, Debug.LEVELS.ERROR, msg) end
function Debug.Warn(category, msg) Debug.Log(category, Debug.LEVELS.WARN, msg) end
function Debug.Info(category, msg) Debug.Log(category, Debug.LEVELS.INFO, msg) end
function Debug.Verbose(category, msg) Debug.Log(category, Debug.LEVELS.VERBOSE, msg) end

return Debug
