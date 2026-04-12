-- Catfish - Core.lua
-- Core logic and state machine

local ADDON_NAME, Catfish = ...

local Core = {}
Catfish.Core = Core

-- ============================================
-- State Machine
-- ============================================

local State = {
    IDLE = "IDLE",          -- 空闲状态
    CASTING = "CASTING",    -- 读条中
    WAITING = "WAITING",    -- 等待收杆
    REELING = "REELING",    -- 收杆中
}

Core.State = State

-- Current state
Core.currentState = State.IDLE

-- State timers
Core.stateStartTime = 0
Core.castStartTime = 0

-- Fishing session data
Core.sessionActive = false
Core.sessionStartTime = 0
Core.lastCastTime = 0

-- Bobber tracking
Core.bobberGUID = nil
Core.bobberUnit = nil

-- Gigantic Bobber state tracking
Core.giganticBobberUsedLastCast = false

-- ============================================
-- State Transition
-- ============================================

function Core:SetState(newState, ...)
    local oldState = self.currentState

    if oldState == newState then
        return
    end

    Catfish:Debug("State change:", oldState, "->", newState)

    -- Exit old state
    self:OnExitState(oldState)

    -- Update state
    self.currentState = newState
    self.stateStartTime = GetTime()

    -- Enter new state
    self:OnEnterState(newState, ...)

    -- Fire state change callback
    if self.OnStateChanged then
        self:OnStateChanged(oldState, newState)
    end

    -- Notify OneKey module to update binding
    if Catfish.Modules.OneKey and newState ~= nil then
        Catfish.Modules.OneKey:OnStateChanged(newState)
    end
end

function Core:GetState()
    return self.currentState
end

function Core:GetStateTime()
    return GetTime() - self.stateStartTime
end

-- ============================================
-- State Handlers
-- ============================================

function Core:OnEnterState(state, ...)
    if state == State.IDLE then
        self:EnterIdle(...)

    elseif state == State.CASTING then
        self:EnterCasting(...)

    elseif state == State.WAITING then
        self:EnterWaiting(...)

    end
end

function Core:OnExitState(state)
    if state == State.IDLE then
        self:ExitIdle()

    elseif state == State.CASTING then
        self:ExitCasting()

    elseif state == State.WAITING then
        self:ExitWaiting()

    end
end

-- ============================================
-- IDLE State
-- ============================================

function Core:EnterIdle()
    -- Catfish:Debug("Entered IDLE state")

    -- Clear bobber data
    self.bobberGUID = nil
    self.bobberUnit = nil

    -- Note: Don't clear isFishingLoot here
    -- It will be cleared by:
    -- 1. Statistics:OnLootClosed (after looting)
    -- 2. Statistics:ClearFishingLootTimeout (timeout after 5 seconds)
end

function Core:ExitIdle()
    -- Catfish:Debug("Exiting IDLE state")
end

-- ============================================
-- CASTING State
-- ============================================

function Core:EnterCasting()
    -- Catfish:Debug("Entered CASTING state")

    -- Ensure auto loot is enabled if the option is set
    if Catfish.db.keepAutoLoot then
        if GetCVar("autoLootDefault") ~= "1" then
            SetCVar("autoLootDefault", "1")
            Catfish:Debug("Auto loot enabled")
        end
    end

    self.castStartTime = GetTime()
    self.lastCastTime = GetTime()
end

function Core:ExitCasting()
    -- Catfish:Debug("Exiting CASTING state")
end

-- ============================================
-- WAITING State
-- ============================================

function Core:EnterWaiting(bobberGUID)
    -- Catfish:Debug("Entered WAITING state, bobber:", bobberGUID)

    self.bobberGUID = bobberGUID

    -- Mark that we're fishing - loot should be recorded
    if Catfish.Modules.Statistics then
        Catfish.Modules.Statistics:OnFishingStarted()
    end
end

function Core:ExitWaiting()
    -- Catfish:Debug("Exiting WAITING state")
end

-- ============================================
-- REELING State
-- ============================================

function Core:CancelFishing()
    -- Catfish:Debug("CancelFishing called, state:", self.currentState)

    if self.currentState == State.CASTING or self.currentState == State.WAITING then
        self:SetState(State.IDLE)
    end
end

-- ============================================
-- Event Handlers (called from Events.lua)
-- ============================================

