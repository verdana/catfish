-- Catfish - Fishing Assistant Addon
-- Init.lua - Initialization and event registration

local ADDON_NAME, Catfish = ...

-- Create global namespace
Catfish = Catfish or {}
Catfish.version = "1.0.0"

-- Create sub-namespaces
Catfish.Core = {}
Catfish.Modules = {}
Catfish.UI = {}
Catfish.Data = {}
Catfish.Locales = {}

-- Default database structure
local DEFAULT_DB = {
    enabled = true,
    sleepMode = false,
    debugMode = false,  -- 持久化调试模式
    oneKeyEnabled = true,
    doubleClickEnabled = false,
    useGiganticBobber = false,  -- 使用巨型鱼漂
    autoToys = true,  -- 自动使用玩具（木筏、鱼漂等）
    keepAutoLoot = true,  -- 保持自动拾取
    selectedBobberToy = nil,  -- 选择的浮标玩具 toyID（nil 表示不使用）
    soundManagement = false,  -- 钓鱼时自动管理声音设置
    showStatsHUD = true,  -- 显示统计 HUD
    statsOnlyFish = true,  -- 只统计鱼类
    treasureChestSound = true,  -- 宝箱出现时播放提示音
    -- 至暗之夜设置
    tww = {
        useAmaniWard = false,  -- 阿曼尼垂钓者的结界
        selectedBait = nil,  -- 选择的鱼饵 (nil/"fortune"/"octopus")
    },
    stats = {
        total = {
            catches = 0,
            time = 0,
        },
        items = {},
        zones = {},
        rareCatches = {},
    },
    toys = {
        raftMode = "random", -- "random", "specific", "none"
        selectedRaft = nil,
        bobberMode = "random", -- "random", "specific", "none"
        selectedBobber = nil,
        extraToys = {},
    },
    equipment = {
        selectedPole = nil,
        selectedHat = nil,
    },
}

local DEFAULT_CHAR_DB = {
    minimap = {
        hide = false,
        minimapPos = 45,
    },
    keybinding = nil,
    hudPosition = nil,  -- { point, x, y } for StatsHUD
}

-- Main frame for event handling
local frame = CreateFrame("Frame")

-- Helper function to deep copy tables (local to avoid conflicts)
local function CopyTable(src)
    if type(src) ~= "table" then return src end

    local seen = {}
    local function copy(s)
        if type(s) ~= "table" then return s end
        if seen[s] then return seen[s] end

        local d = {}
        seen[s] = d

        for k, v in pairs(s) do
            if type(v) == "table" then
                d[k] = copy(v)
            else
                d[k] = v
            end
        end

        return d
    end

    return copy(src)
end

-- Initialize saved variables
local function InitDB()
    if not CatfishDB then
        CatfishDB = {}
    end

    -- Merge with defaults
    for key, value in pairs(DEFAULT_DB) do
        if CatfishDB[key] == nil then
            if type(value) == "table" then
                CatfishDB[key] = CopyTable(value)
            else
                CatfishDB[key] = value
            end
        end
    end

    if not CatfishCharDB then
        CatfishCharDB = {}
    end

    for key, value in pairs(DEFAULT_CHAR_DB) do
        if CatfishCharDB[key] == nil then
            if type(value) == "table" then
                CatfishCharDB[key] = CopyTable(value)
            else
                CatfishCharDB[key] = value
            end
        end
    end

    Catfish.db = CatfishDB
    Catfish.charDB = CatfishCharDB
end

-- Register slash commands
SLASH_CATFISH1 = "/catfish"
SLASH_CATFISH2 = "/cf"

SlashCmdList["CATFISH"] = function(msg)
    msg = msg:lower():trim()

    if msg == "" or msg == "config" or msg == "options" then
        if Catfish.UI.Options then
            Catfish.UI.Options:Open()
        end
    elseif msg == "sleep" or msg == "toggle" then
        if Catfish.UI.MinimapButton then
            Catfish.UI.MinimapButton:ToggleMode()
        end
    elseif msg == "stats" then
        if Catfish.UI.StatsWindow then
            Catfish.UI.StatsWindow:Toggle()
        end
    elseif msg == "reset" then
        CatfishDB = nil
        CatfishCharDB = nil
        InitDB()
        Catfish:Print("Database reset.")
    elseif msg == "debug" then
        Catfish.db.debugMode = not Catfish.db.debugMode
        Catfish:Print("Debug mode:", Catfish.db.debugMode and "ON" or "OFF")
    elseif msg == "log" then
        if Catfish.UI.DebugLog then
            Catfish.UI.DebugLog:Toggle()
        end
    elseif msg == "toys" then
        if Catfish.Modules.Toys then
            Catfish.Modules.Toys:PrintStatus()
        end
    elseif msg == "help" then
        Catfish:Print("Commands:")
        Catfish:Print("  /catfish - Open config panel")
        Catfish:Print("  /catfish sleep - Toggle sleep/active mode")
        Catfish:Print("  /catfish stats - Show statistics")
        Catfish:Print("  /catfish toys - Show toy status")
        Catfish:Print("  /catfish debug - Toggle debug mode")
        Catfish:Print("  /catfish log - Show debug log window")
        Catfish:Print("  /catfish reset - Reset all settings")
    else
        Catfish:Print("Unknown command. Use /catfish help for available commands.")
    end
