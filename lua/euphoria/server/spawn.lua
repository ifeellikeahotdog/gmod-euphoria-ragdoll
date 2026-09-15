-- Server-side Ragdoll Spawning
-- Handles creation and management of ragdolls on the server

if not SERVER then return end

function EUPHORIA:SpawnRagdoll(pos, angle, model)
    model = model or "models/player/group01/male_01.mdl"
    
    local ent = ents.Create("prop_ragdoll")
    if not ent:IsValid() then return nil end
    
    ent:SetModel(model)
    ent:SetPos(pos)
    ent:SetAngles(angle)
    ent:Spawn()
    
    -- Initialize euphoria ragdoll system
    local ragdoll = include("euphoria/ragdoll/ragdoll.lua")
    ragdoll:Initialize(ent)
    
    -- Setup networked syncing
    ent:SetNWString("EuphoriaRagdoll", "true")
    ent:SetNWInt("RagdollIndex", ent:EntIndex())
    
    -- Setup think hook
    local lastUpdate = CurTime()
    ent.EuphoriaThink = function()
        local deltaTime = CurTime() - lastUpdate
        lastUpdate = CurTime()
        
        local ragdollData = EUPHORIA.RAGDOLLS[ent:EntIndex()]
        if ragdollData then
            ragdoll:Update(ragdollData, deltaTime)
        end
    end
    
    hook.Add("Think", "EuphoriaRagdoll_" .. ent:EntIndex(), ent.EuphoriaThink)
    
    print("[Euphoria] Spawned ragdoll at", pos)
    return ent
end

-- Network updates for ragdoll state
util.AddNetworkString("EuphoriaRagdollSync")
util.AddNetworkString("EuphoriaRagdollReact")
util.AddNetworkString("EuphoriaRagdollAnimation")

function EUPHORIA:SyncRagdollToClients(ent, ragdollData)
    if not ragdollData then return end
    
    net.Start("EuphoriaRagdollSync")
    net.WriteEntity(ent)
    net.WriteVector(ent:GetPos())
    net.WriteAngle(ent:GetAngles())
    net.WriteBool(ragdollData.IsRagdolled)
    net.WriteBool(ragdollData.Perception.GroundContact)
    net.WriteString(ragdollData.AnimationBlender.CurrentState)
    net.Broadcast()
end

function EUPHORIA:TriggerRagdollReaction(ent, reactionType, intensity)
    if not ent:IsValid() then return end
    
    local ragdollData = EUPHORIA.RAGDOLLS[ent:EntIndex()]
    if ragdollData then
        include("euphoria/ragdoll/ragdoll.lua"):React(ragdollData, reactionType, intensity)
        
        net.Start("EuphoriaRagdollReact")
        net.WriteEntity(ent)
        net.WriteString(reactionType)
        net.WriteFloat(intensity)
        net.Broadcast()
    end
end

-- Console commands for testing
if game.IsDedicated() or IsListenServer() then
    concommand.Add("euphoria_spawn", function(ply, cmd, args)
        local pos = ply:GetPos() + ply:GetAimVector() * 100
        EUPHORIA:SpawnRagdoll(pos, Angle(0, 0, 0))
    end)
    
    concommand.Add("euphoria_react", function(ply, cmd, args)
        local tr = util.TraceLine({
            start = ply:GetShootPos(),
            endpos = ply:GetShootPos() + ply:GetAimVector() * 10000,
            filter = ply
        })
        
        if tr.Entity and tr.Entity:IsValid() then
            EUPHORIA:TriggerRagdollReaction(tr.Entity, args[1] or "impact", tonumber(args[2]) or 1.0)
        end
    end)
end
