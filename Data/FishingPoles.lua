-- Catfish - FishingPoles.lua
-- Fishing pole data

local ADDON_NAME, Catfish = ...

Catfish.Data.FishingPoles = {
    -- Basic fishing poles
    [6256] = {name = "Fishing Pole", bonus = 0, level = 1},
    [6365] = {name = "Strong Fishing Pole", bonus = 5, level = 1},
    [6366] = {name = "Darkwood Fishing Pole", bonus = 15, level = 1},
    [6367] = {name = "Big Iron Fishing Pole", bonus = 20, level = 1},

    -- Classic poles
    [12225] = {name = "Blump Family Fishing Pole", bonus = 3, level = 1},
    [19022] = {name = "Nat Pagle's Extreme Angler FC-5000", bonus = 20, level = 1},
    [19970] = {name = "Arcanite Fishing Pole", bonus = 35, level = 1}, -- Best classic pole

    -- TBC poles
    [25978] = {name = "Seth's Graphite Fishing Pole", bonus = 20, level = 1},
    [27332] = {name = "Brutillus' Custom Fishing Pole", bonus = 30, level = 1}, -- Quest reward

    -- Wrath poles
    [43631] = {name = "Bone Fishing Pole", bonus = 30, level = 1},
    [43632] = {name = "Kalu'ak Fishing Pole", bonus = 30, level = 1},
    [45992] = {name = "Mastercraft Kalu'ak Fishing Pole", bonus = 30, level = 1},

    -- Cata poles
    [6589] = {name = "Dragonheart Fishing Pole", bonus = 30, level = 1},

    -- MoP poles
    [85414] = {name = "Pandaren Fishing Pole", bonus = 10, level = 1},
    [85415] = {name = "Dragon Fishing Pole", bonus = 30, level = 1},
    [84660] = {name = "Nat's Lucky Fishing Pole", bonus = 25, level = 1},

    -- WoD poles
    [116826] = {name = "Ephemeral Fishing Pole", bonus = 30, level = 1, tempItem = true},
    [118381] = {name = "Savage Fishing Pole", bonus = 20, level = 1},

    -- Legion poles
    [133755] = {name = "Underlight Angler", bonus = 30, level = 1, artifact = true}, -- Artifact fishing pole

    -- BfA poles
    [154692] = {name = "Dreadleather Fishing Pole", bonus = 15, level = 1},
    [154693] = {name = "Cursed Swabby Headgear", bonus = 10, level = 1},
    [163206] = {name = "Hyper-Compressed Ocean", bonus = 25, level = 1},

    -- Shadowlands poles
    [180290] = {name = "Elixir of Detect Undead Fish", bonus = 15, level = 1, toy = true},

    -- Dragonflight poles
    [194901] = {name = "Iskaara Fishing Pole", bonus = 15, level = 1},
    [200150] = {name = "Highland Fishing Pole", bonus = 25, level = 1},

    -- War Within poles
    [222769] = {name = "Ashen Angler's Fishing Pole", bonus = 25, level = 1},
    [224367] = {name = "The Fin-esse Fishing Pole", bonus = 20, level = 1},
}