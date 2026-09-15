-- Joint System
-- Advanced joint constraints and muscle contraction simulation

local JOINT_SYSTEM = {}
JOINT_SYSTEM.__index = JOINT_SYSTEM

-- Joint types
JOINT_SYSTEM.TYPES = {
    BALL_SOCKET = 1,
    HINGE = 2,
    FIXED = 3,
    SPRING = 4,
    RAGDOLL = 5,
}

local Joint = {}
Joint.__index = Joint

function Joint:New(bone1Index, bone2Index, jointType)
    local self = setmetatable({}, Joint)
    
    self.Bone1Index = bone1Index
    self.Bone2Index = bone2Index
    self.Type = jointType or JOINT_SYSTEM.TYPES.BALL_SOCKET
    self.AnchorPoint = Vector(0, 0, 0)
    self.Axis = Vector(0, 0, 1)
    
    -- Constraints
    self.MaxStrain = 10000
    self.CurrentStrain = 0
    self.StiffnessFactor = EUPHORIA:GetConfig("PHYSICS.BODY_STIFFNESS")
    self.DampingFactor = EUPHORIA:GetConfig("PHYSICS.JOINT_FRICTION")
    
    -- Limits
    self.RotationLimit = 45 -- degrees
    self.LinearLimit = 50   -- units
    
    -- State
    self.IsStrained = false
    self.StrainStartTime = 0
    self.LastError = 0
    self.ErrorIntegral = 0
    
    return self
end

function Joint:CalculateConstraintForce(bone1, bone2, deltaTime)
    local error = bone2.Position - bone1.Position
    local errorDistance = error:Length()
    
    -- Check if joint is violated
    if errorDistance > self.LinearLimit then
        self.CurrentStrain = errorDistance
        self.IsStrained = true
        
        if self.StrainStartTime == 0 then
            self.StrainStartTime = CurTime()
        end
    else
        self.IsStrained = false
        self.StrainStartTime = 0
    end
    
    -- PID controller for constraint satisfaction
    local kp = self.StiffnessFactor * 100
    local kd = self.DampingFactor * 10
    local ki = 0.1
    
    local errorDerivative = (error - self.LastError) / deltaTime
    self.ErrorIntegral = self.ErrorIntegral + (error * deltaTime)
    
    local force = (error * kp) + (errorDerivative * kd) + (self.ErrorIntegral * ki)
    self.LastError = error
    
    return force:Clamp(-EUPHORIA:GetConfig("PHYSICS.MAX_FORCE"), EUPHORIA:GetConfig("PHYSICS.MAX_FORCE"))
end

function Joint:UpdateRotationConstraint(bone1, bone2)
    local angle1 = bone1.Rotation
    local angle2 = bone2.Rotation
    
    local angleDiff = angle2 - angle1
    
    -- Wrap angles
    while angleDiff.p > 180 do angleDiff.p = angleDiff.p - 360 end
    while angleDiff.p < -180 do angleDiff.p = angleDiff.p + 360 end
    while angleDiff.y > 180 do angleDiff.y = angleDiff.y - 360 end
    while angleDiff.y < -180 do angleDiff.y = angleDiff.y - 360 end
    while angleDiff.r > 180 do angleDiff.r = angleDiff.r - 360 end
    while angleDiff.r < -180 do angleDiff.r = angleDiff.r - 360 end
    
    local angleMag = math.sqrt(angleDiff.p^2 + angleDiff.y^2 + angleDiff.r^2)
    
    if angleMag > self.RotationLimit then
        local correctionFactor = (angleMag - self.RotationLimit) / angleMag
        local correction = angleDiff * correctionFactor * self.StiffnessFactor
        return correction
    end
    
    return Angle(0, 0, 0)
end

function JOINT_SYSTEM:CreateJoint(ragdoll, bone1, bone2, jointType)
    local joint = Joint:New(bone1, bone2, jointType)
    table.insert(ragdoll.Joints, joint)
    return joint
end

