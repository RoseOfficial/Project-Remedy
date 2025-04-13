-- Olympus GUI System
local Olympus_GUI = {}
Olympus_GUI.open = true
Olympus_GUI.visible = true

-- FFXIV Job Categories
Olympus_GUI.job_categories = {
    { name = "Tanks", jobs = {
        { id = 1, str = "Paladin", short = "PLD" },
        { id = 3, str = "Warrior", short = "WAR" },
        { id = 32, str = "Dark Knight", short = "DRK" },
        { id = 37, str = "Gunbreaker", short = "GNB" },
    }},
    { name = "Healers", jobs = {
        { id = 6, str = "White Mage", short = "WHM" },
        { id = 26, str = "Scholar", short = "SCH" },
        { id = 33, str = "Astrologian", short = "AST" },
        { id = 40, str = "Sage", short = "SGE" },
    }},
    { name = "Melee DPS", jobs = {
        { id = 2, str = "Monk", short = "MNK" },
        { id = 4, str = "Dragoon", short = "DRG" },
        { id = 29, str = "Ninja", short = "NIN" },
        { id = 34, str = "Samurai", short = "SAM" },
        { id = 39, str = "Reaper", short = "RPR" },
    }},
    { name = "Ranged DPS", jobs = {
        { id = 5, str = "Bard", short = "BRD" },
        { id = 31, str = "Machinist", short = "MCH" },
        { id = 38, str = "Dancer", short = "DNC" },
    }},
    { name = "Magic DPS", jobs = {
        { id = 7, str = "Black Mage", short = "BLM" },
        { id = 26, str = "Summoner", short = "SMN" },
        { id = 35, str = "Red Mage", short = "RDM" },
    }}
}

-- Main tabs configuration
Olympus_GUI.tab_control = GUI_CreateTabs("Overview,Combat,Settings,Debug", true)
Olympus_GUI.selected_tab = 1
Olympus_GUI.selected_job = nil

-- Style configuration
local style = {
    window_padding = 10,
    item_spacing = 8,
    tab_rounding = 5,
    frame_padding = 5,
    -- Updated color scheme
    accent_color = { 0.18, 0.55, 0.82, 1.0 },  -- Steel Blue
    warning_color = { 0.91, 0.74, 0.26, 1.0 }, -- Golden Yellow
    success_color = { 0.34, 0.78, 0.56, 1.0 }, -- Sea Green
    text_color = { 0.9, 0.9, 0.9, 1.0 },       -- Light Gray
    background_color = { 0.1, 0.1, 0.1, 1.0 }, -- Dark Gray
}

function Olympus_GUI.GetStyle()
    return style
end

function Olympus_GUI.Init()
    -- Initialize settings
    Olympus_GUI.settings = Olympus_Settings or {
        frameTimeBudget = 16,
        skipLowPriority = true
    }

    -- First create the Project Remedy component
    local Olympus_mainmenu = {
        header = {
            id = "Olympus",
            expanded = false,
            name = "Olympus",
        },
        members = {}
    }
    ml_gui.ui_mgr:AddComponent(Olympus_mainmenu)

    -- Add main Olympus member to Project Remedy
    ml_gui.ui_mgr:AddMember({ 
        id = "Olympus##MENU_Olympus",
        name = "Olympus",
        onClick = function() Olympus_GUI.open = not Olympus_GUI.open end,
        tooltip = "Open the Olympus configuration window.",
        sort = true
    }, "Olympus", "Olympus##MENU_Olympus")
end

-- Add this at the module level (near the top of the file)
local lastFrameTime = 0

-- Update the Draw function
function Olympus_GUI.Draw(event, ticks)
    -- Always track frames, even if GUI is closed
    if Olympus.Performance then
        -- Only start tracking if we're not already tracking
        if Olympus.Performance.frameStartTime == 0 then
            Olympus.Performance.StartFrameTimeTracking()
        end
        Olympus.Performance.EndFrameTimeTracking()
    end

    if not Olympus_GUI.open then return end

    -- Set window properties
    local style = Olympus_GUI.GetStyle()
    GUI:SetNextWindowSize(800, 600, GUI.SetCond_FirstUseEver)
    GUI:PushStyleVar(GUI.StyleVar_WindowPadding, style.window_padding, style.window_padding)
    
    Olympus_GUI.visible, Olympus_GUI.open = GUI:Begin("Olympus Control Panel##MainWindow", Olympus_GUI.open, GUI.WindowFlags_NoCollapse)
    
    if Olympus_GUI.visible then
        -- Draw main tabs with icons
        GUI:PushStyleVar(GUI.StyleVar_FramePadding, style.frame_padding, style.frame_padding)
        local selectedIndex, selectedName = GUI_DrawTabs(Olympus_GUI.tab_control)
        Olympus_GUI.selected_tab = selectedIndex
        GUI:PopStyleVar()
        
        GUI:Spacing()
        
        -- Draw content based on selected tab
        Olympus_GUI.DrawTabsContent()
    end
    
    GUI:PopStyleVar()
    GUI:End()
