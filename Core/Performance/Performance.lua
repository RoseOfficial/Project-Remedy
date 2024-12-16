-- Performance
Olympus = Olympus or {}
Olympus.Performance = {
    frameStartTime = 0,
    lastFrameTime = 0,
    frameTimeBudget = 16, -- Default 16ms (roughly 60fps)
    skipLowPriority = true
}

---Initialize the Performance module
function Olympus.Performance.Initialize()
    Debug.TrackFunctionStart("Olympus.Performance.Initialize")
    Debug.Info(Debug.CATEGORIES.SYSTEM, "Initializing Performance module...")
    
    -- Initialize performance tracking
    Olympus.Performance.frameStartTime = 0
    Olympus.Performance.lastFrameTime = 0
    Debug.Info(Debug.CATEGORIES.PERFORMANCE, "Performance monitoring initialized")
    
    Debug.TrackFunctionEnd("Olympus.Performance.Initialize")
end

---Start frame time tracking
function Olympus.Performance.StartFrameTimeTracking()
    Olympus.Performance.frameStartTime = os.clock()
end

---Get the time elapsed since StartFrameTimeTracking was called
---@return number lastFrameTime The time elapsed since StartFrameTimeTracking was called in milliseconds
function Olympus.Performance.GetLastFrameTime()
    if Olympus.Performance.frameStartTime == 0 then
        return 0
    end
    Olympus.Performance.lastFrameTime = (os.clock() - Olympus.Performance.frameStartTime) * 1000 -- Convert to milliseconds
    return Olympus.Performance.lastFrameTime
end

---Check if frame budget is exceeded
---@return boolean exceeded Whether the frame budget was exceeded
function Olympus.Performance.IsFrameBudgetExceeded()
    local frameTime = Olympus.Performance.GetLastFrameTime()
    return frameTime > Olympus.Performance.frameTimeBudget
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
