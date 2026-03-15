-- Catfish - Events.lua
-- Event handling system

local ADDON_NAME, Catfish = ...

local Events = {}
Catfish.Core.Events = Events

-- Event frame
local eventFrame = nil

-- ============================================
-- Event Registration
-- ============================================

local REGISTERED_EVENTS = {
    "UNIT_SPELLCAST_START",
    "UNIT_SPELLCAST_CHANNEL_START",
    "UNIT_SPELLCAST_CHANNEL_STOP",
    "UNIT_SPELLCAST_FAILED",
    "UNIT_SPELLCAST_INTERRUPTED",
    "UNIT_SPELLCAST_SUCCEEDED",
    "PLAYER_SOFT_INTERACT_CHANGED",
    "UI_ERROR_MESSAGE",
    "CHAT_MSG_LOOT",
    "CHAT_MSG_SYSTEM",
    "PLAYER_REGEN_DISABLED",
    "PLAYER_REGEN_ENABLED",
    "PLAYER_STARTED_MOVING",
    "PLAYER_STOPPED_MOVING",
    "LOOT_READY",
    "LOOT_CLOSED",
    "BAG_UPDATE",
    "UNIT_INVENTORY_CHANGED",
    "UNIT_AURA",
    "CURSOR_CHANGED",
    "GET_ITEM_INFO_RECEIVED",  -- For item data delayed loading
}

-- ============================================
-- Event Handlers
-- ============================================

local function OnEvent(self, event, ...)
    if Events[event] then
        Events[event](...)
    end
end

-- ============================================
-- Spell Events
-- ============================================

function Events.UNIT_SPELLCAST_START(unit, castGUID, spellID)
    if Catfish.Core then
        Catfish.Core:OnSpellCastStart(unit, castGUID, spellID)
    end
end

function Events.UNIT_SPELLCAST_CHANNEL_START(unit, castGUID, spellID)
    if Catfish.Core then
        Catfish.Core:OnSpellCastChannelStart(unit, castGUID, spellID)
    end
end

function Events.UNIT_SPELLCAST_CHANNEL_STOP(unit, castGUID, spellID)
    if Catfish.Core then
        Catfish.Core:OnSpellCastChannelStop(unit, castGUID, spellID)
    end
end

function Events.UNIT_SPELLCAST_FAILED(unit, castGUID, spellID)
    if Catfish.Core then
        Catfish.Core:OnSpellCastFailed(unit, castGUID, spellID)
    end
end

function Events.UNIT_SPELLCAST_INTERRUPTED(unit, castGUID, spellID)
    if Catfish.Core then
        Catfish.Core:OnSpellCastFailed(unit, castGUID, spellID)
    end
end

-- Giant Bobber toy constants
local GIGANTIC_BOBBER_BUFF_ID = 397827
local GIGANTIC_BOBBER_TOY_ID = 202207

function Events.UNIT_SPELLCAST_SUCCEEDED(unit, castGUID, spellID)
    if unit ~= "player" then return end

    -- Check for Gigantic Bobber buff application
    -- The toy applies a buff with spellID 397827
    if spellID == GIGANTIC_BOBBER_BUFF_ID then
        Catfish:Debug("Events: Gigantic Bobber buff applied (spellID:", spellID, ")")

        -- Notify OneKey module to update binding
        if Catfish.Modules and Catfish.Modules.OneKey then
            Catfish.Modules.OneKey:OnToyUsed(GIGANTIC_BOBBER_TOY_ID)
        end
    end
end

-- ============================================
-- Interaction Events
-- ============================================

function Events.PLAYER_SOFT_INTERACT_CHANGED(newTarget, oldTarget)
    if Catfish.Core then
        Catfish.Core:OnSoftInteractChanged(newTarget, oldTarget)
    end
end

-- ============================================
-- UI Events
-- ============================================

function Events.UI_ERROR_MESSAGE(errorType, message)
    -- Check for fishing-related errors
    if message then
        local fishingErrors = {
            "Cannot do that while moving",
            "You can't do that yet",
            "Spell is not ready yet",
            "You are moving",
        }

        for _, err in ipairs(fishingErrors) do
            if message:find(err) then
                if Catfish.Core and Catfish.Core:GetState() ~= Catfish.Core.State.IDLE then
                    Catfish.Core:SetState(Catfish.Core.State.IDLE)
                end
                break
            end
        end
    end
end

-- ============================================
-- Loot Events
-- ============================================

function Events.CHAT_MSG_LOOT(message, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, unused, lineID, senderGUID, senderName)
    -- Parse loot message
    if playerName == Catfish.API:GetPlayerName() then
        Events:ParseLootMessage(message)
    end
end

function Events:ParseLootMessage(message)
    -- Pattern: "You receive loot: [|Hitem:...|h[Item Name]|h]"
    local itemLink = message:match("|c%x+|Hitem:.-|h%[(.-)%]|h|r")
    if itemLink then
        local itemID = itemLink:match("item:(%d+)")
        if itemID then
            itemID = tonumber(itemID)
            Catfish:Debug("Looted item:", itemID)

            -- Record statistics
            if Catfish.Modules.Statistics then
                Catfish.Modules.Statistics:RecordCatch(itemID)
            end
        end
    end
end

function Events.LOOT_READY(autoloot)
    Catfish:Debug("Loot ready, autoloot:", autoloot)

    -- Auto-loot is handled by the game's auto-loot setting
    -- We just need to track what we caught

    if Catfish.Modules.Statistics then
        Catfish.Modules.Statistics:OnLootReady()
    end
end

function Events.LOOT_CLOSED()
    Catfish:Debug("Loot window closed")

    if Catfish.Modules.Statistics then
        Catfish.Modules.Statistics:OnLootClosed()
    end
