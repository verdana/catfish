-- Catfish - LureManager.lua
-- Fishing lure management module

local ADDON_NAME, Catfish = ...

local LureManager = {}
Catfish.Modules.LureManager = LureManager

-- Available lures
LureManager.availableLures = {}

-- Current lure state
LureManager.currentLure = nil
LureManager.lastAppliedTime = 0

-- ============================================
-- Lure Data
-- ============================================

-- Common fishing lures with their bonuses and durations
LureManager.LURE_DATA = {
    -- High-level lures
    {itemID = 202217, name = "Vibrant Lure", bonus = 45, duration = 600, tempItem = true}, -- War Within
    {itemID = 182957, name = "Drowned Worm", bonus = 30, duration = 600, tempItem = true}, -- Shadowlands
    {itemID = 180290, name = "Elixir of Detect Undead Fish", bonus = 15, duration = 600}, -- Shadowlands toy
    {itemID = 68049, name = "Captain Rumsey's Lager", bonus = 10, duration = 1800, toy = true}, -- Toy

    -- Classic lures
    {itemID = 6529, name = "Shiny Bauble", bonus = 25, duration = 600},
    {itemID = 6530, name = "Nightcrawlers", bonus = 50, duration = 600},
    {itemID = 6532, name = "Bright Baubles", bonus = 75, duration = 600},
    {itemID = 6533, name = "Aquadynamic Fish Attractor", bonus = 100, duration = 600},

    -- TBC lures
    {itemID = 34861, name = "Sharpened Fish Hook", bonus = 100, duration = 600},

    -- Wrath lures
    {itemID = 46006, name = "Glow Worm", bonus = 100, duration = 3600, toy = true}, -- Toy

    -- Cata lures
    {itemID = 67410, name = "Heat-Treated Spinning Lure", bonus = 150, duration = 600},

    -- MoP lures
    {itemID = 86547, name = "Emblem of the Sha", bonus = 125, duration = 600},

    -- WoD lures
    {itemID = 116825, name = "Worm Supreme", bonus = 200, duration = 600, toy = true}, -- Toy
    {itemID = 111993, name = "Bladebone Hook", bonus = 100, duration = 600},

    -- Legion lures
    {itemID = 147351, name = "Fishing Attribute Rune", bonus = 100, duration = 600},

    -- BfA lures
    {itemID = 160835, name = "Hyper-Compressed Ocean", bonus = 100, duration = 600},

    -- Dragonflight lures
    {itemID = 200091, name = "Pungent Scentless Bait", bonus = 25, duration = 600},

    -- Hat enchants (for reference)
    {itemID = 136358, name = "Tackle Box", bonus = 5, duration = 600, enchant = true},
}

-- ============================================
-- Lure Scanning
-- ============================================

function LureManager:ScanBags()
    self.availableLures = {}

    for _, lureData in ipairs(self.LURE_DATA) do
        if lureData.toy then
            -- Check if player has the toy
            if Catfish.API:PlayerHasToy(lureData.itemID) then
                table.insert(self.availableLures, lureData)
            end
        else
            -- Check if player has the item
            if Catfish.API:PlayerHasItem(lureData.itemID) then
                table.insert(self.availableLures, lureData)
            end
        end
    end

    -- Sort by bonus (descending)
    table.sort(self.availableLures, function(a, b)
        return a.bonus > b.bonus
    end)

    Catfish:Debug("Found", #self.availableLures, "available lures")
end

-- ============================================
-- Lure Application
-- ============================================

function LureManager:CanApplyLure()
    -- Check if we have a fishing pole equipped
    local mainHandItemID = Catfish.API:GetInventoryItemID(Catfish.API.INVSLOT_MAINHAND)
    if not mainHandItemID then return false end

    -- Check if it's a fishing pole
    local _, _, _, _, _, class, subclass = GetItemInfo(mainHandItemID)
    if class ~= "Weapon" or subclass ~= "Fishing Poles" then
        return false
    end

    -- Check if not in combat
    if InCombatLockdown() then return false end

    return true
end

function LureManager:HasActiveLure()
    -- Check weapon enchant
    local hasEnchant, expiration = Catfish.API:GetWeaponEnchantInfo(true)
    if hasEnchant and expiration > 0 then
        return true, expiration
    end

    -- Check for buff-based lures
    for _, lureData in ipairs(self.LURE_DATA) do
        if lureData.toy or lureData.tempItem then
            local hasBuff, duration = Catfish.API:UnitHasBuff("player", lureData.spellID or 0)
            if hasBuff then
                return true, duration
            end
        end
    end

    return false, 0
end

function LureManager:ApplyLure(lureData)
    if not self:CanApplyLure() then
        Catfish:Debug("Cannot apply lure")
        return false
    end

    -- Check cooldown for toys
    if lureData.toy then
        local cooldown = Catfish.API:GetToyCooldown(lureData.itemID)
        if cooldown > 0 then
            Catfish:Debug("Lure on cooldown:", cooldown)
            return false
        end

        -- Use toy
        Catfish:Debug("Applying lure:", lureData.name)
        Catfish.API:UseToy(lureData.itemID)
        self.lastAppliedTime = GetTime()
        return true
    end

    -- Use item on weapon
    local bagID, slot = Catfish.API:FindItemInBags(lureData.itemID)
    if bagID and slot then
        Catfish:Debug("Applying lure:", lureData.name)

        -- Use item on main hand
        PickupContainerItem(bagID, slot)
        PickupInventoryItem(Catfish.API.INVSLOT_MAINHAND)

        self.lastAppliedTime = GetTime()
        return true
    end

    return false
end

function LureManager:ApplyBestLure()
    if not Catfish.db.autoLure then
        return false
    end

    -- Check if already have a lure
    local hasLure, remaining = self:HasActiveLure()
    if hasLure and remaining > 60 then
        Catfish:Debug("Already have active lure:", remaining, "seconds remaining")
        return false
    end

    -- Scan for available lures
    self:ScanBags()

    if #self.availableLures == 0 then
        Catfish:Debug("No lures available")
        return false
    end

    -- Apply best available lure
    for _, lureData in ipairs(self.availableLures) do
        if self:ApplyLure(lureData) then
            return true
        end
    end

    return false
end

-- ============================================
-- Event Handlers
-- ============================================

function LureManager:OnBagUpdate(bagID)
    -- Rescan lures when inventory changes
    self:ScanBags()
end

function LureManager:OnAuraChanged()
    -- Check if lure expired
    local hasLure = self:HasActiveLure()
    if not hasLure and self.currentLure then
        Catfish:Debug("Lure expired")
        self.currentLure = nil
    end
end

-- ============================================
-- Initialization
-- ============================================

function LureManager:Init()
    -- Initial scan
    self:ScanBags()

    Catfish:Debug("LureManager initialized")
end

-- ============================================
-- Getters
-- ============================================

function LureManager:GetAvailableLures()
    return self.availableLures
end

function LureManager:GetBestLure()
    if #self.availableLures > 0 then
        return self.availableLures[1]
    end
    return nil
end

function LureManager:GetLureInfo(itemID)
    for _, lureData in ipairs(self.LURE_DATA) do
        if lureData.itemID == itemID then
            return lureData
        end
    end
    return nil
end