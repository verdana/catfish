-- Catfish - TWWItems.lua
-- The War Within (至暗之夜) 特有物品管理模块

local ADDON_NAME, Catfish = ...

local TWWItems = {}
Catfish.Modules.TWWItems = TWWItems

-- ============================================
-- 物品数据
-- ============================================

TWWItems.ITEMS = {
    -- 阿曼尼垂钓者的结界
    amaniWard = {
        itemID = 241148,
        buffSpellID = 1237919,
        name = "阿曼尼垂钓者的结界",
    },
    -- 好运神灵鱼诱饵
    fortuneBait = {
        itemID = 241145,
        buffSpellID = 1237964,
        name = "好运神灵鱼诱饵",
    },
    -- 不祥章鱼诱饵
    octopusBait = {
        itemID = 241149,
        buffSpellID = 1237965,
        name = "不祥章鱼诱饵",
    },
}

-- ============================================
-- 检查函数
-- ============================================

-- 检查玩家是否有指定物品
function TWWItems:HasItem(itemKey)
    local itemData = self.ITEMS[itemKey]
    if not itemData then return false end

    return Catfish.API:PlayerHasItem(itemData.itemID)
end

-- 检查玩家是否有指定Buff
function TWWItems:HasBuff(itemKey)
    local itemData = self.ITEMS[itemKey]
    if not itemData then return false end

    return Catfish.API:UnitHasBuff("player", itemData.buffSpellID)
end

-- 获取物品信息
function TWWItems:GetItemInfo(itemKey)
    return self.ITEMS[itemKey]
end

-- ============================================
-- 使用物品
-- ============================================

function TWWItems:UseItem(itemKey)
    local itemData = self.ITEMS[itemKey]
    if not itemData then
        Catfish:Debug("TWWItems: Unknown item key:", itemKey)
        return false
    end

    -- 检查是否在战斗中
    if InCombatLockdown() then
        Catfish:Debug("TWWItems: Cannot use item in combat")
        return false
    end

    -- 检查是否已有Buff
    local hasBuff = self:HasBuff(itemKey)
    Catfish:Debug("TWWItems: HasBuff for", itemData.name, "=", hasBuff)
    if hasBuff then
        Catfish:Debug("TWWItems: Already has buff for:", itemData.name)
        return false
    end

    -- 检查背包中是否有物品
    local hasItem = self:HasItem(itemKey)
    Catfish:Debug("TWWItems: HasItem for", itemData.name, "=", hasItem)
    if not hasItem then
        Catfish:Debug("TWWItems: Item not in bags:", itemData.name)
        return false
    end

    -- 使用物品
    local bagID, slot = Catfish.API:FindItemInBags(itemData.itemID)
    Catfish:Debug("TWWItems: FindItemInBags result:", bagID, slot)
    if bagID and slot then
        Catfish:Debug("TWWItems: Using item:", itemData.name, "at bag", bagID, "slot", slot)
        C_Container.UseContainerItem(bagID, slot)
        return true
    end

    return false
end

-- ============================================
-- 自动使用逻辑
-- ============================================

function TWWItems:UseAmaniWard()
    -- 检查是否启用
    if not Catfish.db.tww or not Catfish.db.tww.useAmaniWard then
        Catfish:Debug("TWWItems: Amani Ward not enabled")
        return false
    end

    Catfish:Debug("TWWItems: Attempting to use Amani Ward")
    return self:UseItem("amaniWard")
end

function TWWItems:UseSelectedBait()
    -- 检查是否选择了鱼饵
    if not Catfish.db.tww or not Catfish.db.tww.selectedBait then
        Catfish:Debug("TWWItems: No bait selected")
        return false
    end

    local baitKey = Catfish.db.tww.selectedBait
    Catfish:Debug("TWWItems: Attempting to use bait:", baitKey)

    if baitKey == "fortune" then
        return self:UseItem("fortuneBait")
    elseif baitKey == "octopus" then
        return self:UseItem("octopusBait")
    end

    return false
end

-- 在抛竿前调用，使用所有配置的至暗之夜物品
function TWWItems:UseAllConfiguredItems()
    Catfish:Debug("TWWItems: UseAllConfiguredItems called")

    -- 检查设置是否存在
    if not Catfish.db.tww then
        Catfish:Debug("TWWItems: tww settings not found")
        return
    end

    Catfish:Debug("TWWItems: useAmaniWard =", Catfish.db.tww.useAmaniWard)
    Catfish:Debug("TWWItems: selectedBait =", Catfish.db.tww.selectedBait)

    -- 先使用阿曼尼垂钓者的结界
    self:UseAmaniWard()

    -- 再使用鱼饵
    self:UseSelectedBait()
end

-- ============================================
-- 初始化
-- ============================================

function TWWItems:Init()
    -- 确保 tww 表存在
    if not Catfish.db.tww then
        Catfish.db.tww = {
            useAmaniWard = false,
            selectedBait = nil,
        }
    end

    Catfish:Debug("TWWItems module initialized")
end