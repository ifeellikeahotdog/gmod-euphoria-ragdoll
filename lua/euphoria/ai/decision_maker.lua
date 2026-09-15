-- Decision Maker System
-- Advanced decision tree and goal-oriented planning

local DECISION_MAKER = {}
DECISION_MAKER.__index = DECISION_MAKER

function DECISION_MAKER:New(ragdoll)
    local self = setmetatable({}, DECISION_MAKER)
    
    self.Ragdoll = ragdoll
    self.CurrentGoal = nil
    self.GoalStack = {}
    self.DecisionInterval = EUPHORIA:GetConfig("AI.DECISION_INTERVAL")
    self.LastDecisionTime = CurTime()
    
    -- Decision weights
    self.WeightSurvival = 1.0
    self.WeightComfort = 0.5
    self.WeightCuriosity = 0.3
    
    -- Personality traits
    self.Aggression = 0.5
    self.Caution = 0.6
    self.Energy = 1.0
    
    return self
end

function DECISION_MAKER:Update(deltaTime)
    if CurTime() - self.LastDecisionTime < self.DecisionInterval then return end
    
    -- Evaluate all possible goals
    local goals = self:EvaluateGoals()
    
    -- Select best goal
    self.CurrentGoal = self:SelectBestGoal(goals)
    
    -- Update personality based on stimuli
    self:UpdatePersonality()
    
    self.LastDecisionTime = CurTime()
end

function DECISION_MAKER:EvaluateGoals()
    local goals = {}
    local perception = self.Ragdoll.Perception
    
    -- Goal: Survive
    local survivalGoal = {
        Type = "Survive",
        Priority = self.WeightSurvival,
        Score = 0,
        Data = {}
    }
    
    -- Check for threats
    if perception.GroundContact == false then
        survivalGoal.Score = survivalGoal.Score + 100 -- Falling is bad
    end
    
    local threats = perception:GetVisibleThreats()
    if #threats > 0 then
        local closestThreat = threats[1]
        survivalGoal.Score = survivalGoal.Score + (self.Caution * (2000 / (closestThreat.Distance + 1)))
        survivalGoal.Data.Threat = closestThreat
    end
    
    table.insert(goals, survivalGoal)
    
    -- Goal: Maintain Balance
    local balanceGoal = {
        Type = "Balance",
        Priority = self.WeightSurvival * 0.8,
        Score = 0,
        Data = {}
    }
    
    if self.Ragdoll.IsRagdolled then
        balanceGoal.Score = balanceGoal.Score + 200
    end
    
    if not perception.GroundContact then
        balanceGoal.Score = balanceGoal.Score + 150
    end
    
    table.insert(goals, balanceGoal)
    
    -- Goal: Interact with environment
    local interactGoal = {
        Type = "Interact",
        Priority = self.WeightCuriosity,
        Score = 0,
        Data = {}
    }
    
    local closestEntity = perception:GetClosestEntity()
    if closestEntity then
        interactGoal.Score = interactGoal.Score + (self.WeightCuriosity * (1000 / (closestEntity.Distance + 1)))
        interactGoal.Data.Target = closestEntity
    end
    
    table.insert(goals, interactGoal)
    
    -- Goal: Explore
    local exploreGoal = {
        Type = "Explore",
        Priority = self.WeightCuriosity * 0.7,
        Score = 50 + (self.Energy * 30),
        Data = {}
    }
    
    table.insert(goals, exploreGoal)
    
    -- Goal: Rest
    local restGoal = {
        Type = "Rest",
        Priority = self.WeightComfort,
        Score = 100 - (self.Energy * 100),
        Data = {}
    }
    
    if self.Energy < 0.3 then
        restGoal.Score = restGoal.Score + 200
    end
    
    table.insert(goals, restGoal)
    
    return goals
end

function DECISION_MAKER:SelectBestGoal(goals)
    local bestGoal = nil
    local bestScore = -math.huge
    
    for _, goal in ipairs(goals) do
        local totalScore = (goal.Score * goal.Priority)
        
        if totalScore > bestScore then
            bestScore = totalScore
            bestGoal = goal
        end
    end
    
    return bestGoal
end

function DECISION_MAKER:UpdatePersonality()
    local perception = self.Ragdoll.Perception
    
    -- Increase caution if threats detected
    if #perception:GetVisibleThreats() > 0 then
        self.Caution = math.min(1.0, self.Caution + 0.1)
    else
        self.Caution = math.max(0.3, self.Caution - 0.01)
    end
    
    -- Decrease energy over time
    self.Energy = math.max(0, self.Energy - 0.001)
    
    -- Increase energy when resting
    if self.CurrentGoal and self.CurrentGoal.Type == "Rest" then
        self.Energy = math.min(1.0, self.Energy + 0.05)
    end
    
    -- Curiosity influenced by energy
    self.WeightCuriosity = self.Energy * 0.5
end

function DECISION_MAKER:PushGoal(goal)
    table.insert(self.GoalStack, goal)
end

function DECISION_MAKER:PopGoal()
    return table.remove(self.GoalStack)
end

function DECISION_MAKER:GetCurrentGoal()
    return self.CurrentGoal
end

function DECISION_MAKER:IsGoalComplete()
    if not self.CurrentGoal then return true end
    
    if self.CurrentGoal.Type == "Balance" then
        return not self.Ragdoll.IsRagdolled and self.Ragdoll.Perception.GroundContact
    elseif self.CurrentGoal.Type == "Survive" then
        return #self.Ragdoll.Perception:GetVisibleThreats() == 0
    end
    
    return false
end

return DECISION_MAKER
