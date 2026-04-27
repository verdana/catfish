-- Catfish - zhCN.lua
-- Simplified Chinese localization

local ADDON_NAME, Catfish = ...

local L = {}
Catfish.Locales.zhCN = L

-- ============================================
-- General
-- ============================================

L.ADDON_NAME = "鲶鱼"
L.ADDON_TITLE = "鲶鱼 - 钓鱼助手"
L.ADDON_DESCRIPTION = "功能丰富的钓鱼助手，支持自动装备、玩具管理和统计记录"

-- ============================================
-- Commands
-- ============================================

L.CMD_HELP = "帮助"
L.CMD_CONFIG = "设置"
L.CMD_STATS = "统计"
L.CMD_RESET = "重置"
L.CMD_DEBUG = "调试"
L.CMD_TOYS = "玩具"

L.HELP_HEADER = "命令列表:"
L.HELP_CONFIG = "打开设置面板"
L.HELP_STATS = "显示统计数据"
L.HELP_TOYS = "显示玩具状态"
L.HELP_DEBUG = "切换调试模式"
L.HELP_RESET = "重置所有设置"

-- ============================================
-- States
-- ============================================

L.STATE_IDLE = "空闲"
L.STATE_CASTING = "抛竿中"
L.STATE_WAITING = "等待上钩"
L.STATE_REELING = "收杆中"

-- ============================================
-- UI Labels
-- ============================================

L.TAB_FISHING = "钓鱼设置"
L.TAB_EQUIPMENT = "装备管理"
L.TAB_TOYS = "玩具设置"
L.TAB_STATS = "统计数据"

L.ENABLE_ONEKEY = "启用一键钓鱼"
L.ENABLE_DOUBLECLICK = "启用双击钓鱼"
L.ENABLE_SOUND_MANAGEMENT = "钓鱼时自动管理声音"
L.SOUND_MANAGEMENT_DESC = "激活时开启后台声音、关闭音乐、最大化音效，休眠时恢复原始设置"
L.USE_GIGANTIC_BOBBER = "使用巨型鱼漂"

L.SET_KEYBIND = "设置快捷键"
L.KEYBIND_SET = "快捷键已设置: %s"
L.KEYBIND_CAPTURE = "按下按键设置快捷键，或按ESC取消"

L.RAFT_MODE = "竹筏模式:"
L.BOBBER_MODE = "鱼漂模式:"
L.MODE_DISABLED = "禁用"
L.MODE_RANDOM = "随机"
L.MODE_SPECIFIC = "指定"

-- ============================================
-- Statistics
-- ============================================

L.STATS_TITLE = "统计数据"
L.STATS_TOTAL_CATCHES = "总钓获数"
L.STATS_TOTAL_TIME = "总钓鱼时间"
L.STATS_CATCHES_PER_HOUR = "每小时钓获数"
L.STATS_CURRENT_SESSION = "当前会话"
L.STATS_UNIQUE_ITEMS = "已钓获物品种类"
L.STATS_TOP_ITEMS = "钓获最多的物品"
L.STATS_TOP_ZONES = "最常钓鱼地点"
L.STATS_RARE_CATCHES = "稀有钓获记录"
L.STATS_NO_RARES = "还没有记录到稀有钓获!"

-- Stats HUD
L.STATS_HUD_TITLE = "钓鱼统计"
L.STATS_DURATION = "持续时间"
L.STATS_CASTS = "抛竿次数"
L.STATS_TOTAL_LOOT = "总收获"
L.STATS_ITEMS_BREAKDOWN = "鱼获明细"
L.STATS_NO_LOOT = "暂无收获"
L.SHOW_STATS_HUD = "显示统计 HUD"
L.SHOW_STATS_HUD_DESC = "在屏幕上显示钓鱼统计数据（持续时间、抛竿次数、鱼获等）"
L.STATS_ONLY_FISH = "只统计鱼类"
L.STATS_ONLY_FISH_DESC = "开启后只统计鱼类物品，排除垃圾、装备、图纸等其他物品"

