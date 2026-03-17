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
    if GIGANTIC_BOBBER_NAME then
        return GIGANTIC_BOBBER_NAME
    end
    local name = Catfish.API:GetItemName(GIGANTIC_BOBBER_TOY_ID)
    Catfish:Debug("OneKey: GetGiganticBobberName - GetItemName returned:", tostring(name))
    if name then
        GIGANTIC_BOBBER_NAME = name  -- 只缓存有效名称
    end
    return name
end

-- Public function to update the cached name (called when item data is received)
function OneKey:UpdateGiganticBobberCache()
    local name = Catfish.API:GetItemName(GIGANTIC_BOBBER_TOY_ID)
    if name then
        GIGANTIC_BOBBER_NAME = name
        Catfish:Debug("OneKey: Updated Gigantic Bobber cache:", name)
    end
end

-- Get custom bobber toy name if selected
local function GetCustomBobberName()
    local toyID = Catfish.db.selectedBobberToy
    if not toyID then
        return nil
    end
    return Catfish.API:GetItemName(toyID)
end

-- Get raft toy name if selected and available
local function GetRaftName()
    local config = Catfish.db.toys
    if config.raftMode == "none" then
        return nil
    end

    if config.raftMode == "specific" and config.selectedRaft then
        local cooldown = Catfish.API:GetToyCooldown(config.selectedRaft)
        if cooldown == 0 then
            return Catfish.API:GetItemName(config.selectedRaft)
        end
        return nil
    end

    -- Random mode: get first available raft
    if Catfish.Modules.Toys then
        local rafts = Catfish.Modules.Toys:GetOwnedRafts()
        for _, toy in ipairs(rafts) do
            local cooldown = Catfish.API:GetToyCooldown(toy.toyID)
            if cooldown == 0 then
                return toy.name
            end
        end
    end
    return nil
end

-- Get raft spellID for buff check
local function GetRaftSpellID()
    local config = Catfish.db.toys
    if config.raftMode == "none" then
        return nil
    end

    if config.raftMode == "specific" and config.selectedRaft then
        -- Find the spellID for selected raft
        if Catfish.Data.Toys and Catfish.Data.Toys.Rafts then
            for _, toy in ipairs(Catfish.Data.Toys.Rafts) do
                if toy.toyID == config.selectedRaft then
                    return toy.spellID
                end
            end
        end
        return nil
    end

    -- Random mode: get spellID of first available raft
    if Catfish.Modules.Toys then
        local rafts = Catfish.Modules.Toys:GetOwnedRafts()
        for _, toy in ipairs(rafts) do
            local cooldown = Catfish.API:GetToyCooldown(toy.toyID)
            if cooldown == 0 then
                return toy.spellID
            end
        end
    end
    return nil
end

-- Check if player already has raft buff
local function HasRaftBuff()
    -- Check all known raft spell IDs
    local raftSpellIDs = {383268, 124036, 288758, 1218420}
    for _, spellID in ipairs(raftSpellIDs) do
        if Catfish.API:UnitHasBuff("player", spellID) then
            return true
        end
    end
    return false
end

-- Get raft buff spell name for macro conditionals
local RAFT_BUFF_NAMES = {
    "Tuskarr Dinghy",      -- 383268
    "Anglers Fishing Raft", -- 124036
    "Gnarlwood Waveboard",  -- 288758
    "Personal Fishing Barge", -- 1218420
}

-- Get raft buff name for macro conditional
local function GetRaftBuffNameForMacro()
    -- Return a condition string that checks for NO raft buffs
    -- In WoW macros, [] groups are AND conditions
    -- Format: [nobuff:BuffA][nobuff:BuffB]...
    local conditions = {}
    for _, buffName in ipairs(RAFT_BUFF_NAMES) do
        table.insert(conditions, "[nobuff:" .. buffName .. "]")
    end
    return table.concat(conditions, "")
end

-- Check if we need to use raft
local function NeedsRaft()
    if Catfish.db.toys.raftMode == "none" then
        return false
    end
    if not IsSwimming() then
        return false
    end
    -- Already on a raft
    if HasRaftBuff() then
        return false
    end
    return GetRaftName() ~= nil
end

-- Check if we need to use custom bobber toy
local function NeedsCustomBobber()
    if not Catfish.db.selectedBobberToy then
        return false
    end

    -- Check if player has the toy
    if not Catfish.API:PlayerHasToy(Catfish.db.selectedBobberToy) then
        return false
    end

    -- Check if toy is on cooldown
    local cooldown = Catfish.API:GetToyCooldown(Catfish.db.selectedBobberToy)
    if cooldown > 0 then
        Catfish:Debug("OneKey: NeedsCustomBobber - toy on cooldown:", cooldown)
        return false
    end

    return true
