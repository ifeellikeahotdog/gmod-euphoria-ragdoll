-- Client-side Rendering
-- Handles visual representation and debugging of ragdolls

if not CLIENT then return end

local ragdollStates = {}

net.Receive("EuphoriaRagdollSync", function(len)
    local ent = net.ReadEntity()
    local pos = net.ReadVector()
    local angles = net.ReadAngle()
    local isRagdolled = net.ReadBool()
    local groundContact = net.ReadBool()
    local animState = net.ReadString()
    
    if not ent or not ent:IsValid() then return end
    
    ragdollStates[ent:EntIndex()] = {
        Position = pos,
        Angles = angles,
        IsRagdolled = isRagdolled,
        GroundContact = groundContact,
        AnimState = animState,
        UpdateTime = CurTime(),
    }
end)

net.Receive("EuphoriaRagdollReact", function(len)
    local ent = net.ReadEntity()
    local reactionType = net.ReadString()
    local intensity = net.ReadFloat()
    
    if not ent or not ent:IsValid() then return end
    
    -- Play reaction particle effects
    local pos = ent:GetPos()
    local emitter = ParticleEmitter(pos)
    
    if reactionType == "impact" then
        for i = 1, math.floor(intensity * 10) do
            local particle = emitter:Add("particles/smoke1", pos)
            particle:SetVelocity(VectorRand() * 100 * intensity)
            particle:SetLifeTime(0)
            particle:SetDieTime(0.5)
            particle:SetStartAlpha(100)
            particle:SetEndAlpha(0)
            particle:SetStartSize(5)
            particle:SetEndSize(20)
        end
    end
    
    emitter:Finish()
end)

hook.Add("PostDrawTranslucentRenderables", "EuphoriaDebugRender", function()
    if not EUPHORIA:GetConfig("DEBUG.ENABLE_RENDERING") then return end
    
    cam.Start3D()
    
    for entIdx, state in pairs(ragdollStates) do
        if state and state.UpdateTime then
            -- Draw ragdoll position marker
            render.SetColorModulation(0, 1, 0)
            render.DrawSphere(state.Position, 10, 8, 8)
            
            -- Draw state text
            if state.IsRagdolled then
                render.SetColorModulation(1, 0, 0)
            else
                render.SetColorModulation(0, 1, 0)
            end
            
            local textPos = state.Position + Vector(0, 0, 20)
            cam.End3D()
            
            draw.SimpleText(state.AnimState, "DermaDefault", textPos:ToScreen().x, textPos:ToScreen().y, Color(255, 255, 255))
            
            cam.Start3D()
        end
    end
    
    cam.End3D()
end)
