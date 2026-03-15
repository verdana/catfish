-- Catfish - API.lua
-- Public API encapsulation for WoW APIs

local ADDON_NAME, Catfish = ...

local API = {}
Catfish.API = API

-- ============================================
-- Spell APIs
-- ============================================

-- Retail fishing spell IDs (multiple spells for different fishing modes)
local FISHING_SPELL_IDS = {
    -- Main Fishing Spells
    7620, 131476,
    -- Other Basic Fishing Spells
    51294, 18248, 131474, 33095, 7732, 7731, 158743, 110410, 88868, 131490,
    -- Compressed Ocean Fishing
    295727,
    -- Skumblade Spear Fishing
    139505,
    -- Ice Fishing
    377895,
    -- Disgusting Vat Fishing
    405274,
    -- Hot-Spring Gulper Fishing
    301092,
}

function API:GetFishingSpellIDs()
    return FISHING_SPELL_IDS
end

function API:GetFishingSpellID()
    return 7620 -- Base fishing spell ID
end

function API:IsFishingSpell(spellID)
    for _, id in ipairs(FISHING_SPELL_IDS) do
        if id == spellID then
            return true
        end
    end
    return false
end

function API:GetFishingSpellName()
    local spellID = self:GetFishingSpellID()
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        return info and info.name
    elseif GetSpellInfo then
        return GetSpellInfo(spellID)
    end
    return nil
end

function API:CanCastFishing()
    -- Check if player has fishing skill
    if not Catfish.hasFishingSkill then
        return false
    end

    -- Check if not in combat
    if InCombatLockdown() then
        return false
    end

    -- Check if spell is usable (with compatibility)
    local spellID = self:GetFishingSpellID()
    if C_Spell and C_Spell.IsSpellUsable then
        return C_Spell.IsSpellUsable(spellID)
    elseif IsUsableSpell then
        return IsUsableSpell(spellID)
    end

    -- Fallback: assume usable if we got here
    return true
end

function API:CastFishing()
    if self:CanCastFishing() then
        -- Check and enable auto loot if needed
        if Catfish.db.keepAutoLoot then
            if GetCVar("autoLootDefault") ~= "1" then
                SetCVar("autoLootDefault", "1")
            end
        end

        local spellName = self:GetFishingSpellName()
        if spellName then
            if C_Spell and C_Spell.CastSpellByName then
                C_Spell.CastSpellByName(spellName)
            elseif CastSpellByName then
                CastSpellByName(spellName)
            end
            return true
        end
    end
    return false
end

-- ============================================
-- Item APIs
-- ============================================

function API:GetItemInfo(itemID)
    local name, link, quality, iLevel, reqLevel, class, subclass,
          maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemID)
    return {
        name = name,
        link = link,
        quality = quality,
        iLevel = iLevel,
        reqLevel = reqLevel,
        class = class,
        subclass = subclass,
        maxStack = maxStack,
        equipSlot = equipSlot,
        texture = texture,
        vendorPrice = vendorPrice,
    }
end

function API:GetItemLink(itemID)
    return select(2, GetItemInfo(itemID))
end

function API:GetItemName(itemID)
    return select(1, GetItemInfo(itemID))
end

function API:PlayerHasItem(itemID)
    return GetItemCount(itemID) > 0
end

-- ============================================
-- Equipment APIs
-- ============================================

-- Inventory slots
API.INVSLOT_HEAD = INVSLOT_HEAD or 1
API.INVSLOT_NECK = INVSLOT_NECK or 2
API.INVSLOT_SHOULDER = INVSLOT_SHOULDER or 3
API.INVSLOT_CHEST = INVSLOT_CHEST or 5
API.INVSLOT_WAIST = INVSLOT_WAIST or 6
API.INVSLOT_LEGS = INVSLOT_LEGS or 7
API.INVSLOT_FEET = INVSLOT_FEET or 8
API.INVSLOT_WRIST = INVSLOT_WRIST or 9
API.INVSLOT_HAND = INVSLOT_HAND or 10
API.INVSLOT_FINGER1 = INVSLOT_FINGER1 or 11
API.INVSLOT_FINGER2 = INVSLOT_FINGER2 or 12
API.INVSLOT_TRINKET1 = INVSLOT_TRINKET1 or 13
API.INVSLOT_TRINKET2 = INVSLOT_TRINKET2 or 14
API.INVSLOT_MAINHAND = INVSLOT_MAINHAND or 16

function API:GetInventoryItemLink(slot)
    return GetInventoryItemLink("player", slot)
end

function API:GetInventoryItemID(slot)
    return GetInventoryItemID("player", slot)
end

function API:EquipItemByName(itemNameOrLink)
    if InCombatLockdown() then
        return false
    end
    EquipItemByName(itemNameOrLink)
    return true
