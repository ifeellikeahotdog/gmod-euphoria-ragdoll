-- Ragdoll Base Class
-- Foundation for all ragdoll entities with physics simulation

local RAGDOLL = {}
RAGDOLL.__index = RAGDOLL
RAGDOLL.Type = "EuphoriaRagdoll"

-- Physics constraints
RAGDOLL.Bones = {}
RAGDOLL.Joints = {}
RAGDOLL.Constraints = {}
RAGDOLL.MassData = {}
RAGDOLL.PhysicsData = {}

-- State variables
RAGDOLL.IsAlive = false
RAGDOLL.IsRagdolled = false
RAGDOLL.LastDamageTime = 0
RAGDOLL.LastImpactForce = Vector(0, 0, 0)
RAGDOLL.CurrentVelocity = Vector(0, 0, 0)
RAGDOLL.AngularVelocity = Angle(0, 0, 0)

function RAGDOLL:New(ent)
    local self = setmetatable({}, RAGDOLL)
    
    self.Entity = ent
    self.IsAlive = true
    self.IsRagdolled = false
    self.Bones = {}
    self.Joints = {}
    self.Constraints = {}
    self.MassData = {}
    self.PhysicsData = {
        TotalMass = 0,
        CenterOfMass = Vector(0, 0, 0),
        Inertia = 0,
    }
    self.StabilityFactor = 1.0
    self.BalanceTimer = 0
    self.ImpactHistory = {}
    self.StrainedJoints = {}
    
    return self
end

function RAGDOLL:InitializeBones(boneCount)
    self.Bones = {}
    self.MassData = {}
    
    for i = 0, boneCount - 1 do
        local bone = {
            Index = i,
            Name = self.Entity:GetBoneName(i),
            Position = self.Entity:GetBonePosition(i),
            Rotation = self.Entity:GetBoneMatrix(i):GetAngles(),
            Mass = EUPHORIA:GetConfig("RAGDOLL.TORSO_MASS") * (EUPHORIA:GetConfig("RAGDOLL.LIMB_MASS_RATIO")),
            Velocity = Vector(0, 0, 0),
            AngularVelocity = Angle(0, 0, 0),
            Force = Vector(0, 0, 0),
            Torque = Angle(0, 0, 0),
            IsConstrained = false,
            BreakForce = 5000,
        }
        
        -- Adjust mass based on bone type
        if string.find(bone.Name, "chest") or string.find(bone.Name, "torso") then
            bone.Mass = EUPHORIA:GetConfig("RAGDOLL.TORSO_MASS")
        elseif string.find(bone.Name, "head") then
            bone.Mass = EUPHORIA:GetConfig("RAGDOLL.TORSO_MASS") * 0.5
        end
        
        self.Bones[i] = bone
        self.MassData[i] = bone.Mass
    end
    
    self:CalculateMassProperties()
end

function RAGDOLL:CalculateMassProperties()
    local totalMass = 0
    local com = Vector(0, 0, 0)
    local inertia = 0
    
    for _, bone in ipairs(self.Bones) do
        totalMass = totalMass + bone.Mass
        com = com + (bone.Position * bone.Mass)
        inertia = inertia + (bone.Mass * bone.Position:LengthSqr())
    end
    
    if totalMass > 0 then
        com = com / totalMass
    end
    
    self.PhysicsData.TotalMass = totalMass
    self.PhysicsData.CenterOfMass = com
    self.PhysicsData.Inertia = inertia
end

function RAGDOLL:ApplyForce(boneIndex, force, position)
    if not self.Bones[boneIndex] then return end
    
    local bone = self.Bones[boneIndex]
    bone.Force = bone.Force + force
    
    -- Calculate torque from off-center force
    if position then
        local r = position - bone.Position
        local torqueMag = r:Cross(force)
        bone.Torque = bone.Torque + Angle(torqueMag.x, torqueMag.y, torqueMag.z)
    end
    
    -- Track impact
    table.insert(self.ImpactHistory, {
        Time = CurTime(),
        Force = force:Length(),
        BoneIndex = boneIndex,
    })
    
    if #self.ImpactHistory > 10 then
        table.remove(self.ImpactHistory, 1)
    end
end

function RAGDOLL:UpdatePhysics(deltaTime)
    deltaTime = deltaTime or 0.01
    local gravity = EUPHORIA:GetConfig("PHYSICS.GRAVITY")
    
    for _, bone in ipairs(self.Bones) do
        -- Apply gravity
        bone.Force = bone.Force + Vector(0, 0, -gravity * bone.Mass)
        
        -- Update velocity
        local acceleration = bone.Force / bone.Mass
        bone.Velocity = bone.Velocity + (acceleration * deltaTime)
        
        -- Apply air resistance
        local resistance = EUPHORIA:GetConfig("PHYSICS.AIR_RESISTANCE")
        bone.Velocity = bone.Velocity * (1 - resistance)
        
        -- Update position
        bone.Position = bone.Position + (bone.Velocity * deltaTime)
        
        -- Reset forces
        bone.Force = Vector(0, 0, 0)
    end
    
    self:CalculateMassProperties()
end

function RAGDOLL:CheckStrainedJoints()
    self.StrainedJoints = {}
    
    for _, joint in ipairs(self.Joints) do
        if joint.CurrentStrain > joint.MaxStrain * 0.8 then
            table.insert(self.StrainedJoints, joint)
        end
    end
    
    return self.StrainedJoints
end

function RAGDOLL:GetImpactForce()
    local totalForce = 0
    for _, impact in ipairs(self.ImpactHistory) do
        if CurTime() - impact.Time < 0.5 then
            totalForce = totalForce + impact.Force
        end
    end
    return totalForce
end

function RAGDOLL:ApplyDamping(dampingFactor)
    dampingFactor = dampingFactor or EUPHORIA:GetConfig("PHYSICS.COLLISION_DAMPING")
    
    for _, bone in ipairs(self.Bones) do
        bone.Velocity = bone.Velocity * (1 - dampingFactor)
    end
end

function EUPHORIA:CreateRagdoll(ent)
    local ragdoll = RAGDOLL:New(ent)
    EUPHORIA.RAGDOLLS[ent:EntIndex()] = ragdoll
    return ragdoll
end

return RAGDOLL