end

local function NeedsGiganticBobber()
    if not Catfish.db.useGiganticBobber then
        Catfish:Debug("OneKey: NeedsGiganticBobber - option disabled")
        return false
    end

    -- Check if player already has the buff
    local hasBuff = Catfish.API:UnitHasBuff("player", GIGANTIC_BOBBER_BUFF_ID)
    if hasBuff then
        Catfish:Debug("OneKey: NeedsGiganticBobber - already has buff")
        return false
    end

    -- Check if player has the toy
    local hasToy = Catfish.API:PlayerHasToy(GIGANTIC_BOBBER_TOY_ID)
    if not hasToy then
        Catfish:Debug("OneKey: NeedsGiganticBobber - player doesn't have toy")
        return false
    end

    -- Check if toy is on cooldown
    local cooldown = Catfish.API:GetToyCooldown(GIGANTIC_BOBBER_TOY_ID)
    if cooldown > 0 then
        Catfish:Debug("OneKey: NeedsGiganticBobber - toy on cooldown:", cooldown)
        return false
    end

    Catfish:Debug("OneKey: NeedsGiganticBobber - returning true")
    return true
end

-- Check if any swim toy is needed
local function NeedsSwimToys()
    return IsSwimming() and (NeedsRaft() or NeedsGiganticBobber() or NeedsCustomBobber())
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
-- @param skipCooldownCheck If true, skip the reel cooldown check (used by scheduled updates)
function OneKey:UpdateBinding(skipCooldownCheck)
    Catfish:Debug("OneKey: UpdateBinding called", skipCooldownCheck and "(skip cooldown)" or "")

    -- Cannot update bindings during combat lockdown
    if InCombatLockdown() then
        Catfish:Debug("OneKey: UpdateBinding skipped - in combat lockdown")
        return
    end

    if not self.autoButton then
        Catfish:Debug("OneKey: UpdateBinding skipped - no autoButton")
        return
    end

    if not self.autoButton:IsVisible() then
        Catfish:Debug("OneKey: UpdateBinding skipped - button not visible")
        return
    end

    if not self.keybind then
        Catfish:Debug("OneKey: UpdateBinding skipped - no keybind set")
        return
    end

    -- Clear existing binding first
    ClearOverrideBindings(self.autoButton)

    local normalizedKey = KEY_NORMALIZE[self.keybind] or self.keybind
    local softTarget = GetSoftInteractTarget and GetSoftInteractTarget()
    local hasFishingBuff = HasFishingBuff()
    local isFishing = Catfish.Core:IsFishing()
    local state = Catfish.Core:GetState()

    if softTarget or hasFishingBuff or isFishing or state == Catfish.Core.State.WAITING then
        -- Bind to INTERACTTARGET for reeling in
        SetOverrideBinding(self.autoButton, true, normalizedKey, "INTERACTTARGET")
        Catfish:Debug("OneKey: Bound to INTERACTTARGET (softTarget:", softTarget ~= nil, "hasBuff:", hasFishingBuff, "isFishing:", isFishing, "state:", state, ")")
    else
        -- Check if we're in cooldown after reeling (to prevent accidental cast after loot)
        -- Skip this check if called from scheduled update
        if not skipCooldownCheck then
            local timeSinceReel = GetTime() - self.lastReelTime
            if timeSinceReel < self.reelCooldown then
                Catfish:Debug("OneKey: UpdateBinding skipped - in reel cooldown")
                return
            end
        end

        -- Swimming with toys configured - use smart swim macro
        if IsSwimming() and NeedsSwimToys() then
            local macroText = self:GetSwimFishingMacro()
            if macroText then
                Catfish.API:SetToyButtonMacro(macroText)
                SetOverrideBindingClick(self.autoButton, true, normalizedKey, "CatfishToyButton")
                Catfish:Debug("OneKey: Bound to swim fishing macro")
            end
            return
        end

        -- Swimming without toys - no binding (let SPACE work normally for ascending)
        if IsSwimming() then
            Catfish:Debug("OneKey: Swimming without toys - no binding set")
            return
        end

        -- Check if we need to use Gigantic Bobber toy first
        if NeedsGiganticBobber() then
            -- Set up the toy button with macro (like Angleur does)
            local toyName = GetGiganticBobberName()
            if toyName and toyName ~= "" then
                Catfish.API:SetToyButtonMacro(toyName)
                -- Bind to click the toy button
                SetOverrideBindingClick(self.autoButton, true, normalizedKey, "CatfishToyButton")
                Catfish:Debug("OneKey: Bound to Gigantic Bobber toy button:", toyName)
            else
                -- Toy name not available yet, fall back to fishing spell
                -- Will retry on next keybind update
                Catfish:Debug("OneKey: Toy name not available, falling back to fishing spell")
                local spellName = GetFishingSpellName()
                if spellName then
                    SetOverrideBindingSpell(self.autoButton, true, normalizedKey, spellName)
                    Catfish:Debug("OneKey: Bound to fishing spell (fallback):", spellName)
                end
            end
        elseif NeedsCustomBobber() then
            -- Use custom bobber toy before fishing
            local bobberName = GetCustomBobberName()
            local spellName = GetFishingSpellName()
            if bobberName and spellName then
                -- Create macro: use bobber toy then cast fishing
                local macroText = "/use " .. bobberName .. "\n/cast " .. spellName
                Catfish.API:SetToyButtonMacro(macroText)
                SetOverrideBindingClick(self.autoButton, true, normalizedKey, "CatfishToyButton")
                Catfish:Debug("OneKey: Bound to custom bobber macro:", bobberName)
            else
                -- Fall back to fishing spell
                if spellName then
                    SetOverrideBindingSpell(self.autoButton, true, normalizedKey, spellName)
                    Catfish:Debug("OneKey: Bound to fishing spell (custom bobber fallback):", spellName)
                end
            end
        else
            -- Bind to fishing spell directly
            local spellName = GetFishingSpellName()
            if spellName then
                SetOverrideBindingSpell(self.autoButton, true, normalizedKey, spellName)
                Catfish:Debug("OneKey: Bound to fishing spell:", spellName)
            else
                Catfish:Debug("OneKey: Failed to get fishing spell name for binding")
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
        -- Pass true to skip cooldown check since we're already waiting the cooldown period
        C_Timer.After(self.reelCooldown, function()
            Catfish:Debug("OneKey: Scheduled binding update triggered")
            self:UpdateBinding(true)  -- Skip cooldown check
        end)
    end

    self:UpdateBinding()
