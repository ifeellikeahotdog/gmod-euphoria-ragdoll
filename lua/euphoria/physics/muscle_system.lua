-- Advanced Muscle Contraction System
-- Simulates muscular effort for balance and movement

local MUSCLE_SYSTEM = {}
MUSCLE_SYSTEM.__index = MUSCLE_SYSTEM

function MUSCLE_SYSTEM:New(ragdoll)
    local self = setmetatable({}, MUSCLE_SYSTEM)
    
    self.Ragdoll = ragdoll
    self.MuscleGroups = {}
    self.MuscleActivation = {}
    self.Fatigue = 0
    self.MuscleRecoveryRate = 0.1
    
    self:InitializeMuscleGroups()
    return self
end

function MUSCLE_SYSTEM:InitializeMuscleGroups()
    self.MuscleGroups = {
        -- Leg muscles
        LeftQuads = {bones = {"ValveBiped.Bip01_L_Thigh"}, strength = 1.0},
        RightQuads = {bones = {"ValveBiped.Bip01_R_Thigh"}, strength = 1.0},
        LeftHamstrings = {bones = {"ValveBiped.Bip01_L_Calf"}, strength = 0.8},
        RightHamstrings = {bones = {"ValveBiped.Bip01_R_Calf"}, strength = 0.8},
        
        -- Core muscles
        Abs = {bones = {"ValveBiped.Bip01_Spine", "ValveBiped.Bip01_Spine1"}, strength = 1.2},
        Back = {bones = {"ValveBiped.Bip01_Spine2"}, strength = 1.1},
        
        -- Arm muscles
        LeftBiceps = {bones = {"ValveBiped.Bip01_L_UpperArm"}, strength = 0.9},
        RightBiceps = {bones = {"ValveBiped.Bip01_R_UpperArm"}, strength = 0.9},
    }
end

function MUSCLE_SYSTEM:ActivateMuscle(groupName, intensity)
    if not self.MuscleGroups[groupName] then return end
    
    self.MuscleActivation[groupName] = math.min(intensity, 1.0)
end

function MUSCLE_SYSTEM:Update(deltaTime)
    -- Update muscle fatigue
    local totalActivation = 0
    for _, activation in pairs(self.MuscleActivation) do
        totalActivation = totalActivation + activation
    end
    
    if totalActivation > 0 then
        self.Fatigue = math.min(1.0, self.Fatigue + (totalActivation * deltaTime * 0.5))
    else
        self.Fatigue = math.max(0, self.Fatigue - (self.MuscleRecoveryRate * deltaTime))
    end
    
    -- Apply muscle forces
    for groupName, activation in pairs(self.MuscleActivation) do
        local group = self.MuscleGroups[groupName]
        if group then
            for _, boneName in ipairs(group.bones) do
                local boneIdx = self.Ragdoll.Entity:LookupBone(boneName)
                if boneIdx then
                    local force = group.strength * activation * (1 - self.Fatigue * 0.3) * 100
                    self.Ragdoll:ApplyForce(boneIdx, Vector(0, 0, force))
                end
            end
        end
    end
    
    -- Reset activation
    self.MuscleActivation = {}
end

return MUSCLE_SYSTEM
