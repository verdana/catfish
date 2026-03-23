-- Catfish - enUS.lua
-- English localization

local ADDON_NAME, Catfish = ...

local L = {}
Catfish.Locales.enUS = L

-- ============================================
-- General
-- ============================================

L.ADDON_NAME = "Catfish"
L.ADDON_TITLE = "Catfish - Fishing Assistant"
L.ADDON_DESCRIPTION = "Feature-rich fishing assistant with auto-equip, toys and statistics"

-- ============================================
-- Commands
-- ============================================

L.CMD_HELP = "help"
L.CMD_CONFIG = "config"
L.CMD_STATS = "stats"
L.CMD_RESET = "reset"
L.CMD_DEBUG = "debug"
L.CMD_TOYS = "toys"

L.HELP_HEADER = "Commands:"
L.HELP_CONFIG = "Open config panel"
L.HELP_STATS = "Show statistics"
L.HELP_TOYS = "Show toy status"
L.HELP_DEBUG = "Toggle debug mode"
L.HELP_RESET = "Reset all settings"

-- ============================================
-- States
-- ============================================

L.STATE_IDLE = "Idle"
L.STATE_CASTING = "Casting"
L.STATE_WAITING = "Waiting"
L.STATE_REELING = "Reeling"

-- ============================================
-- UI Labels
-- ============================================

L.TAB_FISHING = "Fishing"
L.TAB_EQUIPMENT = "Equipment"
L.TAB_TOYS = "Toys"
L.TAB_STATS = "Statistics"

L.ENABLE_ONEKEY = "Enable One-Key Fishing"
L.ENABLE_DOUBLECLICK = "Enable Double-Click Fishing"
L.ENABLE_AUTOEQUIP = "Auto-Equip Fishing Gear"
L.ENABLE_AUTOLURE = "Auto-Apply Lures"
L.ENABLE_AUTOTOYS = "Auto-Use Toys"
L.ENABLE_SOUNDS = "Sound Alerts"
L.ENABLE_SOUND_MANAGEMENT = "Manage Sound While Fishing"
L.SOUND_MANAGEMENT_DESC = "Enable background sound, mute music, and maximize SFX when fishing. Restore on sleep."
L.RESTORE_GEAR = "Restore Original Gear After Fishing"

L.SET_KEYBIND = "Set Keybind"
L.KEYBIND_SET = "Keybind Set: %s"
L.KEYBIND_CAPTURE = "Press a key to set keybind, or ESC to cancel"

L.RAFT_MODE = "Raft Mode:"
L.BOBBER_MODE = "Bobber Mode:"
L.MODE_DISABLED = "Disabled"
L.MODE_RANDOM = "Random"
L.MODE_SPECIFIC = "Specific"

-- ============================================
-- Statistics
-- ============================================

L.STATS_TITLE = "Statistics"
L.STATS_TOTAL_CATCHES = "Total Catches"
L.STATS_TOTAL_TIME = "Total Fishing Time"
L.STATS_CATCHES_PER_HOUR = "Catches per Hour"
L.STATS_CURRENT_SESSION = "Current Session"
L.STATS_UNIQUE_ITEMS = "Unique Items Caught"
L.STATS_TOP_ITEMS = "Top Caught Items"
L.STATS_TOP_ZONES = "Top Fishing Zones"
L.STATS_RARE_CATCHES = "Rare Catches"
L.STATS_NO_RARES = "No rare catches recorded yet!"

-- Stats HUD
L.STATS_HUD_TITLE = "Fishing Stats"
L.STATS_DURATION = "Duration"
L.STATS_CASTS = "Casts"
L.STATS_TOTAL_LOOT = "Total Loot"
L.STATS_ITEMS_BREAKDOWN = "Loot Breakdown"
L.STATS_NO_LOOT = "No loot yet"
L.SHOW_STATS_HUD = "Show Stats HUD"
L.SHOW_STATS_HUD_DESC = "Display fishing statistics on screen (duration, casts, loot, etc.)"
L.STATS_ONLY_FISH = "Only Count Fish"
L.STATS_ONLY_FISH_DESC = "When enabled, only fish items are counted. Excludes junk, gear, recipes, etc."

