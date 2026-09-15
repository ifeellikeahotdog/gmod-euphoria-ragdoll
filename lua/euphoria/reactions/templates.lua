-- Ragdoll Reaction Templates
-- Pre-configured reactions for common scenarios

EUPHORIA.REACTION_TEMPLATES = {
    -- Punched in the face
    PUNCH_HEAD = {
        Type = "impact",
        TargetBone = "ValveBiped.Bip01_Head",
        Force = Vector(300, 0, 0),
        Intensity = 0.8,
    },
    
    -- Kicked in the chest
    KICK_CHEST = {
        Type = "impact",
        TargetBone = "ValveBiped.Bip01_Spine2",
        Force = Vector(500, 0, 0),
        Intensity = 1.0,
    },
    
    -- Fall from height
    FALL_HIGH = {
        Type = "fall",
        Force = Vector(0, 0, -500),
        Intensity = 1.5,
    },
    
    -- Explosion nearby
    EXPLOSION = {
        Type = "impact",
        Force = nil,  -- Radial
        Intensity = 2.0,
    },
    
    -- Being shot
    SHOT = {
        Type = "impact",
        Force = Vector(200, 0, 0),
        Intensity = 0.6,
    },
    
    -- Electrocuted
    ELECTROCUTE = {
        Type = "impact",
        Force = nil,  -- All limbs jolt
        Intensity = 1.2,
    },
    
    -- Freeze
    FREEZE = {
        Type = "rigid",
        Intensity = 1.0,
    },
}

function EUPHORIA:ApplyReactionTemplate(ent, templateName)
    if not EUPHORIA.REACTION_TEMPLATES[templateName] then
        print("[Warning] Unknown reaction template:", templateName)
        return
    end
    
    local template = EUPHORIA.REACTION_TEMPLATES[templateName]
    local ragdoll = EUPHORIA.RAGDOLLS[ent:EntIndex()]
    
    if not ragdoll then return end
    
    if template.TargetBone then
        local boneIdx = ent:LookupBone(template.TargetBone)
        if boneIdx then
            ragdoll:ApplyForce(boneIdx, template.Force or Vector(0, 0, 0))
        end
    else
        -- Apply to all bones
        for _, bone in ipairs(ragdoll.Bones) do
            if template.Force then
                ragdoll:ApplyForce(bone.Index, template.Force)
            end
        end
    end
    
    ragdoll:React(template.Type, template.Intensity)
end