end

function Olympus_GUI.DrawTabsContent()
    if Olympus_GUI.selected_tab == 1 then
        Olympus_GUI.DrawOverviewTab()
    elseif Olympus_GUI.selected_tab == 2 then
        Olympus_GUI.DrawCombatTab()
    elseif Olympus_GUI.selected_tab == 3 then
        Olympus_GUI.DrawSettingsTab()
    elseif Olympus_GUI.selected_tab == 4 then
        Olympus_GUI.DrawDebugTab()
    end
end

function Olympus_GUI.DrawOverviewTab()
    -- Status Section with proper height calculation
    local style = Olympus_GUI.GetStyle()
    local statusHeight = GUI_GetFrameHeight(4) -- 4 rows of content now
    GUI:BeginChild("Status", 0, 200, true)
    
    -- Single button to control both systems
    if Olympus.IsRunning() or (Apollo and Apollo.IsRunning and Apollo.IsRunning()) then
        if GUI:Button("Stop System", 100, 25) then 
            if Olympus.IsRunning() then Olympus.Toggle() end
            if Apollo and Apollo.Toggle then Apollo.Toggle() end
        end
    else
        if GUI:Button("Start System", 100, 25) then 
            if not Olympus.IsRunning() then Olympus.Toggle() end
            if Apollo and Apollo.Toggle then Apollo.Toggle() end
        end
    end
    
    GUI:Spacing()
    GUI:Text("System Status")
    GUI:Separator()
    
    -- Running status with colored indicator
    GUI_AlignedText("Olympus Status:", "Current operational status of the Olympus system")
    GUI:SameLine()
    if Olympus.IsRunning() then
        GUI:TextColored(style.success_color[1], style.success_color[2], style.success_color[3], 1, "Running")
    else
        GUI:TextColored(1, 0, 0, 1, "Stopped")
    end
    
    -- Add Apollo status indicator
    if Apollo and Apollo.IsRunning then
        GUI_AlignedText("Apollo Status:", "Current operational status of Apollo")
        GUI:SameLine()
        if Apollo.IsRunning() then
            GUI:TextColored(style.success_color[1], style.success_color[2], style.success_color[3], 1, "Running")
        else
            GUI:TextColored(1, 0, 0, 1, "Stopped")
        end
    end
    
    GUI:EndChild()
    
    GUI:Spacing()
    
    -- Quick Stats Section
    GUI:BeginChild("QuickStats", 0, 100, true)
    GUI:Text("Performance Metrics")
    GUI:Separator()
    
    -- Performance metrics display
    if Olympus.Performance and Olympus.Performance.GetMetrics then
        local metrics = Olympus.Performance.GetMetrics()
        if metrics then
            GUI:Columns(2)
            
            GUI:Text("Frame Time:")
            GUI:NextColumn()
            if metrics.metrics and metrics.metrics.averageFrameTime then
                GUI:Text(string.format("%.2f ms", metrics.metrics.averageFrameTime * 1000))
            else
                GUI:Text("N/A")
            end
            GUI:NextColumn()
            
            GUI:Text("Update Time:")
            GUI:NextColumn()
            if metrics.metrics and metrics.metrics.updateTime then
                GUI:Text(string.format("%.2f ms", metrics.metrics.updateTime * 1000))
            else
                GUI:Text("N/A")
            end
            GUI:NextColumn()
            
            GUI:Columns(1)
        end
    end
    
    GUI:EndChild()
    
    -- Debug Log Section
    GUI:BeginChild("DebugLog", 0, 0, true)
    GUI:Text("Recent Debug Messages")
    GUI:Separator()
    
    -- Display recent debug messages
    if Debug and Debug.recentLogs then
        for i = #Debug.recentLogs, math.max(1, #Debug.recentLogs - 10), -1 do
            GUI:TextWrapped(Debug.recentLogs[i])
        end
    end
    
    GUI:EndChild()
end

function Olympus_GUI.DrawCombatTab()
    GUI:BeginChild("CombatSettings", 0, 0, true)
    
    GUI:Text("Combat Configuration")
    GUI:Separator()
    GUI:Spacing()
    
    -- Add tabbed interface for job selection
    if GUI:BeginTabBar("JobTabBar", GUI.TabBarFlags_None) then
        for _, category in ipairs(Olympus_GUI.job_categories) do
            if GUI:BeginTabItem(category.name) then
                GUI:Spacing()
                
                -- Create buttons for each job in the category
                for _, job in ipairs(category.jobs) do
                    if GUI:Button(job.str .. " (" .. job.short .. ")", 150, 30) then
                        Olympus_GUI.selected_job = job
                    end
                    
                    -- Show multiple jobs per row
                    if _ % 3 ~= 0 then
                        GUI:SameLine()
                    else
                        GUI:Spacing()
                    end
                end
                
                GUI:EndTabItem()
            end
        end
        GUI:EndTabBar()
    end
    
    GUI:Spacing()
    GUI:Separator()
    GUI:Spacing()
    
    -- Show settings for selected job
    if Olympus_GUI.selected_job then
        GUI:Text("Settings for " .. Olympus_GUI.selected_job.str)
        GUI:Separator()
        
        -- Placeholder for job-specific settings
        -- This would be populated with actual settings based on the selected job
        GUI:Text("Job settings would appear here")
    else
        GUI:TextColored(0.7, 0.7, 0.7, 1, "Select a job to view its settings")
    end
    
    GUI:EndChild()
