-- Catfish - SoundManager.lua
-- 管理钓鱼时的声音设置

local ADDON_NAME, Catfish = ...

local SoundManager = {}
Catfish.Modules.SoundManager = SoundManager

-- 保存的原始设置
SoundManager.savedSettings = nil
SoundManager.enabled = false

-- ============================================
-- 默认声音设置（激活时应用）
-- ============================================

local FISHING_SOUND_SETTINGS = {
    backgroundSound = true,    -- 开启后台声音
    musicEnabled = false,      -- 关闭音乐
    sfxVolume = 1.0,           -- 音效音量最大 (0.0 - 1.0)
}

-- ============================================
-- CVar 名称常量
-- ============================================

local CVAR = {
    BACKGROUND_SOUND = "Sound_EnableSoundWhenInGame",
    MUSIC_ENABLED = "Sound_EnableMusic",
    MUSIC_VOLUME = "Sound_MusicVolume",
    SFX_VOLUME = "Sound_SFXVolume",
    MASTER_VOLUME = "Sound_MasterVolume",
}

-- ============================================
-- 工具函数
-- ============================================

local function GetCVarSafe(name)
    -- 使用新版 API 或旧版 API
    if C_CVar and C_CVar.GetCVar then
        return C_CVar.GetCVar(name)
    else
        return GetCVar(name)
    end
end

local function SetCVarSafe(name, value)
    -- 转换为字符串（CVar 需要）
    local strValue = tostring(value)

    -- 使用新版 API 或旧版 API
    if C_CVar and C_CVar.SetCVar then
        C_CVar.SetCVar(name, strValue)
    else
        SetCVar(name, strValue)
    end

    Catfish:Debug("SoundManager: SetCVar", name, "=", strValue)
end

-- ============================================
-- 保存当前声音设置
-- ============================================

function SoundManager:SaveCurrentSettings()
    self.savedSettings = {
        backgroundSound = GetCVarSafe(CVAR.BACKGROUND_SOUND) == "1",
        musicEnabled = GetCVarSafe(CVAR.MUSIC_ENABLED) == "1",
        musicVolume = tonumber(GetCVarSafe(CVAR.MUSIC_VOLUME)) or 1.0,
        sfxVolume = tonumber(GetCVarSafe(CVAR.SFX_VOLUME)) or 1.0,
        masterVolume = tonumber(GetCVarSafe(CVAR.MASTER_VOLUME)) or 1.0,
    }

    Catfish:Debug("SoundManager: Saved settings:", self.savedSettings.backgroundSound,
        self.savedSettings.musicEnabled, self.savedSettings.sfxVolume)

    return self.savedSettings
end

-- ============================================
-- 恢复之前保存的声音设置
-- ============================================

function SoundManager:RestoreSettings()
    if not self.savedSettings then
        Catfish:Debug("SoundManager: No saved settings to restore")
        return
    end

    SetCVarSafe(CVAR.BACKGROUND_SOUND, self.savedSettings.backgroundSound and "1" or "0")
    SetCVarSafe(CVAR.MUSIC_ENABLED, self.savedSettings.musicEnabled and "1" or "0")
    SetCVarSafe(CVAR.MUSIC_VOLUME, self.savedSettings.musicVolume)
    SetCVarSafe(CVAR.SFX_VOLUME, self.savedSettings.sfxVolume)
    SetCVarSafe(CVAR.MASTER_VOLUME, self.savedSettings.masterVolume)

    Catfish:Debug("SoundManager: Restored settings")

    -- 清除保存的设置
    self.savedSettings = nil
end

-- ============================================
-- 应用钓鱼声音设置
-- ============================================

function SoundManager:ApplyFishingSettings()
    -- 先保存当前设置
    self:SaveCurrentSettings()

    -- 应用钓鱼时的设置
    SetCVarSafe(CVAR.BACKGROUND_SOUND, "1")  -- 开启后台声音
    SetCVarSafe(CVAR.MUSIC_ENABLED, "0")     -- 关闭音乐
    SetCVarSafe(CVAR.SFX_VOLUME, FISHING_SOUND_SETTINGS.sfxVolume)  -- 音效最大

    Catfish:Debug("SoundManager: Applied fishing settings")
end

-- ============================================
-- 激活时调用
-- ============================================

function SoundManager:OnActivate()
    if not self.enabled then return end

    Catfish:Debug("SoundManager: OnActivate")
    self:ApplyFishingSettings()
end

-- ============================================
-- 休眠时调用
-- ============================================

function SoundManager:OnSleep()
    if not self.enabled then return end

    Catfish:Debug("SoundManager: OnSleep")
    self:RestoreSettings()
end

-- ============================================
-- 启用/禁用管理
-- ============================================

function SoundManager:SetEnabled(enabled)
    self.enabled = enabled

    -- 如果禁用时正在激活状态，恢复设置
    if not enabled and self.savedSettings then
        self:RestoreSettings()
    end

    Catfish:Debug("SoundManager: Enabled =", enabled)
end

function SoundManager:IsEnabled()
    return self.enabled
end

-- ============================================
-- 初始化
-- ============================================

function SoundManager:Init()
    self.enabled = Catfish.db.soundManagement or false
    Catfish:Debug("SoundManager: Initialized, enabled =", self.enabled)
end