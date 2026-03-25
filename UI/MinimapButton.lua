-- Catfish - MinimapButton.lua
-- Minimap button for quick access

local ADDON_NAME, Catfish = ...

local MinimapButton = {}
Catfish.UI.MinimapButton = MinimapButton

-- Button frame
MinimapButton.button = nil

-- Dragging state
MinimapButton.isDragging = false

-- ============================================
-- Button Creation
-- ============================================

function MinimapButton:Init()
    if self.button then return end

    -- Create minimap button
    self.button = CreateFrame("Button", "CatfishMinimapButton", MinimapCluster)
    self.button:SetFrameStrata("MEDIUM")
    self.button:SetFrameLevel(8)
    self.button:SetSize(32, 32)
    self.button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    -- Create overlay texture
    local overlay = self.button:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(53, 53)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetVertexColor(0.1, 0.6, 0.6, 0.7)  -- 青色边框，与EnhanceQoL一致
    overlay:SetPoint("TOPLEFT", 0, 0)

    -- Create icon texture
    local icon = self.button:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Fish_52")
    icon:SetPoint("CENTER", 0, 1)
    self.button.icon = icon

    -- Position
    self:UpdatePosition()

    -- Set up drag functionality - restrict to minimap edge
    self.button:RegisterForDrag("LeftButton")
    self.button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    self.button:SetScript("OnDragStart", function(btn)
        self.isDragging = true
    end)

    self.button:SetScript("OnUpdate", function(btn, elapsed)
        if self.isDragging then
            self:UpdateDragPosition()
        end
    end)

    self.button:SetScript("OnDragStop", function(btn)
        self.isDragging = false
        self:SavePosition()
    end)

    -- Click handlers
    self.button:SetScript("OnClick", function(btn, button)
        if button == "LeftButton" then
            self:OnLeftClick()
        elseif button == "RightButton" then
            self:OnRightClick()
        end
    end)

    -- Tooltip
    self.button:SetScript("OnEnter", function(btn)
        self:OnEnter()
    end)

    self.button:SetScript("OnLeave", function(btn)
        GameTooltip:Hide()
    end)

    -- Show/hide based on settings
    if Catfish.charDB.minimap.hide then
        self.button:Hide()
    end

    -- Update icon state for active/sleep mode
    self:UpdateIconState()

    Catfish:Debug("Minimap button initialized")
end

-- ============================================
-- Position Management
-- ============================================

-- Button radius offset (how far outside the minimap edge the button sits)
local BUTTON_RADIUS_OFFSET = 5

function MinimapButton:UpdatePosition()
    local angle = Catfish.charDB.minimap.minimapPos or 45
    local radian = math.rad(angle)

    -- Calculate minimap radius dynamically (half of width/height)
    local minimapWidth = Minimap:GetWidth() / 2
    local minimapHeight = Minimap:GetHeight() / 2

    -- Button distance from center = minimap radius + offset
    local radiusX = minimapWidth + BUTTON_RADIUS_OFFSET
    local radiusY = minimapHeight + BUTTON_RADIUS_OFFSET

    local x = math.cos(radian) * radiusX
    local y = math.sin(radian) * radiusY

    self.button:ClearAllPoints()
    self.button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function MinimapButton:UpdateDragPosition()
    -- Get cursor position relative to minimap center
    local mx, my = Minimap:GetCenter()
    local scale = Minimap:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    cx, cy = cx / scale, cy / scale

    -- Calculate angle from minimap center to cursor
    local dx = cx - mx
    local dy = cy - my
    local angle = math.deg(math.atan2(dy, dx))

    -- Update position along minimap edge
    Catfish.charDB.minimap.minimapPos = angle
    self:UpdatePosition()
end

function MinimapButton:SavePosition()
    -- Position is already saved during drag, just update icon state
    self:UpdateIconState()
end

-- ============================================
-- Click Handlers
-- ============================================

function MinimapButton:OnLeftClick()
    -- Ctrl+左键：切换统计 HUD
    if IsControlKeyDown() then
        if Catfish.UI.StatsHUD then
            Catfish.UI.StatsHUD:Toggle()
        end
        return
    end
    -- 普通左键：打开设置面板
    if Catfish.UI.Options then
        Catfish.UI.Options:Open()
    end
end

function MinimapButton:OnRightClick()
    -- Directly toggle sleep/active mode
    self:ToggleMode()
end

-- ============================================
-- Tooltip
-- ============================================

