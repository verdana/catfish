-- Catfish - Toys.lua
-- Toy management module

local ADDON_NAME, Catfish = ...

local Toys = {}
Catfish.Modules.Toys = Toys

-- Owned toys tracking
Toys.ownedRafts = {}
Toys.ownedBobbers = {}
Toys.ownedExtraToys = {}

-- ============================================
-- Toy Scanning
-- ============================================

function Toys:ScanToys()
    self.ownedRafts = {}
    self.ownedBobbers = {}
    self.ownedExtraToys = {}

    if not Catfish.Data.Toys then return end

    -- Scan rafts
    if Catfish.Data.Toys.Rafts then
        for _, toy in ipairs(Catfish.Data.Toys.Rafts) do
            if Catfish.API:PlayerHasToy(toy.toyID) then
                -- Get localized name from WoW API
                local toyInfo = Catfish.API:GetToyInfo(toy.toyID)
                local localizedName = toyInfo and toyInfo.name or toy.name
                table.insert(self.ownedRafts, {
                    toyID = toy.toyID,
                    name = localizedName,
                    spellID = toy.spellID,
                    icon = toyInfo and toyInfo.icon or toy.icon,
                })
                Catfish:Debug("Found raft:", localizedName)
            end
        end
    end

    -- Scan bobbers
    if Catfish.Data.Toys.Bobbers then
        for _, toy in ipairs(Catfish.Data.Toys.Bobbers) do
            if Catfish.API:PlayerHasToy(toy.toyID) then
                -- Get localized name from WoW API
                local toyInfo = Catfish.API:GetToyInfo(toy.toyID)
                local localizedName = toyInfo and toyInfo.name or toy.name
                table.insert(self.ownedBobbers, {
                    toyID = toy.toyID,
                    name = localizedName,
                    spellID = toy.spellID,
                    icon = toyInfo and toyInfo.icon or toy.icon,
                })
                Catfish:Debug("Found bobber:", localizedName)
            end
        end
    end

    -- Scan extra toys from config
    if Catfish.db.toys.extraToys then
        for _, toyID in ipairs(Catfish.db.toys.extraToys) do
            if Catfish.API:PlayerHasToy(toyID) then
                local toyInfo = Catfish.API:GetToyInfo(toyID)
                if toyInfo then
                    table.insert(self.ownedExtraToys, {
                        toyID = toyID,
                        name = toyInfo.name,
                        icon = toyInfo.icon,
                    })
                end
            end
        end
    end
    -- Catfish:Debug("Toy scan complete:", #self.ownedRafts, "rafts,", #self.ownedBobbers, "bobbers")
end

-- ============================================
-- Raft Functions
-- ============================================

function Toys:GetAvailableRafts()
    local available = {}
    for _, toy in ipairs(self.ownedRafts) do
        local cooldown = Catfish.API:GetToyCooldown(toy.toyID)
        if cooldown == 0 then
            table.insert(available, toy)
        end
    end
    return available
end

function Toys:GetBestRaft()
    local config = Catfish.db.toys

    if config.raftMode == "none" then
        return nil
    end

    if config.raftMode == "specific" and config.selectedRaft then
        -- Check if selected raft is available
        local cooldown = Catfish.API:GetToyCooldown(config.selectedRaft)
        if cooldown == 0 then
            -- Find the toy data
            for _, toy in ipairs(self.ownedRafts) do
                if toy.toyID == config.selectedRaft then
                    return toy
                end
            end
        end
        return nil
    end

    -- Random mode - pick random available raft
    local available = self:GetAvailableRafts()
    if #available > 0 then
        return available[math.random(#available)]
    end

    return nil
end

function Toys:UseRaft()
    if not Catfish.db.autoToys then return false end
    if not Catfish.API:IsPlayerSwimming() then return false end

    local raft = self:GetBestRaft()
    if raft then
        Catfish:Debug("Using raft:", raft.name)
        return Catfish.API:UseToy(raft.toyID)
    end

    return false
end

-- ============================================
-- Bobber Functions
-- ============================================

function Toys:GetAvailableBobbers()
    local available = {}
    for _, toy in ipairs(self.ownedBobbers) do
        local cooldown = Catfish.API:GetToyCooldown(toy.toyID)
        if cooldown == 0 then
            table.insert(available, toy)
        end
    end
    return available
end

function Toys:GetBestBobber()
    local config = Catfish.db.toys

    if config.bobberMode == "none" then
        return nil
    end

    if config.bobberMode == "specific" and config.selectedBobber then
        -- Check if selected bobber is available
        local cooldown = Catfish.API:GetToyCooldown(config.selectedBobber)
        if cooldown == 0 then
            -- Find the toy data
            for _, toy in ipairs(self.ownedBobbers) do
                if toy.toyID == config.selectedBobber then
                    return toy
                end
            end
        end
        return nil
    end

    -- Random mode - pick random available bobber
    local available = self:GetAvailableBobbers()
    if #available > 0 then
        return available[math.random(#available)]
    end

    return nil
end

function Toys:UseBobber()
    if not Catfish.db.autoToys then return false end

    local bobber = self:GetBestBobber()
    if bobber then
        Catfish:Debug("Using bobber:", bobber.name)
        return Catfish.API:UseToy(bobber.toyID)
    end

    return false
end

-- ============================================
-- Extra Toys
-- ============================================

function Toys:AddExtraToy(toyID)
    if not toyID then return false end

    -- Check if already added
    for _, existingID in ipairs(Catfish.db.toys.extraToys) do
        if existingID == toyID then
            return false
        end
    end

    table.insert(Catfish.db.toys.extraToys, toyID)
    self:ScanToys()
    Catfish:Debug("Added extra toy:", toyID)
    return true
end

function Toys:RemoveExtraToy(index)
    if index and Catfish.db.toys.extraToys[index] then
        table.remove(Catfish.db.toys.extraToys, index)
        self:ScanToys()
        return true
    end
    return false
end

function Toys:UseExtraToys()
    if not Catfish.db.autoToys then return end
    if not Catfish.db.toys.extraToys then return end

    for _, toyID in ipairs(Catfish.db.toys.extraToys) do
        local cooldown = Catfish.API:GetToyCooldown(toyID)
        if cooldown == 0 then
            Catfish.API:UseToy(toyID)
            Catfish:Debug("Used extra toy:", toyID)
        end
    end
end

-- ============================================
-- Main Usage Function
-- ============================================

function Toys:UseConfiguredToys()
    -- Use raft if swimming
    if Catfish.API:IsPlayerSwimming() then
        self:UseRaft()
    end

    -- NOTE: Bobbers are now handled by Core.lua using db.selectedBobberToy
    -- The old db.toys.selectedBobber system is deprecated for bobbers

    -- Use any configured extra toys
    self:UseExtraToys()
end

-- ============================================
-- Configuration
-- ============================================

function Toys:SetRaftMode(mode)
    if mode == "random" or mode == "specific" or mode == "none" then
        Catfish.db.toys.raftMode = mode
        Catfish:Debug("Raft mode set to:", mode)
        return true
    end
    return false
end

function Toys:SetSelectedRaft(toyID)
    Catfish.db.toys.selectedRaft = toyID
    Catfish:Debug("Selected raft set to:", toyID)
end

function Toys:SetBobberMode(mode)
    if mode == "random" or mode == "specific" or mode == "none" then
        Catfish.db.toys.bobberMode = mode
        Catfish:Debug("Bobber mode set to:", mode)
        return true
    end
    return false
end

function Toys:SetSelectedBobber(toyID)
    Catfish.db.toys.selectedBobber = toyID
    Catfish:Debug("Selected bobber set to:", toyID)
end

-- ============================================
-- Status Printing
-- ============================================

function Toys:PrintStatus()
    Catfish:Print("=== Toy Status ===")

    Catfish:Print("Rafts owned:", #self.ownedRafts)
    for _, toy in ipairs(self.ownedRafts) do
        local cooldown = Catfish.API:GetToyCooldown(toy.toyID)
        local status = cooldown > 0 and ("on cooldown: " .. cooldown .. "s") or "ready"
        Catfish:Print("  -", toy.name, "(" .. status .. ")")
    end

    Catfish:Print("Bobbers owned:", #self.ownedBobbers)
    for _, toy in ipairs(self.ownedBobbers) do
        local cooldown = Catfish.API:GetToyCooldown(toy.toyID)
        local status = cooldown > 0 and ("on cooldown: " .. cooldown .. "s") or "ready"
        Catfish:Print("  -", toy.name, "(" .. status .. ")")
    end

    Catfish:Print("Extra toys:", #self.ownedExtraToys)
    for _, toy in ipairs(self.ownedExtraToys) do
        local cooldown = Catfish.API:GetToyCooldown(toy.toyID)
        local status = cooldown > 0 and ("on cooldown: " .. cooldown .. "s") or "ready"
        Catfish:Print("  -", toy.name, "(" .. status .. ")")
    end

    Catfish:Print("Raft mode:", Catfish.db.toys.raftMode)
    Catfish:Print("Bobber mode:", Catfish.db.toys.bobberMode)
end

-- ============================================
-- Initialization
-- ============================================

function Toys:Init()
    -- Scan for owned toys
    self:ScanToys()
    -- Catfish:Debug("Toys module initialized")
end

-- ============================================
-- Getters
-- ============================================

function Toys:GetOwnedRafts()
    return self.ownedRafts
end

function Toys:GetOwnedBobbers()
    return self.ownedBobbers
end

function Toys:GetOwnedExtraToys()
    return self.ownedExtraToys
end
