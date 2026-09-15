-- BUGFIX: Main Ragdoll Implementation
-- Fixes: Table iteration bug, VectorRand replacement, CollisionHandler init

local RAGDOLL_IMPL = {}

function RAGDOLL_IMPL:Initialize(ent)
    if not ent or not ent:IsValid() then
        print("[Euphoria ERROR] Invalid entity passed to Initialize")
        return nil
    end
    
    local ragdoll = EUPHORIA:CreateRagdoll(ent)
    
    -- Initialize bones
    ragdoll:InitializeBones(ent:GetBoneCount())
    
    -- Setup joints
    local jointSystem = EUPHORIA.MODULES.JointSystem
    jointSystem:CreateSkeletonJoints(ragdoll)
    
    -- Initialize AI systems
    ragdoll.Perception = EUPHORIA.MODULES.Perception:New(ragdoll)
    ragdoll.DecisionMaker = EUPHORIA.MODULES.DecisionMaker:New(ragdoll)
    ragdoll.BehaviorController = EUPHORIA.MODULES.BehaviorController:New(ragdoll)
    
    -- Initialize animation blender
    ragdoll.AnimationBlender = EUPHORIA.MODULES.AnimationBlender:New(ragdoll)
    
    -- Initialize interaction systems
    ragdoll.PropInteraction = EUPHORIA.MODULES.PropInteraction:New(ragdoll)
    ragdoll.WorldInteraction = EUPHORIA.MODULES.WorldInteraction:New(ragdoll)
    
    -- BUGFIX: Initialize collision handler (was missing)
    ragdoll.CollisionHandler = EUPHORIA.MODULES.CollisionHandler:New(ragdoll)
    
    -- Initialize environment system
    ragdoll.Environment = EUPHORIA.MODULES.Environment:New(ragdoll)
    
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
    if not ragdoll or not ragdoll.Entity or not ragdoll.Entity:IsValid() then return end
    
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
    if EUPHORIA.MODULES.JointSystem then
        EUPHORIA.MODULES.JointSystem:SolveJoints(ragdoll, deltaTime)
    end
    
    -- Handle collisions
    if ragdoll.CollisionHandler then
        ragdoll.CollisionHandler:Update(ragdoll, deltaTime)
    end
    
    -- Update environment
    if ragdoll.Environment then
        ragdoll.Environment:Update(ragdoll, deltaTime)
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
    
    -- BUGFIX: Use proper 1-based iteration and replaced VectorRand
    if ragdoll.Bones and #ragdoll.Bones > 0 then
        for i = 1, math.min(5, #ragdoll.Bones) do
            if ragdoll.Bones[i] then
                -- BUGFIX: Generate random vector properly
                local randomVec = Vector(
                    math.random() * 2 - 1,
                    math.random() * 2 - 1,
                    math.random() * 2 - 1
                ):GetNormalized() * 200
                ragdoll.Bones[i].Velocity = ragdoll.Bones[i].Velocity + randomVec
            end
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
    
    if not ragdoll or not ragdoll.Entity or not ragdoll.Entity:IsValid() then return end
    if not ragdoll.Bones or #ragdoll.Bones == 0 then return end
    
    if forceType == "impact" then
        -- BUGFIX: Use proper 1-based iteration
        for i = 1, math.min(10, #ragdoll.Bones) do
            if ragdoll.Bones[i] then
                local randomVec = Vector(
                    math.random() * 2 - 1,
                    math.random() * 2 - 1,
                    math.random() * 2 - 1
                ):GetNormalized() * 500 * intensity
                ragdoll:ApplyForce(i - 1, randomVec)  -- Adjust for 0-based indexing in ApplyForce
            end
        end
        ragdoll:Ragdoll()
    elseif forceType == "punch" then
        -- Localized punch reaction
        local spineBone = ragdoll.Entity:LookupBone("ValveBiped.Bip01_Spine2")
        if spineBone and ragdoll.Bones[spineBone] then
            ragdoll:ApplyForce(spineBone, Vector(500 * intensity, 0, 0))
        end
        ragdoll:Ragdoll()
    elseif forceType == "fall" then
        -- Downward impact
        local footLeft = ragdoll.Entity:LookupBone("ValveBiped.Bip01_L_Foot")
        local footRight = ragdoll.Entity:LookupBone("ValveBiped.Bip01_R_Foot")
        
        if footLeft and ragdoll.Bones[footLeft] then
            ragdoll:ApplyForce(footLeft, Vector(0, 0, -1000 * intensity))
        end
        if footRight and ragdoll.Bones[footRight] then
            ragdoll:ApplyForce(footRight, Vector(0, 0, -1000 * intensity))
        end
        ragdoll:Ragdoll()
    end
end

return RAGDOLL_IMPL