end

function Olympus_GUI.DrawSettingsTab()
    GUI:BeginChild("GeneralSettings", 0, 0, true)
    
    GUI:Text("General Settings")
    GUI:Separator()
    GUI:Spacing()
    
    -- Performance Settings
    GUI:Text("Performance Settings")
    GUI:Separator()
    
    -- Frame time budget with tooltip
    local frameTimeBudget = Olympus_Settings.frameTimeBudget
    GUI_AlignedText("Frame Time Budget (ms):", "Maximum time allowed for each frame. Lower values may improve responsiveness but could skip calculations.")
    
    -- Create a slider from 5ms to 50ms
    local changed, newValue = GUI:SliderInt("##FrameTimeBudget", frameTimeBudget, 5, 50)
    if changed then
        Olympus_Settings.frameTimeBudget = newValue
        if Olympus.Performance then
            Olympus.Performance.SetThresholds(newValue / 1000, Olympus_Settings.skipLowPriority)
        end
    end
    
    -- Skip Low Priority option
    GUI_AlignedText("Skip Low Priority Tasks:", "Skip non-essential tasks when frame time exceeds budget")
    GUI:SameLine()
    local skipChanged, skipValue = GUI:Checkbox("##SkipLowPriority", Olympus_Settings.skipLowPriority)
    if skipChanged then
        Olympus_Settings.skipLowPriority = skipValue
        if Olympus.Performance then
            Olympus.Performance.SetThresholds(Olympus_Settings.frameTimeBudget / 1000, skipValue)
        end
    end
    
    GUI:Spacing()
    
    -- Save Settings Button
    if GUI:Button("Save Settings", 120, 30) then
        Olympus_Settings.Save()
    end
    
    GUI:EndChild()
end

function Olympus_GUI.DrawDebugTab()
    GUI:BeginChild("DebugSettings", 0, 0, true)
    
    GUI:Text("Debug Settings")
    GUI:Separator()
    GUI:Spacing()
    
    -- Debug Level Select
    GUI:Text("Debug Level:")
    GUI:SameLine()
    
    local debugLevelOptions = { "ERROR", "WARN", "INFO", "VERBOSE" }
    local currentLevel = Debug.level
    
    if GUI:BeginCombo("##DebugLevel", debugLevelOptions[currentLevel], GUI.ComboFlags_None) then
        for i, levelName in ipairs(debugLevelOptions) do
            local isSelected = (i == currentLevel)
            if GUI:Selectable(levelName, isSelected) then
                Debug.level = i
                -- Update settings
                Olympus_Settings.debug.level = i
            end
            
            if isSelected then
                GUI:SetItemDefaultFocus()
            end
        end
        GUI:EndCombo()
    end
    
    GUI:Spacing()
    
    -- Category enable/disable
    GUI:Text("Debug Categories:")
    GUI:Separator()
    
    for category, enabled in pairs(Debug.categoryEnabled) do
        local changed, newValue = GUI:Checkbox(category, enabled)
        if changed then
            Debug.categoryEnabled[category] = newValue
            -- Update settings
            Olympus_Settings.debug.categoryEnabled[category] = newValue
        end
    end
    
    GUI:Spacing()
    
    -- Function Tracking Options
    GUI:Text("Performance Tracking:")
    GUI:Separator()
    
    local ftChanged, ftValue = GUI:Checkbox("Enable Function Tracking", Debug.functionTracking)
    if ftChanged then
        Debug.functionTracking = ftValue
    end
    
    local ptChanged, ptValue = GUI:Checkbox("Enable Performance Tracking", Debug.performanceTracking)
    if ptChanged then
        Debug.performanceTracking = ptValue
    end
    
    -- Performance Data View
    if Debug.performanceTracking and GUI:Button("Show Performance Data", 150, 25) then
        Debug.PrintPerformanceStats()
    end
    
    -- Clear Debug Log Button
    if GUI:Button("Clear Debug Log", 120, 25) then
        Debug.recentLogs = {}
    end
    
    GUI:EndChild()
end

function Olympus_GUI.ShowErrorDialog(message)
    ffxiv_dialog_manager.IssueNotice(
        "Olympus Error",
        message,
        "okonly",
        { width = 400, height = 150, center = true }
    )
end

Olympus_GUI.Init()

RegisterEventHandler("Module.Initialize", Olympus_GUI.Init, "Olympus_GUI.Init")
RegisterEventHandler("Gameloop.Draw", Olympus_GUI.Draw, "Olympus_GUI.Draw")

return Olympus_GUI 