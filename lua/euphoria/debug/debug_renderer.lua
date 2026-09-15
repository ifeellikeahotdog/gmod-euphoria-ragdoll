-- Debug Renderer
-- Visualizes ragdoll systems for debugging and development

local DEBUG_RENDERER = {}
DEBUG_RENDERER.__index = DEBUG_RENDERER

function DEBUG_RENDERER:New()
    local self = setmetatable({}, DEBUG_RENDERER)
    self.Enabled = EUPHORIA:GetConfig("DEBUG.ENABLE_RENDERING")
    return self
end

function DEBUG_RENDERER:RenderJoints(ragdoll)
    if not self.Enabled or not EUPHORIA:GetConfig("DEBUG.SHOW_JOINTS") then return end
    
    for _, joint in ipairs(ragdoll.Joints) do
        local bone1 = ragdoll.Bones[joint.Bone1Index]
        local bone2 = ragdoll.Bones[joint.Bone2Index]
        
        if bone1 and bone2 then
            debugoverlay.Line(bone1.Position, bone2.Position, 0.016, Color(0, 255, 0), true)
        end
    end
end

function DEBUG_RENDERER:RenderPerception(ragdoll)
    if not self.Enabled or not EUPHORIA:GetConfig("DEBUG.SHOW_PERCEPTION") then return end
    
    local perception = ragdoll.Perception
    local headBone = ragdoll.Entity:LookupBone("ValveBiped.Bip01_Head")
    
    if not headBone then return end
    
    local eyePos = ragdoll.Entity:GetBonePosition(headBone)
    
    -- Draw vision cone
    debugoverlay.Sphere(eyePos, perception.VisionRange, 0.016, Color(0, 0, 255, 50), true)
    
    -- Draw visible entities
    for _, entity in ipairs(perception.VisibleEntities) do
        debugoverlay.Line(eyePos, entity.Entity:GetPos(), 0.016, Color(255, 255, 0), true)
    end
end

function DEBUG_RENDERER:RenderForces(ragdoll)
    if not self.Enabled or not EUPHORIA:GetConfig("DEBUG.SHOW_FORCES") then return end
    
    for _, bone in ipairs(ragdoll.Bones) do
        if bone.Force:Length() > 0 then
            local forceDir = bone.Force:GetNormalized()
            local forceScale = math.min(bone.Force:Length() / 100, 50)
            
            debugoverlay.Line(bone.Position, bone.Position + (forceDir * forceScale), 0.016, Color(255, 0, 0), true)
        end
    end
end

function DEBUG_RENDERER:RenderDecisionTree(ragdoll)
    if not self.Enabled or not EUPHORIA:GetConfig("DEBUG.SHOW_DECISION_TREE") then return end
    
    local goal = ragdoll.DecisionMaker:GetCurrentGoal()
    if goal then
        local pos = ragdoll.Entity:GetPos() + Vector(0, 0, 100)
        debugoverlay.Text(pos, "Goal: " .. goal.Type .. " (Score: " .. math.floor(goal.Score) .. ")", 0.016, true)
    end
end

return DEBUG_RENDERER
