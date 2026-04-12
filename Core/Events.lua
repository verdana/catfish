-- Catfish - Events.lua
-- Event handling system

local ADDON_NAME, Catfish = ...

local Events = {}
Catfish.Core.Events = Events

-- Event frame
local eventFrame = nil

-- 钓鱼相关的BUFF
local playerAuras = {}
local giganticBobberAuras = {}
local customBobberAuras = {}

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
	"CHAT_MSG_MONSTER_EMOTE", -- 怪物表情（宝箱、根须蟹等消息）
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
	"GET_ITEM_INFO_RECEIVED", -- For item data delayed loading
	"PLAYER_MOUNT_DISPLAY_CHANGED", -- For mount state changes
	"MOUNT_JOURNAL_USABILITY_CHANGED",
}

-- ============================================
-- Event Handlers
-- ============================================

-- 事件黑名单：这些事件不打印，避免刷屏
local EVENT_PRINT_BLACKLIST = {
	GLOBAL_MOUSE_DOWN = true,
	GLOBAL_MOUSE_UP = true,
	PLAYER_STOPPED_MOVING = true,
	PLAYER_STOPPED_TURNING = true,
	PLAYER_STARTED_TURNING = true,
	PLAYER_STARTED_MOVING = true,
	ACTIONBAR_SLOT_CHANGED = true,
	WORLD_CURSOR_TOOLTIP_UPDATE = true,
	UPDATE_MOUSEOVER_UNIT = true,
	ACTIONBAR_UPDATE_COOLDOWN = true,
	ACTION_RANGE_CHECK_UPDATE = true,
	CURSOR_CHANGED = true,
	SPELL_ACTIVATION_OVERLAY_HIDE = true,
}

local function OnEvent(self, event, ...)
	-- 调试：打印所有事件（已关闭，需要时取消注释并改用 RegisterAllEvents）
	-- if not EVENT_PRINT_BLACKLIST[event] then
	-- 	Catfish:Print("[Event]", event)
	-- end
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

-- Giant Bobber toy constants (now in Data/Constants.lua)
local function GetGiganticBobberConst()
	return Catfish.Data.Constants.GIGANTIC_BOBBER
end

function Events.UNIT_SPELLCAST_SUCCEEDED(unit, castGUID, spellID)
	if unit ~= "player" then
		return
	end

	local GIGANTIC_BOBBER = GetGiganticBobberConst()
	-- Check for Gigantic Bobber buff application
	if spellID == GIGANTIC_BOBBER.BUFF_ID then
		Catfish:Debug("Events: Gigantic Bobber buff applied (spellID:", spellID, ")")
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

function Events.CHAT_MSG_LOOT(
	message,
	playerName,
	languageName,
	channelName,
	playerName2,
	specialFlags,
	zoneChannelID,
	channelIndex,
	channelBaseName,
	unused,
	lineID,
	senderGUID,
	senderName
)
	-- Use pcall to handle tainted strings in instances
	local ok, isPlayer = pcall(function()
		return playerName == Catfish.API:GetPlayerName()
	end)
	-- Parse loot message only if it's the player's loot
	if ok and isPlayer then
		Events:ParseLootMessage(message)
	end
end

function Events:ParseLootMessage(message)
	-- Only record if this was fishing loot
	if not Catfish.Modules.Statistics or not Catfish.Modules.Statistics.isFishingLoot then
		return
	end

	-- Pattern: "You receive loot: [|Hitem:...|h[Item Name]|h]"
	local itemLink = message:match("|c%x+|Hitem:.-|h%[(.-)%]|h|r")
	if itemLink then
		local itemID = itemLink:match("item:(%d+)")
		if itemID then
			itemID = tonumber(itemID)
			Catfish:Debug("Looted item:", itemID)

			-- Record statistics
			Catfish.Modules.Statistics:RecordCatch(itemID)
		end
	end
end

function Events.LOOT_READY(autoloot)
	-- Auto-loot is handled by the game's auto-loot setting
	-- We just need to track what we caught

	if Catfish.Modules.Statistics then
		Catfish.Modules.Statistics:OnLootReady()
	end
