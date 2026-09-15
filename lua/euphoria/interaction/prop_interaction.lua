-- Prop Interaction System
-- Handles interaction with physics props and objects

local PROP_INTERACTION = {}
PROP_INTERACTION.__index = PROP_INTERACTION

function PROP_INTERACTION:New(ragdoll)
    local self = setmetatable({}, PROP_INTERACTION)
    
    self.Ragdoll = ragdoll
    self.GrabbedProp = nil
    self.GrabBone = nil
    self.GrabDistance = EUPHORIA:GetConfig("INTERACTION.GRAB_RANGE")
    self.PropForceMultiplier = EUPHORIA:GetConfig("INTERACTION.PROP_FORCE_MULTIPLIER")
    
    return self
end

function PROP_INTERACTION:Update(ragdoll, deltaTime)
    -- Find nearby interactable props
    local handBone = ragdoll.Entity:LookupBone("ValveBiped.Bip01_R_Hand")
    if not handBone then return end
    
    local handPos = ragdoll.Entity:GetBonePosition(handBone)
    local nearbyEnts = ents.FindInSphere(handPos, self.GrabDistance)
    
    for _, ent in ipairs(nearbyEnts) do
        if ent:GetClass() == "prop_physics" and ent:IsValid() then
            -- Try to grab or interact
            self:InteractWithProp(ent, handPos, ragdoll, deltaTime)
        end
    end
    
    -- Update grabbed prop
    if self.GrabbedProp and self.GrabbedProp:IsValid() then
        self:UpdateGrabbedProp(ragdoll, deltaTime)
    else
        self.GrabbedProp = nil
    end
end

function PROP_INTERACTION:InteractWithProp(prop, handPos, ragdoll, deltaTime)
    local propPos = prop:GetPos()
    local distance = handPos:Distance(propPos)
    
    -- Apply force towards hand
    local toHand = (handPos - propPos):GetNormalized()
    local force = toHand * (self.PropForceMultiplier * 100)
    
    prop:ApplyForceCenter(force)
    
    -- Grab if very close
    if distance < self.GrabDistance * 0.3 and not self.GrabbedProp then
        self:GrabProp(prop, ragdoll)
    end
end

function PROP_INTERACTION:GrabProp(prop, ragdoll)
    self.GrabbedProp = prop
    local handBone = ragdoll.Entity:LookupBone("ValveBiped.Bip01_R_Hand")
    self.GrabBone = handBone
end

function PROP_INTERACTION:ReleaseProp()
    if self.GrabbedProp then
        self.GrabbedProp = nil
        self.GrabBone = nil
    end
end

function PROP_INTERACTION:UpdateGrabbedProp(ragdoll, deltaTime)
    if not self.GrabBone then return end
    
    local handPos = ragdoll.Entity:GetBonePosition(self.GrabBone)
    local propPos = self.GrabbedProp:GetPos()
    local distance = handPos:Distance(propPos)
    
    -- Pull prop toward hand
    local toHand = (handPos - propPos):GetNormalized()
    self.GrabbedProp:ApplyForceCenter(toHand * 200)
    
    -- Release if hand moves too far
    if distance > self.GrabDistance then
        self:ReleaseProp()
    end
end

return PROP_INTERACTION