end

function API:UseInventoryItem(slot)
    if InCombatLockdown() then
        return false
    end
    UseInventoryItem(slot)
    return true
end

-- ============================================
-- Toy APIs
-- ============================================

-- Secure button for using toys
local toyButton = nil

function API:InitToyButton()
    if toyButton then return end

    Catfish:Debug("API:InitToyButton - Creating toy button")
    -- Create a secure button for using toys
    toyButton = CreateFrame("Button", "CatfishToyButton", UIParent, "SecureActionButtonTemplate")
    toyButton:SetSize(1, 1)
    toyButton:SetPoint("CENTER", UIParent, "CENTER", 10000, 10000)
    toyButton:RegisterForClicks("AnyDown", "AnyUp")
    -- Set initial valid state to prevent errors
    toyButton:SetAttribute("type", "item")
    toyButton:Hide()  -- Hide until needed
end

function API:GetToyButton()
    return toyButton
end

function API:SetToyButtonMacro(toyName)
    Catfish:Debug("API:SetToyButtonMacro called with toyName:", tostring(toyName))

    if InCombatLockdown() then
        Catfish:Debug("API:SetToyButtonMacro - In combat, returning false")
        return false
    end

    if not toyName or toyName == "" then
        Catfish:Debug("API:SetToyButtonMacro - Invalid toy name, returning false")
        return false
    end

    if not toyButton then
        self:InitToyButton()
    end

    -- Set the macro text for the toy
    toyButton:SetAttribute("type", "macro")
    toyButton:SetAttribute("macrotext", "/cast " .. toyName)
    toyButton:Show()

    Catfish:Debug("API:SetToyButtonMacro - Button configured, macrotext:", "/cast " .. toyName)
    return true
end

function API:UseToySecure(itemID)
    Catfish:Debug("API:UseToySecure called with itemID:", itemID)

    if InCombatLockdown() then
        Catfish:Debug("API:UseToySecure - In combat, returning false")
        return false
    end

    if not self:PlayerHasToy(itemID) then
        Catfish:Debug("API:UseToySecure - Player doesn't have toy, returning false")
        return false
    end

    -- Initialize button (if needed)
    if not toyButton then
        self:InitToyButton()
    end

    -- Set button type to item and configure it
    toyButton:SetAttribute("type", "item")
    toyButton:SetAttribute("item", "item:" .. itemID)
    toyButton:Show()

    Catfish:Debug("API:UseToySecure - Button type:", tostring(toyButton:GetAttribute("type")))
    Catfish:Debug("API:UseToySecure - Button item:", tostring(toyButton:GetAttribute("item")))
    Catfish:Debug("API:UseToySecure - About to click button...")

    -- Click button to use item
    toyButton:Click()

    Catfish:Debug("API:UseToySecure - Button clicked successfully")
    return true
end

function API:PlayerHasToy(itemID)
    return PlayerHasToy(itemID)
end

function API:GetToyInfo(itemID)
    local toyName, toyIcon, isFavorite, hasFanfare, itemID = C_ToyBox.GetToyInfo(itemID)
    return {
        name = toyName,
        icon = toyIcon,
        isFavorite = isFavorite,
        hasFanfare = hasFanfare,
        itemID = itemID,
    }
end

function API:UseToy(itemID)
    if InCombatLockdown() then
        return false
    end

    if not self:PlayerHasToy(itemID) then
        return false
    end

    local _, cooldown = C_Container.GetItemCooldown(itemID)
    if cooldown > 0 then
        return false
    end

    -- Use secure button instead of macro command
    return self:UseToySecure(itemID)
end

function API:GetToyCooldown(itemID)
    local start, duration, enable = C_Container.GetItemCooldown(itemID)
    if start == 0 then
        return 0
    end
    return start + duration - GetTime()
end

-- ============================================
-- Container APIs
-- ============================================

function API:IterateBags()
    local bags = {0, 1, 2, 3, 4, 5} -- Main bag + 5 bag slots
    local currentBagIndex = 1
    local currentSlot = 0
    local bagID = bags[currentBagIndex]

    return function()
        while currentBagIndex <= #bags do
            bagID = bags[currentBagIndex]
            local slots = C_Container.GetContainerNumSlots(bagID)

            currentSlot = currentSlot + 1
            if currentSlot > slots then
                currentBagIndex = currentBagIndex + 1
                currentSlot = 0
            else
                local itemID = C_Container.GetContainerItemID(bagID, currentSlot)
                if itemID then
                    local info = C_Container.GetContainerItemInfo(bagID, currentSlot)
                    return bagID, currentSlot, itemID, info
                end
            end
        end
        return nil
    end
end

