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
-- Public API
-- ============================================

-- 检查是否已有木筏buff（用于游泳状态判断）
function ItemManager:HasRaftBuff()
    for _, spellID in ipairs(GetConstants().RAFT_SPELL_IDS) do
        if Catfish.API:UnitHasBuff("player", spellID) then
            return true
        end
    end
    return false
end

-- 生成钓鱼筏宏
function ItemManager:BuildDraftMacro()
    local name = GetRaftName()
    if name then
        return "/use [nocombat] " .. name
    end
end

-- 生成巨型鱼漂宏
function ItemManager:BuildGiganticBobberMacro()
    local name = GetGiganticBobberName()
    if name then
        return "/use [nocombat] " .. name
    end
end

-- 生成浮标宏
function ItemManager:BuildCustomBobberMacro()
    local name = GetCustomBobberName()
    if name then
        return "/use [nocombat] " .. name
    end
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

    if config.raftMode == "none" then
        return false
    end

    -- 检查是否已有木筏buff（剩余时间大于60秒）
    for _, spellID in ipairs(GetConstants().RAFT_SPELL_IDS) do
        local hasBuff, remaining = Catfish.API:UnitHasBuff("player", spellID)
        if hasBuff and remaining > 60 then
            return false
        end
    end

    -- 非游泳状态下不需要使用木筏
    if not IsSwimming() then
        return false
    end

    return true
end

-- 检查是否需要巨型鱼漂
function ItemManager:NeedsGiganticBobber()
    if not Catfish.db.useGiganticBobber then
        return false
    end

    local GIGANTIC_BOBBER = GetConstants().GIGANTIC_BOBBER

    -- 已有buff且剩余时间>60秒
    local hasBuff, remaining = Catfish.API:UnitHasBuff("player", GIGANTIC_BOBBER.BUFF_ID)
    if hasBuff and remaining > 60 then
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

-- 检查是否需要自定义浮标
-- 返回: needsUse, shouldOverride
--   needsUse: 是否需要使用浮标
--   shouldOverride: 是否需要覆盖当前浮标（切换了不同类型）
function ItemManager:NeedsCustomBobber()
    local toyID = Catfish.db.selectedBobberToy
    if not toyID then
        return false, false
    end

    if not Catfish.API:PlayerHasToy(toyID) then
        return false, false
    end

    if Catfish.API:GetToyCooldown(toyID) > 0 then
        return false, false
    end

    -- 获取该玩具对应的 spellID (BUFF ID)
    local spellID = GetConstants():GetBobberSpellID(toyID)
    if not spellID then
        -- 未知的玩具ID，默认允许使用
        return true, false
    end

    -- 检查是否已有同类型浮标buff
    local hasBuff, remaining = Catfish.API:UnitHasBuff("player", spellID)
    if hasBuff and remaining > 60 then
        -- 已有足够时间的同类型BUFF，不需要重新使用
        return false, false
    end

    -- 检查是否有其他类型的浮标buff（需要覆盖）
    local hasOtherBobberBuff = self:HasOtherBobberBuff(toyID)

    -- 如果有其他浮标buff或者没有buff/时间不足，都需要使用
    return true, hasOtherBobberBuff
end

-- 检查是否有其他类型的浮标buff（排除当前选择的浮标）
function ItemManager:HasOtherBobberBuff(currentToyID)
    local currentSpellID = GetConstants():GetBobberSpellID(currentToyID)

    for _, spellID in ipairs(GetConstants().BOBBER_SPELL_IDS) do
        if spellID ~= currentSpellID then
            local hasBuff = Catfish.API:UnitHasBuff("player", spellID)
            if hasBuff then
                return true
            end
        end
    end
    return false
end

-- ============================================
-- The War Within Items (至暗之夜物品)
-- ============================================

-- 检查是否需要阿曼尼结界
function ItemManager:NeedsAmaniWard()
    -- 首先检查是否在至暗之夜地图
    if not Catfish.API:IsInTWWZone() then
        return false
    end

    -- 检查设置是否启用
    if not Catfish.db.tww or not Catfish.db.tww.useAmaniWard then
        return false
    end

    local TWW_ITEMS = Catfish.Data.Constants.TWW_ITEMS

    -- 检查是否有 buff
    if Catfish.API:UnitHasBuff("player", TWW_ITEMS.amaniWard.buffSpellID) then
        return false
    end

    -- 检查背包是否有物品
    if not Catfish.API:PlayerHasItem(TWW_ITEMS.amaniWard.itemID) then
        return false
    end

    return true
end

-- 检查是否需要鱼饵
function ItemManager:NeedsBait()
    -- 首先检查是否在至暗之夜地图
    if not Catfish.API:IsInTWWZone() then
        return false
    end

    -- 检查是否选择了鱼饵
    if not Catfish.db.tww or not Catfish.db.tww.selectedBait then
        return false
    end

    local TWW_ITEMS = Catfish.Data.Constants.TWW_ITEMS
    local baitKey = Catfish.db.tww.selectedBait .. "Bait"  -- fortune -> fortuneBait
    local baitData = TWW_ITEMS[baitKey]

    if not baitData then return false end

    -- 检查是否有 buff
    if Catfish.API:UnitHasBuff("player", baitData.buffSpellID) then
        return false
    end

    -- 检查背包是否有物品
    if not Catfish.API:PlayerHasItem(baitData.itemID) then
        return false
    end

    return true
end

-- 构建阿曼尼结界宏
function ItemManager:BuildAmaniWardMacro()
    local TWW_ITEMS = Catfish.Data.Constants.TWW_ITEMS
    local name = Catfish.API:GetItemName(TWW_ITEMS.amaniWard.itemID)
    if name then
        return "/use [nocombat] " .. name
    end
end

-- 构建鱼饵宏
function ItemManager:BuildBaitMacro()
    if not Catfish.db.tww or not Catfish.db.tww.selectedBait then
        return nil
    end

    local TWW_ITEMS = Catfish.Data.Constants.TWW_ITEMS
    local baitKey = Catfish.db.tww.selectedBait .. "Bait"
    local baitData = TWW_ITEMS[baitKey]

    if not baitData then return nil end

    local name = Catfish.API:GetItemName(baitData.itemID)
    if name then
        return "/use [nocombat] " .. name
    end
end


