-- Catfish - Statistics.lua
-- Statistics recording module

local ADDON_NAME, Catfish = ...

local Statistics = {}
Catfish.Modules.Statistics = Statistics

-- Session statistics
Statistics.sessionCatches = 0
Statistics.sessionStartTime = 0
Statistics.lastCatchTime = 0

-- Loot tracking
Statistics.pendingLoot = {}
Statistics.currentLootItems = {}

-- ============================================
-- Catch Recording
-- ============================================

function Statistics:RecordCatch(itemID)
    if not itemID then return end

    local itemName = Catfish.API:GetItemName(itemID)
    local itemLink = Catfish.API:GetItemLink(itemID)
    local quality = select(3, GetItemInfo(itemID))
    local zoneID = Catfish.API:GetZoneID()
    local zoneName = Catfish.API:GetZoneName()
    local subZone = Catfish.API:GetCurrentSubZone()
    local timestamp = time()

    -- Update total catches
    Catfish.db.stats.total.catches = Catfish.db.stats.total.catches + 1
    self.sessionCatches = self.sessionCatches + 1
    self.lastCatchTime = GetTime()

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

    -- Check for rare items (quality >= 4 = epic, 3 = rare)
    if quality and quality >= 3 then
        self:RecordRareCatch(itemID, timestamp, zoneID, subZone)
    end

    Catfish:Debug("Recorded catch:", itemName, "Total:", Catfish.db.stats.total.catches)
end

function Statistics:RecordRareCatch(itemID, timestamp, zoneID, subZone)
    if not Catfish.db.stats.rareCatches[itemID] then
        Catfish.db.stats.rareCatches[itemID] = {}
    end

    local itemName = Catfish.API:GetItemName(itemID)
    local quality = select(3, GetItemInfo(itemID))
    local qualityName = self:GetQualityName(quality)

    table.insert(Catfish.db.stats.rareCatches[itemID], {
        timestamp = timestamp,
        zoneID = zoneID,
        subZone = subZone,
    })

    -- Announce rare catch
    if quality >= 4 then
        Catfish:Print("★ EPIC CATCH:", itemName, "at", subZone)
        PlaySound(SOUNDKIT.RAID_WARNING, "Master")
    else
        Catfish:Print("★ Rare catch:", itemName, "at", subZone)
        PlaySound(SOUNDKIT.IG_QUEST_COMPLETE, "Master")
    end
end

-- ============================================
-- Loot Handling
-- ============================================

function Statistics:OnLootReady()
    -- Track what we're about to loot
    self.currentLootItems = {}

    for slot = 1, GetNumLootItems() do
        local lootType = GetLootSlotType(slot)
        if lootType == LOOT_SLOT_ITEM then
            local itemLink = GetLootSlotLink(slot)
            local itemID = itemLink and self:ExtractItemID(itemLink)
            if itemID then
                local quantity = select(3, GetLootSlotInfo(slot)) or 1
                self.currentLootItems[itemID] = (self.currentLootItems[itemID] or 0) + quantity
            end
        end
    end
end

function Statistics:OnLootClosed()
    -- Record all looted items
    for itemID, quantity in pairs(self.currentLootItems) do
        for i = 1, quantity do
            self:RecordCatch(itemID)
        end
    end

    self.currentLootItems = {}
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
end

-- ============================================
-- Helper Functions
-- ============================================

function Statistics:GetQualityName(quality)
    local names = {
        [0] = "Poor",
        [1] = "Common",
        [2] = "Uncommon",
        [3] = "Rare",
        [4] = "Epic",
        [5] = "Legendary",
        [6] = "Artifact",
        [7] = "Heirloom",
    }
    return names[quality] or "Unknown"
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

    Catfish:Debug("Statistics module initialized")
end