function MinimapButton:OnEnter()
    GameTooltip:SetOwner(self.button, "ANCHOR_LEFT")
    GameTooltip:AddLine("Catfish - 钓鱼助手")
    GameTooltip:AddLine(" ")

    -- Mode status (Active/Sleep)
    if Catfish.db.sleepMode then
        GameTooltip:AddDoubleLine("状态:", "|cFF808080休眠|r", 1, 1, 1)
    else
        GameTooltip:AddDoubleLine("状态:", "|cFF00FF00激活|r", 1, 1, 1)
    end
    GameTooltip:AddLine(" ")

    -- Current mode
    local mode = "未启用"
    if Catfish.db.oneKeyEnabled then
        local key = Catfish.Modules.OneKey:GetKeybind() or "未设置"
        mode = "一键模式 (" .. key .. ")"
    elseif Catfish.db.doubleClickEnabled then
        mode = "双击模式 (右键双击)"
    end
    GameTooltip:AddDoubleLine("钓鱼模式:", mode, 1, 1, 1)

    -- Session stats
    if Catfish.Modules.Statistics then
        local catches = Catfish.Modules.Statistics:GetSessionCatches()
        local time = Catfish.Modules.Statistics:GetSessionTime()
        GameTooltip:AddDoubleLine("本次钓获:", catches, 1, 1, 1)
        GameTooltip:AddDoubleLine("钓鱼时间:", Catfish.Modules.Statistics:FormatTime(time), 1, 1, 1)
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cFFFFFF00左键|r 打开设置", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("|cFFFFFF00Ctrl+左键|r 统计HUD", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("|cFFFFFF00右键|r 切换激活/休眠", 0.7, 0.7, 0.7)

    GameTooltip:Show()
end

-- ============================================
-- Show/Hide
-- ============================================

function MinimapButton:Show()
    if self.button then
        self.button:Show()
        Catfish.charDB.minimap.hide = false
    end
end

function MinimapButton:Hide()
    if self.button then
        self.button:Hide()
        Catfish.charDB.minimap.hide = true
    end
end

function MinimapButton:Toggle()
    if self.button and self.button:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

-- ============================================
-- Icon State (Active/Sleep Mode)
-- ============================================

function MinimapButton:UpdateIconState()
    if not self.button or not self.button.icon then return end

    if Catfish.db.sleepMode then
        -- Sleep mode: dimmed gray icon
        self.button.icon:SetVertexColor(0.4, 0.4, 0.4, 0.7)
    else
        -- Active mode: normal bright icon
        self.button.icon:SetVertexColor(1, 1, 1, 1)
    end
end

function MinimapButton:SetActiveMode()
    Catfish.db.sleepMode = false
    self:UpdateIconState()
    -- Restore bindings when exiting sleep mode
    if Catfish.Modules.OneKey then
        Catfish.Modules.OneKey:RestoreBinding()
    end
    if Catfish.Modules.DoubleClick then
        Catfish.Modules.DoubleClick:RestoreBinding()
    end
    -- Apply sound settings when activating
    if Catfish.Modules.SoundManager then
        Catfish.Modules.SoundManager:OnActivate()
    end
    -- Show HUD if enabled in settings
    if Catfish.db.showStatsHUD and Catfish.UI.StatsHUD then
        Catfish.UI.StatsHUD:Show()
    end
    Catfish:Print("已激活")
end

function MinimapButton:SetSleepMode()
    Catfish.db.sleepMode = true
    self:UpdateIconState()
    -- Clear bindings when entering sleep mode
    if Catfish.Modules.OneKey then
        Catfish.Modules.OneKey:ClearBinding()
    end
    if Catfish.Modules.DoubleClick then
        Catfish.Modules.DoubleClick:ClearBinding()
    end
    -- Restore sound settings when sleeping
    if Catfish.Modules.SoundManager then
        Catfish.Modules.SoundManager:OnSleep()
    end
    -- Hide HUD if enabled in settings
    if Catfish.db.showStatsHUD and Catfish.UI.StatsHUD then
        Catfish.UI.StatsHUD:Hide()
    end
    Catfish:Print("已休眠")
end

function MinimapButton:ToggleMode()
    if Catfish.db.sleepMode then
        self:SetActiveMode()
    else
        self:SetSleepMode()
    end
end

function MinimapButton:IsSleepMode()
    return Catfish.db.sleepMode or false
end
