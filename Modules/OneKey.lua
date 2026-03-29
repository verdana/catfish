-- Catfish - OneKey.lua
-- One-key fishing module - simplified version
-- Uses SetOverrideBindingClick to handle toy usage before casting

local ADDON_NAME, Catfish = ...

local OneKey = {}
Catfish.Modules.OneKey = OneKey

-- ============================================
-- Configuration
-- ============================================

OneKey.keybind = nil
OneKey.autoButton = nil
OneKey.lastBindingUpdate = 0
OneKey.bindingDebounce = 0.05  -- 50ms 防抖

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

-- 检查是否有钓鱼buff（正在钓鱼中）
local function HasFishingBuff()
    local name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellID = UnitChannelInfo("player")
    if name and spellID then
        return Catfish.API:IsFishingSpell(spellID)
    end
    return false
end

-- 检查是否有浮漂（soft target）
local function HasBobber()
    if GetSoftInteractTarget then
        return GetSoftInteractTarget() ~= nil
    end
    return false
end

-- 检查是否应该解除绑定（让按键保持原有功能）
local function ShouldUnbind()
    if InCombatLockdown() then
        return true, "combat"
    end

    -- 坐骑上 → 解除绑定
    if IsMounted() then
        return true, "mounted"
    end

    -- 游泳中检查
    if IsSwimming() then
        local ItemManager = Catfish.Modules.ItemManager
        local config = Catfish.db.toys

        -- 配置了木筏且已有木筏buff → 解除绑定让用户上浮到木筏上
        if config.raftMode ~= "none" and ItemManager:HasRaftBuff() then
            return true, "swimming with raft"
        end

        -- 其他游泳情况（需要木筏或没配置木筏）→ 不解除绑定
        -- 需要木筏时，按键会触发使用木筏
        -- 没配置木筏时，按键会尝试钓鱼（会失败，但这是用户的选择）
        return false, nil
    end

    return false, nil
end

-- ============================================
-- Debounce
-- ============================================

function OneKey:CanUpdateBinding()
    local now = GetTime()
    if now - self.lastBindingUpdate < self.bindingDebounce then
        return false
    end
    self.lastBindingUpdate = now
    return true
end

-- ============================================
-- Button Creation
-- ============================================

local function CreateAutoButton()
    local button = CreateFrame("Button", "CatfishOneKeyAutoButton", UIParent, "SecureActionButtonTemplate")
    button:SetSize(1, 1)
    button:SetPoint("CENTER", UIParent, "CENTER", 10000, 10000)
    button:Hide()
    button:SetAttribute("type", "macro")
    button:SetScript("OnShow", function()
        OneKey:UpdateBinding(1)
    end)
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

-- 默认绑定
function OneKey:DefaultBinding()

end

-- 更新绑定（核心逻辑）
function OneKey:UpdateBinding(id)
    -- 防抖检查
    if not self:CanUpdateBinding() then
        Catfish:Debug("OneKey: UpdateBinding debounced")
        return
    end

    -- 休眠模式下不执行任何功能性操作
    if Catfish.db.sleepMode then
        Catfish:Debug("OneKey: sleep mode active, skip binding")
        return
    end

    -- 基本检查
    if not self.autoButton or not self.autoButton:IsVisible() or not self.keybind then
        return
    end

    -- 清除现有绑定
    ClearOverrideBindings(self.autoButton)

    -- 如果进入战斗，清除绑定，不再继续绑定新功能
    if InCombatLockdown() then
        Catfish:Debug("OneKey: In combat lockdown, skip binding")
        return
    end

    -- 如果在坐骑上，清除绑定，不再继续绑定新功能
    if IsMounted() then
        Catfish:Print("OneKey: mounted, skip binding")
        return
    end


    -- 当前绑定的按键
    local normalizedKey = KEY_NORMALIZE[self.keybind] or self.keybind

    Catfish:Print("UpdateBinding, ", id)
    Catfish:Print("IsSwimming: ", IsSwimming(), ", IsMounted: ", IsMounted(),  ", InCombat: ", InCombatLockdown())

    -- 检查是否应该解除绑定

    -- local shouldUnbind, reason = ShouldUnbind()
    -- Catfish:Print("ShouldUnbind:", shouldUnbind, "reason:", reason)
    -- if shouldUnbind then
    --     Catfish:Print("OneKey: Unbound, reason:", reason)

    --     -- 如果是因为"游泳+有木筏BUFF"而解绑，启动轮询检测"站上木筏"
    --     if reason == "swimming with raft" then
    --         local StatusPoller = Catfish.Core.StatusPoller
    --         if StatusPoller and not StatusPoller:IsPolling() then
    --             StatusPoller:StartPolling("raft-waiting-surface")
    --         end
    --     end

    --     return
    -- end

    -- 有浮漂或有钓鱼buff → 收杆
    if HasBobber() or HasFishingBuff() or Catfish.Core:IsFishing() then
        SetOverrideBinding(self.autoButton, true, normalizedKey, "INTERACTTARGET")
        Catfish:Debug("OneKey: Bound to INTERACTTARGET")
        return
    end

    -- 获取 ItemManager
    local ItemManager = Catfish.Modules.ItemManager

    -- 检查是否需要使用钓鱼筏
    if ItemManager:NeedsRaft() then
        local macro = ItemManager:BuildDraftMacro()
        Catfish:Print("OneKey: raft macro = ", macro)
        if macro then
            Catfish.API:SetToyButtonMacro(macro)
            SetOverrideBindingClick(self.autoButton, true, normalizedKey, "CatfishToyButton")
            Catfish:Print("OneKey: bound to raft")
            return
        end
    end

    -- 检查是否需要使用巨型鱼漂
    if ItemManager:NeedsGiganticBobber() then
        local macro = ItemManager:BuildGiganticBobberMacro()
        Catfish:Print("OneKey: gigantic bobber macro = ", macro)
        if macro then
            Catfish.API:SetToyButtonMacro(macro)
            SetOverrideBindingClick(self.autoButton, true, normalizedKey, "CatfishToyButton")
            Catfish:Print("OneKey: bound to gigantic bobber")
            return
        end
    end

    -- 检查是否需要先使用GCD物品（木筏/结界/鱼饵）
    -- local needsGCD = ItemManager:NeedsGCDItem()
    -- Catfish:Print("NeedsGCDItem:", needsGCD)
    -- if needsGCD then
    --     local macro = ItemManager:GenerateGCDItemMacro()
    --     Catfish:Print("GCD macro:", macro)
    --     if macro then
    --         Catfish.API:SetToyButtonMacro(macro)
    --         SetOverrideBindingClick(self.autoButton, true, normalizedKey, "CatfishToyButton")
    --         Catfish:Print("OneKey: Bound to GCD item (raft)")
    --         -- 不设置定时器！用户需要先上浮到木筏上
    --         -- 游泳状态变化（离开游泳）时会自动触发更新
    --         return
    --     end
    -- end

    -- 无浮漂且无GCD物品 → 生成钓鱼宏（玩具+钓鱼）
    -- local macro = ItemManager:GenerateFishingMacro()
    -- Catfish:Debug("Fishing macro:", macro)
    -- if macro and macro ~= "" then
    --     Catfish.API:SetToyButtonMacro(macro)
    --     SetOverrideBindingClick(self.autoButton, true, normalizedKey, "CatfishToyButton")
    --     Catfish:Debug("OneKey: Bound to fishing macro")
    --     return
    -- end

    -- 无物品需要使用，直接绑定钓鱼法术
    local spellName = GetFishingSpellName()
    if spellName then
        SetOverrideBindingSpell(self.autoButton, true, normalizedKey, spellName)
        Catfish:Debug("OneKey: Bound to fishing spell:", spellName)
    end
