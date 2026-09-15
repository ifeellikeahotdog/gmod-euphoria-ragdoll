-- Behavior Controller System
-- Executes goals through physical actions and animations

local BEHAVIOR_CONTROLLER = {}
BEHAVIOR_CONTROLLER.__index = BEHAVIOR_CONTROLLER

function BEHAVIOR_CONTROLLER:New(ragdoll)
    local self = setmetatable({}, BEHAVIOR_CONTROLLER)
    
    self.Ragdoll = ragdoll
    self.ActiveBehaviors = {}
    self.BehaviorStack = {}
    self.CurrentAction = nil
    self.LastActionTime = CurTime()
    
    return self
end

function BEHAVIOR_CONTROLLER:Update(deltaTime)
    if not self.Ragdoll.DecisionMaker then return end
    
    local goal = self.Ragdoll.DecisionMaker:GetCurrentGoal()
    if not goal then return end
    
    -- Execute behavior based on goal
    if goal.Type == "Survive" then
        self:BehaviorSurvive(goal, deltaTime)
    elseif goal.Type == "Balance" then
        self:BehaviorBalance(goal, deltaTime)
    elseif goal.Type == "Interact" then
        self:BehaviorInteract(goal, deltaTime)
    elseif goal.Type == "Explore" then
        self:BehaviorExplore(goal, deltaTime)
    elseif goal.Type == "Rest" then
        self:BehaviorRest(goal, deltaTime)
    end
end

function BEHAVIOR_CONTROLLER:BehaviorSurvive(goal, deltaTime)
    local perception = self.Ragdoll.Perception
    local threats = perception:GetVisibleThreats()
    
    if #threats > 0 then
        local threat = threats[1]
        
        -- Move away from threat
        local awayDir = (self.Ragdoll.Entity:GetPos() - threat.Entity:GetPos()):GetNormalized()
        
        -- Apply evasive forces
        if self.Ragdoll.Bones[0] then
            self.Ragdoll:ApplyForce(0, awayDir * 300)
        end
        
        -- Try to stand up
        if self.Ragdoll.IsRagdolled then
            self:ApplyBalancingForces(deltaTime)
        end
    end
end

function BEHAVIOR_CONTROLLER:BehaviorBalance(goal, deltaTime)
    if self.Ragdoll.IsRagdolled then
        self:ApplyBalancingForces(deltaTime)
    end
end

function BEHAVIOR_CONTROLLER:ApplyBalancingForces(deltaTime)
    local perception = self.Ragdoll.Perception
    local footBoneLeft = self.Ragdoll.Entity:LookupBone("ValveBiped.Bip01_L_Foot")
    local footBoneRight = self.Ragdoll.Entity:LookupBone("ValveBiped.Bip01_R_Foot")
    local spineBone = self.Ragdoll.Entity:LookupBone("ValveBiped.Bip01_Spine")
    
    if not spineBone then return end
    
    -- Get center of mass
    local com = self.Ragdoll.PhysicsData.CenterOfMass
    local spinePos = self.Ragdoll.Entity:GetBonePosition(spineBone)
    
    -- Calculate balance correction
    local imbalance = com - spinePos
    imbalance.z = 0 -- Only care about horizontal imbalance
    
    if imbalance:Length() > 10 then
        -- Apply corrective force
        local correctionForce = -imbalance:GetNormalized() * 400 * EUPHORIA:GetConfig("RAGDOLL.BALANCE_STRENGTH")
        self.Ragdoll:ApplyForce(spineBone, correctionForce)
        
        -- Apply leg forces
        if footBoneLeft then
            self.Ragdoll:ApplyForce(footBoneLeft, correctionForce * 0.5)
        end
        if footBoneRight then
            self.Ragdoll:ApplyForce(footBoneRight, correctionForce * 0.5)
        end
    end
    
    -- Stabilize upright orientation
    local headBone = self.Ragdoll.Entity:LookupBone("ValveBiped.Bip01_Head")
    if headBone then
        local headRot = self.Ragdoll.Entity:GetBoneMatrix(headBone):GetAngles()
        
        -- Penalize tilting
        if math.abs(headRot.r) > 30 then
            local correctionTorque = Vector(0, 0, -headRot.r * 10)
            self.Ragdoll.Bones[headBone].Torque = self.Ragdoll.Bones[headBone].Torque + correctionTorque
        end
    end
end

function BEHAVIOR_CONTROLLER:BehaviorInteract(goal, deltaTime)
    if goal.Data and goal.Data.Target then
        local target = goal.Data.Target
        local distance = target.Distance
        
        -- Move towards target
        local towardsDir = (target.Entity:GetPos() - self.Ragdoll.Entity:GetPos()):GetNormalized()
        
        if self.Ragdoll.Bones[0] then
            self.Ragdoll:ApplyForce(0, towardsDir * 200)
        end
        
        -- Reach towards target if close enough
        if distance < 150 then
            local armBone = self.Ragdoll.Entity:LookupBone("ValveBiped.Bip01_R_Hand")
            if armBone then
                self.Ragdoll:ApplyForce(armBone, towardsDir * 100)
            end
        end
    end
end

function BEHAVIOR_CONTROLLER:BehaviorExplore(goal, deltaTime)
    -- Wander around
    local wanderDir = VectorRand()
    wanderDir.z = 0
    wanderDir = wanderDir:GetNormalized()
    
    if self.Ragdoll.Bones[0] then
        self.Ragdoll:ApplyForce(0, wanderDir * 150)
    end
end

function BEHAVIOR_CONTROLLER:BehaviorRest(goal, deltaTime)
    -- Reduce activity
    self.Ragdoll:ApplyDamping(0.5)
    
    -- Eventually sit or lie down
    if self.Ragdoll.DecisionMaker.Energy < 0.1 then
        self.Ragdoll:Ragdoll()
    end
end

function BEHAVIOR_CONTROLLER:ExecuteAction(action, duration)
    self.CurrentAction = {
        Type = action,
        StartTime = CurTime(),
        Duration = duration,
    }
end

return BEHAVIOR_CONTROLLER
