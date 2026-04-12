-- Catfish - Equipment.lua
-- Auto-equipment management module

local ADDON_NAME, Catfish = ...

local Equipment = {}
Catfish.Modules.Equipment = Equipment

-- Available equipment lists
Equipment.availablePoles = {}
Equipment.availableHats = {}
Equipment.availableTrinkets = {}

-- ============================================
-- Equipment Scanning
-- ============================================

function Equipment:ScanBags()
    self.availablePoles = {}
    self.availableHats = {}
    self.availableTrinkets = {}

    -- Scan all bags
    for bagID, slot, itemID, info in Catfish.API:IterateBags() do
        local itemName, _, _, _, _, class, subclass, _, equipSlot = GetItemInfo(itemID)

        if equipSlot then
            if equipSlot == "INVTYPE_2HWEAPON" or equipSlot == "INVTYPE_WEAPON" or equipSlot == "INVTYPE_WEAPONMAINHAND" then
                -- Check if it's a fishing pole
                if class == "Weapon" and subclass == "Fishing Poles" then
                    local bonus = self:GetFishingBonus(itemID)
                    table.insert(self.availablePoles, {
                        itemID = itemID,
                        name = itemName,
                        bonus = bonus,
                        bagID = bagID,
                        slot = slot,
                    })
                end
            elseif equipSlot == "INVTYPE_HEAD" then
                -- Check if it's a fishing hat
                if self:IsFishingHat(itemID) then
                    local bonus = self:GetFishingBonus(itemID)
                    table.insert(self.availableHats, {
                        itemID = itemID,
                        name = itemName,
                        bonus = bonus,
                        bagID = bagID,
                        slot = slot,
                    })
                end
            elseif equipSlot == "INVTYPE_TRINKET" then
                -- Check if it has fishing bonus
                local bonus = self:GetFishingBonus(itemID)
                if bonus > 0 then
                    table.insert(self.availableTrinkets, {
                        itemID = itemID,
                        name = itemName,
                        bonus = bonus,
                        bagID = bagID,
                        slot = slot,
                    })
                end
            end
        end
    end

    -- Sort by bonus (descending)
    table.sort(self.availablePoles, function(a, b) return a.bonus > b.bonus end)
    table.sort(self.availableHats, function(a, b) return a.bonus > b.bonus end)
    table.sort(self.availableTrinkets, function(a, b) return a.bonus > b.bonus end)

    Catfish:Debug("Found", #self.availablePoles, "fishing poles,",
                  #self.availableHats, "fishing hats,",
                  #self.availableTrinkets, "fishing trinkets")
end

function Equipment:GetFishingBonus(itemID)
    -- Check known fishing items data
    if Catfish.Data.FishingPoles and Catfish.Data.FishingPoles[itemID] then
        return Catfish.Data.FishingPoles[itemID].bonus or 0
    end
    if Catfish.Data.FishingHats and Catfish.Data.FishingHats[itemID] then
        return Catfish.Data.FishingHats[itemID].bonus or 0
    end
    if Catfish.Data.FishingItems and Catfish.Data.FishingItems[itemID] then
        return Catfish.Data.FishingItems[itemID].bonus or 0
    end

    -- Try to parse from tooltip
    return self:ParseFishingBonusFromTooltip(itemID)
end

function Equipment:ParseFishingBonusFromTooltip(itemID)
    -- Create tooltip scanner if needed
    if not self.tooltipScanner then
        self.tooltipScanner = CreateFrame("GameTooltip", "CatfishTooltipScanner", UIParent, "GameTooltipTemplate")
    end

    self.tooltipScanner:SetOwner(UIParent, "ANCHOR_NONE")
    self.tooltipScanner:SetItemByID(itemID)

    local bonus = 0

    for i = 1, self.tooltipScanner:NumLines() do
        local line = _G["CatfishTooltipScannerTextLeft" .. i]
        if line then
            local text = line:GetText()
            if text then
                -- Look for "+X Fishing" pattern
                local match = text:match("%+(%d+) [Ff]ishing")
                if match then
                    bonus = tonumber(match) or 0
                    break
                end
            end
        end
    end

    return bonus
end

function Equipment:IsFishingHat(itemID)
    -- Check data
    if Catfish.Data.FishingHats and Catfish.Data.FishingHats[itemID] then
        return true
    end

    -- Check tooltip for fishing bonus
    return self:GetFishingBonus(itemID) > 0
end

-- ============================================
-- Event Handlers
-- ============================================

function Equipment:OnBagUpdate(bagID)
    -- Rescan bags when inventory changes
    self:ScanBags()
end

function Equipment:OnInventoryChanged()
    -- Equipment changed
    -- Catfish:Debug("Inventory changed")
end

-- ============================================
-- Initialization
-- ============================================

function Equipment:Init()
    -- Initial scan
    -- self:ScanBags()
    Catfish:Debug("Equipment module initialized")
end