L.RESET_STATS = "重置统计数据"
L.RESET_SESSION = "重置会话"
L.STATS_RESET = "统计数据已重置"
L.SESSION_RESET = "会话统计已重置"

-- ============================================
-- Equipment
-- ============================================

L.EQUIP_TITLE = "装备"
L.EQUIP_AVAILABLE_POLES = "可用的鱼竿:"
L.EQUIP_AVAILABLE_HATS = "可用的钓鱼帽:"
L.EQUIP_CURRENT_POLE = "当前鱼竿: %s"
L.EQUIP_NO_POLE = "未装备鱼竿"
L.EQUIP_BEST_POLE = "最佳可用: %s (+%d 钓鱼)"

-- ============================================
-- Toys
-- ============================================

L.TOYS_TITLE = "玩具"
L.TOYS_STATUS = "玩具状态"
L.TOYS_OWNED = "已拥有: %d"
L.TOYS_READY = "就绪"
L.TOYS_COOLDOWN = "冷却中: %d秒"
L.TOYS_NONE = "无"

L.TOYS_RAFTS = "竹筏"
L.TOYS_BOBBERS = "鱼漂"
L.TOYS_EXTRA = "额外玩具"

L.TOYS_SELECT_RAFT = "选择竹筏"
L.TOYS_SELECT_BOBBER = "选择鱼漂"

-- ============================================
-- Messages
-- ============================================

L.MSG_ENABLED = "已启用"
L.MSG_DISABLED = "已禁用"
L.MSG_DEBUG_MODE = "调试模式: %s"
L.MSG_DATABASE_RESET = "数据库已重置。"
L.MSG_CANNOT_EQUIP_COMBAT = "战斗中无法装备"
L.MSG_CANNOT_CAST = "无法施放钓鱼"
L.MSG_ALREADY_FISHING = "正在钓鱼中"
L.MSG_NOT_FISHING = "当前没有钓鱼"

L.MSG_RARE_CATCH = "★ 稀有钓获: %s 于 %s"
L.MSG_EPIC_CATCH = "★ 史诗钓获: %s 于 %s"

L.MSG_FISHING_STARTED = "钓鱼会话已开始"
L.MSG_FISHING_STOPPED = "钓鱼会话已结束"
L.MSG_LURE_APPLIED = "已使用鱼饵: %s"
L.MSG_LURE_EXPIRED = "鱼饵效果已结束"
L.MSG_NO_LURES = "没有可用的鱼饵"

L.MSG_KEYBIND_IN_COMBAT = "战斗中无法更改快捷键"
L.MSG_KEYBIND_CLEARED = "快捷键已清除"

-- ============================================
-- Tooltips
-- ============================================

L.TIP_LEFT_CLICK = "左键: 打开设置"
L.TIP_RIGHT_CLICK = "右键: 快捷菜单"
L.TIP_DRAG_MOVE = "拖拽: 移动按钮"

L.TIP_FISHING_STATUS = "状态: %s"
L.TIP_SESSION_CATCHES = "本会话钓获: %d"
L.TIP_SESSION_TIME = "本会话时间: %s"

-- ============================================
-- Time Format
-- ============================================

L.TIME_FORMAT_HM = "%d小时%d分钟"
L.TIME_FORMAT_M = "%d分钟"
L.TIME_FORMAT_S = "%d秒"

-- ============================================
-- Quality Names
-- ============================================

L.QUALITY_POOR = "垃圾"
L.QUALITY_COMMON = "普通"
L.QUALITY_UNCOMMON = "优秀"
L.QUALITY_RARE = "精良"
L.QUALITY_EPIC = "史诗"
L.QUALITY_LEGENDARY = "传说"
L.QUALITY_ARTIFACT = "神器"
L.QUALITY_HEIRLOOM = "传家宝"
L.QUALITY_UNKNOWN = "未知"

