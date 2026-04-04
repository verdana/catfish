# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Catfish is a World of Warcraft addon that provides fishing assistance with features like one-key fishing, toy management, and statistics tracking. Written in Lua for WoW Retail (Interface 120001).

## Commands

**In-game slash commands:**
- `/catfish` or `/cf` - Open config panel
- `/cf sleep` - Toggle sleep/active mode
- `/cf stats` - Show statistics window
- `/cf toys` - Show toy status
- `/cf debug` - Toggle debug mode
- `/cf log` - Show debug log window
- `/cf reset` - Reset all settings
- `/cf help` - Show help

**Debug mode:** Enable via `/cf debug` to see detailed console output.

## Architecture

```
Catfish/
├── init.lua              # Entry point, namespace setup, DB init, slash commands
├── Core/
│   ├── Core.lua          # State machine (IDLE → CASTING → WAITING → REELING)
│   ├── Events.lua        # Event registration and routing
│   ├── API.lua           # WoW API encapsulation
│   └── StatusPoller.lua  # Swimming state change detection
├── Modules/
│   ├── OneKey.lua        # One-key fishing via SecureActionButton + OverrideBinding
│   ├── ItemManager.lua   # Unified item usage condition checking
│   ├── Toys.lua          # Toy scanning and usage
│   ├── Statistics.lua    # Catch recording and stats
│   ├── Equipment.lua     # Fishing gear scanning
│   ├── LureManager.lua   # Lure data and scanning
│   ├── SoundManager.lua  # Sound settings management
│   ├── DoubleClick.lua   # Double-click fishing mode
│   └── TWWItems.lua      # The War Within items management
├── UI/
│   ├── Options.lua       # Settings panel (LibEQOL)
│   ├── MinimapButton.lua # Minimap button
│   ├── StatsHUD.lua      # On-screen stats display
│   ├── StatsWindow.lua   # Statistics window
│   ├── DebugLog.lua      # Debug log viewer
│   └── ToySelector.lua   # Toy selection UI
├── Data/
│   ├── Constants.lua     # Global constants
│   ├── FishingPoles.lua  # Fishing pole data
│   ├── FishingHats.lua   # Fishing hat data
│   ├── FishingItems.lua  # Other fishing items
│   └── Toys.lua          # Raft and bobber toy data
└── Locales/              # Localization (enUS, zhCN)
```

**Key architecture patterns:**

1. **State Machine** (`Core.lua`): Fishing flow managed by state transitions. Other modules observe state changes via `OnStateChanged` callbacks.

2. **Event System** (`Events.lua`): Central event frame registers all WoW events. Events are routed to module handlers.

3. **API Layer** (`API.lua`): All WoW API calls are wrapped here for consistency and combat safety checks.

4. **Secure Buttons**: WoW restricts certain actions (casting, using items) during combat. The addon uses `SecureActionButton` with `SetOverrideBinding` for one-key fishing. These buttons require hardware events (key presses) and cannot be triggered programmatically during combat.

## WoW-Specific Constraints

**Combat Lockdown:** During combat, you cannot:
- Call `SetOverrideBinding` or `ClearOverrideBindings`
- Use toys/items via API
- Equip items

Always check `InCombatLockdown()` before these operations.

**Tainted Strings:** In instances, some string values from WoW events are "tainted" and will throw errors when compared. Use `pcall` for string comparisons in event handlers:
```lua
local ok, result = pcall(function()
    return playerName == UnitName("player")
end)
if ok and result then ... end
```

**Fishing Spell IDs:** Multiple spell IDs exist for fishing (see `API.lua:FISHING_SPELL_IDS`). Always use `API:IsFishingSpell(spellID)` for checking.

## Saved Variables

- `CatfishDB` - Account-wide settings (SavedVariables)
- `CatfishCharDB` - Per-character settings (SavedVariablesPerCharacter)

Structure defined in `init.lua:DEFAULT_DB`.

## Libraries

- **LibStub** - Addon library loader
- **LibEQOL** - Settings panel UI library

## Localization

Chinese (zhCN) is the primary language. UI strings are defined in `Locales/zhCN.lua`. Add new strings to both locale files.