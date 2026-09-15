-- Environment System
-- Handles environmental forces and interactions

local ENVIRONMENT = {}
ENVIRONMENT.__index = ENVIRONMENT

function ENVIRONMENT:New(ragdoll)
    local self = setmetatable({}, ENVIRONMENT)
    
    self.Ragdoll = ragdoll
    self.WindForce = Vector(0, 0, 0)
    self.CurrentWaterLevel = 0
    self.IsInWater = false
    self.WaterDrag = 0.5
    
    return self
end

function ENVIRONMENT:Update(ragdoll, deltaTime)
    self:CheckWaterLevel(ragdoll)
    self:ApplyEnvironmentalForces(ragdoll, deltaTime)
end

function ENVIRONMENT:CheckWaterLevel(ragdoll)
    local entityPos = ragdoll.Entity:GetPos()
    local waterLevel = GetWaterLevel(entityPos)
    
    self.CurrentWaterLevel = waterLevel
    self.IsInWater = waterLevel > entityPos.z - 50
end

function ENVIRONMENT:ApplyEnvironmentalForces(ragdoll, deltaTime)
    if self.IsInWater then
        -- Apply water drag to all bones
        for _, bone in ipairs(ragdoll.Bones) do
            bone.Velocity = bone.Velocity * (1 - self.WaterDrag)
            
            -- Apply buoyancy
            local buoyantForce = Vector(0, 0, 500 * bone.Mass)
            bone.Force = bone.Force + buoyantForce
        end
    end
    
    -- Apply wind (if any)
    if self.WindForce:Length() > 0 then
        for _, bone in ipairs(ragdoll.Bones) do
            bone.Force = bone.Force + self.WindForce * bone.Mass * 0.1
        end
    end
end

function ENVIRONMENT:SetWind(windVector)
    self.WindForce = windVector
end

return ENVIRONMENT
