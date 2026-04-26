# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 在此代码库中工作时提供指导。

## 工作目录

代码存储在 WSL 本地目录：`~/workspace/catfish`

**同步到 Windows：** 完成开发后，说"同步"或"sync"将代码同步到 Windows WoW 插件目录。

## 项目概述

Catfish 是一个魔兽世界插件，提供钓鱼辅助功能，包括一键钓鱼、玩具管理和统计数据追踪。使用 Lua 编写，适用于 WoW 正式服（界面版本 120001）。

## 命令

**游戏内斜杠命令：**
- `/catfish` 或 `/cf` - 打开设置面板
- `/cf sleep` - 切换休眠/激活模式
- `/cf stats` - 显示统计窗口
- `/cf toys` - 显示玩具状态
- `/cf debug` - 切换调试模式
- `/cf log` - 显示调试日志窗口
- `/cf reset` - 重置所有设置
- `/cf help` - 显示帮助

**调试模式：** 通过 `/cf debug` 启用，可查看详细的控制台输出。

## 架构

```
Catfish/
├── init.lua              # 入口点，命名空间设置，数据库初始化，斜杠命令
├── Core/
│   ├── Core.lua          # 状态机 (IDLE → CASTING → WAITING → REELING)
│   ├── Events.lua        # 事件注册和路由
│   ├── API.lua           # WoW API 封装
│   └── StatusPoller.lua  # 游泳状态变化检测
├── Modules/
│   ├── OneKey.lua        # 一键钓鱼，通过 SecureActionButton + OverrideBinding 实现
│   ├── ItemManager.lua   # 统一物品使用条件检查
│   ├── Toys.lua          # 玩具扫描和使用
│   ├── Statistics.lua    # 钓鱼记录和统计
│   ├── Equipment.lua     # 钓鱼装备扫描
│   ├── LureManager.lua   # 鱼饵数据和扫描
│   ├── SoundManager.lua  # 音效设置管理
│   ├── DoubleClick.lua   # 双击钓鱼模式
│   └── TWWItems.lua      # 地心之战物品管理
├── UI/
│   ├── Options.lua       # 设置面板 (LibEQOL)
│   ├── MinimapButton.lua # 小地图按钮
│   ├── StatsHUD.lua      # 屏幕统计显示
│   ├── StatsWindow.lua   # 统计窗口
│   ├── DebugLog.lua      # 调试日志查看器
│   └── ToySelector.lua   # 玩具选择界面
├── Data/
│   ├── Constants.lua     # 全局常量
│   ├── FishingPoles.lua  # 鱼竿数据
│   ├── FishingHats.lua   # 钓鱼帽数据
│   ├── FishingItems.lua  # 其他钓鱼物品
│   └── Toys.lua          # 筏子和浮漂玩具数据
└── Locales/              # 本地化 (enUS, zhCN)
```

**核心架构模式：**

1. **状态机** (`Core.lua`)：钓鱼流程通过状态转换管理。其他模块通过 `OnStateChanged` 回调观察状态变化。

2. **事件系统** (`Events.lua`)：中央事件框架注册所有 WoW 事件。事件被路由到模块处理器。

3. **API 层** (`API.lua`)：所有 WoW API 调用都在此封装，以确保一致性和战斗安全检查。

4. **安全按钮**：WoW 在战斗中限制某些操作（施法、使用物品）。插件使用 `SecureActionButton` 配合 `SetOverrideBinding` 实现一键钓鱼。这些按钮需要硬件事件（按键）触发，在战斗中无法通过程序调用。

## WoW 特定限制

**战斗锁定：** 在战斗中，你不能：
- 调用 `SetOverrideBinding` 或 `ClearOverrideBindings`
- 通过 API 使用玩具/物品
- 装备物品

在执行这些操作前务必检查 `InCombatLockdown()`。

**被污染字符串：** 在副本中，来自 WoW 事件的某些字符串值是"被污染的"，比较时会抛出错误。在事件处理器中进行字符串比较时使用 `pcall`：
```lua
local ok, result = pcall(function()
    return playerName == UnitName("player")
end)
if ok and result then ... end
```

**钓鱼法术 ID：** 钓鱼存在多个法术 ID（见 `API.lua:FISHING_SPELL_IDS`）。检查时始终使用 `API:IsFishingSpell(spellID)`。

## 保存变量

- `CatfishDB` - 账号通用设置 (SavedVariables)
- `CatfishCharDB` - 角色专属设置 (SavedVariablesPerCharacter)

结构定义在 `init.lua:DEFAULT_DB` 中。

## 库

- **LibStub** - 插件库加载器
- **LibEQOL** - 设置面板 UI 库

## 本地化

中文 (zhCN) 是主要语言。UI 字符串定义在 `Locales/zhCN.lua` 中。添加新字符串时需同时更新两个本地化文件。
