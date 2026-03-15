-- Catfish - Options.lua
-- Integration with WoW Settings Panel (ESC -> Options -> AddOns)

local ADDON_NAME, Catfish = ...

local Options = {}
Catfish.UI.Options = Options

-- Category reference
Options.category = nil
Options.generalCategory = nil

-- ============================================
-- Keybinding Button Widget
-- ============================================

local function CreateKeybindingButton(parent, onSet)
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

    -- Highlight background for capture mode
    local captureBg = button:CreateTexture(nil, "BACKGROUND")
    captureBg:SetColorTexture(1, 1, 0, 0)
    captureBg:SetAllPoints()
    button.captureBg = captureBg

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
            -- self.text:SetTextColor(0.5, 0.5, 0.5)
        end
    end

    function button:GetKey()
        return self.currentKey
    end

    function button:StartCapture()
        self.waitingForKey = true
        -- self.captureBg:SetColorTexture(1, 1, 0, 0.3)
        self:EnableKeyboard(true)
        self:SetPropagateKeyboardInput(false)
        self.msgFrame:Show()
        self:LockHighlight()
    end

    function button:StopCapture()
        self.waitingForKey = false
        -- self.captureBg:SetColorTexture(1, 1, 0, 0)
        self:EnableKeyboard(false)
        self.msgFrame:Hide()
        self:UnlockHighlight()
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
-- Panel Header Helper (标题栏 + 分割线)
-- ============================================

local function CreatePanelHeader(panel, title, onReset)
    -- 标题文字（左侧）
    local titleText = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    titleText:SetPoint("TOPLEFT", 16, -16)
    titleText:SetText(title)

    -- 重置按钮（右侧）
    if onReset then
        local resetBtn = CreateFrame("Button", nil, panel, "EditModeSystemSettingsDialogButtonTemplate")
        resetBtn:SetPoint("TOPRIGHT", -16, -10)
        resetBtn:SetText("默认")
        resetBtn:SetSize(60, 22)
        resetBtn:SetOnClickHandler(onReset)
    end

    -- 白色渐变分割线
    local divider = panel:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(16)
    divider:SetPoint("TOPLEFT", 16, -40)
    divider:SetPoint("TOPRIGHT", -16, -40)
    divider:SetTexture([[Interface\FriendsFrame\UI-FriendsFrame-OnlineDivider]])

    return titleText, divider
end

-- ============================================
-- About Panel (Default view)
-- ============================================

local function CreateAboutPanel()
    local panel = CreateFrame("Frame", "CatfishAboutPanel")
    panel.name = "Catfish"

    -- 标题栏 + 分割线
    CreatePanelHeader(panel, "鲶鱼 - 钓鱼助手")

    -- Icon (从分割线下方开始)
    local icon = panel:CreateTexture(nil, "ARTWORK")
    icon:SetSize(64, 64)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Fish_52")
    icon:SetPoint("TOPLEFT", 16, -60)

    -- Version info
    local version = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    version:SetPoint("TOPLEFT", icon, "TOPRIGHT", 16, 0)
    version:SetText("版本: " .. (Catfish.version or "1.0.0"))

    local author = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    author:SetPoint("TOPLEFT", version, "BOTTOMLEFT", 0, -4)
    author:SetText("作者: Verdana")

    -- Description
    local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", author, "BOTTOMLEFT", 0, -16)
    desc:SetWidth(400)
    desc:SetJustifyH("LEFT")
    desc:SetText("功能丰富的钓鱼助手，支持：\n• 一键钓鱼 / 双击钓鱼模式\n• 自动装备钓具\n• 自动使用鱼饵和玩具\n• 钓鱼统计")

    -- Required methods for Settings API
    function panel:OnCommit() end
    function panel:OnDefault() end
    function panel:OnRefresh() end

    return panel
end

-- ============================================
-- Main Settings Panel (综合)
-- ============================================