end

function Events.LOOT_CLOSED()
	if Catfish.Core then
		Catfish.Core:OnLootClosed()
	end

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
			Catfish.Modules.OneKey:UpdateBinding(Catfish.Modules.OneKey.BIND_REASON.COMBAT_END)
		end
	end)
end

-- ============================================
-- Mount Events
-- ============================================

function Events.PLAYER_MOUNT_DISPLAY_CHANGED()
	-- 坐骑状态变化时更新绑定
	if Catfish.Modules.OneKey and Catfish.Modules.OneKey.UpdateBinding then
		Catfish.Modules.OneKey:UpdateBinding(Catfish.Modules.OneKey.BIND_REASON.MOUNT_CHANGED)
	end
end

function Events.MOUNT_JOURNAL_USABILITY_CHANGED(...)
	-- 坐骑可用性变化时更新绑定
	-- 可用来检测玩家在水下以及跃出水面
	if Catfish.Modules.OneKey and Catfish.Modules.OneKey.UpdateBinding then
		Catfish.Modules.OneKey:UpdateBinding(Catfish.Modules.OneKey.BIND_REASON.MOUNT_CHANGED)
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



-- ============================================
-- Help Functions
-- ============================================
local function isRaftBuffGained(info)
	if not info or not info.addedAuras then
		return
	end
	for _, aura in ipairs(info.addedAuras) do
		for _, spellID in ipairs(Catfish.Data.Constants.RAFT_SPELL_IDS) do
			-- 使用 pcall 安全比较，避免副本中被污染的值报错
			local ok, match = pcall(function()
				return aura.spellId == spellID
			end)
			if ok and match then
				Catfish:Debug("Gain raft buff: " .. aura.spellId)
				playerAuras[aura.auraInstanceID] = aura.spellId
				return true
			end
		end
	end
	return false
end

local function isRaftBuffLost(info)
	if not info or not info.removedAuraInstanceIDs then
		return
	end
	for _, instanceId in pairs(info.removedAuraInstanceIDs) do
		if playerAuras[instanceId] then
			for _, spellID in ipairs(Catfish.Data.Constants.RAFT_SPELL_IDS) do
				-- 使用 pcall 安全比较，避免副本中被污染的值报错
				local ok, match = pcall(function()
					return playerAuras[instanceId] == spellID
				end)
				if ok and match then
					Catfish:Debug("Lost raft buff: " .. playerAuras[instanceId])
					playerAuras[instanceId] = nil
					return true
				end
			end
		end
	end
	return false
end

local function isRaftBuffRefreshed(info)
    if not info or not info.updatedAuraInstanceIDs then
        return false
    end
    for _, instanceId in pairs(info.updatedAuraInstanceIDs) do
        if playerAuras[instanceId] then
            -- 这个 auraInstanceID 是我们跟踪的钓鱼筏 BUFF
            Catfish:Debug("Raft buff refreshed: " .. playerAuras[instanceId])
            return true
        end
    end
    return false
end

-- ============================================
-- Gigantic Bobber Buff Detection
-- ============================================

local function isGiganticBobberBuffGained(info)
	if not info or not info.addedAuras then
		return false
	end
	local buffID = Catfish.Data.Constants.GIGANTIC_BOBBER.BUFF_ID
	for _, aura in ipairs(info.addedAuras) do
		-- 使用 pcall 安全比较，避免副本中被污染的值报错
		local ok, match = pcall(function()
			return aura.spellId == buffID
		end)
		if ok and match then
			Catfish:Debug("Gain gigantic bobber buff: " .. aura.spellId)
			giganticBobberAuras[aura.auraInstanceID] = aura.spellId
			return true
		end
	end
	return false
end

local function isGiganticBobberBuffLost(info)
    if not info or not info.removedAuraInstanceIDs then
        return false
    end
    for _, instanceId in pairs(info.removedAuraInstanceIDs) do
        if giganticBobberAuras[instanceId] then
            Catfish:Debug("Lost gigantic bobber buff: " .. giganticBobberAuras[instanceId])
            giganticBobberAuras[instanceId] = nil
            return true
        end
    end
    return false
