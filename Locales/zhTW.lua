-- Catfish - zhTW.lua
-- Traditional Chinese localization

local ADDON_NAME, Catfish = ...

local L = {}
Catfish.Locales.zhTW = L

-- ============================================
-- General
-- ============================================

L.ADDON_NAME = "鯰魚"
L.ADDON_TITLE = "鯰魚 - 釣魚助手"
L.ADDON_DESCRIPTION = "功能豐富的釣魚助手，支持自動裝備、玩具管理和統計記錄"

-- ============================================
-- Commands
-- ============================================

L.CMD_HELP = "幫助"
L.CMD_CONFIG = "設置"
L.CMD_STATS = "統計"
L.CMD_RESET = "重置"
L.CMD_DEBUG = "調試"
L.CMD_TOYS = "玩具"

L.HELP_HEADER = "命令列表:"
L.HELP_CONFIG = "打開設置面板"
L.HELP_STATS = "顯示統計數據"
L.HELP_TOYS = "顯示玩具狀態"
L.HELP_DEBUG = "切換調試模式"
L.HELP_RESET = "重置所有設置"

-- ============================================
-- States
-- ============================================

L.STATE_IDLE = "空閒"
L.STATE_CASTING = "拋竿中"
L.STATE_WAITING = "等待上鉤"
L.STATE_REELING = "收杆中"

-- ============================================
-- UI Labels
-- ============================================

L.TAB_FISHING = "釣魚設置"
L.TAB_EQUIPMENT = "裝備管理"
L.TAB_TOYS = "玩具設置"
L.TAB_STATS = "統計數據"

L.ENABLE_ONEKEY = "啟用一鍵釣魚"
L.ENABLE_DOUBLECLICK = "啟用雙擊釣魚"
L.ENABLE_SOUND_MANAGEMENT = "釣魚時自動管理聲音"
L.SOUND_MANAGEMENT_DESC = "激活時開啟背景聲音、關閉音樂、最大化音效，休眠時恢復原始設置"
L.USE_GIGANTIC_BOBBER = "使用巨型魚漂"

L.SET_KEYBIND = "設置快捷鍵"
L.KEYBIND_SET = "快捷鍵已設置: %s"
L.KEYBIND_CAPTURE = "按下按鍵設置快捷鍵，或按ESC取消"

L.RAFT_MODE = "竹筏模式:"
L.BOBBER_MODE = "魚漂模式:"
L.MODE_DISABLED = "禁用"
L.MODE_RANDOM = "隨機"
L.MODE_SPECIFIC = "指定"

-- ============================================
-- Statistics
-- ============================================

L.STATS_TITLE = "統計數據"
L.STATS_TOTAL_CATCHES = "總釣獲數"
L.STATS_TOTAL_TIME = "總釣魚時間"
L.STATS_CATCHES_PER_HOUR = "每小時釣獲數"
L.STATS_CURRENT_SESSION = "當前會話"
L.STATS_UNIQUE_ITEMS = "已釣獲物品種類"
L.STATS_TOP_ITEMS = "釣獲最多的物品"
L.STATS_TOP_ZONES = "最常釣魚地點"
L.STATS_RARE_CATCHES = "稀有釣獲記錄"
L.STATS_NO_RARES = "還沒有記錄到稀有釣獲!"

-- Stats HUD
L.STATS_HUD_TITLE = "釣魚統計"
L.STATS_DURATION = "持續時間"
L.STATS_CASTS = "拋竿次數"
L.STATS_TOTAL_LOOT = "總收穫"
L.STATS_ITEMS_BREAKDOWN = "魚獲明細"
L.STATS_NO_LOOT = "暫無收穫"
L.SHOW_STATS_HUD = "顯示統計 HUD"
L.SHOW_STATS_HUD_DESC = "在屏幕上顯示釣魚統計數據（持續時間、拋竿次數、魚獲等）"
L.STATS_ONLY_FISH = "只統計魚類"
L.STATS_ONLY_FISH_DESC = "開啟後只統計魚類物品，排除垃圾、裝備、圖紙等其他物品"

L.RESET_STATS = "重置統計數據"
L.RESET_SESSION = "重置會話"
L.STATS_RESET = "統計數據已重置"
L.SESSION_RESET = "會話統計已重置"

-- ============================================
-- Equipment
-- ============================================

L.EQUIP_TITLE = "裝備"
L.EQUIP_AVAILABLE_POLES = "可用的魚竿:"
L.EQUIP_AVAILABLE_HATS = "可用的釣魚帽:"
L.EQUIP_CURRENT_POLE = "當前魚竿: %s"
L.EQUIP_NO_POLE = "未裝備魚竿"
L.EQUIP_BEST_POLE = "最佳可用: %s (+%d 釣魚)"

-- ============================================
-- Toys
-- ============================================