end

-- Print function
function Catfish:Print(...)
    print("|cFF00FF00[Catfish]|r", ...)
end

-- Debug print
function Catfish:Debug(...)
    if self.db and self.db.debugMode then
        print("|cFFFFAA00[Catfish]|r", ...)
    end
end

-- Event registration
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, arg1, ...)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        InitDB()
        Catfish:Debug("Addon loaded, database initialized")

        -- Initialize API (secure buttons, etc.)
        if Catfish.API and Catfish.API.InitInteractButton then
            Catfish.API:InitInteractButton()
        end
        if Catfish.API and Catfish.API.InitToyButton then
            Catfish.API:InitToyButton()
        end

        -- Initialize modules
        if Catfish.Core.Events then
            Catfish.Core.Events:Init()
        end
        if Catfish.Modules.OneKey then
            Catfish.Modules.OneKey:Init()
        end
        if Catfish.Modules.ItemManager then
            Catfish.Modules.ItemManager:Init()
        end
        if Catfish.Modules.DoubleClick then
            Catfish.Modules.DoubleClick:Init()
        end
        if Catfish.Modules.Equipment then
            Catfish.Modules.Equipment:Init()
        end
        if Catfish.Modules.Toys then
            Catfish.Modules.Toys:Init()
        end
        if Catfish.Modules.Statistics then
            Catfish.Modules.Statistics:Init()
        end
        if Catfish.Modules.LureManager then
            Catfish.Modules.LureManager:Init()
        end
        if Catfish.Modules.SoundManager then
            Catfish.Modules.SoundManager:Init()
        end
        if Catfish.Modules.TWWItems then
            Catfish.Modules.TWWItems:Init()
        end

        -- Initialize UI
        if Catfish.UI.MinimapButton then
            Catfish.UI.MinimapButton:Init()
        end
        if Catfish.UI.DebugLog then
            Catfish.UI.DebugLog:Init()
        end
        -- Initialize Options panel at startup so it appears in ESC->Options->AddOns
        if Catfish.UI.Options then
            Catfish.UI.Options:Init()
        end
        -- Initialize StatsHUD
        if Catfish.UI.StatsHUD then
            Catfish.UI.StatsHUD:Init()
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        Catfish:Debug("Player entering world")

        -- Check for fishing skill (use C_Spell API or pcall for safety)
        local success, fishingSpell = pcall(function()
            if C_Spell and C_Spell.GetSpellInfo then
                local info = C_Spell.GetSpellInfo(7620)
                return info and info.name
            elseif GetSpellInfo then
                return GetSpellInfo(7620)
            end
            return nil
        end)
        if success and fishingSpell then
            Catfish.hasFishingSkill = true
            -- Catfish:Debug("Fishing skill found:", fishingSpell)
        else
            Catfish.hasFishingSkill = false
            Catfish:Debug("No fishing skill detected (or spell data not loaded yet)")
        end

        -- Initialize toys data
        if Catfish.Modules.Toys then
            Catfish.Modules.Toys:ScanToys()
        end

        -- Update OneKey binding after a short delay to allow item data to load
        C_Timer.After(1.0, function()
            if Catfish.Modules.OneKey then
                Catfish.Modules.OneKey:UpdateBinding(0)
            end
        end)

    elseif event == "PLAYER_LOGIN" then
        Catfish:Debug("Player logged in")

        -- Double-check fishing skill at login
        local success, fishingSpell = pcall(function()
            if C_Spell and C_Spell.GetSpellInfo then
                local info = C_Spell.GetSpellInfo(7620)
                return info and info.name
            elseif GetSpellInfo then
                return GetSpellInfo(7620)
            end
            return nil
        end)
        if success and fishingSpell then
            Catfish.hasFishingSkill = true
            Catfish:Debug("Fishing skill confirmed:", fishingSpell)
        end

        -- Preload Gigantic Bobber item data (item ID 202207)
        -- This triggers the client to request the data from the server
        -- so it's available when the player starts fishing
        if GetItemInfo then
            local itemName = GetItemInfo(202207)
            if itemName then
                Catfish:Debug("Preloaded Gigantic Bobber item:", itemName)
            else
                Catfish:Debug("Gigantic Bobber item data not yet available, will be loaded on first use")
            end
        end
    end
end)

-- Export namespace
_G.Catfish = Catfish