function API:FindItemInBags(itemID)
    for bagID, slot, foundItemID in self:IterateBags() do
        if foundItemID == itemID then
            return bagID, slot
        end
    end
    return nil, nil
end

-- ============================================
-- Unit APIs
-- ============================================

function API:GetPlayerName()
    return UnitName("player")
end

function API:GetPlayerGUID()
    return UnitGUID("player")
end

function API:GetPlayerLevel()
    return UnitLevel("player")
end

function API:IsPlayerMoving()
    return IsPlayerMoving()
end

function API:IsPlayerSwimming()
    return IsSwimming()
end

function API:IsPlayerIndoors()
    return IsIndoors()
end

-- ============================================
-- Zone/Location APIs
-- ============================================

function API:GetCurrentZone()
    return GetRealZoneText()
end

function API:GetCurrentSubZone()
    return GetSubZoneText()
end

function API:GetZoneID()
    return C_Map.GetBestMapForUnit("player") or 0
end

function API:GetZoneName()
    local zoneID = self:GetZoneID()
    if zoneID and zoneID > 0 then
        local mapInfo = C_Map.GetMapInfo(zoneID)
        return mapInfo and mapInfo.name or self:GetCurrentZone()
    end
    return self:GetCurrentZone()
end

-- ============================================
-- Interaction APIs
-- ============================================

-- Secure button for interactions
local interactButton = nil

function API:InitInteractButton()
    if interactButton then return end

    -- Create a secure button for interacting with soft targets
    interactButton = CreateFrame("Button", "CatfishInteractButton", UIParent, "SecureActionButtonTemplate")
    interactButton:SetAttribute("type", "macro")
    interactButton:SetAttribute("macrotext", "/click SoftInteractTarget")
    interactButton:Hide()
end

function API:InteractWithSoftTarget()
    -- Use the secure button to interact with soft target (bobber)
    if interactButton and not InCombatLockdown() then
        interactButton:Click()
    end
end

function API:SetSoftInteract()
    -- Can only set CVar out of combat - use CVars only on init
    -- The soft interact system works through keybinding, not direct API calls
    if not InCombatLockdown() then
        SetCVar("SoftTargetInteract", "3")
    end
end

function API:GetSoftInteractUnit()
    if GetSoftInteractTarget then
        return GetSoftInteractTarget()
    end
    return nil
end

-- ============================================
-- Cooldown APIs
-- ============================================

function API:GetSpellCooldown(spellID)
    local start, duration, enabled, modRate = GetSpellCooldown(spellID)
    if start == 0 then
        return 0
    end
    return start + duration - GetTime()
end

function API:GetItemCooldown(itemID)
    local start, duration, enable = C_Container.GetItemCooldown(itemID)
    if start == 0 then
        return 0
    end
    return start + duration - GetTime()
end

-- ============================================
-- Buff/Debuff APIs
-- ============================================

function API:UnitHasBuff(unit, spellID)
    -- Use modern API for Dragonflight/War Within
    if C_UnitAuras and C_UnitAuras.GetBuffDataByIndex then
        for i = 1, 40 do
            local buffData = C_UnitAuras.GetBuffDataByIndex(unit, i)
            if not buffData then break end
            -- Use pcall to safely compare spellId (protected in combat)
            local ok, match = pcall(function()
                return buffData.spellId == spellID
            end)
            if ok and match then
                local remaining = buffData.expirationTime and (buffData.expirationTime - GetTime()) or 0
                return true, remaining, buffData.applications or 0
            end
        end
    elseif UnitBuff then
        -- Fallback for older clients
        for i = 1, 40 do
            local name, icon, count, debuffType, duration, expirationTime,
                  source, isStealable, nameplateShowPersonal, spellId =
                  UnitBuff(unit, i)
            if not name then break end
            if spellId == spellID then
                return true, expirationTime - GetTime(), count
            end
        end
    end
    return false, 0, 0
end

function API:GetWeaponEnchantInfo(mainHand)
    local hasEnchant, expiration, charges, enchantID = GetWeaponEnchantInfo()
    if mainHand then
        return hasEnchant, expiration and (expiration / 1000) or 0, charges
    end
    return false, 0, 0
end

-- ============================================
-- Timer/Schedule APIs
-- ============================================

function API:ScheduleFunction(func, delay)
    C_Timer.After(delay, func)
end

-- ============================================
-- Debug Utilities
-- ============================================

function API:DumpTable(t, indent)
    if not Catfish.debugMode then return end

    indent = indent or ""
    for k, v in pairs(t) do
        if type(v) == "table" then
            print(indent .. tostring(k) .. ":")
            self:DumpTable(v, indent .. "  ")
        else
            print(indent .. tostring(k) .. " = " .. tostring(v))
        end
    end
end