end

-- ============================================
-- Combat Events
-- ============================================

function Events.PLAYER_REGEN_DISABLED()
    Catfish:Debug("Entered combat")

    -- Cancel fishing if active
    if Catfish.Core and Catfish.Core:IsFishing() then
        Catfish.Core:CancelFishing()
    end

    -- Clear keybinding so the key restores its original function
    if Catfish.Modules.OneKey and Catfish.Modules.OneKey.ClearOverrideBinding then
        Catfish.Modules.OneKey:ClearOverrideBinding()
    end
end

function Events.PLAYER_REGEN_ENABLED()
    Catfish:Debug("Left combat")

    -- Restore keybinding after combat (delayed to avoid taint)
    C_Timer.After(0.1, function()
        if Catfish.Modules.OneKey and Catfish.Modules.OneKey.UpdateBinding then
            Catfish.Modules.OneKey:UpdateBinding()
        end
    end)
end

-- ============================================
-- Movement Events
-- ============================================

local lastSwimmingState = nil

function Events.PLAYER_STARTED_MOVING()
    if Catfish.Core then
        local state = Catfish.Core:GetState()

        -- Fishing is cancelled when moving during casting
        if state == Catfish.Core.State.CASTING then
            C_Timer.After(0.1, function()
                if Catfish.API:IsPlayerMoving() then
                    Catfish.Core:SetState(Catfish.Core.State.IDLE)
                end
            end)
        end
    end

    -- Check swimming state change
    local isSwimming = IsSwimming()
    if lastSwimmingState ~= isSwimming then
        lastSwimmingState = isSwimming
        if Catfish.Modules.OneKey and Catfish.Modules.OneKey.UpdateBinding then
            Catfish.Modules.OneKey:UpdateBinding()
        end
    end
end

function Events.PLAYER_STOPPED_MOVING()
    -- Check swimming state change
    local isSwimming = IsSwimming()
    if lastSwimmingState ~= isSwimming then
        lastSwimmingState = isSwimming
        if Catfish.Modules.OneKey and Catfish.Modules.OneKey.UpdateBinding then
            Catfish.Modules.OneKey:UpdateBinding()
        end
    end
end

-- ============================================
-- Inventory Events
-- ============================================

local bagUpdateTimer = nil

function Events.BAG_UPDATE(bagID)
    -- Debounce: delay execution to merge multiple BAG_UPDATE events
    -- WoW fires BAG_UPDATE multiple times in quick succession (one per bag)
    if bagUpdateTimer then
        bagUpdateTimer:Cancel()
    end
    bagUpdateTimer = C_Timer.NewTimer(0.1, function()
        bagUpdateTimer = nil
        -- Equipment module may need to rescan
        if Catfish.Modules.Equipment then
            Catfish.Modules.Equipment:OnBagUpdate(bagID)
        end

        -- Lure manager may need to rescan
        if Catfish.Modules.LureManager then
            Catfish.Modules.LureManager:OnBagUpdate(bagID)
        end
    end)
end

function Events.UNIT_INVENTORY_CHANGED(unit)
    if unit == "player" then
        if Catfish.Modules.Equipment then
            Catfish.Modules.Equipment:OnInventoryChanged()
        end
    end
end

function Events.UNIT_AURA(unit)
    if unit == "player" then
        if Catfish.Modules.LureManager then
            Catfish.Modules.LureManager:OnAuraChanged()
        end
    end
end

-- ============================================
-- Cursor Events
-- ============================================

function Events.CURSOR_CHANGED(cursorType, oldCursorType)
    -- Used for toy selection UI
    if Catfish.UI.ToySelector and Catfish.UI.ToySelector:IsShown() then
        Catfish.UI.ToySelector:OnCursorChanged(cursorType)
    end
end

-- ============================================
-- System Events
-- ============================================

function Events.CHAT_MSG_SYSTEM(message)
    -- Check for skill increase
    if message:find("Your skill in Fishing has increased to") then
        local newSkill = message:match("increased to (%d+)")
        if newSkill then
            Catfish:Debug("Fishing skill increased to:", newSkill)
        end
    end
end

-- ============================================
-- Item Data Events
-- ============================================

local GIGANTIC_BOBBER_TOY_ID = 202207

function Events.GET_ITEM_INFO_RECEIVED(itemID, success)
    -- When Gigantic Bobber item data is received, update the keybinding
    if itemID == GIGANTIC_BOBBER_TOY_ID and success then
        local itemName = GetItemInfo(itemID)
        Catfish:Debug("GET_ITEM_INFO_RECEIVED: Gigantic Bobber data loaded:", itemName)

        -- Update OneKey cache and binding
        if Catfish.Modules and Catfish.Modules.OneKey then
            if Catfish.Modules.OneKey.UpdateGiganticBobberCache then
                Catfish.Modules.OneKey:UpdateGiganticBobberCache()
            end
            Catfish.Modules.OneKey:UpdateBinding()
        end
    end
end

-- ============================================
-- Initialization
-- ============================================

function Events:Init()
    -- Create event frame
    eventFrame = CreateFrame("Frame")

    -- Register all events
    for _, event in ipairs(REGISTERED_EVENTS) do
        eventFrame:RegisterEvent(event)
    end

    -- Set event handler
    eventFrame:SetScript("OnEvent", OnEvent)

    -- Initialize swimming state
    lastSwimmingState = IsSwimming()

    Catfish:Debug("Events module initialized, registered", #REGISTERED_EVENTS, "events")
end

-- ============================================
-- Manual Event Trigger (for testing)
-- ============================================

function Events:TriggerEvent(event, ...)
    if self[event] then
        self[event](...)
    end
end