L.TOYS_TITLE = "玩具"
L.TOYS_STATUS = "玩具狀態"
L.TOYS_OWNED = "已擁有: %d"
L.TOYS_READY = "就緒"
L.TOYS_COOLDOWN = "冷卻中: %d秒"
L.TOYS_NONE = "無"

L.TOYS_RAFTS = "竹筏"
L.TOYS_BOBBERS = "魚漂"
L.TOYS_EXTRA = "額外玩具"

L.TOYS_SELECT_RAFT = "選擇竹筏"
L.TOYS_SELECT_BOBBER = "選擇魚漂"

-- ============================================
-- Messages
-- ============================================

L.MSG_ENABLED = "已啟用"
L.MSG_DISABLED = "已禁用"
L.MSG_DEBUG_MODE = "調試模式: %s"
L.MSG_DATABASE_RESET = "數據庫已重置。"
L.MSG_CANNOT_EQUIP_COMBAT = "戰鬥中無法裝備"
L.MSG_CANNOT_CAST = "無法施放釣魚"
L.MSG_ALREADY_FISHING = "正在釣魚中"
L.MSG_NOT_FISHING = "當前沒有釣魚"

L.MSG_RARE_CATCH = "★ 稀有釣獲: %s 於 %s"
L.MSG_EPIC_CATCH = "★ 史詩釣獲: %s 於 %s"

L.MSG_FISHING_STARTED = "釣魚會話已開始"
L.MSG_FISHING_STOPPED = "釣魚會話已結束"
L.MSG_LURE_APPLIED = "已使用魚餌: %s"
L.MSG_LURE_EXPIRED = "魚餌效果已結束"
L.MSG_NO_LURES = "沒有可用的魚餌"

L.MSG_KEYBIND_IN_COMBAT = "戰鬥中無法更改快捷鍵"
L.MSG_KEYBIND_CLEARED = "快捷鍵已清除"

-- ============================================
-- Tooltips
-- ============================================

L.TIP_LEFT_CLICK = "左鍵: 打開設置"
L.TIP_RIGHT_CLICK = "右鍵: 快捷菜單"
L.TIP_DRAG_MOVE = "拖拽: 移動按鈕"

L.TIP_FISHING_STATUS = "狀態: %s"
L.TIP_SESSION_CATCHES = "本會話釣獲: %d"
L.TIP_SESSION_TIME = "本會話時間: %s"

-- ============================================
-- Time Format
-- ============================================

L.TIME_FORMAT_HM = "%d小時%d分鐘"
L.TIME_FORMAT_M = "%d分鐘"
L.TIME_FORMAT_S = "%d秒"

-- ============================================
-- Quality Names
-- ============================================

L.QUALITY_POOR = "垃圾"
L.QUALITY_COMMON = "普通"
L.QUALITY_UNCOMMON = "優秀"
L.QUALITY_RARE = "精良"
L.QUALITY_EPIC = "史詩"
L.QUALITY_LEGENDARY = "傳說"
L.QUALITY_ARTIFACT = "神器"
L.QUALITY_HEIRLOOM = "傳家寶"

-- ============================================
-- Errors
-- ============================================

L.ERROR_UNKNOWN_COMMAND = "未知命令。使用 /catfish 幫助 查看可用命令。"
L.ERROR_NO_FISHING_SKILL = "你沒有釣魚技能"
L.ERROR_NOT_EQUIPPED = "未裝備魚竿"
L.ERROR_ALREADY_EQUIPPED = "已裝備: %s"
L.ERROR_ITEM_NOT_FOUND = "找不到物品: %s"
L.ERROR_TOY_NOT_OWNED = "你沒有這個玩具"

-- ============================================
-- Minimap Button
-- ============================================

L.MINIMAP_TITLE = "Catfish - 釣魚助手"
L.MINIMAP_STATUS = "狀態:"
L.MINIMAP_STATUS_ACTIVE = "|cFF00FF00激活|r"
L.MINIMAP_STATUS_SLEEP = "|cFF808080休眠|r"
L.MINIMAP_FISHING_MODE = "釣魚模式:"
L.MINIMAP_MODE_DISABLED = "未啟用"
L.MINIMAP_MODE_ONEKEY = "一鍵模式 (%s)"
L.MINIMAP_MODE_DOUBLECLICK = "雙擊模式 (右鍵雙擊)"
L.MINIMAP_SESSION_CATCHES = "本次釣獲:"
L.MINIMAP_SESSION_TIME = "釣魚時間:"
L.MINIMAP_TIP_LEFT_CLICK = "|cFFFFFF00左鍵|r 打開設置"
L.MINIMAP_TIP_CTRL_LEFT = "|cFFFFFF00Ctrl+左鍵|r 統計HUD"
L.MINIMAP_TIP_RIGHT_CLICK = "|cFFFFFF00右鍵|r 切換激活/休眠"
L.MINIMAP_ACTIVATED = "已激活"
L.MINIMAP_SLEEP = "已休眠"

-- ============================================
-- Options Panel
-- ============================================

