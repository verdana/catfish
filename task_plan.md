# Task Plan: 至暗之夜钓鱼增强功能

## Goal
在"至暗之夜"设置分类下添加两个自动使用物品的功能：
1. 阿曼尼垂钓者的结界 - 自动使用物品
2. 自动上饵 - 下拉菜单选择鱼饵类型

## Current Phase
Phase 4 - Complete

## Phases

### Phase 1: 需求分析与数据收集
- [x] 分析现有 LureManager.lua 鱼饵管理模块
- [x] 分析现有 API.lua 提供的工具方法
- [x] 分析 Core.lua 钓鱼流程
- [x] 确认鱼饵的 Buff SpellID
- **Status:** complete

### Phase 2: 数据库与设置选项
- [x] 在 init.lua 添加默认设置值
- [x] 在 Options.lua 添加设置选项
  - 阿曼尼垂钓者的结界开关
  - 鱼饵下拉菜单
- **Status:** complete

### Phase 3: 功能实现
- [x] 创建 TWWItems.lua 模块处理至暗之夜物品
- [x] 实现背包扫描和 Buff 检查逻辑
- [x] 集成到钓鱼流程中
- [x] 迁移到 OneKey.lua 按键绑定系统（因 WoW 安全限制）
- **Status:** complete

### Phase 4: 测试验证
- [x] 测试阿曼尼垂钓者的结界功能
- [x] 测试鱼饵自动使用功能
- [x] 验证 Buff 检查正确
- **Status:** complete

## Key Questions
1. ~~鱼饵的 Buff SpellID 是什么？~~ 已确认
   - 好运神灵鱼诱饵 (ItemID: 241145) - SpellID: 1237964
   - 不祥章鱼诱饵 (ItemID: 241149) - SpellID: 1237965
2. ~~这些物品是普通物品还是玩具？~~ 普通消耗品，需要扫描背包

## Decisions Made
| Decision | Rationale |
|----------|-----------|
| 创建独立 TWWItems 模块 | 至暗之夜特有功能，与现有 LureManager 分离更清晰 |
| 使用 API:UnitHasBuff 检查 Buff | 已有成熟实现，支持新旧 API |
| 迁移到 OneKey.lua 按键绑定系统 | WoW 安全限制：事件处理程序中无法使用物品，需要硬件事件 |

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
| "该功能只对暴雪的UI开放" | 1 | 在事件处理程序中调用 UseContainerItem 失败，迁移到按键绑定宏系统 |

## Files Modified
- `init.lua` - 添加默认设置 (完成)
- `UI/Options.lua` - 添加设置选项 (完成)
- `Modules/TWWItems.lua` - 新建模块 (保留用于检查函数)
- `Modules/OneKey.lua` - 添加 TWW 物品宏生成 (完成)
- `Core/Core.lua` - 移除无效调用 (完成)
- `Catfish.toc` - 添加新模块 (完成)

## Notes
- 物品信息：
  - 阿曼尼垂钓者的结界: ItemID 241148, Buff SpellID 1237919
  - 好运神灵鱼诱饵: ItemID 241145, Buff SpellID 1237964
  - 不祥章鱼诱饵: ItemID 241149, Buff SpellID 1237965
- 实现方式：使用宏 `/use 物品名\n/cast 钓鱼` 通过按键绑定触发