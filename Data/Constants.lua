-- Catfish - Constants.lua
-- 全局常量定义，避免重复

local ADDON_NAME, Catfish = ...

local Constants = {}
Catfish.Data.Constants = Constants

-- ============================================
-- Quality Colors (物品品质颜色)
-- ============================================

Constants.QUALITY_COLORS = {
	[0] = "|cFF9D9D9D", -- Poor      (gray)
	[1] = "|cFFFFFFFF", -- Common    (white)
	[2] = "|cFF1EFF00", -- Uncommon  (green)
	[3] = "|cFF0070DD", -- Rare      (blue)
	[4] = "|cFFA335EE", -- Epic      (purple)
	[5] = "|cFFFF8000", -- Legendary (orange)
}

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
-- Raft Buff Info (钓鱼筏Buff信息)
-- ============================================

Constants.RAFT_SPELL_IDS = { 383268, 124036, 288758, 1218420 }

-- ============================================
-- Bobber Buff Info (浮标Buff信息)
-- spellID = BUFF ID，每个浮标玩具使用后获得对应 BUFF
-- ============================================

Constants.BOBBER_SPELL_IDS = {
	397827, -- 可重复使用的巨型鱼漂
	231291, -- 浮标箱：蠕虫罐头
	240803, -- 浮标箱：雕刻木舵
	231319, -- 浮标箱：猫头
	240801, -- 浮标箱：恶魔脑袋
	240800, -- 浮标箱：附魔浮标
	240806, -- 浮标箱：森林之面
	240802, -- 浮标箱：漂浮图腾
	231349, -- 浮标箱：鱼人脑袋
	240804, -- 浮标箱：贡多拉复制品
	231341, -- 浮标箱：尖叫鸭子
	231338, -- 浮标箱：拖船
	232613, -- 浮标箱：木质佩佩
	335484, -- 蝙蝠面具浮标
	1222880, -- 限量版火箭浮标
	1222884, -- 饮料高脚杯浮标
	1222888, -- 有机惠灵顿浮标
}

-- toyID → spellID 映射表
Constants.BOBBER_TOY_TO_SPELL = {
	[202207] = 397827, -- 可重复使用的巨型鱼漂
	[142528] = 231291, -- 浮标箱：蠕虫罐头
	[147307] = 240803, -- 浮标箱：雕刻木舵
	[142529] = 231319, -- 浮标箱：猫头
	[147312] = 240801, -- 浮标箱：恶魔脑袋
	[147308] = 240800, -- 浮标箱：附魔浮标
	[147309] = 240806, -- 浮标箱：森林之面
	[147310] = 240802, -- 浮标箱：漂浮图腾
	[142532] = 231349, -- 浮标箱：鱼人脑袋
	[147311] = 240804, -- 浮标箱：贡多拉复制品
	[142531] = 231341, -- 浮标箱：尖叫鸭子
	[142530] = 231338, -- 浮标箱：拖船
	[143662] = 232613, -- 浮标箱：木质佩佩
	[180993] = 335484, -- 蝙蝠面具浮标
	[237345] = 1222880, -- 限量版火箭浮标
	[237346] = 1222884, -- 饮料高脚杯浮标
	[237347] = 1222888, -- 有机惠灵顿浮标
}

-- ============================================
-- Helper Functions
-- ============================================

function Constants:GetQualityColor(quality)
	return self.QUALITY_COLORS[quality] or self.QUALITY_COLORS[1]
end

-- 根据 toyID 获取对应的 spellID (BUFF ID)
function Constants:GetBobberSpellID(toyID)
	return self.BOBBER_TOY_TO_SPELL[toyID]
end
