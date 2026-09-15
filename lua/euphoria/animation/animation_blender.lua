-- Animation Blender System
-- Blends between multiple animations and bone transformations

local ANIMATION_BLENDER = {}
ANIMATION_BLENDER.__index = ANIMATION_BLENDER

function ANIMATION_BLENDER:New(ragdoll)
    local self = setmetatable({}, ANIMATION_BLENDER)
    
    self.Ragdoll = ragdoll
    self.ActiveAnimations = {}
    self.BlendSpeed = EUPHORIA:GetConfig("ANIMATION.BLEND_SPEED")
    self.IdleState = "idle_stand"
    self.CurrentState = self.IdleState
    self.StateTime = 0
    self.BreathingCycle = 0
    
    return self
end

function ANIMATION_BLENDER:Update(ragdoll, deltaTime)
    self.StateTime = self.StateTime + deltaTime
    self.BreathingCycle = self.BreathingCycle + deltaTime
    
    -- Update animation state based on activity
    self:UpdateAnimationState(ragdoll, deltaTime)
    
    -- Blend animations
    self:BlendAnimations(ragdoll, deltaTime)
    
    -- Apply breathing motion
    self:ApplyBreathing(ragdoll, deltaTime)
end

function ANIMATION_BLENDER:UpdateAnimationState(ragdoll, deltaTime)
    if ragdoll.IsRagdolled then
        self.CurrentState = "ragdoll"
    elseif not ragdoll.Perception.GroundContact then
        self.CurrentState = "falling"
    else
        local velocity = ragdoll.Entity:GetVelocity():Length()
        
        if velocity > 200 then
            self.CurrentState = "running"
        elseif velocity > 50 then
            self.CurrentState = "walking"
        else
            self.CurrentState = self.IdleState
        end
    end
end

function ANIMATION_BLENDER:BlendAnimations(ragdoll, deltaTime)
    local blendFactor = math.min(self.BlendSpeed * deltaTime, 1.0)
    
    -- Store current bone positions
    for boneIdx, bone in ipairs(ragdoll.Bones) do
        if not bone.BlendedPos then
            bone.BlendedPos = bone.Position
        end
        
        -- Smooth blend between positions
        bone.BlendedPos = bone.BlendedPos + (bone.Position - bone.BlendedPos) * blendFactor
    end
end

function ANIMATION_BLENDER:ApplyBreathing(ragdoll, deltaTime)
    if ragdoll.IsRagdolled or not ragdoll.IsAlive then return end
    
    local chestBone = ragdoll.Entity:LookupBone("ValveBiped.Bip01_Spine2")
    if not chestBone then return end
    
    local breathingCycle = EUPHORIA:GetConfig("ANIMATION.BREATHING_CYCLE")
    local breathAmount = math.sin((self.BreathingCycle / breathingCycle) * math.pi * 2) * 2
    
    if ragdoll.Bones[chestBone] then
        -- Apply subtle chest movement
        ragdoll.Bones[chestBone].Position.z = ragdoll.Bones[chestBone].Position.z + breathAmount
    end
end

function ANIMATION_BLENDER:PlayAnimation(animName, speed)
    table.insert(self.ActiveAnimations, {
        Name = animName,
        Speed = speed or 1.0,
        StartTime = CurTime(),
        Duration = 2.0,
    })
end

function ANIMATION_BLENDER:GetCurrentState()
    return self.CurrentState
end

return ANIMATION_BLENDER