local function CreateMainPanel()
    local panel = CreateFrame("Frame", "CatfishMainPanel")
    panel.name = "综合"
    panel:Hide()

    -- 标题栏 + 分割线 + 默认按钮
    CreatePanelHeader(panel, "综合", function()
        -- 重置综合为默认值
        Catfish.db.oneKeyEnabled = false
        Catfish.db.doubleClickEnabled = false
        Catfish.charDB.minimap.hide = false
    end)

    -- 内容区从分割线下方开始
    local offsetY = -40
    local checkboxHeight = 24
    local function GetNextOffset()
        offsetY = offsetY - checkboxHeight - 8
        return offsetY
    end

    -- Create checkbox helper
    local function CreateCheckbox(label, initialValue, tooltip, callback)
        local check = CreateFrame("CheckButton", nil, panel)
        check:SetSize(24, 24)
        check:SetPoint("TOPLEFT", 16, GetNextOffset())
        check:SetChecked(initialValue)

        -- Create checkbox textures
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

        -- Create text label
        check.text = check:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        check.text:SetPoint("LEFT", check, "RIGHT", 4, 0)
        check.text:SetText(label)

        if tooltip then
            check.tooltip = tooltip
        end

        check:SetScript("OnClick", function(self)
            local checked = self:GetChecked()
            if callback then callback(checked) end
        end)

        return check
    end

    -- One-Key Mode (declare variable first for forward reference)
    local oneKeyCheck
    local doubleClickCheck

    oneKeyCheck = CreateCheckbox(
        "启用一键钓鱼",
        Catfish.db.oneKeyEnabled,
        "按下一个键完成钓鱼动作",
        function(checked)
            Catfish.db.oneKeyEnabled = checked
            if checked then
                Catfish.db.doubleClickEnabled = false
                if doubleClickCheck then
                    doubleClickCheck:SetChecked(false)
                end
                -- Disable DoubleClick module's runtime state
                if Catfish.Modules.DoubleClick then
                    Catfish.Modules.DoubleClick:SetEnabled(false)
                end
            end
            -- Update OneKey module's binding state
            if Catfish.Modules.OneKey then
                Catfish.Modules.OneKey:SetEnabled(checked)
            end
        end
    )

    -- Keybinding button (shown when one-key mode is enabled)
    local keybindLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    keybindLabel:SetPoint("TOPLEFT", oneKeyCheck, "BOTTOMLEFT", 24, -4)
    keybindLabel:SetText("快捷键")

    local keybindBtn = CreateKeybindingButton(panel, function(key)
        if Catfish.Modules.OneKey then
            return Catfish.Modules.OneKey:SetKeybind(key)
        end
        return false
    end)
    keybindBtn:SetPoint("LEFT", keybindLabel, "RIGHT", 8, 0)

    -- Set initial keybind display
    if Catfish.Modules.OneKey then
        keybindBtn:SetKey(Catfish.Modules.OneKey:GetKeybind())
    end

    offsetY = -20 - (checkboxHeight + 8) * 3  -- Account for checkboxes and keybind row

    -- Double-Click Mode
    doubleClickCheck = CreateCheckbox(
        "启用双击钓鱼",
        Catfish.db.doubleClickEnabled,
        "快速双击鼠标右键开始钓鱼",
        function(checked)
            Catfish.db.doubleClickEnabled = checked
            if checked then
                Catfish.db.oneKeyEnabled = false
                if oneKeyCheck then
                    oneKeyCheck:SetChecked(false)
                end
                -- Disable OneKey module's binding
                if Catfish.Modules.OneKey then
                    Catfish.Modules.OneKey:SetEnabled(false)
                end
            end
            if Catfish.Modules.DoubleClick then
                Catfish.Modules.DoubleClick:SetEnabled(checked)
            end
        end
    )

    -- Hide Minimap Button
    local hideMinimapCheck = CreateCheckbox(
        "隐藏小地图按钮",
        Catfish.charDB.minimap.hide,
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
        end
    )

    -- Debug Mode
    CreateCheckbox(
        "启用调试模式",
        Catfish.db.debugMode,
        "在聊天框输出详细的调试信息，用于排查问题",
        function(checked)
            Catfish.db.debugMode = checked
        end
    )

    -- Required methods for Settings API
    function panel:OnCommit() end
    function panel:OnDefault() end
    function panel:OnRefresh() end

    return panel
