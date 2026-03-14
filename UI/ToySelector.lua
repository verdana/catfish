-- Catfish - ToySelector.lua
-- Toy selection interface

local ADDON_NAME, Catfish = ...

local ToySelector = {}
Catfish.UI.ToySelector = ToySelector

-- Window frame
ToySelector.frame = nil
ToySelector.selectedType = nil -- "raft" or "bobber"
ToySelector.callback = nil

-- ============================================
-- Window Creation
-- ============================================

function ToySelector:Init()
    if self.frame then return end

    -- Create main frame
    self.frame = CreateFrame("Frame", "CatfishToySelector", UIParent, "BasicFrameTemplateWithInset")
    self.frame:SetSize(350, 400)
    self.frame:SetPoint("CENTER")
    self.frame:SetMovable(true)
    self.frame:EnableMouse(true)
    self.frame:RegisterForDrag("LeftButton")
    self.frame:SetScript("OnDragStart", self.frame.StartMoving)
    self.frame:SetScript("OnDragStop", self.frame.StopMovingOrSizing)
    self.frame:SetClampedToScreen(true)
    self.frame:Hide()

    -- Set title
    self.frame.title = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.frame.title:SetPoint("TOP", self.frame, "TOP", 0, -5)
    self.frame.title:SetText("Select Toy")

    -- Create content area
    self.content = CreateFrame("Frame", nil, self.frame)
    self.content:SetSize(320, 320)
    self.content:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10, -35)

    Catfish:Debug("Toy selector initialized")
end

-- ============================================
-- Show Toy List
-- ============================================

function ToySelector:ShowForType(toyType, callback)
    if not self.frame then
        self:Init()
    end

    self.selectedType = toyType
    self.callback = callback

    -- Update title
    if toyType == "raft" then
        self.frame.title:SetText("Select Raft")
    elseif toyType == "bobber" then
        self.frame.title:SetText("Select Bobber")
    end

    -- Clear content
    for i = 1, self.content:GetNumChildren() do
        local child = select(i, self.content:GetChildren())
        if child then child:Hide() end
    end

    -- Get toys
    local toys = self:GetToysForType(toyType)

    -- Create scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, self.content, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(300, 300)
    scrollFrame:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, 0)

    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetSize(280, 1000)
    scrollFrame:SetScrollChild(scrollContent)

    -- Populate toy list
    local yOffset = -5

    -- Add "None" option
    yOffset = self:AddToyButton(scrollContent, yOffset, {
        name = "None",
        toyID = nil,
        icon = nil,
        description = "Disable this toy type",
    })

    -- Add separator
    local separator = scrollContent:CreateTexture(nil, "ARTWORK")
    separator:SetSize(260, 1)
    separator:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 10, yOffset)
    separator:SetColorTexture(0.5, 0.5, 0.5, 0.5)
    yOffset = yOffset - 15

    -- Add toys
    for _, toy in ipairs(toys) do
        yOffset = self:AddToyButton(scrollContent, yOffset, toy)
    end

    self.frame:Show()
end

function ToySelector:AddToyButton(parent, yOffset, toy)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(280, 40)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, yOffset)

    -- Background
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.2, 0.2, 0.2, 0.5)

    -- Highlight
    button:SetHighlightTexture("Interface\\ChatFrame\\ChatFrameBackground")
    button:GetHighlightTexture():SetColorTexture(0.3, 0.3, 0.3, 0.5)

    -- Icon
    if toy.icon then
        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetSize(32, 32)
        icon:SetPoint("LEFT", button, "LEFT", 5, 0)
        icon:SetTexture(toy.icon)
    end

    -- Name
    local name = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    name:SetPoint("LEFT", button, "LEFT", toy.icon and 45 or 10, 5)
    name:SetText(toy.name)

    -- Description
    if toy.description then
        local desc = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        desc:SetPoint("LEFT", button, "LEFT", toy.icon and 45 or 10, -10)
        desc:SetText(toy.description)
        desc:SetTextColor(0.7, 0.7, 0.7)
    end

    -- Click handler
    button:SetScript("OnClick", function()
        self:OnToySelected(toy)
    end)

    return yOffset - 45
end

function ToySelector:GetToysForType(toyType)
    local toys = {}

    if toyType == "raft" then
        if Catfish.Modules.Toys then
            toys = Catfish.Modules.Toys:GetOwnedRafts()
        else
            toys = Catfish.Data.Toys and Catfish.Data.Toys.Rafts or {}
        end
    elseif toyType == "bobber" then
        if Catfish.Modules.Toys then
            toys = Catfish.Modules.Toys:GetOwnedBobbers()
        else
            toys = Catfish.Data.Toys and Catfish.Data.Toys.Bobbers or {}
        end
    end

    return toys
end

-- ============================================
-- Selection Handler
-- ============================================

function ToySelector:OnToySelected(toy)
    if self.callback then
        self.callback(toy)
    end

    -- Update database
    if self.selectedType == "raft" then
        Catfish.db.toys.selectedRaft = toy.toyID
    elseif self.selectedType == "bobber" then
        Catfish.db.toys.selectedBobber = toy.toyID
    end

    self.frame:Hide()
end

-- ============================================
-- Window Control
-- ============================================

function ToySelector:IsShown()
    return self.frame and self.frame:IsShown()
end

function ToySelector:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

-- ============================================
-- Cursor Changed Handler (for drag-drop)
-- ============================================

function ToySelector:OnCursorChanged(cursorType)
    -- Handle cursor changes for toy selection
    -- This is used if we want drag-drop support from toy box
end