L.OPT_FISHING_MODE = "釣魚模式"
L.OPT_ONEKEY_DESC = "按下一個鍵完成釣魚動作"
L.OPT_KEYBIND_LABEL = "快捷鍵綁定"
L.OPT_KEYBIND_DESC = "點擊設置一鍵釣魚的快捷鍵"
L.OPT_DOUBLECLICK_DESC = "快速雙擊鼠標右鍵開始釣魚"
L.OPT_TOYS_SECTION = "玩具設置"
L.OPT_RAFT_DESC = "選擇游泳時要使用的釣魚筏（選擇'無'表示不使用釣魚筏）"
L.OPT_GIGANTIC_BOBBER_DESC = "每次拋竿前自動使用\"可重複使用的巨型魚漂\"玩具，放大魚漂便於觀察"
L.OPT_BOBBER_DESC = "選擇要使用的浮標玩具（選擇'無'表示不使用自定義浮標）"
L.OPT_STATS_SECTION = "統計設置"
L.OPT_SHOW_HUD_DESC = "在屏幕上顯示釣魚統計數據（持續時間、拋竿次數、魚獲等）"
L.OPT_ONLY_FISH_DESC = "開啟後只統計魚類物品，排除垃圾、裝備、圖紙等其他物品"
L.OPT_OTHER_SECTION = "其它設置"
L.OPT_SOUND_DESC = "激活時自動開啟背景聲音、關閉音樂、最大化音效音量，休眠時恢復原始設置"
L.OPT_AUTOLOOT_DESC = "每次拋竿時自動檢查並開啟自動拾取功能"
L.OPT_HIDE_MINIMAP_DESC = "隱藏小地圖上的插件按鈕"
L.OPT_DEBUG_DESC = "在聊天框輸出詳細的調試信息，用於排查問題"
L.OPT_TWW_SECTION = "至暗之夜"
L.OPT_TREASURE_SOUND_DESC = "釣魚時出現藏寶箱時播放提示音（至暗之夜版本功能）"
L.OPT_AMANI_WARD_DESC = "拋竿前自動使用阿曼尼垂釣者的結界（需要背包中有該物品，且身上沒有對應Buff）"
L.OPT_AUTO_BAIT_DESC = "拋竿前自動使用選中的魚餌（需要背包中有該物品，且身上沒有對應Buff）"
L.OPT_HIDE_MINIMAP = "隱藏小地圖按鈕"
L.OPT_DEBUG_MODE = "啟用調試模式"
L.OPT_TREASURE_SOUND = "寶箱出現提示音"
L.OPT_AMANI_WARD = "阿曼尼垂釣者的結界"
L.ENABLE_AUTOLOOT = "保持自動拾取"
L.OPT_KEYBIND_HINT = "按下按鍵設置，ESC取消，右鍵清除綁定"
L.OPT_NONE = "無"
L.OPT_SELECT_RAFT = "選擇釣魚筏"
L.OPT_SELECT_BOBBER = "選擇浮標"
L.OPT_AUTO_BAIT = "自動上餌"

-- ============================================
-- Bait Names
-- ============================================

L.BAIT_FORTUNE = "好運神靈魚誘餌"
L.BAIT_OCTOPUS = "不祥章魚誘餌"
L.BAIT_BLOODHUNTER = "鮮血獵手誘餌"

-- ============================================
-- Stats HUD
-- ============================================

L.HUD_TITLE = "|cFF00FF00Catfish 釣魚統計|r"
L.HUD_NO_LOOT = "暫無收穫"
L.HUD_DURATION = "耗時:"
L.HUD_CASTS = "拋竿:"
L.HUD_HARVEST = "收穫:"

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

L.ONEKEY_SET_IN_COMBAT = "戰鬥中無法設置快捷鍵"
L.ONEKEY_CLEARED = "快捷鍵已清除"
L.ONEKEY_SET_TO = "快捷鍵已設置為: %s"

-- ============================================
-- Treasure Chest
-- ============================================

L.TREASURE_DETECTED = "★ 檢測到藏寶箱！"

-- ============================================
-- Epic Catch
-- ============================================

L.EPIC_CATCH_FORMAT = "★ EPIC CATCH: %s%s at %s"

-- ============================================
-- Quality Names (for Statistics)
-- ============================================

L.QUALITY_POOR = "Poor"
L.QUALITY_COMMON = "Common"
L.QUALITY_UNCOMMON = "Uncommon"
L.QUALITY_RARE = "Rare"
L.QUALITY_EPIC = "Epic"
L.QUALITY_LEGENDARY = "Legendary"
L.QUALITY_ARTIFACT = "Artifact"
L.QUALITY_HEIRLOOM = "Heirloom"
L.QUALITY_UNKNOWN = "Unknown"

-- ============================================
-- Misc
-- ============================================

L.NOT_BOUND = NOT_BOUND or "Not Bound"
L.LIBEQOL_NOT_FOUND = "LibEQOL not found, using fallback settings"

return L
