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

    -- First create the Project Remedy component
    local Olympus_mainmenu = {
        header = {
            id = "Olympus",
            expanded = false,
            name = "Olympus",
            -- texture = GetStartupPath().."\\GUI\\UI_Textures\\ffxiv_shiny.png"
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

function Olympus_GUI.Draw(event, ticks)
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
    
    -- Add your performance metrics here
    -- Example:
    --[[GUI:Columns(3)
    GUI:Text("CPU Usage:")
    GUI:Text("Memory Usage:")
    GUI:Text("Actions/min:")
    GUI:NextColumn()
    GUI:Text("2.3%")
    GUI:Text("45 MB")
    GUI:Text("32")
    GUI:Columns(1)]]

    GUI:EndChild()
end

function Olympus_GUI.DrawCombatTab()
    -- Use columns for layout
    local style = Olympus_GUI.GetStyle()
    GUI:Columns(2, true) -- 2 columns, with borders

    -- Job Selection Panel (Left Column)
    Olympus_GUI.DrawJobSelectionPanel()

    GUI:NextColumn()

    -- Job Configuration Panel (Right Column)
    GUI:BeginChild("JobConfig", 0, 300, true) -- Use 0 width to fill column
    if Olympus_GUI.selected_job then
        GUI:Text(Olympus_GUI.selected_job.str .. " Configuration")
        GUI:Separator()
        GUI:Spacing()

        -- Add Apollo spell toggles for White Mage
        if Apollo and Olympus_GUI.selected_job.str == "White Mage" then
            -- Spell Categories
            for category in pairs(Apollo.Constants.SPELL_TOGGLES.categories) do
                if GUI:TreeNode(category .. " Spells") then
                    GUI:Indent(10)
                    local spells = Apollo.GetSpellsByCategory(category)
                    for spellName, spell in pairs(spells) do
                        local isEnabled = Apollo.Constants.SPELL_TOGGLES.enabled[spellName]
                        local newEnabled = GUI:Checkbox(spellName .. " (Level " .. spell.level .. ")", isEnabled)
                        if newEnabled ~= isEnabled then
                            Apollo.ToggleSpell(spellName)
                        end
                    end
                    GUI:Unindent(10)
                    GUI:TreePop()
                end
            end
        else
            GUI:TextColored(style.warning_color[1], style.warning_color[2], style.warning_color[3], 1, "Select a job to configure")
        end
    else
        GUI:TextColored(style.warning_color[1], style.warning_color[2], style.warning_color[3], 1, "Select a job to configure")
    end
    GUI:EndChild()
    
    GUI:Columns(1) -- Reset to single column
end

function Olympus_GUI.DrawJobSelectionPanel()
    local style = Olympus_GUI.GetStyle()
    GUI:BeginChild("JobSelect", 0, 300, true) -- Use 0 width to fill column
    GUI:Text("Job Selection")
    GUI:Separator()
    GUI:Spacing()
    
    for _, category in ipairs(Olympus_GUI.job_categories) do
        if GUI:TreeNode(category.name) then
            GUI:Indent(10)
            for _, job in ipairs(category.jobs) do
                local selected = Olympus_GUI.selected_job and Olympus_GUI.selected_job.id == job.id
                if selected then
                    GUI:PushStyleColor(GUI.Col_Button, style.accent_color[1], style.accent_color[2], style.accent_color[3], 0.7)
                end
                
                if GUI:Button(job.str .. " (" .. job.short .. ")", 170, 25) then
                    Olympus_GUI.selected_job = job
                end
                
                if selected then GUI:PopStyleColor() end
            end
            GUI:Unindent(10)
            GUI:TreePop()
        end
    end
    GUI:EndChild()
end

function Olympus_GUI.DrawSettingsTab()
    GUI:Spacing()
    
    GUI_DrawIntMinMax("Min Distance", "OlympusMinDistance", 1, 5, 0, 50, function()
        -- Optional callback when value changes
        Olympus.UpdateDistanceSettings()
    end)
end

-- Draw Debug Tab
function Olympus_GUI.DrawDebugTab()
    GUI:Spacing()
    GUI:Text("Debug Information:")
    GUI:Separator()
    GUI:Spacing()
    
    GUI:Text("Version: " .. (Olympus.VERSION or "Unknown"))
    
    -- Add more debug information
    if Olympus.GetDebugInfo then
        local debugInfo = Olympus.GetDebugInfo()
        if type(debugInfo) == "table" then
            for k,v in pairs(debugInfo) do
                GUI:Text(tostring(k) .. ": " .. tostring(v))
            end
        end
    end
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
