-- Catfish - ItemManager.lua
-- 统一管理钓鱼相关物品的使用条件检查

local ADDON_NAME, Catfish = ...

local ItemManager = {}
Catfish.Modules.ItemManager = ItemManager

-- ============================================
-- Constants Reference
-- ============================================

local function GetConstants()
    return Catfish.Data.Constants
end

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

-- ============================================
-- Toy Item Checks (不受GCD影响)
-- ============================================

-- 注意：木筏需要读条，属于GCD物品，放在GCD检查中处理



-- 获取巨型鱼漂名称
local GIGANTIC_BOBBER_NAME = nil

local function GetGiganticBobberName()
    if GIGANTIC_BOBBER_NAME then
        return GIGANTIC_BOBBER_NAME
    end
    local GIGANTIC_BOBBER = GetConstants().GIGANTIC_BOBBER
    local name = Catfish.API:GetItemName(GIGANTIC_BOBBER.TOY_ID)
    if name then
        GIGANTIC_BOBBER_NAME = name
    end
    return name
end

-- 检查是否需要自定义浮标
local function NeedsCustomBobber()
    local toyID = Catfish.db.selectedBobberToy
    if not toyID then
        return false
    end

    if not Catfish.API:PlayerHasToy(toyID) then
        return false
    end

    if Catfish.API:GetToyCooldown(toyID) > 0 then
        return false
    end

    return true
end

-- 获取自定义浮标名称
local function GetCustomBobberName()
    return Catfish.API:GetItemName(Catfish.db.selectedBobberToy)
end

-- ============================================
-- GCD Item Checks (需要读条的物品)
-- ============================================

-- 获取木筏名称
local function GetRaftName()
    local config = Catfish.db.toys
    if config.raftMode == "specific" and config.selectedRaft then
        local cooldown = Catfish.API:GetToyCooldown(config.selectedRaft)
        if cooldown == 0 then
            return Catfish.API:GetItemName(config.selectedRaft)
        end
        return nil
    end

    -- 随机模式：获取第一个可用的木筏
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

-- ============================================
-- GCD Item Checks (受GCD影响的消耗品)
-- ============================================

-- 检查是否需要阿曼尼结界
local function NeedsAmaniWard()
    if not Catfish.db.tww or not Catfish.db.tww.useAmaniWard then
        return false
    end

    local TWW_ITEMS = GetConstants().TWW_ITEMS

    -- 已有buff
    if Catfish.API:UnitHasBuff("player", TWW_ITEMS.amaniWard.buffSpellID) then
        return false
    end

    -- 没有物品
    if not Catfish.API:PlayerHasItem(TWW_ITEMS.amaniWard.itemID) then
        return false
    end

    return true
end

-- 检查是否需要鱼饵
local function NeedsTWWBait()
    if not Catfish.db.tww or not Catfish.db.tww.selectedBait then
        return false
    end

    local TWW_ITEMS = GetConstants().TWW_ITEMS
    local baitKey = Catfish.db.tww.selectedBait
    local baitData = TWW_ITEMS[baitKey .. "Bait"]

    if not baitData then
        return false
    end

    -- 已有buff
    if Catfish.API:UnitHasBuff("player", baitData.buffSpellID) then
        return false
    end

    -- 没有物品
    if not Catfish.API:PlayerHasItem(baitData.itemID) then
        return false
    end

    return true
end

-- 获取阿曼尼结界名称
local function GetAmaniWardName()
    local TWW_ITEMS = GetConstants().TWW_ITEMS
    return Catfish.API:GetItemName(TWW_ITEMS.amaniWard.itemID)
end

-- 获取鱼饵名称
local function GetTWWBaitName()
    if not Catfish.db.tww or not Catfish.db.tww.selectedBait then
        return nil
    end
    local TWW_ITEMS = GetConstants().TWW_ITEMS
    local baitKey = Catfish.db.tww.selectedBait
    local baitData = TWW_ITEMS[baitKey .. "Bait"]
    if not baitData then
        return nil
    end
    return Catfish.API:GetItemName(baitData.itemID)
end

-- ============================================
-- Public API
-- ============================================

-- 检查是否需要任何物品（用于状态判断）
function ItemManager:NeedsAnyItem()
    return NeedsRaft() or NeedsGiganticBobber() or NeedsCustomBobber() or
           NeedsAmaniWard() or NeedsTWWBait()
end

-- 检查是否已有木筏buff（用于游泳状态判断）
function ItemManager:HasRaftBuff()
    for _, spellID in ipairs(GetConstants().RAFT_SPELL_IDS) do
        if Catfish.API:UnitHasBuff("player", spellID) then
            return true
        end
    end
    return false
end

