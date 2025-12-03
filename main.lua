local TimeMagic = RegisterMod("Time Magic", 1)
TimeMagic.Version = "1.0.0"

TimeMagic.RenderTimeScale = 1.0
TimeMagic.GameTimeScale = 1.0
TimeMagic.LastTime = Isaac.GetTime()
TimeMagic.LastRenderFrame = Isaac.GetFrameCount()
TimeMagic.LastGameFrame = Game():GetFrameCount()
TimeMagic.RenderTimesPerSecond = 60
TimeMagic.GameTimesPerSecond = 30
TimeMagic.Counter = 0
TimeMagic.Period = 2    -- should be even number
TimeMagic:AddCallback(ModCallbacks.MC_POST_RENDER, function(self)
    self.Counter = self.Counter + 1
    if self.Counter >= self.Period then
        local currentTime = Isaac.GetTime()
        local currentRenderFrame = Isaac.GetFrameCount()
        local currentGameFrame = Game():GetFrameCount()

        local deltaTime = currentTime - self.LastTime
        local deltaRenderFrames = currentRenderFrame - self.LastRenderFrame
        local deltaGameFrames = currentGameFrame - self.LastGameFrame

        self.LastTime = currentTime
        self.LastRenderFrame = currentRenderFrame
        self.LastGameFrame = currentGameFrame

        self.RenderTimeScale = 1e3 * deltaRenderFrames / deltaTime / self.RenderTimesPerSecond
        self.GameTimeScale = 1e3 * deltaGameFrames / deltaTime / self.GameTimesPerSecond

        self.Counter = 0
    end
end)

TimeMagic.TargetTimeScale = 1.0
function TimeMagic:SetTimeScale(scale)
    scale = scale and tonumber(scale) or 1.0
    self.TargetTimeScale = scale
end

TimeMagic.SpeedUpLock = false
TimeMagic.SpeedUpUpdateTimes = 1
function TimeMagic:SpeedUp()
    if self.SpeedUpLock then return end
    if Game():IsPaused() then return end
    if self.TargetTimeScale > 1.0 then
        if self.TargetTimeScale > self.GameTimeScale then
            self.SpeedUpUpdateTimes = self.SpeedUpUpdateTimes + 1
        elseif self.TargetTimeScale < self.GameTimeScale then
            self.SpeedUpUpdateTimes = math.max(1.0, self.SpeedUpUpdateTimes-1)
        end
        self.SpeedUpLock = true
        for i = 1, math.floor(self.SpeedUpUpdateTimes) do
            Game():Update()
        end
        self.SpeedUpLock = false
    end
end

TimeMagic.SpeedDownUpdateTimes = 1
TimeMagic.SpeedDownLock = false
function TimeMagic:SpeedDown()
    if self.SpeedDownLock then return end
    if Game():IsPaused() then return end
    if self.TargetTimeScale < 1.0 then
        if self.TargetTimeScale < self.RenderTimeScale then
            self.SpeedDownUpdateTimes = self.SpeedDownUpdateTimes * 1.2
        elseif self.TargetTimeScale > self.RenderTimeScale then
            self.SpeedDownUpdateTimes = math.max(1.0, self.SpeedDownUpdateTimes/2)
        end
        self.SpeedDownLock = true
        for i = 1, math.floor(self.SpeedDownUpdateTimes) do
            Isaac.GetRoomEntities()
        end
        self.SpeedDownLock = false
    end
end

TimeMagic:AddCallback(ModCallbacks.MC_POST_UPDATE, function(self)
    self:SpeedUp()
end)

TimeMagic:AddCallback(ModCallbacks.MC_POST_RENDER, function(self)
    self:SpeedDown()
end)

-----------------------------------------------------------------------------

TimeScaler = {}
setmetatable(TimeScaler, {
    __index = {
        SetTimeScale = function(self, scale)
            TimeMagic:SetTimeScale(scale)
        end,
        GetRenderTimeScale = function(self)
            return TimeMagic.RenderTimeScale
        end,
        GetGameTimeScale = function(self)
            return TimeMagic.GameTimeScale
        end
    },
    __newindex = function()end,
    __tostring = function()return 'TimeScaler v'..TimeMagic.Version..' - Keye3Tuido\n' end,
    __metatable = false
})

Isaac.ConsoleOutput(tostring(TimeScaler))