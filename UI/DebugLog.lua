-- Catfish - DebugLog.lua
-- Debug log window for capturing and copying Catfish messages

local ADDON_NAME, Catfish = ...

local DebugLog = {}
Catfish.UI.DebugLog = DebugLog

-- Log storage
DebugLog.logs = {}
DebugLog.maxLogs = 100
DebugLog.frame = nil

-- ============================================
-- Log Capture (using secure hook to avoid affecting other addons)
-- ============================================

local function CapturePrint(...)
    -- Capture original output
    local args = {...}
    local message = ""
    local argCount = select("#", ...)

    for i = 1, argCount do
        local arg = select(i, ...)
        -- 正确处理 nil 和 false
        if arg == nil then
            message = message .. "nil"
        elseif arg == false then
            message = message .. "false"
        elseif arg == true then
            message = message .. "true"
        else
            message = message .. tostring(arg)
        end
        if i < argCount then
            message = message .. " "
        end
    end

    -- Check if this is a Catfish message
    if message:find("Catfish") or message:find("catfish") or message:find("鲶鱼") then
        DebugLog:AddLog(message)
    end
end

function DebugLog:AddLog(message)
    -- Add timestamp
    local time = date("%H:%M:%S")
    local logEntry = "[" .. time .. "] " .. message

    -- Add to log
    table.insert(self.logs, logEntry)

    -- Trim old logs
    while #self.logs > self.maxLogs do
        table.remove(self.logs, 1)
    end

    -- Update frame if visible
    if self.frame and self.frame:IsShown() and self.editBox then
        self:RefreshDisplay()
    end
end

function DebugLog:RefreshDisplay()
    if not self.editBox then return end

    local text = table.concat(self.logs, "\n")
    self.editBox:SetText(text)
    self.editBox:HighlightText()
end

-- ============================================
-- UI Creation
-- ============================================

function DebugLog:CreateFrame()
    if self.frame then return end

    -- Create main frame
    local frame = CreateFrame("Frame", "CatfishDebugLogFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(600, 400)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    -- Title
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -5)
    frame.title:SetText("Catfish Debug Log")

    -- Create scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 40)

    -- Create edit box for text display
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetWidth(550)
    editBox:SetHeight(300)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("GameFontNormalSmall")
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    scrollFrame:SetScrollChild(editBox)

    -- Clear button
    local clearBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    clearBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 10)
    clearBtn:SetSize(80, 25)
    clearBtn:SetText("Clear")
    clearBtn:SetScript("OnClick", function()
        DebugLog.logs = {}
        editBox:SetText("")
    end)

    -- Copy button
    local copyBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    copyBtn:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
    copyBtn:SetSize(80, 25)
    copyBtn:SetText("Copy All")
    copyBtn:SetScript("OnClick", function()
        editBox:HighlightText()
        editBox:SetFocus()
    end)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
    closeBtn:SetSize(80, 25)
    closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)

    self.frame = frame
    self.editBox = editBox

    Catfish:Debug("Debug log frame created")
end

-- ============================================
-- Public Methods
-- ============================================

function DebugLog:Toggle()
    if not self.frame then
        self:CreateFrame()
    end

    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self:RefreshDisplay()
        self.frame:Show()
    end
end

function DebugLog:Show()
    if not self.frame then
        self:CreateFrame()
    end
    self:RefreshDisplay()
    self.frame:Show()
end

function DebugLog:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

-- ============================================
-- Initialization
-- ============================================

function DebugLog:Init()
    -- Use hooksecurefunc to safely hook print without affecting other addons
    -- This allows multiple addons to hook the same function
    hooksecurefunc("print", CapturePrint)

    -- Add initial log
    self:AddLog("Catfish Debug Log initialized")
end