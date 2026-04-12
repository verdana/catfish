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

-- UpdateBinding 调用原因枚举
local BIND_REASON = {
    INIT = "init",
    BUTTON_SHOW = "button-show",
    KEYBIND_SET = "keybind-set",
    STATE_CHANGED = "state-changed",
    SWIMMING_STATE = "swimming-state",
    COMBAT_END = "combat-end",
    MOUNT_CHANGED = "mount-changed",
    ITEM_LOADED = "item-loaded",
    RAFT_GAINED = "raft-gained",
    RAFT_LOST = "raft-lost",
    RAFT_REFRESHED = "raft-refreshed",
    GIGANTIC_BOBBER_GAINED = "gigantic-bobber-gained",
    GIGANTIC_BOBBER_LOST = "gigantic-bobber-lost",
    GIGANTIC_BOBBER_REFRESHED = "gigantic-bobber-refreshed",
    CUSTOM_BOBBER_GAINED = "custom-bobber-gained",
    CUSTOM_BOBBER_LOST = "custom-bobber-lost",
    CUSTOM_BOBBER_REFRESHED = "custom-bobber-refreshed",
}
OneKey.BIND_REASON = BIND_REASON

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
        OneKey:UpdateBinding(BIND_REASON.BUTTON_SHOW)
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
        Catfish:Debug("OneKey: mounted, skip binding")
        return
    end


    -- 当前绑定的按键
    local normalizedKey = KEY_NORMALIZE[self.keybind] or self.keybind

    -- Catfish:Debug("UpdateBinding id:", id, "IsSwimming:", IsSwimming(), "IsMounted:", IsMounted(), "InCombat:", InCombatLockdown())

    -- 游泳状态特殊处理
    if IsSwimming() then
        local ItemManager = Catfish.Modules.ItemManager
        local config = Catfish.db.toys

        -- 配置了木筏
        if config.raftMode ~= "none" then
            -- 已有木筏buff → 解除绑定，让按键恢复原有功能
            -- 用户需要按按键上浮到木筏上
            if ItemManager:HasRaftBuff() then
                Catfish:Debug("OneKey: swimming with raft buff - unbinding")

                -- 启动轮询，等待离开游泳状态（站上木筏）
                local StatusPoller = Catfish.Core.StatusPoller
                if StatusPoller and not StatusPoller:IsPolling() then
                    StatusPoller:StartPolling("raft-waiting-surface")
                end
                return
            end

            -- 没有木筏buff → 绑定使用木筏
            local macro = ItemManager:BuildDraftMacro()
            if macro then
                Catfish.API:SetToyButtonMacro(macro)
                SetOverrideBindingClick(self.autoButton, true, normalizedKey, "CatfishToyButton")
                Catfish:Debug("OneKey: swimming, bound to raft")
                return
            end
        end

        -- 没配置木筏 → 尝试钓鱼（会失败，但这是用户的选择）
        -- 继续下面的逻辑
    end

    -- 有浮漂或有钓鱼buff → 收杆
    if HasBobber() or HasFishingBuff() or Catfish.Core:IsFishing() then
        SetOverrideBinding(self.autoButton, true, normalizedKey, "INTERACTTARGET")
        Catfish:Debug("OneKey: Bound to INTERACTTARGET")
        return
    end

    -- 获取 ItemManager
    local ItemManager = Catfish.Modules.ItemManager

    -- 检查是否需要使用钓鱼筏（非游泳状态下）
    if ItemManager:NeedsRaft() then
        local macro = ItemManager:BuildDraftMacro()
        if macro then
            Catfish.API:SetToyButtonMacro(macro)
            SetOverrideBindingClick(self.autoButton, true, normalizedKey, "CatfishToyButton")
            Catfish:Debug("OneKey: bound to raft (non-swimming)")
            return
        end
    end

    -- 检查是否需要使用巨型鱼漂
    if ItemManager:NeedsGiganticBobber() then
        local macro = ItemManager:BuildGiganticBobberMacro()
        if macro then
            Catfish.API:SetToyButtonMacro(macro)
            SetOverrideBindingClick(self.autoButton, true, normalizedKey, "CatfishToyButton")
            Catfish:Debug("OneKey: bound to gigantic bobber")
            return
        end
    end

    -- 检查是否需要使用浮标
    if ItemManager:NeedsCustomBobber() then
        local macro = ItemManager:BuildCustomBobberMacro()
        if macro then
            Catfish.API:SetToyButtonMacro(macro)
            SetOverrideBindingClick(self.autoButton, true, normalizedKey, "CatfishToyButton")
            Catfish:Debug("OneKey: bound to custom bobber")
            return
        end
    end

    -- 无物品需要使用，直接绑定钓鱼法术
    local spellName = Catfish.API:GetFishingSpellName()
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
    self:UpdateBinding(BIND_REASON.KEYBIND_SET)

    Catfish:Print("快捷键已设置为: " .. keyOrButton)
    return true
end

function OneKey:GetKeybind()
    return self.keybind
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
    self:UpdateBinding(BIND_REASON.STATE_CHANGED)
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
    self:UpdateBinding(BIND_REASON.SWIMMING_STATE)
end

-- ============================================
-- Utility
-- ============================================

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
