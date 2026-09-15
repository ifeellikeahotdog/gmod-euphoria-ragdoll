-- World Interaction System
-- Handles interaction with world geometry and environment

local WORLD_INTERACTION = {}
WORLD_INTERACTION.__index = WORLD_INTERACTION

function WORLD_INTERACTION:New(ragdoll)
    local self = setmetatable({}, WORLD_INTERACTION)
    
    self.Ragdoll = ragdoll
    self.SurfaceContactPoints = {}
    self.LeaningAngle = EUPHORIA:GetConfig("INTERACTION.LEAN_ANGLE")
    self.StepHeight = EUPHORIA:GetConfig("INTERACTION.STEP_HEIGHT")
    
    return self
end

function WORLD_INTERACTION:Update(ragdoll, deltaTime)
    self:FindContactPoints(ragdoll)
    self:HandleLeaningAgainstWalls(ragdoll, deltaTime)
    self:HandleStairs(ragdoll, deltaTime)
end

function WORLD_INTERACTION:FindContactPoints(ragdoll)
    self.SurfaceContactPoints = {}
    
    for boneIdx, bone in ipairs(ragdoll.Bones) do
        local tr = util.TraceLine({
            start = bone.Position,
            endpos = bone.Position + Vector(0, 0, -50),
            filter = ragdoll.Entity
        })
        
        if tr.Hit then
            table.insert(self.SurfaceContactPoints, {
                BoneIndex = boneIdx,
                Position = tr.HitPos,
                Normal = tr.HitNormal,
                Distance = bone.Position:Distance(tr.HitPos),
            })
        end
    end
end

function WORLD_INTERACTION:HandleLeaningAgainstWalls(ragdoll, deltaTime)
    local chestBone = ragdoll.Entity:LookupBone("ValveBiped.Bip01_Spine2")
    if not chestBone then return end
    
    local chestPos = ragdoll.Entity:GetBonePosition(chestBone)
    
    -- Check for walls in front
    local tr = util.TraceLine({
        start = chestPos,
        endpos = chestPos + ragdoll.Entity:GetAngles():Forward() * 50,
        filter = ragdoll.Entity
    })
    
    if tr.Hit and not ragdoll.IsRagdolled then
        -- Lean against wall
        local pushAway = tr.HitNormal * 100
        ragdoll:ApplyForce(chestBone, pushAway)
    end
end

function WORLD_INTERACTION:HandleStairs(ragdoll, deltaTime)
    -- Check if ragdoll is trying to climb stairs
    local footBoneLeft = ragdoll.Entity:LookupBone("ValveBiped.Bip01_L_Foot")
    local footBoneRight = ragdoll.Entity:LookupBone("ValveBiped.Bip01_R_Foot")
    
    if not footBoneLeft or not footBoneRight then return end
    
    local leftFootPos = ragdoll.Entity:GetBonePosition(footBoneLeft)
    local rightFootPos = ragdoll.Entity:GetBonePosition(footBoneRight)
    
    -- Check for steps
    local leftTr = util.TraceLine({
        start = leftFootPos + Vector(0, 0, self.StepHeight),
        endpos = leftFootPos + ragdoll.Entity:GetAngles():Forward() * 20 + Vector(0, 0, self.StepHeight),
        filter = ragdoll.Entity
    })
    
    local rightTr = util.TraceLine({
        start = rightFootPos + Vector(0, 0, self.StepHeight),
        endpos = rightFootPos + ragdoll.Entity:GetAngles():Forward() * 20 + Vector(0, 0, self.StepHeight),
        filter = ragdoll.Entity
    })
    
    if leftTr.Hit or rightTr.Hit then
        -- Try to step up
        if footBoneLeft then
            ragdoll:ApplyForce(footBoneLeft, Vector(0, 0, 300))
        end
        if footBoneRight then
            ragdoll:ApplyForce(footBoneRight, Vector(0, 0, 300))
        end
    end
end

return WORLD_INTERACTION
