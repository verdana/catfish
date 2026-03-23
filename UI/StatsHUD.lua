-- Catfish - StatsHUD.lua
-- On-screen statistics display

local ADDON_NAME, Catfish = ...

local StatsHUD = {}
Catfish.UI.StatsHUD = StatsHUD

-- Frame reference
StatsHUD.frame = nil

-- Update interval
local UPDATE_INTERVAL = 0.5
local updateTimer = 0

-- ============================================
-- Helper: Check if item is fish
-- ============================================

local function IsFishItem(itemID)
    if not itemID then return false end
    local _, _, _, _, _, itemType, itemSubType = GetItemInfo(itemID)
    -- Fish can have itemSubType "Fish", "烹饪" (Cooking), or be in Consumable category
    -- Check if it's a fish by itemSubType
    if itemSubType == "Fish" or itemSubType == "烹饪" then
        return true
    end
    -- Also check itemType for consumables that might be fish
    if itemType == "Consumable" and (itemSubType == "Food" or itemSubType == "食物") then
        return true
    end
    return false
end

-- ============================================
-- Create HUD Frame
-- ============================================

function StatsHUD:CreateFrame()
    if self.frame then return end

    -- Create main frame
    local frame = CreateFrame("Frame", "CatfishStatsHUD", UIParent, "BackdropTemplate")
    frame:SetSize(250, 150)
    frame:SetPoint("CENTER", UIParent, "CENTER", 200, -100)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)

    -- Background
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.7)
    frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", frame, "TOP", 0, -8)
    title:SetText("|cFF00FF00Catfish 钓鱼统计|r")
    frame.title = title

    -- Content area (scrolling not needed, just stack text)
    frame.lines = {}

    -- Create initial text lines with larger spacing (18px instead of 14px)
    for i = 1, 20 do
        local line = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        line:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -30 - (i-1) * 18)
        line:SetJustifyH("LEFT")
        line:Hide()
        frame.lines[i] = line
    end

    self.frame = frame
    frame:Hide()

    Catfish:Debug("StatsHUD frame created")
end

-- ============================================
-- Update HUD Content
-- ============================================

