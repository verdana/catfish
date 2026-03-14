-- Catfish - StatsWindow.lua
-- Statistics display window

local ADDON_NAME, Catfish = ...

local StatsWindow = {}
Catfish.UI.StatsWindow = StatsWindow

-- Window frame
StatsWindow.frame = nil
StatsWindow.currentView = "overview"

-- ============================================
-- Window Creation
-- ============================================

function StatsWindow:Init()
    if self.frame then return end

    -- Create main frame
    self.frame = CreateFrame("Frame", "CatfishStatsWindow", UIParent, "BasicFrameTemplateWithInset")
    self.frame:SetSize(400, 450)
    self.frame:SetPoint("CENTER")
    self.frame:SetMovable(true)
    self.frame:EnableMouse(true)
    self.frame:RegisterForDrag("LeftButton")
    self.frame:SetScript("OnDragStart", self.frame.StartMoving)
    self.frame:SetScript("OnDragStop", self.frame.StopMovingOrSizing)
    self.frame:SetClampedToScreen(true)

    -- Set title
    self.frame.title = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.frame.title:SetPoint("TOP", self.frame, "TOP", 0, -5)
    self.frame.title:SetText("Catfish Statistics")

    -- Create view tabs
    self:CreateViewTabs()

    -- Create content area
    self.content = CreateFrame("Frame", nil, self.frame)
    self.content:SetSize(370, 350)
    self.content:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10, -50)

    -- Show overview
    self:ShowOverview()

    Catfish:Debug("Stats window initialized")
end

-- ============================================
-- View Tabs
-- ============================================

function StatsWindow:CreateViewTabs()
    local views = {"Overview", "Items", "Zones", "Rares"}

    for i, view in ipairs(views) do
        local tab = CreateFrame("Button", nil, self.frame)
        tab:SetSize(80, 25)
        tab:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 15 + (i - 1) * 90, -28)
        tab:SetNormalFontObject("GameFontNormalSmall")
        tab:SetText(view)

        tab:SetNormalTexture("Interface\\ChatFrame\\ChatFrameBackground")
        tab:GetNormalTexture():SetColorTexture(0.2, 0.2, 0.2, 0.5)

        tab:SetScript("OnClick", function()
            self:SelectView(view:lower())
        end)

        self["tab" .. view] = tab
    end
end

function StatsWindow:SelectView(view)
    self.currentView = view

    -- Clear content
    for i = 1, self.content:GetNumChildren() do
        local child = select(i, self.content:GetChildren())
        if child then child:Hide() end
    end

    -- Show selected view
    if view == "overview" then
        self:ShowOverview()
    elseif view == "items" then
        self:ShowItems()
    elseif view == "zones" then
        self:ShowZones()
    elseif view == "rares" then
        self:ShowRares()
    end
end

-- ============================================
-- Overview View
-- ============================================

function StatsWindow:ShowOverview()
    local stats = Catfish.db.stats
    local yOffset = -10

    -- Total catches
    local totalCatches = self.content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    totalCatches:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, yOffset)
    totalCatches:SetText("Total Catches: " .. (stats.total.catches or 0))
    yOffset = yOffset - 30

    -- Total time
    local totalTime = self.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    totalTime:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, yOffset)
    totalTime:SetText("Total Fishing Time: " .. self:FormatTime(stats.total.time or 0))
    yOffset = yOffset - 25

    -- Catches per hour
    local totalCatches = stats.total.catches or 0
    local totalSeconds = stats.total.time or 0
    local cph = totalSeconds > 0 and (totalCatches / totalSeconds * 3600) or 0

    local cphText = self.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cphText:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, yOffset)
    cphText:SetText(string.format("Catches per Hour: %.1f", cph))
    yOffset = yOffset - 40

    -- Session stats
    if Catfish.Modules.Statistics then
        local sessionCatches = Catfish.Modules.Statistics:GetSessionCatches()
        local sessionTime = Catfish.Modules.Statistics:GetSessionTime()

        local sessionLabel = self.content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        sessionLabel:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, yOffset)
        sessionLabel:SetText("Current Session")
        yOffset = yOffset - 25

        local sessionCatchesText = self.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        sessionCatchesText:SetPoint("TOPLEFT", self.content, "TOPLEFT", 20, yOffset)
        sessionCatchesText:SetText("Catches: " .. sessionCatches)
        yOffset = yOffset - 20

        local sessionTimeText = self.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        sessionTimeText:SetPoint("TOPLEFT", self.content, "TOPLEFT", 20, yOffset)
        sessionTimeText:SetText("Time: " .. self:FormatTime(sessionTime))
        yOffset = yOffset - 40
    end

    -- Unique items
    local uniqueItems = 0
    for _ in pairs(stats.items) do uniqueItems = uniqueItems + 1 end

    local uniqueText = self.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    uniqueText:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, yOffset)
    uniqueText:SetText("Unique Items Caught: " .. uniqueItems)
