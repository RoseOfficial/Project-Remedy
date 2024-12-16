-- Performance
Olympus = Olympus or {}
Olympus.Performance = {
    frameStartTime = 0,
    lastFrameTime = 0,
    frameTimeBudget = 16, -- Default 16ms (roughly 60fps)
    skipLowPriority = true,
    frameTimeHistory = {}, -- Add frame history table
    fpsHistory = {},          -- Add FPS history
    MAX_FRAME_HISTORY = 60, -- Track last 60 frames for averaging
    MAX_FPS_HISTORY = 10,     -- Keep shorter history for FPS smoothing
    framesBudgetExceeded = 0,
    lastBudgetCheck = 0,
    BUDGET_CHECK_INTERVAL = 1000 -- Check every second
}

---Initialize the Performance module
function Olympus.Performance.Initialize()
    Debug.TrackFunctionStart("Olympus.Performance.Initialize")
    Debug.Info(Debug.CATEGORIES.SYSTEM, "Initializing Performance module...")
    
    -- Initialize performance tracking
    Olympus.Performance.frameStartTime = 0
    Olympus.Performance.lastFrameTime = 0
    Olympus.Performance.frameTimeHistory = {}
    Olympus.Performance.fpsHistory = {}    -- Initialize FPS history
    Debug.Info(Debug.CATEGORIES.PERFORMANCE, "Performance monitoring initialized")
    
    Debug.TrackFunctionEnd("Olympus.Performance.Initialize")
end

---Start frame time tracking
function Olympus.Performance.StartFrameTimeTracking()
    -- Now() returns microseconds, so we'll get better precision
    Olympus.Performance.frameStartTime = Now()
end

---End frame time tracking and update history
function Olympus.Performance.EndFrameTimeTracking()
    if Olympus.Performance.frameStartTime ~= 0 then
        -- Get elapsed time in microseconds, then convert to milliseconds
        local frameTime = (Now() - Olympus.Performance.frameStartTime) / 1000 -- Convert microseconds to milliseconds
        if frameTime > 0 then  -- Only track valid frame times
            Olympus.Performance.lastFrameTime = frameTime
            
            -- Add to history
            table.insert(Olympus.Performance.frameTimeHistory, frameTime)
            
            -- Keep history at max length
            while #Olympus.Performance.frameTimeHistory > Olympus.Performance.MAX_FRAME_HISTORY do
                table.remove(Olympus.Performance.frameTimeHistory, 1)
            end
        end
        
        -- Always restart frame timing immediately
        Olympus.Performance.frameStartTime = Now()
    else
        -- If we don't have a start time, start tracking now
        Olympus.Performance.frameStartTime = Now()
    end
end

---Get the last recorded frame time
---@return number lastFrameTime The last recorded frame time in milliseconds
function Olympus.Performance.GetLastFrameTime()
    return Olympus.Performance.lastFrameTime
end

---Get the average frame time over the history window
---@return number averageFrameTime The average frame time in milliseconds
function Olympus.Performance.GetAverageFrameTime()
    if #Olympus.Performance.frameTimeHistory == 0 then
        return 0
    end
    
    local sum = 0
    for _, time in ipairs(Olympus.Performance.frameTimeHistory) do
        sum = sum + time
    end
    
    return sum / #Olympus.Performance.frameTimeHistory
end

---Check if frame budget is exceeded
---@return boolean exceeded Whether the frame budget was exceeded
function Olympus.Performance.IsFrameBudgetExceeded()
    return Olympus.Performance.lastFrameTime > Olympus.Performance.frameTimeBudget
end

---Set performance thresholds
---@param frameTimeThreshold number Frame time budget in seconds (e.g., 0.016 for 16ms)
---@param skipLowPriority boolean Whether to skip low priority actions when budget exceeded
---@return boolean success Whether the thresholds were successfully set
function Olympus.Performance.SetThresholds(frameTimeThreshold, skipLowPriority)
    Debug.Info(Debug.CATEGORIES.PERFORMANCE, string.format(
        "Performance thresholds updated - Budget: %.1fms, Skip Low Priority: %s",
        frameTimeThreshold * 1000,
        tostring(skipLowPriority)
    ))
    Olympus.Performance.frameTimeBudget = frameTimeThreshold * 1000 -- Convert to milliseconds
    Olympus.Performance.skipLowPriority = skipLowPriority
    return true
end

---Get the number of frames currently being averaged
---@return number frameCount The number of frames in the history
function Olympus.Performance.GetFrameHistoryCount()
    return #Olympus.Performance.frameTimeHistory
end

---Get smoothed FPS
---@return number smoothedFPS The smoothed FPS
function Olympus.Performance.GetSmoothedFPS()
    if #Olympus.Performance.frameTimeHistory == 0 then return 0 end
    
    -- Calculate average frame time from history
    local sum = 0
    for _, time in ipairs(Olympus.Performance.frameTimeHistory) do
        sum = sum + time
    end
    local avgFrameTime = sum / #Olympus.Performance.frameTimeHistory
    
    -- Convert to FPS with safety check
    if avgFrameTime <= 0 then return 0 end
    local fps = math.floor(1000 / avgFrameTime)
    if fps > 300 then fps = 300 end -- Cap at 300
    
    return fps
end

---Track and get the number of frames that exceeded budget in the last second
---@return number framesOverBudget Number of frames that exceeded budget
function Olympus.Performance.GetFramesBudgetExceeded()
    -- Reset counter every second
    local now = Now()
    if (now - Olympus.Performance.lastBudgetCheck) > Olympus.Performance.BUDGET_CHECK_INTERVAL then
        Olympus.Performance.framesBudgetExceeded = 0
        Olympus.Performance.lastBudgetCheck = now
    end
    
    -- Check if current frame exceeded budget
    if Olympus.Performance.IsFrameBudgetExceeded() then
        Olympus.Performance.framesBudgetExceeded = Olympus.Performance.framesBudgetExceeded + 1
    end
    
    return Olympus.Performance.framesBudgetExceeded
end

return Olympus.Performance
