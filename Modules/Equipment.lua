-- Catfish - Equipment.lua
-- Auto-equipment management module

local ADDON_NAME, Catfish = ...

local Equipment = {}
Catfish.Modules.Equipment = Equipment

-- Equipment tracking
Equipment.currentPole = nil
Equipment.currentHat = nil
Equipment.originalMainHand = nil
Equipment.originalHead = nil
Equipment.originalTrinket1 = nil
Equipment.originalTrinket2 = nil

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
-- Equipment Management
-- ============================================

function Equipment:EquipFishingGear()
    if InCombatLockdown() then
        Catfish:Debug("Cannot equip in combat")
        return false
    end

    -- Scan for available gear
    self:ScanBags()

    -- Save current equipment
    self:SaveOriginalGear()

    -- Equip best pole
    if #self.availablePoles > 0 then
        local bestPole = self.availablePoles[1]
        if bestPole.itemID ~= Catfish.API:GetInventoryItemID(Catfish.API.INVSLOT_MAINHAND) then
            Catfish:Debug("Equipping fishing pole:", bestPole.name)
            Catfish.API:EquipItemByName(bestPole.name)
            self.currentPole = bestPole
        end
    end

    -- Equip best hat
    if #self.availableHats > 0 then
        local bestHat = self.availableHats[1]
        if bestHat.itemID ~= Catfish.API:GetInventoryItemID(Catfish.API.INVSLOT_HEAD) then
            Catfish:Debug("Equipping fishing hat:", bestHat.name)
            Catfish.API:EquipItemByName(bestHat.name)
            self.currentHat = bestHat
        end
    end

    -- Equip trinkets (optional)
    -- Note: Trinket usage is usually preferred over permanent equipping
    -- as fishing trinkets often have use effects

    return true
end

function Equipment:SaveOriginalGear()
    self.originalMainHand = Catfish.API:GetInventoryItemID(Catfish.API.INVSLOT_MAINHAND)
    self.originalHead = Catfish.API:GetInventoryItemID(Catfish.API.INVSLOT_HEAD)
    self.originalTrinket1 = Catfish.API:GetInventoryItemID(Catfish.API.INVSLOT_TRINKET1)
    self.originalTrinket2 = Catfish.API:GetInventoryItemID(Catfish.API.INVSLOT_TRINKET2)

    Catfish:Debug("Saved original equipment:",
                  "MH:", self.originalMainHand,
                  "Head:", self.originalHead)
end

function Equipment:RestoreOriginalGear()
    if InCombatLockdown() then
        Catfish:Debug("Cannot restore in combat")
        return false
    end

    if not Catfish.db.equipment.restoreAfterFishing then
        return false
    end

    -- Restore main hand
    if self.originalMainHand then
        local currentMainHand = Catfish.API:GetInventoryItemID(Catfish.API.INVSLOT_MAINHAND)
        if currentMainHand ~= self.originalMainHand then
            local itemName = Catfish.API:GetItemName(self.originalMainHand)
            if itemName then
                Catfish:Debug("Restoring main hand:", itemName)
                Catfish.API:EquipItemByName(itemName)
            end
        end
    end

    -- Restore head
    if self.originalHead then
        local currentHead = Catfish.API:GetInventoryItemID(Catfish.API.INVSLOT_HEAD)
        if currentHead ~= self.originalHead then
            local itemName = Catfish.API:GetItemName(self.originalHead)
            if itemName then
                Catfish:Debug("Restoring head:", itemName)
                Catfish.API:EquipItemByName(itemName)
            end
        end
    end

    -- Clear saved equipment
    self.currentPole = nil
    self.currentHat = nil
    self.originalMainHand = nil
    self.originalHead = nil

    return true
end

-- ============================================
-- Trinket Usage
-- ============================================

function Equipment:UseFishingTrinkets()
    if InCombatLockdown() then return end

    -- Check trinket slots for fishing trinkets
    for i, slot in ipairs({Catfish.API.INVSLOT_TRINKET1, Catfish.API.INVSLOT_TRINKET2}) do
        local itemID = Catfish.API:GetInventoryItemID(slot)
        if itemID then
            local bonus = self:GetFishingBonus(itemID)
            if bonus > 0 then
                -- Check if trinket has a use effect
                if self:HasUseEffect(itemID) then
                    local cooldown = Catfish.API:GetItemCooldown(itemID)
                    if cooldown == 0 then
                        Catfish:Debug("Using fishing trinket in slot", slot)
                        Catfish.API:UseInventoryItem(slot)
                    end
                end
            end
        end
    end
end

function Equipment:HasUseEffect(itemID)
    -- Check if item has an on-use effect
    if not self.tooltipScanner then
        self.tooltipScanner = CreateFrame("GameTooltip", "CatfishTooltipScanner", UIParent, "GameTooltipTemplate")
    end

    self.tooltipScanner:SetOwner(UIParent, "ANCHOR_NONE")
    self.tooltipScanner:SetItemByID(itemID)

    for i = 1, self.tooltipScanner:NumLines() do
        local line = _G["CatfishTooltipScannerTextLeft" .. i]
        if line then
            local text = line:GetText()
            if text then
                -- Look for "Use:" pattern
                if text:find("^Use:") or text:find("Use:") then
                    return true
                end
            end
        end
    end

    return false
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
    Catfish:Debug("Inventory changed")
end

-- ============================================
-- Initialization
-- ============================================

function Equipment:Init()
    -- Initial scan
    self:ScanBags()

    Catfish:Debug("Equipment module initialized")
end

-- ============================================
-- Getters
-- ============================================

function Equipment:GetAvailablePoles()
    return self.availablePoles
end

function Equipment:GetAvailableHats()
    return self.availableHats
end

function Equipment:GetAvailableTrinkets()
    return self.availableTrinkets
end

function Equipment:GetBestPole()
    if #self.availablePoles > 0 then
        return self.availablePoles[1]
    end
    return nil
end

function Equipment:GetBestHat()
    if #self.availableHats > 0 then
        return self.availableHats[1]
    end
    return nil
end