-- 获取玩具物品列表（不需要读条的玩具）
function ItemManager:GetToyItemsToUse()
    local items = {}

    Catfish:Debug("GetToyItemsToUse: checking toys...")

    -- 优先级：巨型鱼漂 → 自定义浮标（木筏需要读条，单独处理）
    if NeedsGiganticBobber() then
        local name = GetGiganticBobberName()
        Catfish:Debug("GetToyItemsToUse: NeedsGiganticBobber=true, name=", tostring(name))
        if name then table.insert(items, name) end
    end

    if NeedsCustomBobber() then
        local name = GetCustomBobberName()
        Catfish:Debug("GetToyItemsToUse: NeedsCustomBobber=true, name=", tostring(name))
        if name then table.insert(items, name) end
    end

    Catfish:Debug("GetToyItemsToUse: total items=", #items)
    return items
end

-- 获取需要使用的GCD物品（需要读条的物品，优先级：木筏 > 结界 > 鱼饵）
function ItemManager:GetGCDItemToUse()
    -- 木筏优先级最高（游泳时必须先有木筏）
    if NeedsRaft() then
        local name = GetRaftName()
        Catfish:Print("GetGCDItemToUse: NeedsRaft=true, name=", tostring(name))
        if name then return name end
        -- 如果需要木筏但木筏不可用（冷却中），返回特殊标记
        -- 这样调用方知道要等待而不是钓鱼
        return "__RAFT_COOLDOWN__"
    end

    if NeedsAmaniWard() then
        return GetAmaniWardName()
    end

    if NeedsTWWBait() then
        return GetTWWBaitName()
    end
    return nil
end

-- 检查是否需要使用GCD物品
function ItemManager:NeedsGCDItem()
    local item = self:GetGCDItemToUse()
    return item ~= nil and item ~= "__RAFT_COOLDOWN__"
end

-- 检查是否需要等待木筏（需要木筏但木筏冷却中）
function ItemManager:IsWaitingForRaft()
    return self:GetGCDItemToUse() == "__RAFT_COOLDOWN__"
end

-- 生成GCD物品使用宏
function ItemManager:GenerateGCDItemMacro()
    local item = self:GetGCDItemToUse()
    if item then
        return "/use " .. item
    end
    return nil
end

-- 生成钓鱼筏宏
function ItemManager:BuildDraftMacro()
    local name = GetRaftName()
    if name then
        return "/use " .. name
    end
end

-- 生成巨型鱼漂宏
function ItemManager:BuildGiganticBobberMacro()
    local name = GetGiganticBobberName()
    if name then
        return "/use " .. name
    end
end

-- 生成钓鱼宏（玩具物品 + 钓鱼）
function ItemManager:GenerateFishingMacro()
    local lines = {}
    local spellName = GetFishingSpellName() or "钓鱼"

    -- 添加玩具物品
    local toys = self:GetToyItemsToUse()
    for _, item in ipairs(toys) do
        table.insert(lines, "/use " .. item)
    end

    -- 最后施放钓鱼
    table.insert(lines, "/cast " .. spellName)

    return table.concat(lines, "\n")
end

-- 更新巨型鱼漂名称缓存
function ItemManager:UpdateGiganticBobberCache()
    local GIGANTIC_BOBBER = GetConstants().GIGANTIC_BOBBER
    local name = Catfish.API:GetItemName(GIGANTIC_BOBBER.TOY_ID)
    if name then
        GIGANTIC_BOBBER_NAME = name
    end
end

-- ============================================
-- Initialization
-- ============================================

function ItemManager:Init()
    Catfish:Debug("ItemManager module initialized")
end

-- 检查是否需要木筏
function ItemManager:NeedsRaft()
    local config = Catfish.db.toys
    Catfish:Print("NeedsRaft: raftMode=", tostring(config.raftMode), " isSwimming=", tostring(IsSwimming()))

    if config.raftMode == "none" then
        return false
    end

    -- 检查是否已有木筏buff，且剩余时间大于60秒
    for _, spellID in ipairs(GetConstants().RAFT_SPELL_IDS) do
        local hasBuff, remaining = Catfish.API:UnitHasBuff("player", spellID)
        if hasBuff then
            -- 如果buff剩余时间大于60秒，不需要重新使用
            if remaining > 60 then
                Catfish:Debug("NeedsRaft: already has raft buff, remaining:", remaining)
                return false
            end
        end
    end

    Catfish:Debug("NeedsRaft: returning true")
    return true
end

-- 检查是否需要巨型鱼漂
function ItemManager:NeedsGiganticBobber()
    if not Catfish.db.useGiganticBobber then
        return false
    end

    local GIGANTIC_BOBBER = GetConstants().GIGANTIC_BOBBER

    -- 已有buff
    if Catfish.API:UnitHasBuff("player", GIGANTIC_BOBBER.BUFF_ID) then
        return false
    end

    -- 没有玩具
    if not Catfish.API:PlayerHasToy(GIGANTIC_BOBBER.TOY_ID) then
        return false
    end

    -- 冷却中
    if Catfish.API:GetToyCooldown(GIGANTIC_BOBBER.TOY_ID) > 0 then
        return false
    end

    return true
end
