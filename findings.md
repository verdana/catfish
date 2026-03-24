# Findings & Decisions

## Requirements
1. 统计数据直接以文本形式显示在游戏界面上（HUD 模式，不需要打开独立窗口）
2. 统计维度：
   - 标题
   - 钓鱼持续时间
   - 抛竿次数
   - 钓到的所有东西数量（包括垃圾、装备、图纸等物品）
3. 统计每种鱼获的数量及占比
4. 设置界面添加"统计选项"（Checkbox），默认开启
5. 设置界面添加"只统计鱼类"（Checkbox），默认开启，开启后只有鱼才统计，其它物品排除

## Research Findings

### 现有 Statistics.lua 模块
- 已有 `sessionCatches` 和 `sessionStartTime` 字段
- `RecordCatch(itemID)` 方法记录每次钓获
- 数据存储在 `Catfish.db.stats.items[itemID]` 中
- 已有 `FormatTime(seconds)` 方法格式化时间

### 判断物品是否为鱼类

WoW 没有直接的"鱼类"物品类型，但可以通过 `itemSubType` 判断：

**推荐方案**：使用 `itemSubType == "Fish"` 作为判断条件。

```lua
local function IsFishItem(itemID)
    local _, _, _, _, _, itemType, itemSubType = GetItemInfo(itemID)
    return itemSubType == "Fish"
end
```

这种方法覆盖：
- 可食用鱼（Consumable 子类型 "Fish"）
- 原材料鱼（Trade Goods 子类型 "Fish"）

### WoW 物品类型 API
```lua
-- 获取物品信息
local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice = GetItemInfo(itemID)

-- itemType 可能的值包括：
-- "Consumable" - 消耗品
-- "Quest" - 任务物品
-- "Trade Goods" - 贸易品
-- "Junk" - 垃圾
-- "Weapon" - 武器
-- "Armor" - 护甲
-- 等等
```

## Technical Decisions
| Decision | Rationale |
|----------|-----------|
| 使用 FontString 显示 HUD | 轻量级，适合文本显示 |
| 框架可拖拽 | 允许用户自定义位置 |
| 实时更新 vs 定时更新 | 待定，考虑性能 |

## Issues Encountered
| Issue | Resolution |
|-------|------------|

## Resources
- WoW API: GetItemInfo - https://wowpedia.fandom.com/wiki/API_GetItemInfo