end

-- ============================================
-- Toy Usage Callback (called from Events when toy is used)
-- ============================================

function OneKey:OnToyUsed(toyID)
    Catfish:Debug("OneKey: OnToyUsed called with toyID:", toyID)

    -- Only handle Gigantic Bobber toy
    if toyID ~= GIGANTIC_BOBBER_TOY_ID then
        return
    end

    -- Delay update to allow buff to fully apply
    C_Timer.After(0.5, function()
        if not InCombatLockdown() then
            Catfish:Debug("OneKey: Updating binding after toy usage")
            self:UpdateBinding()
        else
            Catfish:Debug("OneKey: In combat, skipping binding update")
        end
    end)
end

-- ============================================
-- Swim Fishing Macro Generation
-- ============================================

function OneKey:GetSwimFishingMacro()
    local macroLines = {}
    local spellName = GetFishingSpellName() or "钓鱼"

    -- 1. Use raft if configured and no buff (Lua checks, updated on buff change)
    if NeedsRaft() then
        local raftName = GetRaftName()
        if raftName then
            table.insert(macroLines, "/use " .. raftName)
        end
    end

    -- 2. Use Gigantic Bobber if enabled and no buff (Lua checks)
    if NeedsGiganticBobber() then
        local giganticName = GetGiganticBobberName()
        if giganticName then
            table.insert(macroLines, "/use " .. giganticName)
        end
    end

    -- 3. Use custom bobber if selected (cooldown check in Lua)
    if NeedsCustomBobber() then
        local bobberName = GetCustomBobberName()
        if bobberName then
            table.insert(macroLines, "/use " .. bobberName)
        end
    end

    -- 4. Finally: cast fishing
    table.insert(macroLines, "/cast " .. spellName)

    return table.concat(macroLines, "\n")
end

-- ============================================
-- Event Handling for Buff Changes
-- ============================================

function OneKey:OnUnitAuraEvent(unit)
    -- Only care about player's aura changes
    if unit ~= "player" then return end

    -- Update binding if we're swimming (to re-evaluate raft buff)
    if IsSwimming() and self.keybind and self.autoButton and not InCombatLockdown() then
        Catfish:Debug("OneKey: OnUnitAuraEvent - updating swim binding")
        self:UpdateBinding()
    end
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

    -- Show button if one-key mode is enabled and not in sleep mode
    if Catfish.db.oneKeyEnabled and not Catfish.db.sleepMode then
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