end

-- ============================================
-- Other Settings Panel (其它)
-- ============================================

local function CreateOtherPanel()
    local panel = CreateFrame("Frame", "CatfishOtherPanel")
    panel.name = "其它"
    panel:Hide()

    -- 标题栏 + 分割线 + 默认按钮
    CreatePanelHeader(panel, "其它", function()
        -- 重置为默认值
        Catfish.db.useGiganticBobber = false
        Catfish.db.autoToys = true
    end)

    -- 内容区从分割线下方开始
    local offsetY = -40
    local checkboxHeight = 24
    local function GetNextOffset()
        offsetY = offsetY - checkboxHeight - 8
        return offsetY
    end

    -- Create checkbox helper
    local function CreateCheckbox(label, initialValue, tooltip, callback)
        local check = CreateFrame("CheckButton", nil, panel)
        check:SetSize(24, 24)
        check:SetPoint("TOPLEFT", 16, GetNextOffset())
        check:SetChecked(initialValue)

        -- Create checkbox textures
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

        -- Create text label
        check.text = check:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        check.text:SetPoint("LEFT", check, "RIGHT", 4, 0)
        check.text:SetText(label)

        if tooltip then
            check.tooltip = tooltip
        end

        check:SetScript("OnClick", function(self)
            local checked = self:GetChecked()
            if callback then callback(checked) end
        end)

        return check
    end

    -- Auto Use Toys
    CreateCheckbox(
        "自动使用玩具",
        Catfish.db.autoToys,
        "钓鱼时自动使用配置的木筏、鱼漂等玩具",
        function(checked)
            Catfish.db.autoToys = checked
        end
    )

    -- Use Gigantic Bobber
    CreateCheckbox(
        "使用巨型鱼漂",
        Catfish.db.useGiganticBobber,
        "每次抛竿前自动使用\"可重复使用的巨型鱼漂\"玩具",
        function(checked)
            Catfish.db.useGiganticBobber = checked
        end
    )

    -- Required methods for Settings API
    function panel:OnCommit() end
    function panel:OnDefault() end
    function panel:OnRefresh() end

    return panel
end

-- ============================================
-- Initialize Settings
-- ============================================

function Options:Init()
    if self.category then return end

    -- Create about panel (main category)
    local aboutPanel = CreateAboutPanel()

    -- Register main category with Blizzard Settings
    local category, layout = Settings.RegisterCanvasLayoutCategory(aboutPanel, "Catfish")
    -- In WoW 12.0+, category.ID is automatically assigned as a number - do NOT override it
    self.category = category
    Settings.RegisterAddOnCategory(category)

    -- Create main settings panel (subcategory: 综合)
    local mainPanel = CreateMainPanel()
    mainPanel.name = "综合"
    mainPanel.parent = "Catfish"
    local mainSubcategory = Settings.RegisterCanvasLayoutSubcategory(category, mainPanel, "综合")
    self.mainCategory = mainSubcategory

    -- Create other settings panel (subcategory: 其它)
    local otherPanel = CreateOtherPanel()
    otherPanel.name = "其它"
    otherPanel.parent = "Catfish"
    local otherSubcategory = Settings.RegisterCanvasLayoutSubcategory(category, otherPanel, "其它")
    self.otherCategory = otherSubcategory

    Catfish:Debug("Options panel registered with Blizzard Settings, category ID:", category.ID)
end

function Options:Open()
    if not self.category then
        self:Init()
    end
    if self.category then
        -- Use the numeric category.ID directly (auto-assigned by WoW 12.0+)
        Settings.OpenToCategory(self.category.ID)
    end
end
