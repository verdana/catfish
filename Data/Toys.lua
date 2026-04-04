-- Catfish - Toys.lua
-- Toy data for fishing-related toys

local ADDON_NAME, Catfish = ...

Catfish.Data.Toys = {}

-- ============================================
-- Rafts (water walking/swimming aids)
-- ============================================

Catfish.Data.Toys.Rafts = {
    {
        name = "Tuskarr Dinghy",
        toyID = 198428,
        spellID = 383268,
        icon = 236574,
        description = "Dragonflight tuskarr raft, allows fishing while floating",
        source = "Tuskarr Reputation"
    },
    {
        name = "Anglers Fishing Raft",
        toyID = 85500,
        spellID = 124036,
        icon = 774121,
        description = "Pandaria anglers raft, allows fishing while floating",
        source = "The Anglers Reputation"
    },
    {
        name = "Gnarlwood Waveboard",
        toyID = 166461,
        spellID = 288758,
        icon = 133798,
        description = "Surfboard-style water walking toy",
        source = "BfA Zone Drop"
    },
    {
        name = "Personal Fishing Barge",
        toyID = 235801,
        spellID = 1218420,
        icon = 2341435,
        description = "War Within fishing barge",
        source = "Profession"
    },
}

-- ============================================
-- Bobbers (custom fishing bobber appearances)
-- ============================================

Catfish.Data.Toys.Bobbers = {
    -- Oversized Bobber
    {
        name = "Reusable Oversized Bobber",
        toyID = 202207,
        spellID = 397827,
        icon = 236576,
        description = "Makes your bobber larger and easier to see",
        source = "Dragonflight Fishing"
    },

    -- Crate of Bobbers series
    {
        name = "Crate of Bobbers: Can of Worms",
        toyID = 142528,
        spellID = 231291,
        icon = 236197,
        description = "Bobber shaped like a can of worms",
        source = "Legion Fishing"
    },
    {
        name = "Crate of Bobbers: Carved Wooden Helm",
        toyID = 147307,
        spellID = 240803,
        icon = 463008,
        description = "Bobber shaped like a wooden helm",
        source = "Legion Fishing"
    },
    {
        name = "Crate of Bobbers: Cat Head",
        toyID = 142529,
        spellID = 231319,
        icon = 454045,
        description = "Bobber shaped like a cat head",
        source = "Legion Fishing"
    },
    {
        name = "Crate of Bobbers: Demon Noggin",
        toyID = 147312,
        spellID = 240801,
        icon = 236292,
        description = "Bobber shaped like a demon head",
        source = "Legion Fishing"
    },
    {
        name = "Crate of Bobbers: Enchanted Bobber",
        toyID = 147308,
        spellID = 240800,
        icon = 236449,
        description = "Magical enchanted bobber",
        source = "Legion Fishing"
    },
    {
        name = "Crate of Bobbers: Face of the Forest",
        toyID = 147309,
        spellID = 240806,
        icon = 236157,
        description = "Bobber with forest spirit face",
        source = "Legion Fishing"
    },
    {
        name = "Crate of Bobbers: Floating Totem",
        toyID = 147310,
        spellID = 240802,
        icon = 310733,
        description = "Bobber shaped like a totem",
        source = "Legion Fishing"
    },
    {
        name = "Crate of Bobbers: Murloc Head",
        toyID = 142532,
        spellID = 231349,
        icon = 134169,
        description = "Bobber shaped like a murloc head",
        source = "Legion Fishing"
    },
    {
        name = "Crate of Bobbers: Replica Gondola",
        toyID = 147311,
        spellID = 240804,
        icon = 517162,
        description = "Bobber shaped like a gondola",
        source = "Legion Fishing"
    },
    {
        name = "Crate of Bobbers: Squeaky Duck",
        toyID = 142531,
        spellID = 231341,
        icon = 1369786,
        description = "Bobber shaped like a rubber duck",
        source = "Legion Fishing"
    },
    {
        name = "Crate of Bobbers: Tugboat",
        toyID = 142530,
        spellID = 231338,
        icon = 1126431,
        description = "Bobber shaped like a tugboat",
        source = "Legion Fishing"
    },
    {
        name = "Crate of Bobbers: Wooden Pepe",
        toyID = 143662,
        spellID = 232613,
        icon = 1044996,
        description = "Bobber shaped like a wooden Pepe",
        source = "Legion Fishing"
    },

    -- Other bobber toys
    {
        name = "Bat Visage Bobber",
        toyID = 180993,
        spellID = 335484,
        icon = 132182,
        description = "Bobber shaped like a bat face",
        source = "Shadowlands"
    },
    {
        name = "Limited Edition Rocket Bobber",
        toyID = 237345,
        spellID = 1222880,
        icon = 6383563,
        description = "Rocket-shaped bobber",
        source = "War Within"
    },
    {
        name = "Artisan Beverage Goblet Bobber",
        toyID = 237346,
        spellID = 1222884,
        icon = 6383561,
        description = "Goblet-shaped bobber",
        source = "War Within"
    },
    {
        name = "Organically-Sourced Wellington Bobber",
        toyID = 237347,
        spellID = 1222888,
        icon = 6383562,
        description = "Boot-shaped bobber",
        source = "War Within"
    },
}

-- ============================================
-- Helper Functions
-- ============================================

function Catfish.Data.Toys:GetToyByID(toyID)
    -- Check rafts
    for _, toy in ipairs(self.Rafts) do
        if toy.toyID == toyID then
            return toy
        end
    end

    -- Check bobbers
    for _, toy in ipairs(self.Bobbers) do
        if toy.toyID == toyID then
            return toy
        end
    end

    return nil
end