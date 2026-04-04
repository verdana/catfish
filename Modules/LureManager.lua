-- Catfish - LureManager.lua
-- Fishing lure management module

local ADDON_NAME, Catfish = ...

local LureManager = {}
Catfish.Modules.LureManager = LureManager

-- Available lures
LureManager.availableLures = {}

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
-- Event Handlers
-- ============================================

function LureManager:OnBagUpdate(bagID)
    -- Rescan lures when inventory changes
    self:ScanBags()
end

-- ============================================
-- Initialization
-- ============================================

function LureManager:Init()
    -- Initial scan
    self:ScanBags()

    Catfish:Debug("LureManager initialized")
end