end

-- ============================================
-- Items View
-- ============================================

function StatsWindow:ShowItems()
    local stats = Catfish.db.stats

    -- Create scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, self.content, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(340, 340)
    scrollFrame:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, 0)

    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetSize(320, 1000)
    scrollFrame:SetScrollChild(scrollContent)

    -- Get and sort items
    local items = {}
    for itemID, data in pairs(stats.items) do
        table.insert(items, {
            itemID = itemID,
            name = data.name or "Unknown",
            count = data.count,
            quality = data.quality or 0,
        })
    end
    table.sort(items, function(a, b) return a.count > b.count end)

    -- Populate list
    local yOffset = -5
    for i, item in ipairs(items) do
        local itemText = scrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        itemText:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 5, yOffset)
        itemText:SetText(i .. ". " .. item.name .. " - " .. item.count)
        yOffset = yOffset - 20
    end
end

-- ============================================
-- Zones View
-- ============================================

function StatsWindow:ShowZones()
    local stats = Catfish.db.stats

    -- Create scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, self.content, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(340, 340)
    scrollFrame:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, 0)

    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetSize(320, 1000)
    scrollFrame:SetScrollChild(scrollContent)

    -- Get and sort zones
    local zones = {}
    for zoneID, data in pairs(stats.zones) do
        table.insert(zones, {
            zoneID = zoneID,
            name = data.name or "Unknown Zone",
            catches = data.catches,
        })
    end
    table.sort(zones, function(a, b) return a.catches > b.catches end)

    -- Populate list
    local yOffset = -5
    for i, zone in ipairs(zones) do
        local zoneText = scrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        zoneText:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 5, yOffset)
        zoneText:SetText(i .. ". " .. zone.name .. " - " .. zone.catches .. " catches")
        yOffset = yOffset - 20
    end
end

-- ============================================
-- Rares View
-- ============================================

function StatsWindow:ShowRares()
    local stats = Catfish.db.stats

    -- Create scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, self.content, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(340, 340)
    scrollFrame:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, 0)

    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetSize(320, 2000)
    scrollFrame:SetScrollChild(scrollContent)

    -- Get rare catches
    local rares = {}
    for itemID, catches in pairs(stats.rareCatches) do
        local itemName = Catfish.API:GetItemName(itemID) or "Unknown"
        for _, catch in ipairs(catches) do
            table.insert(rares, {
                itemID = itemID,
                name = itemName,
                timestamp = catch.timestamp,
                zone = catch.subZone or "Unknown",
            })
        end
    end

    -- Sort by timestamp (newest first)
    table.sort(rares, function(a, b) return a.timestamp > b.timestamp end)

    if #rares == 0 then
        local noRares = scrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noRares:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 5, -5)
        noRares:SetText("No rare catches recorded yet!")
    else
        local yOffset = -5
        for i, rare in ipairs(rares) do
            local dateStr = date("%Y-%m-%d %H:%M", rare.timestamp)

            local rareText = scrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            rareText:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 5, yOffset)
            rareText:SetText(rare.name)
            yOffset = yOffset - 15

            local detailText = scrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            detailText:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 20, yOffset)
            detailText:SetText(dateStr .. " at " .. rare.zone)
            detailText:SetTextColor(0.7, 0.7, 0.7)
            yOffset = yOffset - 25
        end
    end
end

-- ============================================
-- Helpers
-- ============================================

function StatsWindow:FormatTime(seconds)
    if not seconds or seconds <= 0 then
        return "0m"
    end
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    if hours > 0 then
        return string.format("%dh %dm", hours, minutes)
    else
        return string.format("%dm", minutes)
    end
end

-- ============================================
-- Window Control
-- ============================================

function StatsWindow:Toggle()
    if not self.frame then
        self:Init()
    end

    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self:Refresh()
        self.frame:Show()
    end
end

function StatsWindow:Show()
    if not self.frame then
        self:Init()
    end
    self:Refresh()
    self.frame:Show()
end

function StatsWindow:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

function StatsWindow:Refresh()
    -- Rebuild current view
    self:SelectView(self.currentView)
end