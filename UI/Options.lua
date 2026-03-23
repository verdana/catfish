-- Catfish - Options.lua
-- Settings panel using LibEQOL library

local ADDON_NAME, Catfish = ...

local Options = {}
Catfish.UI.Options = Options

Options.category = nil

-- Local reference to LibEQOL
local SettingsLib = nil

-- Ignore modifier-only keys for keybinding
local ignoreKeys = {
    ["BUTTON1"] = true, ["BUTTON2"] = true,
    ["UNKNOWN"] = true,
    ["LSHIFT"] = true, ["LCTRL"] = true, ["LALT"] = true,
    ["RSHIFT"] = true, ["RCTRL"] = true, ["RALT"] = true,
}

-- ============================================
-- Initialize Settings with LibEQOL
-- ============================================

function Options:Init()
    if self.category then return end

    -- Get LibEQOL
    SettingsLib = LibStub and LibStub("LibEQOLSettingsMode-1.0")

    -- Check if LibEQOL is available
    if not SettingsLib then
        Catfish:Print("LibEQOL not found, using fallback settings")
        self:InitFallback()
        return
    end

    -- Set prefix for settings keys
    SettingsLib:SetVariablePrefix("CF_")

    -- Create root category
    local cat = SettingsLib:CreateRootCategory("Catfish")
    self.category = cat

    -- Build all settings
    self:BuildSettings(cat)

    -- Hook SettingsPanel close to exit keybind capture mode
    if SettingsPanel then
        SettingsPanel:HookScript("OnHide", function()
            Options:OnClose()
        end)
    end

    Catfish:Debug("Options panel registered with LibEQOL")
end

-- ============================================
-- Fallback Initialization (without LibEQOL)
-- ============================================

function Options:InitFallback()
    local panel = CreateFrame("Frame", "CatfishOptionsPanel")
    panel.name = "Catfish"
    self.panel = panel

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Catfish - " .. (Catfish.version or "1.0.0"))

    local category = Settings.RegisterCanvasLayoutCategory(panel, "Catfish")
    self.category = category
    Settings.RegisterAddOnCategory(category)

    Catfish:Debug("Options panel registered (fallback mode)")
end

-- ============================================
-- Build Settings
-- ============================================

