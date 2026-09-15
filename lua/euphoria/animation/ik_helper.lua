-- Inverse Kinematics Helper
-- Assists with limb positioning and reaching behaviors

local IK_HELPER = {}
IK_HELPER.__index = IK_HELPER

function IK_HELPER:New(ragdoll)
    local self = setmetatable({}, IK_HELPER)
    
    self.Ragdoll = ragdoll
    self.MaxIterations = 5
    self.Precision = 0.1
    
    return self
end

function IK_HELPER:SolveChainIK(startBoneIdx, endBoneIdx, targetPos)
    -- Simplified IK solver for limb chains
    local bones = {}
    local current = endBoneIdx
    
    while current and current ~= startBoneIdx do
        table.insert(bones, 1, current)
        current = self:GetParentBone(current)
    end
    table.insert(bones, 1, startBoneIdx)
    
    if #bones < 2 then return end
    
    -- Iterative solver
    for iteration = 1, self.MaxIterations do
        local endPos = self.Ragdoll.Entity:GetBonePosition(bones[#bones])
        local error = targetPos - endPos
        
        if error:Length() < self.Precision then break end
        
        -- Adjust bones from end to start
        for i = #bones - 1, 1, -1 do
            local bone = self.Ragdoll.Bones[bones[i]]
            if bone then
                bone.Position = bone.Position + (error * 0.1)
            end
        end
    end
end

function IK_HELPER:GetParentBone(boneIdx)
    -- Returns parent bone index in hierarchy
    local ent = self.Ragdoll.Entity
    return ent:GetBoneParent(boneIdx)
end

return IK_HELPER