-- ============================================
-- Errors
-- ============================================

L.ERROR_UNKNOWN_COMMAND = "未知命令。使用 /catfish 帮助 查看可用命令。"
L.ERROR_NO_FISHING_SKILL = "你没有钓鱼技能"
L.ERROR_NOT_EQUIPPED = "未装备鱼竿"
L.ERROR_ALREADY_EQUIPPED = "已装备: %s"
L.ERROR_ITEM_NOT_FOUND = "找不到物品: %s"
L.ERROR_TOY_NOT_OWNED = "你没有这个玩具"

-- ============================================
-- Minimap Button
-- ============================================

L.MINIMAP_TITLE = "Catfish - 钓鱼助手"
L.MINIMAP_STATUS = "状态:"
L.MINIMAP_STATUS_ACTIVE = "|cFF00FF00激活|r"
L.MINIMAP_STATUS_SLEEP = "|cFF808080休眠|r"
L.MINIMAP_FISHING_MODE = "钓鱼模式:"
L.MINIMAP_MODE_DISABLED = "未启用"
L.MINIMAP_MODE_ONEKEY = "一键模式 (%s)"
L.MINIMAP_MODE_DOUBLECLICK = "双击模式 (右键双击)"
L.MINIMAP_SESSION_CATCHES = "本次钓获:"
L.MINIMAP_SESSION_TIME = "钓鱼时间:"
L.MINIMAP_TIP_LEFT_CLICK = "|cFFFFFF00左键|r 打开设置"
L.MINIMAP_TIP_CTRL_LEFT = "|cFFFFFF00Ctrl+左键|r 统计HUD"
L.MINIMAP_TIP_RIGHT_CLICK = "|cFFFFFF00右键|r 切换激活/休眠"
L.MINIMAP_ACTIVATED = "已激活"
L.MINIMAP_SLEEP = "已休眠"

-- ============================================
-- Options Panel
-- ============================================

L.OPT_FISHING_MODE = "钓鱼模式"
L.OPT_ONEKEY_DESC = "按下一个键完成钓鱼动作"
L.OPT_KEYBIND_LABEL = "快捷键绑定"
L.OPT_KEYBIND_DESC = "点击设置一键钓鱼的快捷键"
L.OPT_DOUBLECLICK_DESC = "快速双击鼠标右键开始钓鱼"
L.OPT_TOYS_SECTION = "玩具设置"
L.OPT_RAFT_DESC = "选择游泳时要使用的钓鱼筏（选择'无'表示不使用钓鱼筏）"
L.OPT_GIGANTIC_BOBBER_DESC = "每次抛竿前自动使用\"可重复使用的巨型鱼漂\"玩具，放大鱼漂便于观察"
L.OPT_BOBBER_DESC = "选择要使用的浮标玩具（选择'无'表示不使用自定义浮标）"
L.OPT_STATS_SECTION = "统计设置"
L.OPT_SHOW_HUD_DESC = "在屏幕上显示钓鱼统计数据（持续时间、抛竿次数、鱼获等）"
L.OPT_ONLY_FISH_DESC = "开启后只统计鱼类物品，排除垃圾、装备、图纸等其他物品"
L.OPT_OTHER_SECTION = "其它设置"
L.OPT_SOUND_DESC = "激活时自动开启后台声音、关闭音乐、最大化音效音量，休眠时恢复原始设置"
L.OPT_AUTOLOOT_DESC = "每次抛竿时自动检查并开启自动拾取功能"
L.OPT_HIDE_MINIMAP_DESC = "隐藏小地图上的插件按钮"
L.OPT_DEBUG_DESC = "在聊天框输出详细的调试信息，用于排查问题"
L.OPT_TWW_SECTION = "至暗之夜"
L.OPT_TREASURE_SOUND_DESC = "钓鱼时出现藏宝箱时播放提示音（至暗之夜版本功能）"
L.OPT_AMANI_WARD_DESC = "抛竿前自动使用阿曼尼垂钓者的结界（需要背包中有该物品，且身上没有对应Buff）"
L.OPT_AUTO_BAIT_DESC = "抛竿前自动使用选中的鱼饵（需要背包中有该物品，且身上没有对应Buff）"
L.OPT_HIDE_MINIMAP = "隐藏小地图按钮"
L.OPT_DEBUG_MODE = "启用调试模式"
L.OPT_TREASURE_SOUND = "宝箱出现提示音"
L.OPT_AMANI_WARD = "阿曼尼垂钓者的结界"
L.ENABLE_AUTOLOOT = "保持自动拾取"
L.OPT_KEYBIND_HINT = "按下按键设置，ESC取消，右键清除绑定"
L.OPT_NONE = "无"
L.OPT_SELECT_RAFT = "选择钓鱼筏"
L.OPT_SELECT_BOBBER = "选择浮标"
L.OPT_AUTO_BAIT = "自动上饵"

