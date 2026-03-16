-- Catfish - Options.lua
-- Settings panel using WoW native Settings API

local ADDON_NAME, Catfish = ...

local Options = {}
Catfish.UI.Options = Options

Options.category = nil
Options.panel = nil

-- ============================================
-- Keybinding Button Widget
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
-- Create Checkbox Helper
-- ============================================

local function CreateCheckbox(parent, label, initialValue, tooltip, callback)
    local check = CreateFrame("CheckButton", nil, parent)
    check:SetSize(24, 24)
    check:SetChecked(initialValue)

    -- Textures
    local normalTexture = check:CreateTexture()
    normalTexture:SetTexture("Interface\\Buttons\\UI-CheckBox-Up")
    normalTexture:SetSize(24, 24)
    normalTexture:SetPoint("CENTER")
    check:SetNormalTexture(normalTexture)

    local highlightTexture = check:CreateTexture()
    highlightTexture:SetTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
    highlightTexture:SetSize(24, 24)
    highlightTexture:SetPoint("CENTER")
    check:SetHighlightTexture(highlightTexture)

    local checkedTexture = check:CreateTexture()
    checkedTexture:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    checkedTexture:SetSize(24, 24)
    checkedTexture:SetPoint("CENTER")
    check:SetCheckedTexture(checkedTexture)

    local pushedTexture = check:CreateTexture()
    pushedTexture:SetTexture("Interface\\Buttons\\UI-CheckBox-Down")
    pushedTexture:SetSize(24, 24)
    pushedTexture:SetPoint("CENTER")
    check:SetPushedTexture(pushedTexture)

    -- Label
    check.text = check:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    check.text:SetPoint("LEFT", check, "RIGHT", 4, 0)
    check.text:SetText(label)

    if tooltip then
        check:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(tooltip, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        check:SetScript("OnLeave", GameTooltip_Hide)
    end

    check:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        if callback then callback(checked) end
    end)

    return check
end

-- ============================================
-- Create Dropdown Helper
-- ============================================

local function CreateDropdownButton(parent, label, options, currentValue, callback)
    local button = CreateFrame("Button", nil, parent, "EditModeSystemSettingsDialogButtonTemplate")
    button:SetSize(160, 24)

    button.text = button:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    button.text:SetPoint("CENTER")

    local function UpdateText()
        for k, v in pairs(options) do
            if k == currentValue then
                button.text:SetText(v)
                return
            end
        end
        button.text:SetText(label or "选择...")
    end

    button:SetOnClickHandler(function()
        local function InitDropdown(_, level)
            local info = UIDropDownMenu_CreateInfo()
            info.func = function(_, key)
                currentValue = key
                UpdateText()
                if callback then callback(key) end
            end

            for key, value in pairs(options) do
                info.text = value
                info.arg1 = key
                info.checked = (currentValue == key)
                UIDropDownMenu_AddButton(info)
            end
        end

        local menu = CreateFrame("Frame", nil, UIParent, "UIDropDownMenuTemplate")
        UIDropDownMenu_Initialize(menu, InitDropdown, "MENU")
        ToggleDropDownMenu(1, nil, menu, button, 0, 0)
    end)

    UpdateText()

    return button
end

-- ============================================
-- Initialize Settings
-- ============================================

function Options:Init()
    if self.category then return end

    -- Create main panel
    local panel = CreateFrame("Frame", "CatfishOptionsPanel")
    panel.name = "Catfish"
    self.panel = panel

    -- Title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Catfish - " .. (Catfish.version or "1.0.0"))

    -- Divider
    local divider = panel:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(16)
    divider:SetPoint("TOPLEFT", 16, -40)
    divider:SetPoint("TOPRIGHT", -16, -40)
    divider:SetTexture([[Interface\FriendsFrame\UI-FriendsFrame-OnlineDivider]])

    -- Build settings
    self:BuildSettings(panel)

    -- Register with Settings API
    local category = Settings.RegisterCanvasLayoutCategory(panel, "Catfish")
    self.category = category
    Settings.RegisterAddOnCategory(category)

    Catfish:Debug("Options panel registered")
end

-- ============================================
-- Build Settings
-- ============================================

