-- Catfish - OneKey.lua
-- One-key fishing module using WoW override keybinding system
-- Uses SetOverrideBindingClick to handle toy usage before casting

local ADDON_NAME, Catfish = ...

local OneKey = {}
Catfish.Modules.OneKey = OneKey

-- Configuration
OneKey.keybind = nil
OneKey.isActive = false
OneKey.autoButton = nil
OneKey.fishButton = nil  -- The button that handles fishing action
OneKey.lastReelTime = 0  -- Track last reel time for cooldown
OneKey.reelCooldown = 0.3  -- Cooldown in seconds after reeling

-- ============================================
-- Helper Functions
-- ============================================

local function GetFishingSpellName()
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(7620)
        return info and info.name
    elseif GetSpellInfo then
        return GetSpellInfo(7620)
    end
    return nil
end

-- Check if player has fishing buff (is currently fishing)
local function HasFishingBuff()
    if C_Spell and C_Spell.GetSpellInfo then
        local name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellID = UnitChannelInfo("player")
        if name and spellID then
            if Catfish.API:IsFishingSpell(spellID) then
                return true
            end
        end
    end
    return false
end

-- Check if player needs to use Gigantic Bobber toy
local GIGANTIC_BOBBER_BUFF_ID = 397827
local GIGANTIC_BOBBER_TOY_ID = 202207
local GIGANTIC_BOBBER_NAME = nil  -- Will be cached on first use

local function GetGiganticBobberName()
    if not GIGANTIC_BOBBER_NAME then
        GIGANTIC_BOBBER_NAME = Catfish.API:GetItemName(GIGANTIC_BOBBER_TOY_ID)
    end
    return GIGANTIC_BOBBER_NAME
end

local function NeedsGiganticBobber()
    if not Catfish.db.useGiganticBobber then
        return false
    end

    -- Check if player already has the buff
    local hasBuff = Catfish.API:UnitHasBuff("player", GIGANTIC_BOBBER_BUFF_ID)
    if hasBuff then
        return false
    end

    -- Check if player has the toy
    local hasToy = Catfish.API:PlayerHasToy(GIGANTIC_BOBBER_TOY_ID)
    if not hasToy then
        return false
    end

    -- Check if toy is on cooldown
    local cooldown = Catfish.API:GetToyCooldown(GIGANTIC_BOBBER_TOY_ID)
    if cooldown > 0 then
        return false
    end

    return true
end

-- ============================================
-- Fishing Action Button Creation
-- This button handles the actual fishing logic
-- ============================================

local function CreateFishActionButton()
    -- Create a secure action button that we'll click via keybind
    local button = CreateFrame("Button", "CatfishFishActionButton", UIParent, "SecureActionButtonTemplate")
    button:SetSize(1, 1)
    button:SetPoint("CENTER", UIParent, "CENTER", 10000, 10000)
    button:Hide()

    -- Register for clicks
    button:RegisterForClicks("AnyUp", "AnyDown")

    -- Secure snippet to handle the action
    -- This runs in secure environment
    button:SetAttribute("_onclick", [[
        -- Check if we have a soft target (bobber)
        local softTarget = GetSoftInteractTarget()

        if softTarget then
            -- We have a bobber, interact with it
            self:SetAttribute("type", "macro")
            self:SetAttribute("macrotext", "/click SoftInteractTarget")
        else
            -- No bobber, cast fishing
            self:SetAttribute("type", "spell")
            self:SetAttribute("spell", "钓鱼")
        end
    ]])

    return button
end

-- ============================================
-- Auto Button Creation (for keybind override)
-- ============================================

local function CreateAutoButton()
    -- Create a button that will receive the keybind
    local button = CreateFrame("Button", "CatfishOneKeyAutoButton", UIParent, "SecureActionButtonTemplate")
    button:SetSize(1, 1)
    button:SetPoint("CENTER", UIParent, "CENTER", 10000, 10000)
    button:Hide()

    -- Set up as click button
    button:SetAttribute("type", "click")
    button:SetAttribute("clickbutton", CatfishFishActionButton)

    -- OnShow: Update the binding
    button:SetScript("OnShow", function()
        OneKey:UpdateBinding()
    end)

    -- OnHide: Clear the binding
    button:SetScript("OnHide", function()
        ClearOverrideBindings(button)
    end)

    return button
end

-- ============================================
-- Keybind Management
-- ============================================

local KEY_NORMALIZE = {
    [" "] = "SPACE",
    ["Space"] = "SPACE",
    ["space"] = "SPACE",
}

local BLOCKED_KEYS = {
    ["LeftButton"] = true,
    ["RightButton"] = true,
    ["MiddleButton"] = true,
    ["BUTTON1"] = true,
    ["BUTTON2"] = true,
    ["BUTTON3"] = true,
}