function Core:OnSpellCastStart(unit, castGUID, spellID)
    if unit ~= "player" then return end
    if not Catfish.API:IsFishingSpell(spellID) then return end

    -- Start session if not active
    if not self.sessionActive then
        self.sessionActive = true
        self.sessionStartTime = GetTime()
    end

    -- Record cast
    if Catfish.Modules.Statistics then
        Catfish.Modules.Statistics:RecordCast()
    end

    -- 休眠模式下不自动使用玩具
    if not Catfish.db.sleepMode and Catfish.db.autoToys and Catfish.Modules.Toys then
        Catfish.Modules.Toys:UseConfiguredToys()
    end

    -- NOTE: TWW items (Amani Ward, baits) are handled by the keybinding system in OneKey.lua
    -- We cannot auto-use items from event handlers as it requires a hardware event.
    -- The binding is set up to use items when the player presses the key.

    self:SetState(State.CASTING)
end

function Core:OnSpellCastChannelStart(unit, castGUID, spellID)
    if unit ~= "player" then return end
    if InCombatLockdown() then return end

    if not Catfish.API:IsFishingSpell(spellID) then return end

    -- Start session if not active
    if not self.sessionActive then
        self.sessionActive = true
        self.sessionStartTime = GetTime()
    end

    -- Record cast
    if Catfish.Modules.Statistics then
        Catfish.Modules.Statistics:RecordCast()
    end

    -- Ensure auto loot is enabled if the option is set
    if Catfish.db.keepAutoLoot then
        if GetCVar("autoLootDefault") ~= "1" then
            SetCVar("autoLootDefault", "1")
            Catfish:Debug("Auto loot enabled")
        end
    end

    -- 休眠模式下不自动使用玩具
    if not Catfish.db.sleepMode and Catfish.db.autoToys and Catfish.Modules.Toys then
        Catfish.Modules.Toys:UseConfiguredToys()
    end

    -- NOTE: TWW items (Amani Ward, baits) are handled by the keybinding system in OneKey.lua
    -- We cannot auto-use items from event handlers as it requires a hardware event.
    -- The binding is set up to use items when the player presses the key.

    -- Transition to waiting when channel starts (bobber is in water)
    self:SetState(State.WAITING)
end

function Core:OnSpellCastChannelStop(unit, castGUID, spellID)
    if unit ~= "player" then return end
    if not Catfish.API:IsFishingSpell(spellID) then return end

    -- Channel stopped
    -- Don't clear isFishingLoot here - LOOT_READY may come after
    -- The flag is cleared in Statistics:OnLootClosed instead
    if self.currentState == State.WAITING then
        Catfish:Debug("Channel stopped in WAITING - transitioning to REELING")
        self:SetState(State.REELING)

        -- 启动短计时器检测
        self.reelStartTime = GetTime()
        C_Timer.After(0.5, function()
            if self.currentState == State.REELING then
                -- 超时无 LOOT_READY，说明是被取消了
                self:SetState(State.IDLE)
            end
        end)
    end
end

function Core:OnSpellCastFailed(unit, castGUID, spellID)
    if unit ~= "player" then return end
    if not Catfish.API:IsFishingSpell(spellID) then return end

    Catfish:Debug("Fishing spell failed")
    self:SetState(State.IDLE)
end

function Core:OnSoftInteractChanged(newTarget, oldTarget)
    -- Don't auto-trigger reel on soft interact change
    -- The player needs to manually interact (double-click or keybind) to reel in
    -- Just track the bobber unit for later use
    if newTarget then
        self.bobberUnit = newTarget
    end

    -- Notify OneKey module to update binding (soft target changed)
    if Catfish.Modules.OneKey then
        Catfish.Modules.OneKey:OnStateChanged()
    end
end

function Core:OnLootClosed()
    self:SetState(State.IDLE)
end


-- ============================================
-- Getters
-- ============================================

function Core:IsFishing()
    return self.currentState ~= State.IDLE
end

function Core:GetSessionTime()
    if self.sessionActive then
        return GetTime() - self.sessionStartTime
    end
    return 0
end

function Core:GetTotalSessionTime()
    return Catfish.db.stats.total.time + self:GetSessionTime()
end

-- ============================================
-- Initialization
-- ============================================

function Core:Init()
    Catfish:Debug("Core module initialized")
end