L.RESET_STATS = "Reset Statistics"
L.RESET_SESSION = "Reset Session"
L.STATS_RESET = "Statistics reset"
L.SESSION_RESET = "Session statistics reset"

-- ============================================
-- Equipment
-- ============================================

L.EQUIP_TITLE = "Equipment"
L.EQUIP_AVAILABLE_POLES = "Available Fishing Poles:"
L.EQUIP_AVAILABLE_HATS = "Available Fishing Hats:"
L.EQUIP_CURRENT_POLE = "Current Pole: %s"
L.EQUIP_NO_POLE = "No fishing pole equipped"
L.EQUIP_BEST_POLE = "Best Available: %s (+%d fishing)"

-- ============================================
-- Toys
-- ============================================

L.TOYS_TITLE = "Toys"
L.TOYS_STATUS = "Toy Status"
L.TOYS_OWNED = "Owned: %d"
L.TOYS_READY = "Ready"
L.TOYS_COOLDOWN = "On cooldown: %ds"
L.TOYS_NONE = "None"

L.TOYS_RAFTS = "Rafts"
L.TOYS_BOBBERS = "Bobbers"
L.TOYS_EXTRA = "Extra Toys"

L.TOYS_SELECT_RAFT = "Select Raft"
L.TOYS_SELECT_BOBBER = "Select Bobber"

-- ============================================
-- Messages
-- ============================================

L.MSG_ENABLED = "enabled"
L.MSG_DISABLED = "disabled"
L.MSG_DEBUG_MODE = "Debug mode: %s"
L.MSG_DATABASE_RESET = "Database reset."
L.MSG_CANNOT_EQUIP_COMBAT = "Cannot equip in combat"
L.MSG_CANNOT_CAST = "Cannot cast fishing"
L.MSG_ALREADY_FISHING = "Already fishing"
L.MSG_NOT_FISHING = "Not currently fishing"

L.MSG_RARE_CATCH = "★ Rare catch: %s at %s"
L.MSG_EPIC_CATCH = "★ EPIC CATCH: %s at %s"

L.MSG_FISHING_STARTED = "Fishing session started"
L.MSG_FISHING_STOPPED = "Fishing session ended"
L.MSG_LURE_APPLIED = "Lure applied: %s"
L.MSG_LURE_EXPIRED = "Lure expired"
L.MSG_NO_LURES = "No lures available"

L.MSG_KEYBIND_IN_COMBAT = "Cannot change keybind in combat"
L.MSG_KEYBIND_CLEARED = "Keybind cleared"

-- ============================================
-- Tooltips
-- ============================================

L.TIP_LEFT_CLICK = "Left-Click: Open Config"
L.TIP_RIGHT_CLICK = "Right-Click: Quick Menu"
L.TIP_DRAG_MOVE = "Drag: Move Button"

L.TIP_FISHING_STATUS = "Status: %s"
L.TIP_SESSION_CATCHES = "Session Catches: %d"
L.TIP_SESSION_TIME = "Session Time: %s"

-- ============================================
-- Time Format
-- ============================================

L.TIME_FORMAT_HM = "%dh %dm"
L.TIME_FORMAT_M = "%dm"
L.TIME_FORMAT_S = "%ds"

-- ============================================
-- Quality Names
-- ============================================

L.QUALITY_POOR = "Poor"
L.QUALITY_COMMON = "Common"
L.QUALITY_UNCOMMON = "Uncommon"
L.QUALITY_RARE = "Rare"
L.QUALITY_EPIC = "Epic"
L.QUALITY_LEGENDARY = "Legendary"
L.QUALITY_ARTIFACT = "Artifact"
L.QUALITY_HEIRLOOM = "Heirloom"

-- ============================================
-- Errors
-- ============================================

L.ERROR_UNKNOWN_COMMAND = "Unknown command. Use /catfish help for available commands."
L.ERROR_NO_FISHING_SKILL = "You don't have fishing skill"
L.ERROR_NOT_EQUIPPED = "No fishing pole equipped"
L.ERROR_ALREADY_EQUIPPED = "Already equipped: %s"
L.ERROR_ITEM_NOT_FOUND = "Item not found: %s"
L.ERROR_TOY_NOT_OWNED = "You don't own this toy"

return L