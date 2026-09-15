-- AI Perception System
-- Handles sensing, awareness, and environmental observation

local PERCEPTION = {}
PERCEPTION.__index = PERCEPTION

function PERCEPTION:New(ragdoll)
    local self = setmetatable({}, PERCEPTION)
    
    self.Ragdoll = ragdoll
    self.VisibleEntities = {}
    self.HeardSounds = {}
    self.EnvironmentalHazards = {}
    self.GroundContact = false
    self.LastUpdateTime = CurTime()
    
    -- Sensory configuration
    self.VisionRange = EUPHORIA:GetConfig("AI.PERCEPTION_RANGE")
    self.PeripheralVision = EUPHORIA:GetConfig("AI.PERIPHERAL_VISION")
    self.HearingRange = self.VisionRange * 1.5
    self.ViewAngles = Angle(0, 0, 0)
    
    -- Memory
    self.EntityMemory = {}
    self.HazardMemory = {}
    self.EventMemory = {}
    
    return self
end

function PERCEPTION:Update(deltaTime)
    local headBone = self.Ragdoll.Entity:LookupBone("ValveBiped.Bip01_Head")
    if not headBone then return end
    
    local headPos = self.Ragdoll.Entity:GetBonePosition(headBone)
    local lookDir = self.Ragdoll.Entity:GetAngles():Forward()
    
    -- Update vision
    self:UpdateVision(headPos, lookDir)
    
    -- Update hearing
    self:UpdateHearing(headPos)
    
    -- Check ground contact
    self:CheckGroundContact()
    
    -- Update environmental awareness
    self:ScanEnvironment(headPos)
    
    -- Decay memory
    self:DecayMemory(deltaTime)
    
    self.LastUpdateTime = CurTime()
end

function PERCEPTION:UpdateVision(eyePos, lookDir)
    self.VisibleEntities = {}
    
    local ents = ents.FindInSphere(eyePos, self.VisionRange)
    
    for _, ent in ipairs(ents) do
        if ent == self.Ragdoll.Entity then continue end
        if not ent:IsValid() then continue end
        
        -- Check if entity is in view
        local toEntity = (ent:GetPos() - eyePos):GetNormalized()
        local dotProduct = lookDir:Dot(toEntity)
        
        -- Check if in FOV (including peripheral vision)
        if dotProduct > math.cos(math.rad(self.PeripheralVision / 2)) then
            -- Line of sight check
            local tr = util.TraceLine({
                start = eyePos,
                endpos = ent:GetPos(),
                filter = self.Ragdoll.Entity
            })
            
            if tr.Fraction > 0.95 or tr.Entity == ent then
                table.insert(self.VisibleEntities, {
                    Entity = ent,
                    Distance = eyePos:Distance(ent:GetPos()),
                    Angle = math.deg(math.acos(dotProduct)),
                    LastSeen = CurTime(),
                })
            end
        end
    end
    
    -- Store in memory
    for _, entity in ipairs(self.VisibleEntities) do
        self.EntityMemory[entity.Entity:EntIndex()] = {
            Entity = entity.Entity,
            LastPosition = entity.Entity:GetPos(),
            LastSeen = CurTime(),
            Type = entity.Entity:GetClass(),
        }
    end
end

function PERCEPTION:UpdateHearing(pos)
    self.HeardSounds = {}
    
    -- Check for explosions, impacts, and loud entities
    local ents = ents.FindInSphere(pos, self.HearingRange)
    
    for _, ent in ipairs(ents) do
        if ent == self.Ragdoll.Entity then continue end
        if not ent:IsValid() then continue end
        
        -- Check if entity is moving fast (making noise)
        local velocity = ent:GetVelocity():Length()
        if velocity > 200 then
            table.insert(self.HeardSounds, {
                Entity = ent,
                Distance = pos:Distance(ent:GetPos()),
                Intensity = math.min(velocity / 1000, 1.0),
                Time = CurTime(),
            })
        end
    end
end

function PERCEPTION:CheckGroundContact()
    local footBoneLeft = self.Ragdoll.Entity:LookupBone("ValveBiped.Bip01_L_Foot")
    local footBoneRight = self.Ragdoll.Entity:LookupBone("ValveBiped.Bip01_R_Foot")
    
    self.GroundContact = false
    
    if footBoneLeft then
        local footPos = self.Ragdoll.Entity:GetBonePosition(footBoneLeft)
        local tr = util.TraceLine({
            start = footPos,
            endpos = footPos + Vector(0, 0, -50),
            filter = self.Ragdoll.Entity
        })
        if tr.Hit then self.GroundContact = true end
    end
    
    if footBoneRight then
        local footPos = self.Ragdoll.Entity:GetBonePosition(footBoneRight)
        local tr = util.TraceLine({
            start = footPos,
            endpos = footPos + Vector(0, 0, -50),
            filter = self.Ragdoll.Entity
        })
        if tr.Hit then self.GroundContact = true end
    end
end

function PERCEPTION:ScanEnvironment(pos)
    self.EnvironmentalHazards = {}
    
    -- Check for nearby hazards
    local ents = ents.FindInSphere(pos, self.VisionRange)
    
    for _, ent in ipairs(ents) do
        if ent == self.Ragdoll.Entity then continue end
        if not ent:IsValid() then continue end
        
        local hazardType = nil
        
        -- Identify hazards
        if ent:IsWorld() then
            hazardType = "world"
        elseif ent:GetClass() == "prop_physics" then
            local vel = ent:GetVelocity():Length()
            if vel > 300 then
                hazardType = "moving_prop"
            end
        elseif string.find(ent:GetClass(), "damage") then
            hazardType = "damage_zone"
        end
        
        if hazardType then
            table.insert(self.EnvironmentalHazards, {
                Entity = ent,
                Type = hazardType,
                Distance = pos:Distance(ent:GetPos()),
                Detected = CurTime(),
            })
        end
    end
end

function PERCEPTION:DecayMemory(deltaTime)
    local memoryDuration = EUPHORIA:GetConfig("AI.MEMORY_DURATION")
    
    -- Decay entity memory
    for idx, mem in pairs(self.EntityMemory) do
        if CurTime() - mem.LastSeen > memoryDuration then
            self.EntityMemory[idx] = nil
        end
    end
    
    -- Decay event memory
    for idx, event in pairs(self.EventMemory) do
        if CurTime() - event.Time > memoryDuration then
            self.EventMemory[idx] = nil
        end
    end
end

function PERCEPTION:GetVisibleThreats()
    local threats = {}
    for _, entity in ipairs(self.VisibleEntities) do
        if entity.Entity:IsPlayer() or entity.Entity:IsNPC() then
            table.insert(threats, entity)
        end
    end
    return threats
end

function PERCEPTION:GetClosestEntity()
    if #self.VisibleEntities == 0 then return nil end
    
    local closest = self.VisibleEntities[1]
    for _, entity in ipairs(self.VisibleEntities) do
        if entity.Distance < closest.Distance then
            closest = entity
        end
    end
    return closest
end

function PERCEPTION:RememberEvent(eventType, data)
    table.insert(self.EventMemory, {
        Type = eventType,
        Data = data,
        Time = CurTime(),
    })
end

return PERCEPTION
