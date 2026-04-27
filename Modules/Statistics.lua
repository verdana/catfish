-- Catfish - Statistics.lua
-- Statistics recording module

local ADDON_NAME, Catfish = ...

local Statistics = {}
Catfish.Modules.Statistics = Statistics

-- Session statistics
Statistics.sessionCatches   = 0
Statistics.sessionStartTime = 0
Statistics.lastCatchTime    = 0
Statistics.sessionCasts     = 0  -- 抛竿次数
Statistics.sessionItems     = {} -- 会话物品统计

-- Loot tracking
Statistics.pendingLoot      = {} -- 待拾取物品
Statistics.currentLootItems = {} -- 当前拾取物品

-- Flag to track if current loot is from fishing
-- Set when entering WAITING state, cleared after loot is processed or timeout
Statistics.isFishingLoot = false
Statistics.fishingLootTimeout = nil -- 拾取超时时间

-- Quality name cache (populated on first use)
local QUALITY_NAMES

-- ============================================
-- Catch Recording
-- ============================================

function Statistics:RecordCatch(itemID)
    if not itemID then return end

    local itemName = Catfish.API:GetItemName(itemID)
    local itemLink = select(2, GetItemInfo(itemID))
    local quality = select(3, GetItemInfo(itemID))
    local zoneID = Catfish.API:GetZoneID()
    local zoneName = Catfish.API:GetZoneName()
    local subZone = Catfish.API:GetCurrentSubZone()
    local timestamp = time()

    -- Update total catches
    Catfish.db.stats.total.catches = Catfish.db.stats.total.catches + 1
    self.sessionCatches = self.sessionCatches + 1
    self.lastCatchTime = GetTime()

    -- Update session items
    self.sessionItems = self.sessionItems or {}
    self.sessionItems[itemID] = (self.sessionItems[itemID] or 0) + 1

    -- Update item statistics
    if not Catfish.db.stats.items[itemID] then
        Catfish.db.stats.items[itemID] = {
            count = 0,
            firstCaught = timestamp,
            lastCaught = timestamp,
            name = itemName,
            link = itemLink,
            quality = quality,
        }
    end

    Catfish.db.stats.items[itemID].count = Catfish.db.stats.items[itemID].count + 1
    Catfish.db.stats.items[itemID].lastCaught = timestamp

    -- Update zone statistics
    if not Catfish.db.stats.zones[zoneID] then
        Catfish.db.stats.zones[zoneID] = {
            name = zoneName,
            catches = 0,
            items = {},
        }
    end

    Catfish.db.stats.zones[zoneID].catches = Catfish.db.stats.zones[zoneID].catches + 1

    if not Catfish.db.stats.zones[zoneID].items[itemID] then
        Catfish.db.stats.zones[zoneID].items[itemID] = 0
    end
    Catfish.db.stats.zones[zoneID].items[itemID] =
        Catfish.db.stats.zones[zoneID].items[itemID] + 1
end

-- ============================================
-- Loot Handling
-- ============================================

function Statistics:OnLootReady()
    -- Only track fishing loot (flag is set in Core:EnterWaiting)
    if not self.isFishingLoot then
        return
    end

    -- Track what we're about to loot
    self.currentLootItems = {}

    for slot = 1, GetNumLootItems() do
        local lootType = GetLootSlotType(slot)
        local itemLink = GetLootSlotLink(slot)
        -- lootType 1 = item (LOOT_SLOT_ITEM)
        if lootType == 1 and itemLink then
            local itemID = self:ExtractItemID(itemLink)
            if itemID then
                local quantity = select(3, GetLootSlotInfo(slot)) or 1
                self.currentLootItems[itemID] = (self.currentLootItems[itemID] or 0) + quantity
            end
        end
    end
end

function Statistics:OnLootClosed()
    -- Only record if this was fishing loot
    if not self.isFishingLoot then
        self.currentLootItems = {}
        return
    end

    -- Record all looted items
    local itemCount = 0
    for itemID, quantity in pairs(self.currentLootItems) do
        -- Check quality once before recording
        local quality = select(3, GetItemInfo(itemID))

        -- Record the catch with quantity (for stats)
        for i = 1, quantity do
            self:RecordCatch(itemID)
        end
        itemCount = itemCount + 1

        -- Announce rare catch only once per item type
        if quality and quality >= 3 then
            self:AnnounceRareCatch(itemID, quantity)
        end
    end

    -- Summary debug log (once per loot)
    if itemCount > 0 then
        Catfish:Debug("Recorded catch:", itemCount, "item type(s), Total:", Catfish.db.stats.total.catches)
    end

    -- Clear loot tracking
    self.currentLootItems = {}
    self.isFishingLoot = false
end

-- Called when entering WAITING state (bobber in water)
function Statistics:OnFishingStarted()
    -- Cancel any existing timeout
    if self.fishingLootTimeout then
        self.fishingLootTimeout:Cancel()
    end

    self.isFishingLoot = true

    -- Set a timeout to clear the flag after 30 seconds (safety)
    -- This handles cases where fishing is cancelled without proper cleanup
    self.fishingLootTimeout = C_Timer.NewTimer(30, function()
        if self.isFishingLoot then
            self.isFishingLoot = false
            self.fishingLootTimeout = nil
        end
    end)
end

-- Called when entering IDLE state (fishing ended or cancelled)
function Statistics:OnFishingEnded()
    -- Cancel any existing timeout
    if self.fishingLootTimeout then
        self.fishingLootTimeout:Cancel()
        self.fishingLootTimeout = nil
    end

    self.isFishingLoot = false
end

-- Called when player reels in (enters REELING state) - backup
function Statistics:OnFishingReelStart()
    -- Cancel any existing timeout
    if self.fishingLootTimeout then
        self.fishingLootTimeout:Cancel()
    end

    self.isFishingLoot = true