function StatsHUD:Update()
    if not self.frame or not self.frame:IsShown() then return end

    local stats = Catfish.Modules.Statistics
    local core = Catfish.Core
    local db = Catfish.db

    if not stats or not core then return end

    -- Get session data
    local sessionTime = core:GetSessionTime()
    local totalCatches = stats:GetSessionCatches()
    local castCount = stats.sessionCasts or 0
    local items = stats:GetSessionItems()

    -- Build lines with colors
    local lines = {}
    local lineIndex = 1

    -- Gold color for summary info (WoW yellow: |cFFFFD100)
    local GOLD_COLOR = "|cFFFFD100"
    local WHITE_COLOR = "|cFFFFFFFF"
    local GRAY_COLOR = "|cFF808080"
    local END_COLOR = "|r"

    -- Item breakdown first
    local totalItems = 0
    local itemCounts = {}

    for itemID, count in pairs(items) do
        -- Filter by "only fish" setting
        if db.statsOnlyFish then
            if IsFishItem(itemID) then
                itemCounts[itemID] = count
                totalItems = totalItems + count
            end
        else
            itemCounts[itemID] = count
            totalItems = totalItems + count
        end
    end

    -- Sort by count
    local sortedItems = {}
    for itemID, count in pairs(itemCounts) do
        local itemName = Catfish.API:GetItemName(itemID) or "Unknown"
        local quality = select(3, GetItemInfo(itemID)) or 1
        table.insert(sortedItems, {itemID = itemID, name = itemName, count = count, quality = quality})
    end
    table.sort(sortedItems, function(a, b) return a.count > b.count end)

    -- Helper to get quality color
    local function GetQualityColor(quality)
        local colors = {
            [0] = "|cFF9D9D9D", -- Poor (gray)
            [1] = "|cFFFFFFFF", -- Common (white)
            [2] = "|cFF1EFF00", -- Uncommon (green)
            [3] = "|cFF0070DD", -- Rare (blue)
            [4] = "|cFFA335EE", -- Epic (purple)
            [5] = "|cFFFF8000", -- Legendary (orange)
        }
        return colors[quality] or "|cFFFFFFFF"
    end

    -- Display items (with blank line first instead of header)
    local noCatches = #sortedItems == 0
    local centerLineIndex = nil

    if noCatches then
        -- No catches: show centered message
        lines[lineIndex] = ""  -- blank line
        lineIndex = lineIndex + 1
        lines[lineIndex] = GRAY_COLOR .. "暂无收获" .. END_COLOR
        centerLineIndex = lineIndex
        lineIndex = lineIndex + 1
    else
        -- Has catches: show list with leading blank line
        lines[lineIndex] = ""
        lineIndex = lineIndex + 1

        for _, item in ipairs(sortedItems) do
            local percent = totalItems > 0 and (item.count / totalItems * 100) or 0
            local qualityColor = GetQualityColor(item.quality)
            local line = qualityColor .. item.name .. END_COLOR .. GRAY_COLOR .. ": " .. item.count .. " (" .. string.format("%.1f", percent) .. "%)" .. END_COLOR
            lines[lineIndex] = line
            lineIndex = lineIndex + 1

            if lineIndex > 17 then break end -- Limit lines, leave room for summary
        end
    end

    -- Blank line before summary
    lines[lineIndex] = ""
    lineIndex = lineIndex + 1

    -- Summary line at bottom: 耗时：xxxm   抛竿：xx  收获：xx
    -- Gold labels, white values
    local summaryLine = GOLD_COLOR .. "耗时: " .. END_COLOR .. WHITE_COLOR .. stats:FormatTime(sessionTime) .. END_COLOR
        .. GRAY_COLOR .. "   " .. END_COLOR
        .. GOLD_COLOR .. "抛竿: " .. END_COLOR .. WHITE_COLOR .. tostring(castCount) .. END_COLOR
        .. GRAY_COLOR .. "   " .. END_COLOR
        .. GOLD_COLOR .. "收获: " .. END_COLOR .. WHITE_COLOR .. tostring(totalCatches) .. END_COLOR
    lines[lineIndex] = summaryLine
    lineIndex = lineIndex + 1

    -- Update frame text
    for i, line in ipairs(self.frame.lines) do
        if lines[i] then
            line:SetText(lines[i])
            line:Show()
            -- Center the "暂无收获" line
            if centerLineIndex and i == centerLineIndex then
                line:SetJustifyH("CENTER")
            else
                line:SetJustifyH("LEFT")
            end
        else
            line:Hide()
        end
    end

    -- Adjust frame height (18px per line + header + padding)
    local height = 30 + lineIndex * 18 + 10
    self.frame:SetHeight(math.min(height, 400))
end

-- ============================================
-- OnUpdate Handler
-- ============================================

function StatsHUD:OnUpdate(elapsed)
    updateTimer = updateTimer + elapsed
    if updateTimer >= UPDATE_INTERVAL then
        updateTimer = 0
        self:Update()
    end
end

-- ============================================
-- Show/Hide
-- ============================================

function StatsHUD:Show()
    if not self.frame then
        self:CreateFrame()
    end
    self.frame:Show()
    self.frame:SetScript("OnUpdate", function(_, elapsed)
        self:OnUpdate(elapsed)
    end)
    self:Update()
end

function StatsHUD:Hide()
    if self.frame then
        self.frame:Hide()
        self.frame:SetScript("OnUpdate", nil)
    end
end

function StatsHUD:Toggle()
    if self.frame and self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

function StatsHUD:IsShown()
    return self.frame and self.frame:IsShown()
end

-- ============================================
-- Set Enabled
-- ============================================

function StatsHUD:SetEnabled(enabled)
    if enabled then
        self:Show()
    else
        self:Hide()
    end
end

-- ============================================
-- Initialization
-- ============================================

function StatsHUD:Init()
    -- Create frame but don't show yet
    self:CreateFrame()

    -- Check initial setting
    if Catfish.db.showStatsHUD then
        self:Show()
    end

    Catfish:Debug("StatsHUD module initialized")
end