end

local function isGiganticBobberBuffRefreshed(info)
    if not info or not info.updatedAuraInstanceIDs then
        return false
    end
    for _, instanceId in pairs(info.updatedAuraInstanceIDs) do
        if giganticBobberAuras[instanceId] then
            Catfish:Debug("Gigantic bobber buff refreshed: " .. giganticBobberAuras[instanceId])
            return true
        end
    end
    return false
end

-- ============================================
-- Custom Bobber Buff Detection (自定义浮标)
-- ============================================

local function isCustomBobberBuffGained(info)
    if not info or not info.addedAuras then
        return false
    end
    local BOBBER_SPELL_IDS = Catfish.Data.Constants.BOBBER_SPELL_IDS
    for _, aura in ipairs(info.addedAuras) do
        for _, spellID in ipairs(BOBBER_SPELL_IDS) do
            -- 跳过巨型鱼漂（它有单独的处理逻辑）
            if spellID ~= Catfish.Data.Constants.GIGANTIC_BOBBER.BUFF_ID then
                local ok, match = pcall(function()
                    return aura.spellId == spellID
                end)
                if ok and match then
                    Catfish:Debug("Gain custom bobber buff: " .. aura.spellId)
                    customBobberAuras[aura.auraInstanceID] = aura.spellId
                    return true
                end
            end
        end
    end
    return false
end

local function isCustomBobberBuffLost(info)
    if not info or not info.removedAuraInstanceIDs then
        return false
    end
    for _, instanceId in pairs(info.removedAuraInstanceIDs) do
        if customBobberAuras[instanceId] then
            Catfish:Debug("Lost custom bobber buff: " .. customBobberAuras[instanceId])
            customBobberAuras[instanceId] = nil
            return true
        end
    end
    return false
end

local function isCustomBobberBuffRefreshed(info)
    if not info or not info.updatedAuraInstanceIDs then
        return false
    end
    for _, instanceId in pairs(info.updatedAuraInstanceIDs) do
        if customBobberAuras[instanceId] then
            Catfish:Debug("Custom bobber buff refreshed: " .. customBobberAuras[instanceId])
            return true
        end
    end
    return false
end


