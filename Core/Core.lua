-- Catfish - Core.lua
-- Core logic and state machine

local ADDON_NAME, Catfish = ...

local Core = {}
Catfish.Core = Core

-- ============================================
-- State Machine
-- ============================================

local State = {
    IDLE = "IDLE",
    CASTING = "CASTING",
    WAITING = "WAITING",
    REELING = "REELING",
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
    if Catfish.Modules.OneKey then
        Catfish:Debug("-> Core:SetState, newState = ", newState)
        Catfish.Modules.OneKey:OnStateChanged()
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

    elseif state == State.REELING then
        self:EnterReeling(...)
    end
end

function Core:OnExitState(state)
    if state == State.IDLE then
        self:ExitIdle()

    elseif state == State.CASTING then
        self:ExitCasting()

    elseif state == State.WAITING then
        self:ExitWaiting()

    elseif state == State.REELING then
        self:ExitReeling()
    end
end

-- ============================================
-- IDLE State
-- ============================================

function Core:EnterIdle()
    Catfish:Debug("Entered IDLE state")

    -- Clear bobber data
    self.bobberGUID = nil
    self.bobberUnit = nil

    -- Note: Don't clear isFishingLoot here
    -- It will be cleared by:
    -- 1. Statistics:OnLootClosed (after looting)
    -- 2. Statistics:ClearFishingLootTimeout (timeout after 5 seconds)
end

function Core:ExitIdle()
    Catfish:Debug("Exiting IDLE state")
end

-- ============================================
-- CASTING State
-- ============================================

function Core:EnterCasting()
    Catfish:Debug("Entered CASTING state")

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
    Catfish:Debug("Exiting CASTING state")
end

-- ============================================
-- WAITING State
-- ============================================

function Core:EnterWaiting(bobberGUID)
    Catfish:Debug("Entered WAITING state, bobber:", bobberGUID)

    self.bobberGUID = bobberGUID

    -- Mark that we're fishing - loot should be recorded
    if Catfish.Modules.Statistics then
        Catfish.Modules.Statistics:OnFishingStarted()
    end
end

function Core:ExitWaiting()
    Catfish:Debug("Exiting WAITING state")
end

-- ============================================
-- REELING State
-- ============================================

function Core:EnterReeling()
    Catfish:Debug("Entered REELING state")

    -- Mark that this is a fishing loot session
    if Catfish.Modules.Statistics then
        Catfish.Modules.Statistics:OnFishingReelStart()
    end

    -- Interact with bobber using secure button
    Catfish.API:InteractWithSoftTarget()

    -- Schedule return to idle
    C_Timer.After(0.5, function()
        if self.currentState == State.REELING then
            self:SetState(State.IDLE)
        end
    end)
end

function Core:ExitReeling()
    Catfish:Debug("Exiting REELING state")
end

-- ============================================
-- Fishing Actions
-- ============================================

function Core:StartFishing()
    if self.currentState ~= State.IDLE then
        Catfish:Debug("Cannot start fishing - not in IDLE state")
        return false
    end

    -- Check sleep mode - core fishing features are disabled
    if Catfish.db.sleepMode then
        Catfish:Debug("Cannot start fishing - sleep mode is active")
        return false
    end

    -- Check if we can fish
    if not Catfish.API:CanCastFishing() then
        Catfish:Debug("Cannot cast fishing")
        return false
    end

    -- Use configured toys (rafts, bobbers, extra toys) if auto-toys is enabled
    if Catfish.db.autoToys and Catfish.Modules.Toys then
        Catfish.Modules.Toys:UseConfiguredToys()
    end

    -- Use The War Within items (阿曼尼垂钓者的结界, 鱼饵) if enabled
    if Catfish.Modules.TWWItems then
        Catfish.Modules.TWWItems:UseAllConfiguredItems()
    end

    -- Check if Gigantic Bobber buff is already active
    local GIGANTIC_BOBBER = Catfish.Data.Constants.GIGANTIC_BOBBER
    local giganticBobberActive = Catfish.API:UnitHasBuff("player", GIGANTIC_BOBBER.BUFF_ID)
    Catfish:Debug("Gigantic Bobber active:", giganticBobberActive)
    Catfish:Debug("useGiganticBobber setting:", Catfish.db.useGiganticBobber)
    Catfish:Debug("selectedBobberToy:", Catfish.db.selectedBobberToy)

    -- Use Gigantic Bobber if enabled and buff not active
    if Catfish.db.useGiganticBobber and not giganticBobberActive then
        local usedToy = self:UseGiganticBobber()
        if usedToy then
            Catfish:Debug("Used Gigantic Bobber toy - press again to fish")
            self.giganticBobberUsedLastCast = true
            return true  -- Wait for next cast to use bobber toy and fish
        end
    end

    -- Use Bobber Toy if selected (selectedBobberToy ~= nil means a bobber is selected)
    -- Use it when: Gigantic Bobber buff is already active, OR we didn't just use Gigantic Bobber
    if Catfish.db.selectedBobberToy then
        if giganticBobberActive or not self.giganticBobberUsedLastCast then
            self:UseBobberToy()
        end
    end

    -- Reset the flag after considering bobber toys
    self.giganticBobberUsedLastCast = false

    -- Start session if not active
    if not self.sessionActive then
        self.sessionActive = true
        self.sessionStartTime = GetTime()
    end

    -- Record cast
    if Catfish.Modules.Statistics then
        Catfish.Modules.Statistics:RecordCast()
    end

    -- Cast fishing
    Catfish.API:CastFishing()
    self:SetState(State.CASTING)

    return true
end

function Core:StopFishing()
    Catfish:Debug("Stop fishing requested")

    -- End session
    if self.sessionActive then
        local sessionTime = GetTime() - self.sessionStartTime
        Catfish.db.stats.total.time = Catfish.db.stats.total.time + sessionTime
        self.sessionActive = false
    end

    self:SetState(State.IDLE)
end

-- ============================================
-- Gigantic Bobber
-- ============================================

function Core:UseGiganticBobber()
    local GIGANTIC_BOBBER = Catfish.Data.Constants.GIGANTIC_BOBBER
    Catfish:Print("=== Gigantic Bobber Debug ===")
    Catfish:Print("useGiganticBobber setting:", Catfish.db.useGiganticBobber and "enabled" or "disabled")

    -- Check if player already has the buff
    local hasBuff = Catfish.API:UnitHasBuff("player", GIGANTIC_BOBBER.BUFF_ID)
    Catfish:Print("Has buff (" .. GIGANTIC_BOBBER.BUFF_ID .. "):", hasBuff and "YES" or "NO")
    if hasBuff then
        Catfish:Print("Already has Gigantic Bobber buff - skipping")
        return false
    end

    -- Check if player has the toy
    local hasToy = Catfish.API:PlayerHasToy(GIGANTIC_BOBBER.TOY_ID)
    Catfish:Print("Has toy (" .. GIGANTIC_BOBBER.TOY_ID .. "):", hasToy and "YES" or "NO")
    if not hasToy then
        Catfish:Print("Player does not have Gigantic Bobber toy")
        return false
    end

    -- Check if toy is on cooldown
    local cooldown = Catfish.API:GetToyCooldown(GIGANTIC_BOBBER.TOY_ID)
    Catfish:Print("Toy cooldown:", cooldown)
    if cooldown > 0 then
        Catfish:Print("Gigantic Bobber toy on cooldown:", cooldown, "seconds")
        return false
    end

    -- Use the toy
    Catfish:Print("Attempting to use Gigantic Bobber toy...")
    local result = Catfish.API:UseToy(GIGANTIC_BOBBER.TOY_ID)
    Catfish:Print("UseToy result:", result and "SUCCESS" or "FAILED")
    return result
end

function Core:UseBobberToy()
    local toyID = Catfish.db.selectedBobberToy
    Catfish:Debug("UseBobberToy called, toyID:", toyID)
    if not toyID then
        Catfish:Debug("No bobber toy selected")
        return false
    end

    -- Check if player has the toy
    if not Catfish.API:PlayerHasToy(toyID) then
        Catfish:Debug("Player does not have bobber toy:", toyID)
        return false
    end

    -- Check if toy is on cooldown
    local cooldown = Catfish.API:GetToyCooldown(toyID)
    if cooldown > 0 then
        Catfish:Debug("Bobber toy on cooldown:", cooldown, "seconds")
        return false
    end

    -- Use the toy
    Catfish:Debug("Using bobber toy:", toyID)
    local result = Catfish.API:UseToy(toyID)
    Catfish:Debug("UseBobberToy result:", result and "SUCCESS" or "FAILED")
    return result
end

function Core:CancelFishing()
    Catfish:Debug("CancelFishing called, state:", self.currentState)

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

    -- Use configured toys (rafts, bobbers, extra toys) if auto-toys is enabled
    -- This happens during the cast, most toys can be used without interrupting
    if Catfish.db.autoToys and Catfish.Modules.Toys then
        Catfish.Modules.Toys:UseConfiguredToys()
    end

    -- NOTE: TWW items (Amani Ward, baits) are handled by the keybinding system in OneKey.lua
    -- We cannot auto-use items from event handlers as it requires a hardware event.
    -- The binding is set up to use items when the player presses the key.

    self:SetState(State.CASTING)
end

function Core:OnSpellCastChannelStart(unit, castGUID, spellID)
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

    -- Ensure auto loot is enabled if the option is set
    if Catfish.db.keepAutoLoot then
        if GetCVar("autoLootDefault") ~= "1" then
            SetCVar("autoLootDefault", "1")
            Catfish:Debug("Auto loot enabled")
        end
    end

    -- Use configured toys (rafts, bobbers, extra toys) if auto-toys is enabled
    -- This handles the case where channel starts directly (some fishing modes)
    if Catfish.db.autoToys and Catfish.Modules.Toys then
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
        Catfish:Debug("Channel stopped in WAITING - transitioning to IDLE")
        self:SetState(State.IDLE)
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
        Catfish:Debug("-> Core:OnSoftInteractChanged, newTarget = ", newTarget)
        Catfish.Modules.OneKey:OnStateChanged()
    end
end

function Core:OnBobberBob()
    -- Called when bobber animation shows fish on line
    if self.currentState == State.WAITING then
        Catfish:Debug("Bobber bobbed - fish on!")

        -- Set state to reeling
        self:SetState(State.REELING)
    end
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
