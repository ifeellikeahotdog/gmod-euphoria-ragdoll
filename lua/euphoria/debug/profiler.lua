-- Performance Profiler
-- Monitors and optimizes system performance

local PROFILER = {}
PROFILER.__index = PROFILER

function PROFILER:New()
    local self = setmetatable({}, PROFILER)
    
    self.Metrics = {}
    self.SampleSize = 100
    self.CurrentSample = 0
    
    return self
end

function PROFILER:StartMeasure(name)
    if not self.Metrics[name] then
        self.Metrics[name] = {
            samples = {},
            total = 0,
            min = math.huge,
            max = 0,
        }
    end
    
    self.Metrics[name].startTime = SysTime()
end

function PROFILER:EndMeasure(name)
    if not self.Metrics[name] then return end
    
    local elapsed = (SysTime() - self.Metrics[name].startTime) * 1000 -- Convert to ms
    
    table.insert(self.Metrics[name].samples, elapsed)
    if #self.Metrics[name].samples > self.SampleSize then
        table.remove(self.Metrics[name].samples, 1)
    end
    
    self.Metrics[name].total = self.Metrics[name].total + elapsed
    self.Metrics[name].min = math.min(self.Metrics[name].min, elapsed)
    self.Metrics[name].max = math.max(self.Metrics[name].max, elapsed)
end

function PROFILER:GetStats(name)
    if not self.Metrics[name] then return nil end
    
    local metric = self.Metrics[name]
    local avg = metric.total / #metric.samples
    
    return {
        average = avg,
        min = metric.min,
        max = metric.max,
        samples = #metric.samples,
    }
end

function PROFILER:PrintStats()
    print("\n=== Euphoria Performance Stats ===")
    for name, metric in pairs(self.Metrics) do
        if #metric.samples > 0 then
            local avg = metric.total / #metric.samples
            print(string.format("%s: %.3f ms (min: %.3f, max: %.3f)", name, avg, metric.min, metric.max))
        end
    end
    print("================================\n")
end

return PROFILER
