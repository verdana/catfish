-- Catfish - DoubleClick.lua
-- Double-click fishing module using override bindings

local ADDON_NAME, Catfish = ...

local DoubleClick = {}
Catfish.Modules.DoubleClick = DoubleClick

-- Configuration
DoubleClick.enabled = false
DoubleClick.timeout = 0.4
DoubleClick.mouseButton = "RightButton"
DoubleClick.bindKey = "BUTTON2"

-- State tracking
DoubleClick.watching = false
DoubleClick.lastClickTime = 0
DoubleClick.eventFrame = nil
DoubleClick.bindingFrame = nil

-- ============================================
-- Override Binding Management
-- ============================================

local function GetFishingSpellName()
    -- Use C_Spell API for modern WoW
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(7620)
        return info and info.name
    else
        return GetSpellInfo and GetSpellInfo(7620)
    end
end

-- Check if player has the "安详垂钓" (Serene Fishing) buff
-- This buff is present while fishing and disappears when reeling in
local function HasFishingBuff()
    -- Check for fishing channel buff
    -- The buff ID for "安详垂钓" needs to be found
    -- For now, check if player is channeling fishing spell
    if C_Spell and C_Spell.GetSpellInfo then
        -- Check channeling
        local name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellID = UnitChannelInfo("player")
        if name and spellID then
            if Catfish.API:IsFishingSpell(spellID) then
                return true
            end
        end
    end
    return false
end

local function SetFishingBinding()
    if InCombatLockdown() then return false end
    if not DoubleClick.bindingFrame then return false end

    -- Check if we have a soft interact target (bobber) or fishing buff
    local softTarget = GetSoftInteractTarget and GetSoftInteractTarget()
    local hasFishingBuff = HasFishingBuff()
    local isFishing = Catfish.Core:IsFishing()

    Catfish:Debug("SetFishingBinding: softTarget=", tostring(softTarget), "hasFishingBuff=", tostring(hasFishingBuff), "isFishing=", tostring(isFishing))

    if softTarget or hasFishingBuff or isFishing then
        -- Bind to INTERACTTARGET for reeling in
        local success = SetOverrideBinding(DoubleClick.bindingFrame, true, DoubleClick.bindKey, "INTERACTTARGET")
        Catfish:Debug("SetOverrideBinding:", DoubleClick.bindKey, "-> INTERACTTARGET, success:", tostring(success))
        return success
    else
        -- Bind to fishing spell for casting
        local spellName = GetFishingSpellName()
        if not spellName then
            Catfish:Print("Error: Cannot find fishing spell name")
            return false
        end

        local success = SetOverrideBindingSpell(DoubleClick.bindingFrame, true, DoubleClick.bindKey, spellName)
        Catfish:Debug("SetOverrideBindingSpell:", DoubleClick.bindKey, "->", spellName, "success:", tostring(success))
        return success
    end
end

local function ClearFishingBinding()
    if InCombatLockdown() then return end
    if not DoubleClick.bindingFrame then return end

    ClearOverrideBindings(DoubleClick.bindingFrame)
    Catfish:Debug("Fishing binding cleared")
end

-- ============================================
-- Click Detection via Global Mouse Events
-- ============================================

function DoubleClick:OnMouseEvent(event, button)
    if not self.enabled then return end
    if button ~= self.mouseButton then return end
    if InCombatLockdown() then return end
    if UnitIsDeadOrGhost("player") then return end

    -- Check sleep mode - fishing features are disabled
    if Catfish.db.sleepMode then
        Catfish:Debug("DoubleClick: sleep mode is active, ignoring")
        return
    end

    -- Ignore if mouse is over a UI frame
    if not WorldFrame:IsMouseMotionFocus() and GetMouseFoci()[1] ~= nil then
        return
    end

    Catfish:Debug("MouseEvent:", event, "button:", button, "watching:", tostring(self.watching), "isFishing:", tostring(Catfish.Core:IsFishing()), "state:", Catfish.Core:GetState())

    if event == "GLOBAL_MOUSE_UP" then
        if self.watching then
            -- Second click detected
            Catfish:Debug("Second click detected!")
            self.watching = false
            -- Clear binding after a short delay
            C_Timer.After(0.05, function()
                ClearFishingBinding()
            end)
        else
            -- First click - start watching
            self.watching = true
            Catfish:Debug("First click - setting binding")

            -- Set binding for second click
            SetFishingBinding()

            -- Auto-reset after timeout
            C_Timer.After(self.timeout, function()
                if DoubleClick.watching then
                    Catfish:Debug("Timeout - resetting")
                    DoubleClick.watching = false
                    ClearFishingBinding()
                end
            end)
        end
    end
end

-- ============================================
-- Configuration
-- ============================================

function DoubleClick:SetEnabled(enabled)
    self.enabled = enabled
    Catfish.db.doubleClickEnabled = enabled

    if not enabled then
        ClearFishingBinding()
        self.watching = false
    end

    Catfish:Debug("Double-click mode:", enabled and "enabled" or "disabled")
end

function DoubleClick:SetTimeout(timeout)
    self.timeout = math.max(0.1, math.min(1.0, timeout))
    Catfish.db.doubleClickTimeout = self.timeout
end

-- ============================================
-- Initialization
-- ============================================

function DoubleClick:Init()
    self.enabled = Catfish.db.doubleClickEnabled or false
    self.timeout = Catfish.db.doubleClickTimeout or 0.4

    -- Create binding frame
    if not self.bindingFrame then
        self.bindingFrame = CreateFrame("Frame", "CatfishDoubleClickBindingFrame", UIParent)
    end

    -- Create event frame
    if not self.eventFrame then
        self.eventFrame = CreateFrame("Frame")
        self.eventFrame:RegisterEvent("GLOBAL_MOUSE_UP")
        self.eventFrame:SetScript("OnEvent", function(frame, event, button)
            DoubleClick:OnMouseEvent(event, button)
        end)
    end
end

-- ============================================
-- State Check
-- ============================================

function DoubleClick:IsEnabled()
    return self.enabled
end

function DoubleClick:GetTimeout()
    return self.timeout
end

-- ============================================
-- Sleep Mode Support
-- ============================================

function DoubleClick:ClearBinding()
    ClearFishingBinding()
    self.watching = false
    Catfish:Debug("DoubleClick: Binding cleared for sleep mode")
end

function DoubleClick:RestoreBinding()
    -- No action needed - binding is set dynamically on first click
    Catfish:Debug("DoubleClick: Ready for active mode")
end
