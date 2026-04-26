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

-- Build hash set for O(1) lookup
local FISHING_SPELL_SET = {}
for _, id in ipairs(FISHING_SPELL_IDS) do
    FISHING_SPELL_SET[id] = true
end

function API:IsFishingSpell(spellID)
    return FISHING_SPELL_SET[spellID] or false
end

function API:GetFishingSpellName()
    local spellID = 7620
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        return info and info.name
    elseif GetSpellInfo then
        return GetSpellInfo(spellID)
    end
    return nil
end

-- ============================================
-- Item APIs
-- ============================================

function API:GetItemName(itemID)
    return select(1, GetItemInfo(itemID))
end

function API:PlayerHasItem(itemID)
    return GetItemCount(itemID) > 0
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

function API:SetToyButtonMacro(macroText)
    Catfish:Debug("API:SetToyButtonMacro called with macroText:", tostring(macroText))

    if InCombatLockdown() then
        Catfish:Debug("API:SetToyButtonMacro - In combat, returning false")
        return false
    end

    if not macroText or macroText == "" then
        Catfish:Debug("API:SetToyButtonMacro - Invalid macro text, returning false")
        return false
    end

    if not toyButton then
        self:InitToyButton()
    end

    -- Determine if this is a complete macro or just a toy name
    -- If it starts with "/" or contains newlines, treat as complete macro
    local finalMacro
    if macroText:sub(1, 1) == "/" or macroText:find("\n") then
        -- Complete macro text
        finalMacro = macroText
    else
        -- Just a toy name, add /cast prefix
        finalMacro = "/cast " .. macroText
    end

    -- Set the macro text for the toy
    toyButton:SetAttribute("type", "macro")
    toyButton:SetAttribute("macrotext", finalMacro)
    toyButton:Show()

    Catfish:Debug("API:SetToyButtonMacro - Button configured, macrotext:", finalMacro)
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
    -- GetItemInfo returns localized name reliably
    local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemID)
    if name then
        return {
            name = name,
            icon = texture,
            itemID = itemID,
        }
    end
    return nil
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
    if start == nil or start == 0 then
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

function API:IsPlayerSwimming()
    return IsSwimming()
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
-- The War Within Zone Check
-- ============================================

-- 检查当前是否在至暗之夜地图（递归检查父级地图）
function API:IsInTWWZone()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return false end

    local twwMapIDs = Catfish.Data.Constants.TWW_MAP_IDS

    -- 递归向上查找父级地图
    while mapID do
        -- 检查当前层级是否匹配
        for _, id in ipairs(twwMapIDs) do
            if mapID == id then
                return true
            end
        end

        -- 向上查找父级
        local mapInfo = C_Map.GetMapInfo(mapID)
        if not mapInfo or not mapInfo.parentMapID or mapInfo.parentMapID == 0 then
            break
        end

        mapID = mapInfo.parentMapID
    end

    return false
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

-- ============================================
-- Cooldown APIs
-- ============================================

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


