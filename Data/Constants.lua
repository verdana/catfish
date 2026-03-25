-- Catfish - Constants.lua
-- 全局常量定义，避免重复

local ADDON_NAME, Catfish = ...

local Constants = {}
Catfish.Data.Constants = Constants

-- ============================================
-- Gigantic Bobber (可重复使用的巨型鱼漂)
-- ============================================

Constants.GIGANTIC_BOBBER = {
    TOY_ID = 202207,
    BUFF_ID = 397827,
}

-- ============================================
-- The War Within Items (至暗之夜物品)
-- ============================================

Constants.TWW_ITEMS = {
    amaniWard = {
        itemID = 241148,
        buffSpellID = 1237919,
        name = "阿曼尼垂钓者的结界",
    },
    fortuneBait = {
        itemID = 241145,
        buffSpellID = 1237964,
        name = "好运神灵鱼诱饵",
    },
    octopusBait = {
        itemID = 241149,
        buffSpellID = 1237965,
        name = "不祥章鱼诱饵",
    },
}

-- ============================================
-- Quality Colors (物品品质颜色)
-- ============================================

Constants.QUALITY_COLORS = {
    [0] = "|cFF9D9D9D", -- Poor (gray)
    [1] = "|cFFFFFFFF", -- Common (white)
    [2] = "|cFF1EFF00", -- Uncommon (green)
    [3] = "|cFF0070DD", -- Rare (blue)
    [4] = "|cFFA335EE", -- Epic (purple)
    [5] = "|cFFFF8000", -- Legendary (orange)
}

-- ============================================
-- Raft Buff Info (木筏Buff信息)
-- ============================================

Constants.RAFT_SPELL_IDS = {383268, 124036, 288758, 1218420}

Constants.RAFT_BUFF_NAMES = {
    "Tuskarr Dinghy",        -- 383268
    "Anglers Fishing Raft",  -- 124036
    "Gnarlwood Waveboard",   -- 288758
    "Personal Fishing Barge", -- 1218420
}

-- ============================================
-- Helper Functions
-- ============================================

function Constants:GetQualityColor(quality)
    return self.QUALITY_COLORS[quality] or self.QUALITY_COLORS[1]
end