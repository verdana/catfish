-- Catfish - Options.lua
-- Settings panel using LibEQOL library

local ADDON_NAME, Catfish = ...

local Options = {}
Catfish.UI.Options = Options

Options.category = nil
Options.keybindButton = nil

-- Local reference to LibEQOL
local SettingsLib = nil

-- ============================================
-- Keybinding Button Widget (Custom Implementation)
-- ============================================

local function CreateKeybindingButton(parent, onSet, onGet)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(180, 24)

    -- Button textures
    local normalTexture = button:CreateTexture()
    normalTexture:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
    normalTexture:SetTexCoord(0, 0.625, 0, 0.6875)
    normalTexture:SetAllPoints()
    button:SetNormalTexture(normalTexture)

    local highlightTexture = button:CreateTexture()
    highlightTexture:SetTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
    highlightTexture:SetTexCoord(0, 0.625, 0, 0.6875)
    highlightTexture:SetAllPoints()
    button:SetHighlightTexture(highlightTexture)

    local pushedTexture = button:CreateTexture()
    pushedTexture:SetTexture("Interface\\Buttons\\UI-Panel-Button-Down")
    pushedTexture:SetTexCoord(0, 0.625, 0, 0.6875)
    pushedTexture:SetAllPoints()
    button:SetPushedTexture(pushedTexture)

    -- Button text
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    button.text:SetPoint("CENTER")
    button:SetText(NOT_BOUND)

    -- State
    button.waitingForKey = false
    button.currentKey = nil

    -- Message frame for capture mode
    local msgFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    msgFrame:SetSize(400, 30)
    msgFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    msgFrame:SetBackdropColor(0, 0, 0, 1)
    msgFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    msgFrame:SetFrameLevel(1000)
    msgFrame:Hide()

    local msgText = msgFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    msgText:SetPoint("CENTER")
    msgText:SetText("按下按键设置快捷键，按ESC清除，点击按钮取消")
    msgFrame:SetPoint("BOTTOM", button, "TOP", 0, 5)

    button.msgFrame = msgFrame

    function button:SetKey(key)
        self.currentKey = key
        if key and key ~= "" then
            self.text:SetText(key)
            self.text:SetTextColor(1, 1, 1)
        else
            self.text:SetText(NOT_BOUND)
        end
    end

    function button:GetKey()
        return self.currentKey
    end

    function button:StartCapture()
        self.waitingForKey = true
        self:EnableKeyboard(true)
        self:SetPropagateKeyboardInput(false)
        self.msgFrame:Show()
        self:LockHighlight()
    end

    function button:StopCapture()
        self.waitingForKey = false
        self:EnableKeyboard(false)
        self.msgFrame:Hide()
        self:UnlockHighlight()
    end

    function button:UpdateDisplay()
        if onGet then
            self:SetKey(onGet())
        end
    end

    button:SetScript("OnClick", function(self)
        if self.waitingForKey then
            self:StopCapture()
        else
            self:StartCapture()
        end
    end)

    -- Ignore these modifier-only keys
    local ignoreKeys = {
        ["LSHIFT"] = true, ["RSHIFT"] = true,
        ["LCTRL"] = true, ["RCTRL"] = true,
        ["LALT"] = true, ["RALT"] = true,
        ["UNKNOWN"] = true,
    }

    button:SetScript("OnKeyDown", function(self, key)
        if not self.waitingForKey then return end

        -- ESC clears the binding
        if key == "ESCAPE" then
            self:StopCapture()
            self:SetKey(nil)
            if onSet then onSet(nil) end
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

        self:StopCapture()

        -- Try to set the keybind
        if onSet then
            local success = onSet(keyStr)
            if success == false then
                -- Failed to set, revert display
                self:SetKey(self.currentKey)
                return
            end
        end

        self:SetKey(keyStr)
    end)

    button:EnableKeyboard(false)

    return button
end

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

    -- Keybind button - use CreateButton with current keybind text
    local currentKeybind = CatfishCharDB.keybinding or NOT_BOUND
    SettingsLib:CreateButton(cat, {
        key = "oneKeyKeybind",
        label = "快捷键绑定",
        text = currentKeybind,
        desc = "点击设置一键钓鱼的快捷键",
        click = function()
            Options:ShowKeybindDialog()
        end,
    })

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

    -- Auto Use Toys
    SettingsLib:CreateCheckbox(cat, {
        key = "autoToys",
        name = "自动使用玩具",
        desc = "钓鱼时自动使用配置的木筏、鱼漂等玩具",
        default = db.autoToys or false,
        get = function() return db.autoToys or false end,
        set = function(value) db.autoToys = value end,
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
    -- Other Settings Section
    -- ============================================

    SettingsLib:CreateHeader(cat, "其它设置")

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
end

-- ============================================
-- Keybind Dialog
-- ============================================

function Options:ShowKeybindDialog()
    if not self.keybindDialog then
        self:CreateKeybindDialog()
    end
    self.keybindDialog:Show()
    if self.keybindButton then
        self.keybindButton:UpdateDisplay()
    end
end

function Options:CreateKeybindDialog()
    -- Create a simple dialog frame
    local dialog = CreateFrame("Frame", "CatfishKeybindDialog", UIParent, "BackdropTemplate")
    dialog:SetSize(350, 120)
    dialog:SetPoint("CENTER")
    dialog:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    dialog:SetBackdropColor(0, 0, 0, 1)
    dialog:SetFrameStrata("DIALOG")
    dialog:SetFrameLevel(100)
    dialog:EnableMouse(true)
    dialog:SetMovable(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", dialog.StartMoving)
    dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
    dialog:Hide()

    -- Title
    local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", dialog, "TOP", 0, -10)
    title:SetText("设置一键钓鱼快捷键")

    -- Close on escape
    dialog:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:Hide()
        end
    end)
    dialog:SetPropagateKeyboardInput(true)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, dialog, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -2, -2)

    self.keybindDialog = dialog

    -- Create keybind button
    self.keybindButton = CreateKeybindingButton(
        dialog,
        function(key)
            if Catfish.Modules.OneKey then
                local success = Catfish.Modules.OneKey:SetKeybind(key)
                return success
            end
            return false
        end,
        function()
            if Catfish.Modules.OneKey then
                return Catfish.Modules.OneKey:GetKeybind()
            end
            return nil
        end
    )
    self.keybindButton:SetPoint("CENTER", dialog, "CENTER", 0, -10)
    self.keybindButton:UpdateDisplay()

    -- Instructions
    local hint = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hint:SetPoint("BOTTOM", dialog, "BOTTOM", 0, 10)
    hint:SetText("按ESC清除快捷键")
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
    end
end

-- ============================================
-- Refresh Keybind Button Display
-- ============================================

function Options:RefreshKeybindButton()
    if self.keybindButton then
        self.keybindButton:UpdateDisplay()
    end
end