-- Catfish - StatusPoller.lua
-- 状态变化检测器：在需要的时间窗口内轮询状态变化
-- 解决游泳状态变化没有事件触发的问题

local ADDON_NAME, Catfish = ...

local StatusPoller = {}
Catfish.Core.StatusPoller = StatusPoller

-- ============================================
-- 状态
-- ============================================

local pollFrame = nil
local isPolling = false
local pollStartTime = 0
local pollReason = ""
local lastSwimmingState = nil
local lastPollTime = 0

-- ============================================
-- 配置
-- ============================================

local MAX_POLL_DURATION = 8   -- 最长轮询时间（秒），足够从水下浮到水面
local POLL_INTERVAL = 0.05    -- 轮询间隔（秒），20帧检测一次

-- ============================================
-- Public API
-- ============================================

-- 启动轮询
-- @param reason string - 启动原因，用于调试
function StatusPoller:StartPolling(reason)
    reason = reason or "unknown"
    
    -- 如果已经在轮询，检查是否需要更新原因
    if isPolling then
        Catfish:Debug("StatusPoller: already polling, existing reason:", pollReason, "new reason:", reason)
        -- 可以选择更新原因或忽略
        return
    end
    
    isPolling = true
    pollStartTime = GetTime()
    lastSwimmingState = IsSwimming()
    pollReason = reason
    lastPollTime = 0
    
    Catfish:Debug("StatusPoller: START - reason:", pollReason, "swimming:", tostring(lastSwimmingState))
    
    -- 创建或显示轮询帧
    if not pollFrame then
        pollFrame = CreateFrame("Frame")
        pollFrame:SetScript("OnUpdate", function(self, elapsed)
            StatusPoller:OnUpdate(elapsed)
        end)
    end
    pollFrame:Show()
end

-- 停止轮询
function StatusPoller:StopPolling()
    if not isPolling then return end
    
    isPolling = false
    pollReason = ""
    if pollFrame then
        pollFrame:Hide()
    end
    
    Catfish:Debug("StatusPoller: STOP")
end

-- 检查是否正在轮询
function StatusPoller:IsPolling()
    return isPolling
end

-- ============================================
-- OnUpdate 处理
-- ============================================

function StatusPoller:OnUpdate(elapsed)
    if not isPolling then return end
    
    local now = GetTime()
    
    -- 限制轮询频率
    if now - lastPollTime < POLL_INTERVAL then
        return
    end
    lastPollTime = now
    
    -- 检查超时
    if now - pollStartTime > MAX_POLL_DURATION then
        Catfish:Debug("StatusPoller: timeout after", MAX_POLL_DURATION, "seconds, stopping")
        self:StopPolling()
        return
    end
    
    -- 检测游泳状态变化
    local currentSwimming = IsSwimming()
    if currentSwimming ~= lastSwimmingState then
        Catfish:Debug("StatusPoller: SWIMMING STATE CHANGED:", 
            tostring(lastSwimmingState), "->", tostring(currentSwimming), 
            "reason:", pollReason)
        
        lastSwimmingState = currentSwimming
        
        -- 触发状态变化回调
        self:OnSwimmingStateChanged(currentSwimming)
    end
    
    -- 检测木筏BUFF变化
    local hasRaftBuff = false
    if Catfish.Modules.ItemManager then
        hasRaftBuff = Catfish.Modules.ItemManager:HasRaftBuff()
    end
    
    -- 如果不在游泳且有木筏BUFF，说明已经站上木筏，可以停止轮询
    if not currentSwimming and hasRaftBuff then
        Catfish:Debug("StatusPoller: detected on raft (not swimming, has buff), stopping")
        self:StopPolling()
        return
    end
    
    -- 如果没有木筏BUFF且不在游泳，可能是木筏消失了
    if not currentSwimming and not hasRaftBuff then
        -- 检查是否是从木筏上掉下来了
        if pollReason:find("raft") then
            Catfish:Debug("StatusPoller: raft may have disappeared, stopping")
            self:StopPolling()
            return
        end
    end
end

-- ============================================
-- 状态变化回调
-- ============================================

function StatusPoller:OnSwimmingStateChanged(isSwimming)
    -- 通知 OneKey 模块更新绑定
    if Catfish.Modules.OneKey then
        if Catfish.Modules.OneKey.OnSwimmingStateChanged then
            Catfish.Modules.OneKey:OnSwimmingStateChanged(isSwimming)
        else
            -- 兼容：直接调用 UpdateBinding
            Catfish.Modules.OneKey:UpdateBinding("OnSwimmingStateChanged")
        end
    end
    
    -- 通知状态机（如果有）
    if Catfish.StateMachine and Catfish.StateMachine.OnSwimmingStateChanged then
        Catfish.StateMachine:OnSwimmingStateChanged(isSwimming)
    end
end

-- ============================================
-- 初始化
-- ============================================

function StatusPoller:Init()
    -- 初始化游泳状态
    lastSwimmingState = IsSwimming()
    Catfish:Debug("StatusPoller: initialized, current swimming:", tostring(lastSwimmingState))
end