-- ============================================
-- Bait Names
-- ============================================

L.BAIT_FORTUNE = "好运神灵鱼诱饵"
L.BAIT_OCTOPUS = "不祥章鱼诱饵"
L.BAIT_BLOODHUNTER = "鲜血猎手诱饵"

-- ============================================
-- Stats HUD
-- ============================================

L.HUD_TITLE = "|cFF00FF00Catfish 钓鱼统计|r"
L.HUD_NO_LOOT = "暂无收获"
L.HUD_DURATION = "耗时:"
L.HUD_CASTS = "抛竿:"
L.HUD_HARVEST = "收获:"

-- ============================================
-- Stats Window
-- ============================================

L.STATS_WINDOW_TITLE = "Catfish Statistics"
L.STATS_TAB_OVERVIEW = "Overview"
L.STATS_TAB_ITEMS = "Items"
L.STATS_TAB_ZONES = "Zones"
L.STATS_TAB_RARES = "Rares"
L.STATS_TOTAL_CATCHES = "Total Catches: %d"
L.STATS_TOTAL_TIME_LABEL = "Total Fishing Time: %s"
L.STATS_CPH_LABEL = "Catches per Hour: %.1f"
L.STATS_CURRENT_SESSION_LABEL = "Current Session"
L.STATS_SESSION_CATCHES = "Catches: %d"
L.STATS_SESSION_TIME_LABEL = "Time: %s"
L.STATS_UNIQUE_LABEL = "Unique Items Caught: %d"
L.STATS_NO_RARES = "No rare catches recorded yet!"
L.STATS_CATCHES_FORMAT = "%d catches"

-- ============================================
-- Toy Status
-- ============================================

L.TOY_STATUS_HEADER = "=== Toy Status ==="
L.TOY_RAFTS_OWNED = "Rafts owned: %d"
L.TOY_BOBBERS_OWNED = "Bobbers owned: %d"
L.TOY_EXTRA_OWNED = "Extra toys: %d"
L.TOY_READY = "ready"
L.TOY_ON_COOLDOWN = "on cooldown: %ds"
L.TOY_RAFT_MODE = "Raft mode: %s"
L.TOY_BOBBER_MODE = "Bobber mode: %s"

-- ============================================
-- OneKey Messages
-- ============================================

L.ONEKEY_SET_IN_COMBAT = "战斗中无法设置快捷键"
L.ONEKEY_CLEARED = "快捷键已清除"
L.ONEKEY_SET_TO = "快捷键已设置为: %s"

-- ============================================
-- Treasure Chest
-- ============================================

L.TREASURE_DETECTED = "★ 检测到藏宝箱！"

-- ============================================
-- Epic Catch
-- ============================================

L.EPIC_CATCH_FORMAT = "★ EPIC CATCH: %s%s at %s"

-- ============================================
-- Misc
-- ============================================

L.NOT_BOUND = NOT_BOUND or "Not Bound"
L.LIBEQOL_NOT_FOUND = "LibEQOL not found, using fallback settings"

return L