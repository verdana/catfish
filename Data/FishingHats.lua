-- Catfish - FishingHats.lua
-- Fishing hat data

local ADDON_NAME, Catfish = ...

Catfish.Data.FishingHats = {
    -- Classic fishing hat
    [19972] = {
        name = "Lucky Fishing Hat",
        bonus = 5,
        source = "Quest Reward (Stranglethorn Fishing Extravaganza)"
    },

    -- TBC fishing hat
    [33820] = {
        name = "Weather-Beaten Fishing Hat",
        bonus = 5,
        source = "Quest Reward (Shattrath Fishing Daily)"
    },

    -- Wrath fishing hats
    [88710] = {
        name = "Nat's Hat",
        bonus = 5,
        source = "Vendor (Nat Pagle)"
    },
    [88711] = {
        name = "Nat's Hat",
        bonus = 5,
        source = "Vendor (Anglers Wharf)"
    },

    -- Pandaria fishing hat
    [84661] = {
        name = "Nat's Lucky Fishing Hat",
        bonus = 5,
        source = "Vendor (Nat Pagle, Pandaria)"
    },

    -- Draenor fishing hat
    [118393] = {
        name = "Hightfish Cap",
        bonus = 10,
        source = "Garrison Fishing Shack"
    },
    [118394] = {
        name = "Tentacled Hat",
        bonus = 10,
        source = "Garrison Fishing Shack"
    },

    -- Legion fishing hats
    [133680] = {
        name = "Demonsteel Helm of Fishing",
        bonus = 15,
        source = "Crafted (Blacksmithing)"
    },
    [138815] = {
        name = "Sparkle Queen's Crown",
        bonus = 5,
        source = "Dungeon Drop (Court of Stars)"
    },
    [138816] = {
        name = "Crown of the Soothing Current",
        bonus = 5,
        source = "Dungeon Drop (Halls of Valor)"
    },

    -- BfA fishing hats
    [168033] = {
        name = "Azsh'ari Stormsurge Cowl",
        bonus = 15,
        source = "Vendor (Nazjatar)"
    },

    -- Shadowlands fishing hat
    [184065] = {
        name = "Stygian Shellkeeper",
        bonus = 8,
        source = "Zone Drop (The Maw)"
    },

    -- Dragonflight fishing hats
    [200119] = {
        name = "Fisherfriend's Helmet",
        bonus = 8,
        source = "Quest Reward"
    },

    -- War Within fishing hat
    [222768] = {
        name = "Deepdive Helmet",
        bonus = 10,
        source = "Profession"
    },
}

-- Hat enchants that give fishing bonus
Catfish.Data.HatEnchants = {
    [136358] = {
        name = "Tackle Box",
        bonus = 5,
        duration = 600,
        source = "Legion Enchant"
    },
}