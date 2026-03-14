-- Catfish - FishingItems.lua
-- Fishing-related items data (trinkets, consumables, etc.)

local ADDON_NAME, Catfish = ...

Catfish.Data.FishingItems = {
    -- ============================================
    -- Trinkets with fishing bonuses
    -- ============================================

    -- Classic
    [19737] = {
        name = "Brooch of the Great Betrayer",
        bonus = 0,
        slot = "trinket",
        effect = "use",
        source = "Quest Reward"
    },

    -- Wrath
    [45985] = {
        name = "Charm of the Tuskarr",
        bonus = 0,
        slot = "trinket",
        effect = "use",
        cooldown = 60,
        source = "Kalu'ak Quartermaster"
    },
    [45988] = {
        name = "Blessing of the Old God",
        bonus = 0,
        slot = "trinket",
        effect = "use",
        cooldown = 60,
        source = "Drop"
    },

    -- Draenor
    [118392] = {
        name = "Hook of the Master Angler",
        bonus = 0,
        slot = "trinket",
        effect = "use",
        cooldown = 60,
        source = "Garrison Fishing Shack"
    },

    -- Legion
    [133915] = {
        name = "Concordance of the Legionfall",
        bonus = 0,
        slot = "trinket",
        effect = "passive",
        source = "Artifact Trait"
    },

    -- BfA
    [168042] = {
        name = "Oceansim Natator",
        bonus = 0,
        slot = "trinket",
        effect = "use",
        cooldown = 60,
        source = "Nazjatar"
    },
    [168041] = {
        name = "Inoculating Extract",
        bonus = 0,
        slot = "trinket",
        effect = "use",
        cooldown = 60,
        source = "Nazjatar"
    },

    -- Dragonflight
    [200093] = {
        name = "Aquatic Shades",
        bonus = 5,
        slot = "trinket",
        effect = "passive",
        source = "Profession"
    },

    -- ============================================
    -- Consumables with fishing bonuses
    -- ============================================

    -- Captain Rumsey's Lager (Toy)
    [68049] = {
        name = "Captain Rumsey's Lager",
        bonus = 10,
        duration = 1800,
        toy = true,
        source = "Darkmoon Faire / Drop"
    },

    -- ============================================
    -- Other fishing-related items
    -- ============================================

    -- Nightcrawlers
    [6530] = {
        name = "Nightcrawlers",
        bonus = 50,
        type = "lure",
        duration = 600,
        source = "Vendor / Drop"
    },

    -- Bright Baubles
    [6532] = {
        name = "Bright Baubles",
        bonus = 75,
        type = "lure",
        duration = 600,
        source = "Vendor"
    },

    -- Aquadynamic Fish Attractor
    [6533] = {
        name = "Aquadynamic Fish Attractor",
        bonus = 100,
        type = "lure",
        duration = 600,
        source = "Vendor / Craft"
    },

    -- Glow Worm (Toy)
    [46006] = {
        name = "Glow Worm",
        bonus = 100,
        duration = 3600,
        toy = true,
        source = "Quest Reward"
    },

    -- Worm Supreme (Toy)
    [116825] = {
        name = "Worm Supreme",
        bonus = 200,
        duration = 600,
        toy = true,
        source = "Garrison"
    },

    -- Vibrant Lure (War Within)
    [202217] = {
        name = "Vibrant Lure",
        bonus = 45,
        type = "lure",
        duration = 600,
        tempItem = true,
        source = "Profession"
    },

    -- ============================================
    -- Special fishing items
    -- ============================================

    -- Ancient Vrykul Ring (transforms into fish for faster swimming)
    [43709] = {
        name = "Ancient Vrykul Ring",
        bonus = 0,
        effect = "transform",
        duration = 60,
        cooldown = 300,
        source = "Quest"
    },

    -- Hook of the Master Angler (transforms into fish)
    [8494] = {
        name = "Hook of the Master Angler",
        bonus = 0,
        effect = "transform",
        duration = 60,
        cooldown = 300,
        source = "Drop (Gahz'ranka)"
    },
}

-- Category lists for easy access
Catfish.Data.FishingTrinkets = {}
Catfish.Data.FishingLures = {}

-- Populate categories on load
for itemID, data in pairs(Catfish.Data.FishingItems) do
    if data.slot == "trinket" then
        Catfish.Data.FishingTrinkets[itemID] = data
    end
    if data.type == "lure" or data.toy then
        Catfish.Data.FishingLures[itemID] = data
    end
end