function JOINT_SYSTEM:SolveJoints(ragdoll, deltaTime)
    for _, joint in ipairs(ragdoll.Joints) do
        local bone1 = ragdoll.Bones[joint.Bone1Index]
        local bone2 = ragdoll.Bones[joint.Bone2Index]
        
        if bone1 and bone2 then
            local constraintForce = joint:CalculateConstraintForce(bone1, bone2, deltaTime)
            local rotationCorrection = joint:UpdateRotationConstraint(bone1, bone2)
            
            -- Apply constraint forces
            bone1.Force = bone1.Force - constraintForce
            bone2.Force = bone2.Force + constraintForce
            
            -- Apply rotation corrections
            bone1.Torque = bone1.Torque - rotationCorrection
            bone2.Torque = bone2.Torque + rotationCorrection
        end
    end
end

function JOINT_SYSTEM:CreateSkeletonJoints(ragdoll)
    -- Standard humanoid skeleton joints
    local joints = {
        -- Spine connections
        {bone1 = "ValveBiped.Bip01_Spine", bone2 = "ValveBiped.Bip01_Spine1", type = JOINT_SYSTEM.TYPES.RAGDOLL},
        {bone1 = "ValveBiped.Bip01_Spine1", bone2 = "ValveBiped.Bip01_Spine2", type = JOINT_SYSTEM.TYPES.RAGDOLL},
        {bone1 = "ValveBiped.Bip01_Spine2", bone2 = "ValveBiped.Bip01_Neck1", type = JOINT_SYSTEM.TYPES.RAGDOLL},
        {bone1 = "ValveBiped.Bip01_Neck1", bone2 = "ValveBiped.Bip01_Head", type = JOINT_SYSTEM.TYPES.HINGE},
        
        -- Left arm
        {bone1 = "ValveBiped.Bip01_L_Clavicle", bone2 = "ValveBiped.Bip01_L_UpperArm", type = JOINT_SYSTEM.TYPES.BALL_SOCKET},
        {bone1 = "ValveBiped.Bip01_L_UpperArm", bone2 = "ValveBiped.Bip01_L_Forearm", type = JOINT_SYSTEM.TYPES.HINGE},
        {bone1 = "ValveBiped.Bip01_L_Forearm", bone2 = "ValveBiped.Bip01_L_Hand", type = JOINT_SYSTEM.TYPES.HINGE},
        
        -- Right arm
        {bone1 = "ValveBiped.Bip01_R_Clavicle", bone2 = "ValveBiped.Bip01_R_UpperArm", type = JOINT_SYSTEM.TYPES.BALL_SOCKET},
        {bone1 = "ValveBiped.Bip01_R_UpperArm", bone2 = "ValveBiped.Bip01_R_Forearm", type = JOINT_SYSTEM.TYPES.HINGE},
        {bone1 = "ValveBiped.Bip01_R_Forearm", bone2 = "ValveBiped.Bip01_R_Hand", type = JOINT_SYSTEM.TYPES.HINGE},
        
        -- Left leg
        {bone1 = "ValveBiped.Bip01_L_Thigh", bone2 = "ValveBiped.Bip01_L_Calf", type = JOINT_SYSTEM.TYPES.HINGE},
        {bone1 = "ValveBiped.Bip01_L_Calf", bone2 = "ValveBiped.Bip01_L_Foot", type = JOINT_SYSTEM.TYPES.HINGE},
        
        -- Right leg
        {bone1 = "ValveBiped.Bip01_R_Thigh", bone2 = "ValveBiped.Bip01_R_Calf", type = JOINT_SYSTEM.TYPES.HINGE},
        {bone1 = "ValveBiped.Bip01_R_Calf", bone2 = "ValveBiped.Bip01_R_Foot", type = JOINT_SYSTEM.TYPES.HINGE},
    }
    
    for _, jointDef in ipairs(joints) do
        local bone1Idx = ragdoll.Entity:LookupBone(jointDef.bone1)
        local bone2Idx = ragdoll.Entity:LookupBone(jointDef.bone2)
        
        if bone1Idx and bone2Idx then
            JOINT_SYSTEM:CreateJoint(ragdoll, bone1Idx, bone2Idx, jointDef.type)
        end
    end
end

return JOINT_SYSTEM