function Options:BuildSettings(panel)
    local db = Catfish.db
    local offsetY = -56
    local rowHeight = 32

    local function NextY()
        offsetY = offsetY - rowHeight
        return offsetY
    end

    -- ============================================
    -- 钓鱼模式 Section
    -- ============================================
    local sectionTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sectionTitle:SetPoint("TOPLEFT", 16, NextY())
    sectionTitle:SetText("|cFFFFD100钓鱼模式|r")

    -- One-Key Mode (forward declare doubleClickCheck for mutual exclusion)
    local doubleClickCheck
    local oneKeyCheck = CreateCheckbox(panel, "启用一键钓鱼", db.oneKeyEnabled,
        "按下一个键完成钓鱼动作",
        function(checked)
            db.oneKeyEnabled = checked
            if checked then
                -- Mutually exclusive with double-click
                db.doubleClickEnabled = false
                if doubleClickCheck then doubleClickCheck:SetChecked(false) end
                if Catfish.Modules.DoubleClick then
                    Catfish.Modules.DoubleClick:SetEnabled(false)
                end
            end
            if Catfish.Modules.OneKey then
                Catfish.Modules.OneKey:SetEnabled(checked)
            end
        end)
    oneKeyCheck:SetPoint("TOPLEFT", 16, NextY())

    -- Keybind button
    local keybindBtn = CreateKeybindingButton(panel,
        function(key)
            if Catfish.Modules.OneKey then
                return Catfish.Modules.OneKey:SetKeybind(key)
            end
            return false
        end,
        function()
            if Catfish.Modules.OneKey then
                return Catfish.Modules.OneKey:GetKeybind()
            end
            return nil
        end)
    keybindBtn:SetPoint("LEFT", oneKeyCheck.text, "RIGHT", 150, 0)
    keybindBtn:UpdateDisplay()
    self.keybindButton = keybindBtn

    -- Double-Click Mode
    doubleClickCheck = CreateCheckbox(panel, "启用双击钓鱼", db.doubleClickEnabled,
        "快速双击鼠标右键开始钓鱼",
        function(checked)
            db.doubleClickEnabled = checked
            if checked then
                -- Mutually exclusive with one-key
                db.oneKeyEnabled = false
                if oneKeyCheck then oneKeyCheck:SetChecked(false) end
                if Catfish.Modules.OneKey then
                    Catfish.Modules.OneKey:SetEnabled(false)
                end
            end
            if Catfish.Modules.DoubleClick then
                Catfish.Modules.DoubleClick:SetEnabled(checked)
            end
        end)
    doubleClickCheck:SetPoint("TOPLEFT", 16, NextY())

    -- ============================================
    -- 玩具设置 Section
    -- ============================================
    local sectionTitle2 = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sectionTitle2:SetPoint("TOPLEFT", 16, NextY() - 8)
    sectionTitle2:SetText("|cFFFFD100玩具设置|r")

    -- Auto Use Toys
    local autoToysCheck = CreateCheckbox(panel, "自动使用玩具", db.autoToys,
        "钓鱼时自动使用配置的木筏、鱼漂等玩具",
        function(checked) db.autoToys = checked end)
    autoToysCheck:SetPoint("TOPLEFT", 16, NextY())

    -- Use Gigantic Bobber
    local giganticBobberCheck = CreateCheckbox(panel, "使用巨型鱼漂", db.useGiganticBobber,
        "每次抛竿前自动使用\"可重复使用的巨型鱼漂\"玩具，放大鱼漂便于观察",
        function(checked) db.useGiganticBobber = checked end)
    giganticBobberCheck:SetPoint("TOPLEFT", 16, NextY())

    -- Use Bobber Toy
    local useBobberToyCheck = CreateCheckbox(panel, "使用浮标", db.useBobberToy,
        "每次抛竿前自动使用选择的浮标玩具改变鱼漂外观",
        function(checked) db.useBobberToy = checked end)
    useBobberToyCheck:SetPoint("TOPLEFT", 16, NextY())

    -- Bobber Toy Dropdown Button (on next line)
    local function getBobberOptions()
        local options = {}
        local ownedBobbers = Catfish.Modules.Toys and Catfish.Modules.Toys:GetOwnedBobbers() or {}
        for _, toy in ipairs(ownedBobbers) do
            options[toy.toyID] = toy.name
        end
        return options
    end

    local bobberDropdown = CreateDropdownButton(panel, "选择浮标...", getBobberOptions(), db.selectedBobberToy,
        function(value) db.selectedBobberToy = value end)
    bobberDropdown:SetPoint("TOPLEFT", 40, NextY())

    -- ============================================
    -- 其它设置 Section
    -- ============================================
    local sectionTitle3 = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sectionTitle3:SetPoint("TOPLEFT", 16, NextY() - 8)
    sectionTitle3:SetText("|cFFFFD100其它设置|r")

    -- Keep Auto Loot
    local autoLootCheck = CreateCheckbox(panel, "保持自动拾取", db.keepAutoLoot,
        "每次抛竿时自动检查并开启自动拾取功能",
        function(checked) db.keepAutoLoot = checked end)
    autoLootCheck:SetPoint("TOPLEFT", 16, NextY())

    -- Hide Minimap Button
    local hideMinimapCheck = CreateCheckbox(panel, "隐藏小地图按钮", Catfish.charDB.minimap.hide,
        "隐藏小地图上的插件按钮",
        function(checked)
            Catfish.charDB.minimap.hide = checked
            if Catfish.UI.MinimapButton then
                if checked then
                    Catfish.UI.MinimapButton:Hide()
                else
                    Catfish.UI.MinimapButton:Show()
                end
            end
        end)
    hideMinimapCheck:SetPoint("TOPLEFT", 16, NextY())

    -- Debug Mode
    local debugCheck = CreateCheckbox(panel, "启用调试模式", db.debugMode,
        "在聊天框输出详细的调试信息，用于排查问题",
        function(checked) db.debugMode = checked end)
    debugCheck:SetPoint("TOPLEFT", 16, NextY())

    -- Required methods for Settings API
    function panel:OnCommit() end
    function panel:OnDefault() end
    function panel:OnRefresh() end
end

-- ============================================
-- Open Settings
-- ============================================

function Options:Open()
    if not self.category then
        self:Init()
    end
    if self.category then
        Settings.OpenToCategory(self.category.ID)
    end
end