function Events.UNIT_AURA(unit, info)
	if unit ~= "player" then
		return
	end

	-- 休眠模式下不处理
	if Catfish.db and Catfish.db.sleepMode then
		return
	end

	if Catfish.Modules.LureManager then
		Catfish.Modules.LureManager:OnAuraChanged()
	end

	local config = Catfish.db.toys or {}

	-- 战斗中不检查光环的获取以及丢失
	if InCombatLockdown() then
		return
	end

	-- 如果获取钓鱼筏BUFF，重新刷新一下绑定
    if isRaftBuffGained(info) then
        Catfish.Modules.OneKey:UpdateBinding(Catfish.Modules.OneKey.BIND_REASON.RAFT_GAINED)
        return
    end

	-- 同样的如果失去了钓鱼筏BUFF，一样刷新下绑定
    if isRaftBuffLost(info) then
        Catfish.Modules.OneKey:UpdateBinding(Catfish.Modules.OneKey.BIND_REASON.RAFT_LOST)
        return
    end

	-- 如果钓鱼筏BUFF时间被刷新（再次使用玩具），也更新绑定
	if isRaftBuffRefreshed(info) then
		Catfish.Modules.OneKey:UpdateBinding(Catfish.Modules.OneKey.BIND_REASON.RAFT_REFRESHED)
		return
	end

	-- 巨型鱼漂 BUFF 获取
	if isGiganticBobberBuffGained(info) then
		Catfish.Modules.OneKey:UpdateBinding(Catfish.Modules.OneKey.BIND_REASON.GIGANTIC_BOBBER_GAINED)
		return
	end

	-- 巨型鱼漂 BUFF 失去
	if isGiganticBobberBuffLost(info) then
		Catfish.Modules.OneKey:UpdateBinding(Catfish.Modules.OneKey.BIND_REASON.GIGANTIC_BOBBER_LOST)
		return
	end

	-- 巨型鱼漂 BUFF 刷新
	if isGiganticBobberBuffRefreshed(info) then
		Catfish.Modules.OneKey:UpdateBinding(Catfish.Modules.OneKey.BIND_REASON.GIGANTIC_BOBBER_REFRESHED)
		return
	end

	-- 自定义浮标 BUFF 获取
	if isCustomBobberBuffGained(info) then
		Catfish.Modules.OneKey:UpdateBinding(Catfish.Modules.OneKey.BIND_REASON.CUSTOM_BOBBER_GAINED)
		return
	end

	-- 自定义浮标 BUFF 失去
	if isCustomBobberBuffLost(info) then
		Catfish.Modules.OneKey:UpdateBinding(Catfish.Modules.OneKey.BIND_REASON.CUSTOM_BOBBER_LOST)
		return
	end

	-- 自定义浮标 BUFF 刷新
	if isCustomBobberBuffRefreshed(info) then
		Catfish.Modules.OneKey:UpdateBinding(Catfish.Modules.OneKey.BIND_REASON.CUSTOM_BOBBER_REFRESHED)
		return
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
	-- Use pcall to handle tainted strings in instances
	local ok, result = pcall(function()
		-- Check for skill increase
		if message:find("Your skill in Fishing has increased to") then
			local newSkill = message:match("increased to (%d+)")
			if newSkill then
				Catfish:Debug("Fishing skill increased to:", newSkill)
			end
		end
	end)
	-- Silently ignore errors from tainted strings
end

-- ============================================
-- Monster Emote Events (宝箱出现消息)
-- ============================================

function Events.CHAT_MSG_MONSTER_EMOTE(
	message,
	playerName,
	languageName,
	channelName,
	playerName2,
	specialFlags,
	zoneChannelID,
	channelIndex,
	channelBaseName,
	unused,
	lineID,
	senderGUID,
	senderName
)
	-- Use pcall to handle tainted strings in instances
	local ok, result = pcall(function()
		local playerName = Catfish.API:GetPlayerName()

		-- 宝箱消息格式：一个藏宝箱为{角色名}出现了！
		if message:find("藏宝箱") and message:find(playerName) and message:find("出现了") then
			if Catfish.Modules.Statistics then
				Catfish.Modules.Statistics:OnTreasureChestSpawned()
			end
		end
	end)
	-- Silently ignore errors from tainted strings
end

-- ============================================
-- Item Data Events
-- ============================================

function Events.GET_ITEM_INFO_RECEIVED(itemID, success)
	local GIGANTIC_BOBBER = Catfish.Data.Constants.GIGANTIC_BOBBER
	-- When Gigantic Bobber item data is received, update caches
	if itemID == GIGANTIC_BOBBER.TOY_ID and success then
		local itemName = GetItemInfo(itemID)
		Catfish:Debug("GET_ITEM_INFO_RECEIVED: Gigantic Bobber data loaded:", itemName)

		-- Update ItemManager cache
		if Catfish.Modules and Catfish.Modules.ItemManager then
			Catfish.Modules.ItemManager:UpdateGiganticBobberCache()
		end
		-- Update OneKey binding
		if Catfish.Modules and Catfish.Modules.OneKey then
			Catfish.Modules.OneKey:UpdateBinding(Catfish.Modules.OneKey.BIND_REASON.ITEM_LOADED)
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
	-- 调试模式：使用 RegisterAllEvents() 监听所有事件（性能开销大，调试完改回）
	for _, event in ipairs(REGISTERED_EVENTS) do
		eventFrame:RegisterEvent(event)
	end

	-- Set event handler
	eventFrame:SetScript("OnEvent", OnEvent)

	Catfish:Debug("Events module initialized, registered", #REGISTERED_EVENTS, "events")
end
