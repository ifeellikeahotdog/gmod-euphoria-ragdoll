-- Collision Handler System
-- Manages collisions, impacts, and physical responses

local COLLISION_HANDLER = {}
COLLISION_HANDLER.__index = COLLISION_HANDLER

function COLLISION_HANDLER:New(ragdoll)
    local self = setmetatable({}, COLLISION_HANDLER)
    
    self.Ragdoll = ragdoll
    self.ActiveCollisions = {}
    self.CollisionThreshold = 500 -- Minimum impact force to register
    self.LastImpactTime = {}
    
    return self
end

function COLLISION_HANDLER:Update(ragdoll, deltaTime)
    self:DetectCollisions(ragdoll)
    self:ProcessCollisions(ragdoll, deltaTime)
end

function COLLISION_HANDLER:DetectCollisions(ragdoll)
    self.ActiveCollisions = {}
    
    for boneIdx, bone in ipairs(ragdoll.Bones) do
        local tr = util.TraceLine({
            start = bone.Position - (bone.Velocity * 0.016),
            endpos = bone.Position + (bone.Velocity * 0.016),
            filter = ragdoll.Entity
        })
        
        if tr.Hit then
            local impactForce = bone.Velocity:Length() * bone.Mass
            
            if impactForce > self.CollisionThreshold then
                table.insert(self.ActiveCollisions, {
                    BoneIndex = boneIdx,
                    HitEntity = tr.Entity,
                    HitPos = tr.HitPos,
                    HitNormal = tr.HitNormal,
                    ImpactForce = impactForce,
                    Time = CurTime(),
                })
            end
        end
    end
end

function COLLISION_HANDLER:ProcessCollisions(ragdoll, deltaTime)
    for _, collision in ipairs(self.ActiveCollisions) do
        local bone = ragdoll.Bones[collision.BoneIndex]
        if not bone then continue end
        
        -- Reflect velocity
        local reflection = bone.Velocity - (2 * bone.Velocity:Dot(collision.HitNormal) * collision.HitNormal)
        bone.Velocity = reflection * 0.6 -- Bounce coefficient
        
        -- Apply damping
        ragdoll:ApplyDamping(EUPHORIA:GetConfig("PHYSICS.COLLISION_DAMPING"))
        
        -- Record impact
        ragdoll:ApplyForce(collision.BoneIndex, collision.HitNormal * collision.ImpactForce * 0.1)
        
        -- Trigger reaction if impact is strong
        if collision.ImpactForce > 2000 then
            ragdoll:React("impact", collision.ImpactForce / 5000)
        end
    end
end

return COLLISION_HANDLER