end

function Statistics:AnnounceRareCatch(itemID, quantity)
    local itemName = Catfish.API:GetItemName(itemID)
    local quality = select(3, GetItemInfo(itemID))
    local subZone = Catfish.API:GetCurrentSubZone()
    local zoneID = Catfish.API:GetZoneID()
    local timestamp = time()

    -- Record to rare catches
    if not Catfish.db.stats.rareCatches[itemID] then
        Catfish.db.stats.rareCatches[itemID] = {}
    end

    table.insert(Catfish.db.stats.rareCatches[itemID], {
        timestamp = timestamp,
        zoneID = zoneID,
        subZone = subZone,
    })

    -- Announce once with quantity info
    local quantityText = quantity > 1 and (" x" .. quantity) or ""
    if quality >= 4 then
        Catfish:Print(string.format(Catfish.L.EPIC_CATCH_FORMAT, itemName, quantityText, subZone))
        PlaySound(8959) -- RAID_WARNING
    end
end

function Statistics:ExtractItemID(link)
    if not link then return nil end
    local itemID = link:match("item:(%d+)")
    return itemID and tonumber(itemID)
end

-- ============================================
-- Statistics Queries
-- ============================================

function Statistics:GetTotalCatches()
    return Catfish.db.stats.total.catches
end

function Statistics:GetTotalTime()
    return Catfish.db.stats.total.time
end

function Statistics:GetSessionCatches()
    return self.sessionCatches
end

function Statistics:GetSessionTime()
    if Catfish.Core.sessionActive then
        return GetTime() - Catfish.Core.sessionStartTime
    end
    return 0
end

function Statistics:GetSessionItems()
    return self.sessionItems
end

function Statistics:RecordCast()
    self.sessionCasts = self.sessionCasts + 1
end

function Statistics:GetItemStats(itemID)
    return Catfish.db.stats.items[itemID]
end

function Statistics:GetZoneStats(zoneID)
    return Catfish.db.stats.zones[zoneID]
end

function Statistics:GetRareCatches()
    return Catfish.db.stats.rareCatches
end

function Statistics:GetTopItems(limit)
    local items = {}

    for itemID, data in pairs(Catfish.db.stats.items) do
        table.insert(items, {
            itemID = itemID,
            count = data.count,
            name = data.name,
            quality = data.quality,
        })
    end

    table.sort(items, function(a, b)
        return a.count > b.count
    end)

    if limit then
        local result = {}
        for i = 1, math.min(limit, #items) do
            table.insert(result, items[i])
        end
        return result
    end

    return items
end

function Statistics:GetTopZones(limit)
    local zones = {}

    for zoneID, data in pairs(Catfish.db.stats.zones) do
        table.insert(zones, {
            zoneID = zoneID,
            name = data.name,
            catches = data.catches,
        })
    end

    table.sort(zones, function(a, b)
        return a.catches > b.catches
    end)

    if limit then
        local result = {}
        for i = 1, math.min(limit, #zones) do
            table.insert(result, zones[i])
        end
        return result
    end

    return zones
end

function Statistics:GetCatchesPerHour()
    local totalCatches = self:GetTotalCatches()
    local totalTime = self:GetTotalTime()

    if totalTime > 0 then
        return (totalCatches / totalTime) * 3600
    end

    return 0
end

-- ============================================
-- Reset Functions
-- ============================================

function Statistics:ResetAll()
    Catfish.db.stats = {
        total = {
            catches = 0,
            time = 0,
        },
        items = {},
        zones = {},
        rareCatches = {},
    }

    self.sessionCatches = 0
    self.sessionStartTime = 0

    Catfish:Print("Statistics reset")
end

function Statistics:ResetSession()
    self.sessionCatches = 0
    self.sessionStartTime = 0
    self.sessionCasts = 0
    self.sessionItems = {}
end

-- ============================================
-- Helper Functions
-- ============================================

function Statistics:GetQualityName(quality)
    if not QUALITY_NAMES then
        QUALITY_NAMES = {
            [0] = Catfish.L.QUALITY_POOR,
            [1] = Catfish.L.QUALITY_COMMON,
            [2] = Catfish.L.QUALITY_UNCOMMON,
            [3] = Catfish.L.QUALITY_RARE,
            [4] = Catfish.L.QUALITY_EPIC,
            [5] = Catfish.L.QUALITY_LEGENDARY,
            [6] = Catfish.L.QUALITY_ARTIFACT,
            [7] = Catfish.L.QUALITY_HEIRLOOM,
        }
    end
    return QUALITY_NAMES[quality] or Catfish.L.QUALITY_UNKNOWN
end

-- ============================================
-- Treasure Chest Detection
-- ============================================

function Statistics:OnTreasureChestSpawned()
    -- 检查是否启用了宝箱提示音
    if not Catfish.db.treasureChestSound then
        return
    end

    Catfish:Print(Catfish.L.TREASURE_DETECTED)
    PlaySound(8960) -- IG_QUEST_COMPLETE
end

function Statistics:FormatTime(seconds)
    if not seconds or seconds <= 0 then
        return "0m"
    end

    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)

    if hours > 0 then
        return string.format("%dh %dm", hours, minutes)
    else
        return string.format("%dm", minutes)
    end
end

-- ============================================
-- Initialization
-- ============================================

function Statistics:Init()
    -- Initialize session
    self.sessionCatches = 0
    self.sessionStartTime = 0
    self.lastCatchTime = 0
    self.sessionCasts = 0
    self.sessionItems = {}
    self.isFishingLoot = false
    self.fishingLootTimeout = nil

    Catfish:Debug("Statistics module initialized")
end