end

function OneKey:SetKeybind(keyOrButton)
    if InCombatLockdown() then
        Catfish:Print("战斗中无法设置快捷键")
        return false
    end

    -- 清除现有绑定
    if self.autoButton then
        ClearOverrideBindings(self.autoButton)
    end

    -- 清除绑定
    if not keyOrButton or keyOrButton == "" then
        self.keybind = nil
        CatfishCharDB.keybinding = nil
        Catfish:Print("快捷键已清除")
        return true
    end

    -- 忽略屏蔽的按键
    if BLOCKED_KEYS[keyOrButton] then
        return false
    end

    -- 保存并更新
    self.keybind = keyOrButton
    CatfishCharDB.keybinding = keyOrButton
    self:UpdateBinding(3)

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
-- Enable/Disable
-- ============================================

function OneKey:SetEnabled(enabled)
    if InCombatLockdown() then return end

    if self.autoButton then
        if enabled and not Catfish.db.sleepMode then
            self.autoButton:Show()
        else
            self.autoButton:Hide()
        end
    end
end

-- ============================================
-- State Change Handler
-- ============================================

function OneKey:OnStateChanged(state)
    if state == nil then return end
    if not self.autoButton or not self.autoButton:IsVisible() or not self.keybind then
        return
    end
    self:UpdateBinding(4)
end

-- ============================================
-- Sleep Mode Support
-- ============================================

function OneKey:ClearOverrideBinding()
    if self.autoButton then
        ClearOverrideBindings(self.autoButton)
    end
end

function OneKey:ClearBinding()
    if self.autoButton then
        self.autoButton:Hide()
    end
end

function OneKey:RestoreBinding()
    if self.autoButton and self.keybind and Catfish.db.oneKeyEnabled then
        self.autoButton:Show()
    end
end

-- ============================================
-- StatusPoller Callbacks
-- ============================================

-- 游泳状态变化回调（由 StatusPoller 调用）
function OneKey:OnSwimmingStateChanged(isSwimming)
    Catfish:Debug("OneKey: OnSwimmingStateChanged - isSwimming:", tostring(isSwimming))
    self:UpdateBinding("swimming-state-changed")
end

-- ============================================
-- Compatibility Stubs (for other modules)
-- ============================================

function OneKey:OnToyUsed(toyID)
    -- 由 ItemManager 处理，此处仅作兼容
end

function OneKey:UpdateGiganticBobberCache()
    Catfish.Modules.ItemManager:UpdateGiganticBobberCache()
end

function OneKey:IsActive()
    return self.autoButton ~= nil and self.autoButton:IsVisible()
end

-- ============================================
-- Initialization
-- ============================================

function OneKey:Init()
    -- 创建按钮
    self.autoButton = CreateAutoButton()

    -- 加载保存的快捷键
    if CatfishCharDB.keybinding then
        self.keybind = CatfishCharDB.keybinding
    end

    -- 显示按钮（如果启用且不在休眠模式）
    if Catfish.db.oneKeyEnabled and not Catfish.db.sleepMode then
        self.autoButton:Show()
    end

    Catfish:Debug("OneKey module initialized")
end
