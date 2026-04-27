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

-- ============================================
-- Minimap Button
-- ============================================

L.MINIMAP_TITLE = "Catfish - Fishing Assistant"
L.MINIMAP_STATUS = "Status:"
L.MINIMAP_STATUS_ACTIVE = "|cFF00FF00Active|r"
L.MINIMAP_STATUS_SLEEP = "|cFF808080Sleep|r"
L.MINIMAP_FISHING_MODE = "Fishing Mode:"
L.MINIMAP_MODE_DISABLED = "Not enabled"
L.MINIMAP_MODE_ONEKEY = "One-Key Mode (%s)"
L.MINIMAP_MODE_DOUBLECLICK = "Double-Click Mode (Right Click)"
L.MINIMAP_SESSION_CATCHES = "Session Catches:"
L.MINIMAP_SESSION_TIME = "Session Time:"
L.MINIMAP_TIP_LEFT_CLICK = "|cFFFFFF00Left-Click|r Open Settings"
L.MINIMAP_TIP_CTRL_LEFT = "|cFFFFFF00Ctrl+Left-Click|r Stats HUD"
L.MINIMAP_TIP_RIGHT_CLICK = "|cFFFFFF00Right-Click|r Toggle Active/Sleep"
L.MINIMAP_ACTIVATED = "Activated"
L.MINIMAP_SLEEP = "Sleeping"

-- ============================================
-- Options Panel
-- ============================================

L.OPT_FISHING_MODE = "Fishing Mode"
L.OPT_ONEKEY_DESC = "Press one key to complete fishing actions"
L.OPT_KEYBIND_LABEL = "Keybind"
L.OPT_KEYBIND_DESC = "Click to set the one-key fishing keybind"
L.OPT_DOUBLECLICK_DESC = "Double-click right mouse button to start fishing"
L.OPT_TOYS_SECTION = "Toy Settings"
L.OPT_RAFT_DESC = "Select a fishing raft to use while swimming (select 'None' to disable)"
L.OPT_GIGANTIC_BOBBER_DESC = "Automatically use 'Gigantic Bobber' toy before each cast to enlarge the bobber"
L.OPT_BOBBER_DESC = "Select a bobber toy to use (select 'None' to use default bobber)"
L.OPT_STATS_SECTION = "Statistics Settings"
L.OPT_SHOW_HUD_DESC = "Display fishing statistics on screen (duration, casts, loot, etc.)"
L.OPT_ONLY_FISH_DESC = "When enabled, only fish items are counted. Excludes junk, gear, recipes, etc."
L.OPT_OTHER_SECTION = "Other Settings"
L.OPT_SOUND_DESC = "When active, enable background sound, mute music, and maximize SFX volume. Restore on sleep."
L.OPT_AUTOLOOT_DESC = "Automatically check and enable auto-loot on each cast"
L.OPT_HIDE_MINIMAP_DESC = "Hide the minimap button"
L.OPT_DEBUG_DESC = "Output detailed debug info to chat frame for troubleshooting"
L.OPT_TWW_SECTION = "The War Within"
L.OPT_TREASURE_SOUND_DESC = "Play a sound when a treasure chest appears while fishing"
L.OPT_AMANI_WARD_DESC = "Automatically use Amani Fisher's Ward before casting (requires item in bags, no buff active)"
L.OPT_AUTO_BAIT_DESC = "Automatically use selected bait before casting (requires item in bags, no buff active)"
L.OPT_HIDE_MINIMAP = "Hide Minimap Button"
L.OPT_DEBUG_MODE = "Enable Debug Mode"
L.OPT_TREASURE_SOUND = "Treasure Chest Sound"
L.OPT_AMANI_WARD = "Amani Fisher's Ward"
L.ENABLE_AUTOLOOT = "Keep Auto Loot"
L.OPT_KEYBIND_HINT = "Press a key to set, ESC to cancel, right-click to clear"
L.OPT_NONE = "None"
L.OPT_SELECT_RAFT = "Select Raft"
L.OPT_SELECT_BOBBER = "Select Bobber"
L.OPT_AUTO_BAIT = "Auto Bait"

-- ============================================
-- Bait Names
-- ============================================

L.BAIT_FORTUNE = "Fortune Favour Fish Lure"
L.BAIT_OCTOPUS = "Ominous Octopus Lure"
L.BAIT_BLOODHUNTER = "Bloodhunter Lure"

-- ============================================
-- Stats HUD
-- ============================================

L.HUD_TITLE = "|cFF00FF00Catfish Fishing Stats|r"
L.HUD_NO_LOOT = "No loot yet"
L.HUD_DURATION = "Duration:"
L.HUD_CASTS = "Casts:"
L.HUD_HARVEST = "Harvest:"

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

L.ONEKEY_SET_IN_COMBAT = "Cannot set keybind in combat"
L.ONEKEY_CLEARED = "Keybind cleared"
L.ONEKEY_SET_TO = "Keybind set to: %s"

-- ============================================
-- Treasure Chest
-- ============================================

L.TREASURE_DETECTED = "★ Treasure chest detected!"

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