-- Main Ragdoll Implementation
-- Integrates all systems into a complete ragdoll entity

local RAGDOLL_IMPL = {}

function RAGDOLL_IMPL:Initialize(ent)
    local ragdoll = EUPHORIA:CreateRagdoll(ent)
    
    -- Initialize bones
    ragdoll:InitializeBones(ent:GetBoneCount())
    
    -- Setup joints
    local jointSystem = include("euphoria/ragdoll/joint_system.lua")
    jointSystem:CreateSkeletonJoints(ragdoll)
    
    -- Initialize AI systems
    ragdoll.Perception = include("euphoria/ai/perception.lua"):New(ragdoll)
    ragdoll.DecisionMaker = include("euphoria/ai/decision_maker.lua"):New(ragdoll)
    ragdoll.BehaviorController = include("euphoria/ai/behavior_controller.lua"):New(ragdoll)
    
    -- Initialize animation blender
    ragdoll.AnimationBlender = include("euphoria/animation/animation_blender.lua"):New(ragdoll)
    
    -- Initialize interaction systems
    ragdoll.PropInteraction = include("euphoria/interaction/prop_interaction.lua"):New(ragdoll)
    ragdoll.WorldInteraction = include("euphoria/interaction/world_interaction.lua"):New(ragdoll)
    
    -- Setup networked physics
    if SERVER then
        ragdoll.NetworkedSync = {}
        ragdoll.LastSyncTime = CurTime()
        ragdoll.SyncInterval = 0.05
    end
    
    print("[Euphoria] Ragdoll initialized: " .. ent:GetName())
    return ragdoll
end

function RAGDOLL_IMPL:Update(ragdoll, deltaTime)
    if not ragdoll or not ragdoll.Entity:IsValid() then return end
    
    -- Update perception
    if ragdoll.Perception then
        ragdoll.Perception:Update(deltaTime)
    end
    
    -- Make decisions
    if ragdoll.DecisionMaker then
        ragdoll.DecisionMaker:Update(deltaTime)
    end
    
    -- Control behavior
    if ragdoll.BehaviorController then
        ragdoll.BehaviorController:Update(deltaTime)
    end
    
    -- Update physics
    ragdoll:UpdatePhysics(deltaTime)
    
    -- Solve constraints
    local jointSystem = include("euphoria/ragdoll/joint_system.lua")
    jointSystem:SolveJoints(ragdoll, deltaTime)
    
    -- Handle collisions
    if ragdoll.CollisionHandler then
        ragdoll.CollisionHandler:Update(ragdoll, deltaTime)
    end
    
    -- Update animations
    if ragdoll.AnimationBlender then
        ragdoll.AnimationBlender:Update(ragdoll, deltaTime)
    end
    
    -- Handle interactions
    if ragdoll.PropInteraction then
        ragdoll.PropInteraction:Update(ragdoll, deltaTime)
    end
    
    if ragdoll.WorldInteraction then
        ragdoll.WorldInteraction:Update(ragdoll, deltaTime)
    end
end

function RAGDOLL_IMPL:Ragdoll(ragdoll)
    ragdoll.IsRagdolled = true
    ragdoll.StabilityFactor = 0.1
    
    -- Apply sudden impulse to simulate ragdolling
    for i = 0, math.min(5, #ragdoll.Bones) do
        if ragdoll.Bones[i] then
            ragdoll.Bones[i].Velocity = ragdoll.Bones[i].Velocity + VectorRand() * 200
        end
    end
end

function RAGDOLL_IMPL:StandUp(ragdoll)
    if not ragdoll.IsRagdolled then return end
    
    ragdoll.IsRagdolled = false
    ragdoll.StabilityFactor = 1.0
    ragdoll.BalanceTimer = 0
    
    -- Reset velocities
    for _, bone in ipairs(ragdoll.Bones) do
        bone.Velocity = bone.Velocity * 0.5
    end
end

function RAGDOLL_IMPL:React(ragdoll, forceType, intensity)
    forceType = forceType or "impact"
    intensity = intensity or 1.0
    
    if forceType == "impact" then
        -- Wide spread impact
        for i = 0, math.min(10, #ragdoll.Bones) do
            if ragdoll.Bones[i] then
                ragdoll:ApplyForce(i, VectorRand() * 500 * intensity)
            end
        end
        ragdoll:Ragdoll()
    elseif forceType == "punch" then
        -- Localized punch reaction
        if ragdoll.Bones[ragdoll.Entity:LookupBone("ValveBiped.Bip01_Spine2")] then
            ragdoll:ApplyForce(ragdoll.Entity:LookupBone("ValveBiped.Bip01_Spine2"), Vector(500 * intensity, 0, 0))
        end
        ragdoll:Ragdoll()
    elseif forceType == "fall" then
        -- Downward impact
        if ragdoll.Bones[ragdoll.Entity:LookupBone("ValveBiped.Bip01_L_Foot")] then
            ragdoll:ApplyForce(ragdoll.Entity:LookupBone("ValveBiped.Bip01_L_Foot"), Vector(0, 0, -1000 * intensity))
        end
        if ragdoll.Bones[ragdoll.Entity:LookupBone("ValveBiped.Bip01_R_Foot")] then
            ragdoll:ApplyForce(ragdoll.Entity:LookupBone("ValveBiped.Bip01_R_Foot"), Vector(0, 0, -1000 * intensity))
        end
        ragdoll:Ragdoll()
    end
end

return RAGDOLL_IMPL