function Options:BuildSettings(cat)
    local db = Catfish.db

    -- ============================================
    -- Fishing Mode Section
    -- ============================================

    SettingsLib:CreateHeader(cat, "钓鱼模式")

    -- One-Key Mode Checkbox
    SettingsLib:CreateCheckbox(cat, {
        key = "oneKeyEnabled",
        name = "启用一键钓鱼",
        desc = "按下一个键完成钓鱼动作",
        default = db.oneKeyEnabled or false,
        get = function() return db.oneKeyEnabled or false end,
        set = function(value)
            db.oneKeyEnabled = value
            if value then
                -- Mutually exclusive with double-click
                db.doubleClickEnabled = false
                Settings.NotifyUpdate("CF_doubleClickEnabled")
            end
            if Catfish.Modules.OneKey then
                Catfish.Modules.OneKey:SetEnabled(value)
            end
        end,
    })

    -- Keybind button text function
    local function GetKeybindText()
        return CatfishCharDB.keybinding or NOT_BOUND
    end

    -- Store button initializer for text update
    local keybindButton = SettingsLib:CreateButton(cat, {
        key = "oneKeyKeybind",
        label = "快捷键绑定",
        text = GetKeybindText(),
        desc = "点击设置一键钓鱼的快捷键",
        click = function(buttonFrame)
            -- Suppress OnEditFocusLost for this click
            Options._suppressFocusLost = true
            -- Left-click only (LibEQOL doesn't pass button type)
            -- Toggle capture mode
            if Options:IsKeybindCaptureActive() then
                Options:HideKeybindCapture()
            else
                Options:ShowKeybindCapture(buttonFrame)
            end
        end,
    })

    -- Hook InitFrame to capture the actual frame reference and handle right-click
    if keybindButton and keybindButton.InitFrame then
        local origInitFrame = keybindButton.InitFrame
        keybindButton.InitFrame = function(self, frame, ...)
            Options.keybindButtonFrame = frame
            -- Enable right-click on the button
            if frame.Button then
                frame.Button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                frame.Button:HookScript("PostClick", function(self, btn)
                    if btn == "RightButton" then
                        -- Right-click clears binding
                        if Catfish.Modules.OneKey then
                            Catfish.Modules.OneKey:SetKeybind(nil)
                        end
                        Options:UpdateKeybindButtonText()
                        Options:HideKeybindCapture()
                    end
                end)
            end
            return origInitFrame(self, frame, ...)
        end
    end

    self.keybindButtonInit = keybindButton

    -- Double-Click Mode Checkbox
    SettingsLib:CreateCheckbox(cat, {
        key = "doubleClickEnabled",
        name = "启用双击钓鱼",
        desc = "快速双击鼠标右键开始钓鱼",
        default = db.doubleClickEnabled or false,
        get = function() return db.doubleClickEnabled or false end,
        set = function(value)
            db.doubleClickEnabled = value
            if value then
                -- Mutually exclusive with one-key
                db.oneKeyEnabled = false
                Settings.NotifyUpdate("CF_oneKeyEnabled")
            end
            if Catfish.Modules.DoubleClick then
                Catfish.Modules.DoubleClick:SetEnabled(value)
            end
        end,
    })

    -- ============================================
    -- Toys Section
    -- ============================================

    SettingsLib:CreateHeader(cat, "玩具设置")

    -- Raft Dropdown
    SettingsLib:CreateDropdown(cat, {
        key = "selectedRaft",
        name = "选择钓鱼筏",
        desc = "选择游泳时要使用的钓鱼筏（选择'无'表示不使用钓鱼筏）",
        varType = Settings.VarType.String,
        default = db.toys.selectedRaft and tostring(db.toys.selectedRaft) or "",
        get = function() return db.toys.selectedRaft and tostring(db.toys.selectedRaft) or "" end,
        set = function(value)
            if value and value ~= "" then
                db.toys.selectedRaft = tonumber(value)
                db.toys.raftMode = "specific"
            else
                db.toys.selectedRaft = nil
                db.toys.raftMode = "none"
            end
        end,
        optionfunc = function()
            local options = { [""] = "无" }
            local ownedRafts = Catfish.Modules.Toys and Catfish.Modules.Toys:GetOwnedRafts() or {}
            for _, toy in ipairs(ownedRafts) do
                options[tostring(toy.toyID)] = toy.name
            end
            return options
        end,
    })

    -- Use Gigantic Bobber
    SettingsLib:CreateCheckbox(cat, {
        key = "useGiganticBobber",
        name = "使用巨型鱼漂",
        desc = "每次抛竿前自动使用\"可重复使用的巨型鱼漂\"玩具，放大鱼漂便于观察",
        default = db.useGiganticBobber or false,
        get = function() return db.useGiganticBobber or false end,
        set = function(value) db.useGiganticBobber = value end,
    })

    -- Bobber Toy Dropdown
    SettingsLib:CreateDropdown(cat, {
        key = "selectedBobberToy",
        name = "选择浮标",
        desc = "选择要使用的浮标玩具（选择'无'表示不使用自定义浮标）",
        varType = Settings.VarType.String,
        default = db.selectedBobberToy and tostring(db.selectedBobberToy) or "",
        get = function() return db.selectedBobberToy and tostring(db.selectedBobberToy) or "" end,
        set = function(value)
            if value and value ~= "" then
                db.selectedBobberToy = tonumber(value)
            else
                db.selectedBobberToy = nil
            end
        end,
        optionfunc = function()
            local options = { [""] = "无" }
            local ownedBobbers = Catfish.Modules.Toys and Catfish.Modules.Toys:GetOwnedBobbers() or {}
            -- Filter out the Gigantic Bobber (toyID 202207) - it's controlled by its own checkbox
            local GIGANTIC_BOBBER_TOY_ID = 202207
            for _, toy in ipairs(ownedBobbers) do
                if toy.toyID ~= GIGANTIC_BOBBER_TOY_ID then
                    options[tostring(toy.toyID)] = toy.name
                end
            end
            return options
        end,
    })

    -- ============================================
    -- Statistics Section
    -- ============================================

    SettingsLib:CreateHeader(cat, "统计设置")

    -- Show Stats HUD
    local showStatsHUDElement = SettingsLib:CreateCheckbox(cat, {
        key = "showStatsHUD",
        name = "显示统计 HUD",
        desc = "在屏幕上显示钓鱼统计数据（持续时间、抛竿次数、鱼获等）",
        default = true,
        get = function() return db.showStatsHUD == true end,
        set = function(value)
            db.showStatsHUD = value
            if Catfish.UI.StatsHUD then
                Catfish.UI.StatsHUD:SetEnabled(value)
            end
        end,
    })

    -- Only Count Fish (depends on showStatsHUD)
    SettingsLib:CreateCheckbox(cat, {
        key = "statsOnlyFish",
        name = "只统计鱼类",
        desc = "开启后只统计鱼类物品，排除垃圾、装备、图纸等其他物品",
        default = true,
        get = function() return db.statsOnlyFish == true end,
        set = function(value)
            db.statsOnlyFish = value
        end,
        parent = showStatsHUDElement,
        parentCheck = function() return db.showStatsHUD == true end,
    })

    -- ============================================
    -- Other Settings Section
    -- ============================================

    SettingsLib:CreateHeader(cat, "其它设置")

    -- Sound Management
    SettingsLib:CreateCheckbox(cat, {
        key = "soundManagement",
        name = "钓鱼时自动管理声音",
        desc = "激活时自动开启后台声音、关闭音乐、最大化音效音量，休眠时恢复原始设置",
        default = db.soundManagement or false,
        get = function() return db.soundManagement or false end,
        set = function(value)
            db.soundManagement = value
            if Catfish.Modules.SoundManager then
                Catfish.Modules.SoundManager:SetEnabled(value)
            end
        end,
    })

    -- Keep Auto Loot
    SettingsLib:CreateCheckbox(cat, {
        key = "keepAutoLoot",
        name = "保持自动拾取",
        desc = "每次抛竿时自动检查并开启自动拾取功能",
        default = db.keepAutoLoot or false,
        get = function() return db.keepAutoLoot or false end,
        set = function(value) db.keepAutoLoot = value end,
    })

    -- Hide Minimap Button
    SettingsLib:CreateCheckbox(cat, {
        key = "hideMinimap",
        name = "隐藏小地图按钮",
        desc = "隐藏小地图上的插件按钮",
        default = Catfish.charDB.minimap.hide or false,
        get = function() return Catfish.charDB.minimap.hide or false end,
        set = function(value)
            Catfish.charDB.minimap.hide = value
            if Catfish.UI.MinimapButton then
                if value then
                    Catfish.UI.MinimapButton:Hide()
                else
                    Catfish.UI.MinimapButton:Show()
                end
            end
        end,
    })

    -- Debug Mode
    SettingsLib:CreateCheckbox(cat, {
        key = "debugMode",
        name = "启用调试模式",
        desc = "在聊天框输出详细的调试信息，用于排查问题",
        default = db.debugMode or false,
        get = function() return db.debugMode or false end,
        set = function(value) db.debugMode = value end,
    })

    -- ============================================
    -- The War Within Section (至暗之夜)
    -- ============================================

    SettingsLib:CreateHeader(cat, "至暗之夜")

    -- Treasure Chest Sound (The War Within feature)
    SettingsLib:CreateCheckbox(cat, {
        key = "treasureChestSound",
        name = "宝箱出现提示音",
        desc = "钓鱼时出现藏宝箱时播放提示音（至暗之夜版本功能）",
        default = db.treasureChestSound or true,
        get = function() return db.treasureChestSound ~= false end,
        set = function(value) db.treasureChestSound = value end,
    })
end

-- ============================================
-- Keybind Capture
-- ============================================

-- Check if keybind capture mode is active
function Options:IsKeybindCaptureActive()
    return self.keybindCapture and self.keybindCapture:IsShown()
end

-- Hide keybind capture and reset button highlight
function Options:HideKeybindCapture()
    if self.keybindCapture then
        self.keybindCapture:Hide()
        self.keybindCapture:ClearFocus()
    end
    -- Reset button highlight
    self:SetButtonHighlight(false)
end

-- Flag to prevent OnEditFocusLost from hiding during button click
Options._suppressFocusLost = false

-- Set button highlight state
function Options:SetButtonHighlight(highlight)
    local frame = self.keybindButtonFrame
    if frame and frame.Button then
        if highlight then
            -- Lock button in highlight state
            frame.Button:LockHighlight()
        else
            -- Unlock button highlight
            frame.Button:UnlockHighlight()
        end
    end
end

function Options:ShowKeybindCapture(buttonFrame)
    if not self.keybindCapture then
        self:CreateKeybindCapture()
    end

    -- Set button highlight
    self:SetButtonHighlight(true)

    self.keybindCapture:Show()
    self.keybindCapture:SetFocus()

    -- Position hint box above the button (after Show for proper rendering)
    if buttonFrame and self.keybindCapture.hintBox then
        local hintBox = self.keybindCapture.hintBox
        hintBox:ClearAllPoints()
        hintBox:SetPoint("BOTTOM", buttonFrame, "TOP", 0, 10)
        hintBox:Show()
    end
end

function Options:CreateKeybindCapture()
    -- Create a frame to capture key input
    local frame = CreateFrame("EditBox", "CatfishKeybindCapture", UIParent)
    frame:SetSize(1, 1)  -- Minimal size, invisible
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(1000)
    frame:SetAutoFocus(false)

    -- Hint box positioned above the button (simplified content)
    local hintBox = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    hintBox:SetSize(320, 35)
    hintBox:SetFrameStrata("FULLSCREEN_DIALOG")
    hintBox:SetFrameLevel(1001)
    hintBox:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    hintBox:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    hintBox:SetBackdropBorderColor(0.4, 0.6, 0.8)
    hintBox:Hide()

    -- Single instruction line
    local hint = hintBox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    hint:SetPoint("CENTER", hintBox, "CENTER", 0, 0)
    hint:SetText("按下按键设置，ESC取消，右键清除绑定")

    frame.hintBox = hintBox

    -- OnKeyDown handler
    frame:SetScript("OnKeyDown", function(self, key)
        -- ESC cancels the binding mode (does NOT clear the binding)
        if key == "ESCAPE" then
            self.hintBox:Hide()
            self:Hide()
            self:ClearFocus()
            Options:SetButtonHighlight(false)
            return
        end

        -- Ignore modifier-only keys
        if ignoreKeys[key] then return end

        -- Build the key string with modifiers
        local keyStr = key
        if IsShiftKeyDown() then
            keyStr = "SHIFT-" .. keyStr
        end
        if IsControlKeyDown() then
            keyStr = "CTRL-" .. keyStr
        end
        if IsAltKeyDown() then
            keyStr = "ALT-" .. keyStr
        end

        -- Set the keybind
        if Catfish.Modules.OneKey then
            Catfish.Modules.OneKey:SetKeybind(keyStr)
        end

        self.hintBox:Hide()
        self:Hide()
        self:ClearFocus()
        -- Update button display and reset highlight
        Options:UpdateKeybindButtonText()
        Options:SetButtonHighlight(false)
    end)

    -- Show hint box when frame is shown
    frame:SetScript("OnShow", function(self)
        self.hintBox:Show()
    end)

    frame:SetScript("OnHide", function(self)
        self.hintBox:Hide()
    end)

    frame:SetScript("OnEditFocusLost", function(self)
        -- Skip if suppressed (button click is handling this)
        if Options._suppressFocusLost then
            Options._suppressFocusLost = false
            return
        end
        Options:HideKeybindCapture()
    end)

    -- Right-click on hint box clears binding
    hintBox:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            if Catfish.Modules.OneKey then
                Catfish.Modules.OneKey:SetKeybind(nil)
            end
            Options:UpdateKeybindButtonText()
        end
        Options:HideKeybindCapture()
    end)

    self.keybindCapture = frame
end

-- Update the keybind button text to reflect current binding
function Options:UpdateKeybindButtonText()
    local newText = CatfishCharDB.keybinding or NOT_BOUND

    -- Update initializer data
    if self.keybindButtonInit and self.keybindButtonInit.data then
        self.keybindButtonInit.data.text = newText
    end

    -- Update the button text FontString directly
    if self.keybindButtonFrame then
        local frame = self.keybindButtonFrame
        -- The button frame should have a Button child with Text
        if frame.Button and frame.Button.Text then
            frame.Button.Text:SetText(newText)
        end
    end

    -- Refresh the settings panel
    if SettingsPanel and SettingsPanel.RepairDisplay then
        SettingsPanel:RepairDisplay()
    end
end

-- ============================================
-- Open Settings
-- ============================================

function Options:Open()
    if not self.category then
        self:Init()
    end
    if self.category then
        Settings.OpenToCategory(self.category:GetID())
        -- Update keybind button text when opening settings
        self:UpdateKeybindButtonText()
    end
end

-- Called when settings panel is closed
function Options:OnClose()
    -- Exit keybind capture mode if active
    self:HideKeybindCapture()
end