-- Update binding based on current state
function OneKey:UpdateBinding()
    -- Cannot update bindings during combat lockdown
    if InCombatLockdown() then
        return
    end

    if not self.autoButton or not self.autoButton:IsVisible() then
        return
    end
    if not self.keybind then
        return
    end

    -- Clear existing binding first
    ClearOverrideBindings(self.autoButton)

    -- Skip binding if swimming (let key retain original function)
    if IsSwimming() then
        return
    end

    local normalizedKey = KEY_NORMALIZE[self.keybind] or self.keybind
    local softTarget = GetSoftInteractTarget and GetSoftInteractTarget()
    local hasFishingBuff = HasFishingBuff()
    local isFishing = Catfish.Core:IsFishing()
    local state = Catfish.Core:GetState()

    if softTarget or hasFishingBuff or isFishing or state == Catfish.Core.State.WAITING then
        -- Bind to INTERACTTARGET for reeling in
        SetOverrideBinding(self.autoButton, true, normalizedKey, "INTERACTTARGET")
    else
        -- Check if we're in cooldown after reeling (to prevent accidental cast after loot)
        local timeSinceReel = GetTime() - self.lastReelTime
        if timeSinceReel < self.reelCooldown then
            return
        end

        -- Check if we need to use Gigantic Bobber toy first
        if NeedsGiganticBobber() then
            -- Set up the toy button with macro (like Angleur does)
            local toyName = GetGiganticBobberName()
            if toyName then
                Catfish.API:SetToyButtonMacro(toyName)
                -- Bind to click the toy button
                SetOverrideBindingClick(self.autoButton, true, normalizedKey, "CatfishToyButton")
                Catfish:Debug("OneKey: Binding to Gigantic Bobber toy button:", toyName)
            end
        else
            -- Bind to fishing spell directly
            local spellName = GetFishingSpellName()
            if spellName then
                SetOverrideBindingSpell(self.autoButton, true, normalizedKey, spellName)
            end
        end
    end
end

function OneKey:SetKeybind(keyOrButton)
    if InCombatLockdown() then
        Catfish:Print("战斗中无法设置快捷键")
        return false
    end

    -- Clear existing binding
    if self.autoButton then
        ClearOverrideBindings(self.autoButton)
    end

    -- Clear binding if key is nil or empty
    if not keyOrButton or keyOrButton == "" then
        self.keybind = nil
        CatfishCharDB.keybinding = nil
        Catfish:Print("快捷键已清除")
        return true
    end

    -- Silently ignore blocked keys
    if BLOCKED_KEYS[keyOrButton] then
        return false
    end

    -- Store the keybind
    self.keybind = keyOrButton
    CatfishCharDB.keybinding = keyOrButton

    -- Update the binding
    self:UpdateBinding()

    Catfish:Print("快捷键已设置为: " .. keyOrButton)
    return true
end

function OneKey:GetKeybind()
    return self.keybind
end

function OneKey:ClearKeybind()
    self:SetKeybind(nil)
end

-- ============================================
-- Enable/Disable Management
-- ============================================

function OneKey:SetEnabled(enabled)
    if InCombatLockdown() then return end

    if self.autoButton then
        if enabled then
            -- Only show button if not in sleep mode
            if not Catfish.db.sleepMode then
                self.autoButton:Show()
            end
        else
            self.autoButton:Hide()
        end
    end
end

-- ============================================
-- State Update (called from Core when state changes)
-- ============================================

function OneKey:OnStateChanged()
    if not self.autoButton or not self.autoButton:IsVisible() or not self.keybind then
        return
    end

    -- Check if we just finished fishing (transition from WAITING/REELING to IDLE)
    local state = Catfish.Core:GetState()
    if state == Catfish.Core.State.IDLE then
        -- Record reel time to prevent accidental cast
        self.lastReelTime = GetTime()

        -- Schedule binding update after cooldown
        C_Timer.After(self.reelCooldown, function()
            if self.autoButton and self.autoButton:IsVisible() and self.keybind then
                -- Only update if still in IDLE state
                if Catfish.Core:GetState() == Catfish.Core.State.IDLE then
                    self:UpdateBinding()
                end
            end
        end)
    end

    self:UpdateBinding()
end

-- ============================================
-- Initialization
-- ============================================

function OneKey:Init()
    -- Create fish action button first
    self.fishButton = CreateFishActionButton()

    -- Create auto button
    self.autoButton = CreateAutoButton()

    -- Load saved keybind
    if CatfishCharDB.keybinding then
        self.keybind = CatfishCharDB.keybinding
    end

    -- Show button if one-key mode is enabled
    if Catfish.db.oneKeyEnabled then
        self.autoButton:Show()
    end
end

-- ============================================
-- State Check
-- ============================================

function OneKey:IsActive()
    return self.isActive
end

-- ============================================
-- Sleep Mode Support
-- ============================================

function OneKey:ClearOverrideBinding()
    -- Clear only the override binding, keep button visible for restoration
    if self.autoButton then
        ClearOverrideBindings(self.autoButton)
    end
end

function OneKey:ClearBinding()
    -- Hide the button to remove all bindings
    if self.autoButton then
        self.autoButton:Hide()
    end
end

function OneKey:RestoreBinding()
    -- Show the button to restore bindings (only if one-key mode is enabled)
    if self.autoButton and self.keybind and Catfish.db.oneKeyEnabled then
        self.autoButton:Show()
    end
end