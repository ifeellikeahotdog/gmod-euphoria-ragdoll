-- UPGRADE: Optimized Perception System
-- Reduces query frequency, implements culling, and adds safety checks

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
    
    -- UPGRADE: Add update throttling
    self.LastVisionUpdateTime = CurTime()
    self.LastHearingUpdateTime = CurTime()
    self.LastEnvironmentUpdateTime = CurTime()
    
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
    if not self.Ragdoll or not self.Ragdoll.Entity or not self.Ragdoll.Entity:IsValid() then
        return
    end
    
    local headBone = self.Ragdoll.Entity:LookupBone("ValveBiped.Bip01_Head")
    if not headBone or headBone == -1 then
        return
    end
    
    local headPos = self.Ragdoll.Entity:GetBonePosition(headBone)
    local lookDir = self.Ragdoll.Entity:GetAngles():Forward()
    
    -- UPGRADE: Throttle expensive perception updates
    if CurTime() - self.LastVisionUpdateTime >= 0.1 then  -- 10 Hz instead of every frame
        self:UpdateVision(headPos, lookDir)
        self.LastVisionUpdateTime = CurTime()
    end
    
    if CurTime() - self.LastHearingUpdateTime >= 0.15 then  -- 6.7 Hz
        self:UpdateHearing(headPos)
        self.LastHearingUpdateTime = CurTime()
    end
    
    if CurTime() - self.LastEnvironmentUpdateTime >= 0.2 then  -- 5 Hz
        self:ScanEnvironment(headPos)
        self.LastEnvironmentUpdateTime = CurTime()
    end
    
    -- Update ground contact every frame (cheap raycasts)
    self:CheckGroundContact()
    
    -- Decay memory
    self:DecayMemory(deltaTime)
    
    self.LastUpdateTime = CurTime()
end

function PERCEPTION:UpdateVision(eyePos, lookDir)
    self.VisibleEntities = {}
    
    local ents = ents.FindInSphere(eyePos, self.VisionRange)
    if not ents then return end
    
    for _, ent in ipairs(ents) do
        if not ent or not ent:IsValid() then continue end
        if ent == self.Ragdoll.Entity then continue end
        
        local toEntity = (ent:GetPos() - eyePos):GetNormalized()
        local dotProduct = lookDir:Dot(toEntity)
        
        -- Check if in FOV
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
                    Angle = math.deg(math.acos(math.Clamp(dotProduct, -1, 1))),
                    LastSeen = CurTime(),
                })
            end
        end
    end
    
    -- Store in memory
    for _, entity in ipairs(self.VisibleEntities) do
        if entity.Entity and entity.Entity:IsValid() then
            self.EntityMemory[entity.Entity:EntIndex()] = {
                Entity = entity.Entity,
                LastPosition = entity.Entity:GetPos(),
                LastSeen = CurTime(),
                Type = entity.Entity:GetClass(),
            }
        end
    end
end

function PERCEPTION:UpdateHearing(pos)
    self.HeardSounds = {}
    
    local ents = ents.FindInSphere(pos, self.HearingRange)
    if not ents then return end
    
    for _, ent in ipairs(ents) do
        if not ent or not ent:IsValid() then continue end
        if ent == self.Ragdoll.Entity then continue end
        
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
    if not self.Ragdoll or not self.Ragdoll.Entity or not self.Ragdoll.Entity:IsValid() then
        self.GroundContact = false
        return
    end
    
    local footBoneLeft = self.Ragdoll.Entity:LookupBone("ValveBiped.Bip01_L_Foot")
    local footBoneRight = self.Ragdoll.Entity:LookupBone("ValveBiped.Bip01_R_Foot")
    
    self.GroundContact = false
    
    if footBoneLeft and footBoneLeft ~= -1 then
        local footPos = self.Ragdoll.Entity:GetBonePosition(footBoneLeft)
        local tr = util.TraceLine({
            start = footPos,
            endpos = footPos + Vector(0, 0, -50),
            filter = self.Ragdoll.Entity
        })
        if tr.Hit then self.GroundContact = true end
    end
    
    if footBoneRight and footBoneRight ~= -1 then
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
    
    local ents = ents.FindInSphere(pos, self.VisionRange)
    if not ents then return end
    
    for _, ent in ipairs(ents) do
        if not ent or not ent:IsValid() then continue end
        if ent == self.Ragdoll.Entity then continue end
        
        local hazardType = nil
        
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
    
    for idx, mem in pairs(self.EntityMemory) do
        if CurTime() - mem.LastSeen > memoryDuration then
            self.EntityMemory[idx] = nil
        end
    end
    
    for idx, event in pairs(self.EventMemory) do
        if CurTime() - event.Time > memoryDuration then
            self.EventMemory[idx] = nil
        end
    end
end

function PERCEPTION:GetVisibleThreats()
    local threats = {}
    for _, entity in ipairs(self.VisibleEntities) do
        if entity.Entity and entity.Entity:IsValid() then
            if entity.Entity:IsPlayer() or entity.Entity:IsNPC() then
                table.insert(threats, entity)
            end
        end
    end
    return threats
end

function PERCEPTION:GetClosestEntity()
    if #self.VisibleEntities == 0 then return nil end
    
    local closest = self.VisibleEntities[1]
    for _, entity in ipairs(self.VisibleEntities) do
        if entity and entity.Distance and closest.Distance then
            if entity.Distance < closest.Distance then
                closest = entity
            end
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
