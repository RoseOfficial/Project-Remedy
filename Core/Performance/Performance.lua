-- Performance
Olympus = Olympus or {}
Olympus.Performance = {
    frameStartTime = 0,
    frameTimeThreshold = 0.016, -- 16ms default frame budget
    frameBudgetExceeded = false,
    skipLowPriority = false,
    frameTimeHistory = {},
    maxHistorySize = 100,
    totalExecutionTime = 0,
    executionCount = 0
}

---Initialize the Performance module
function Olympus.Performance.Initialize()
    Debug.TrackFunctionStart("Olympus.Performance.Initialize")
    Debug.Info(Debug.CATEGORIES.SYSTEM, "Initializing Performance module...")
    
    -- Initialize performance tracking
    Olympus.Performance.frameStartTime = 0
    Olympus.Performance.frameBudgetExceeded = false
    Olympus.Performance.frameTimeHistory = {}
    Olympus.Performance.totalExecutionTime = 0
    Olympus.Performance.executionCount = 0
    
    Debug.Info(Debug.CATEGORIES.SYSTEM, string.format(
        "Performance module initialized with settings - Frame Budget: %.1fms, Skip Low Priority: %s",
        Olympus.Performance.frameTimeThreshold * 1000,
        tostring(Olympus.Performance.skipLowPriority)
    ))
    Debug.TrackFunctionEnd("Olympus.Performance.Initialize")
end

---Start frame time tracking
function Olympus.Performance.StartFrameTimeTracking()
    Olympus.Performance.frameStartTime = os.clock()
    Olympus.Performance.frameBudgetExceeded = false
end

---Check if frame budget is exceeded
---@return boolean exceeded Whether the frame budget was exceeded
function Olympus.Performance.IsFrameBudgetExceeded()
    local currentTime = os.clock()
    local frameTime = currentTime - Olympus.Performance.frameStartTime
    Olympus.Performance.frameBudgetExceeded = frameTime > Olympus.Performance.frameTimeThreshold
    
    -- Update total execution time
    Olympus.Performance.totalExecutionTime = Olympus.Performance.totalExecutionTime + frameTime
    Olympus.Performance.executionCount = Olympus.Performance.executionCount + 1
    
    -- Store frame time in history
    table.insert(Olympus.Performance.frameTimeHistory, frameTime)
    if #Olympus.Performance.frameTimeHistory > Olympus.Performance.maxHistorySize then
        table.remove(Olympus.Performance.frameTimeHistory, 1)
    end
    
    -- Calculate average frame time
    local sum = 0
    for _, time in ipairs(Olympus.Performance.frameTimeHistory) do
        sum = sum + time
    end
    local avgFrameTime = sum / #Olympus.Performance.frameTimeHistory
    
    -- Log performance stats every 100 frames
    if #Olympus.Performance.frameTimeHistory % 100 == 0 then
        -- Calculate average execution time per run
        local avgExecutionTime = Olympus.Performance.totalExecutionTime / Olympus.Performance.executionCount
        
        Debug.Info(Debug.CATEGORIES.PERFORMANCE, 
            string.format("Stats - Avg Frame: %.3fms, Current: %.3fms, Budget: %.3fms | Total Runtime: %.2fs, Avg Runtime: %.3fms, Executions: %d", 
                avgFrameTime * 1000,
                frameTime * 1000,
                Olympus.Performance.frameTimeThreshold * 1000,
                Olympus.Performance.totalExecutionTime,
                avgExecutionTime * 1000,
                Olympus.Performance.executionCount))
                
        -- Reset counters every 10000 executions to avoid potential number overflow
        if Olympus.Performance.executionCount >= 10000 then
            Olympus.Performance.totalExecutionTime = 0
            Olympus.Performance.executionCount = 0
        end
    end
    
    return Olympus.Performance.frameBudgetExceeded
end

---Set performance thresholds
---@param frameTimeThreshold number Frame time budget in seconds (e.g., 0.016 for 16ms)
---@param skipLowPriority boolean Whether to skip low priority actions when budget exceeded
function Olympus.Performance.SetThresholds(frameTimeThreshold, skipLowPriority)
    Olympus.Performance.frameTimeThreshold = frameTimeThreshold
    Olympus.Performance.skipLowPriority = skipLowPriority
end
