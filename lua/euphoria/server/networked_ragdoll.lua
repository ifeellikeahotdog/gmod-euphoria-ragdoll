-- Networked Ragdoll System
-- Handles replication of ragdoll state between server and clients

if not SERVER then return end

local updateInterval = 0.05 -- 20 updates per second
local lastUpdateTime = {}

function EUPHORIA:UpdateNetworkedRagdolls()
    for entIdx, ragdollData in pairs(EUPHORIA.RAGDOLLS) do
        if not ragdollData.Entity or not ragdollData.Entity:IsValid() then
            EUPHORIA.RAGDOLLS[entIdx] = nil
            continue
        end
        
        if not lastUpdateTime[entIdx] then
            lastUpdateTime[entIdx] = CurTime()
        end
        
        if CurTime() - lastUpdateTime[entIdx] >= updateInterval then
            EUPHORIA:SyncRagdollToClients(ragdollData.Entity, ragdollData)
            lastUpdateTime[entIdx] = CurTime()
        end
    end
end

hook.Add("Think", "EuphoriaNetworkedRagdolls", function()
    EUPHORIA:UpdateNetworkedRagdolls()
end)

-- Listen for client requests
net.Receive("EuphoriaRagdollSync", function(len, ply)
    -- Client received sync
end)

function EUPHORIA:GetRagdollState(ent)
    if not ent or not ent:IsValid() then return nil end
    
    local ragdollData = EUPHORIA.RAGDOLLS[ent:EntIndex()]
    if not ragdollData then return nil end
    
    return {
        Position = ent:GetPos(),
        Angles = ent:GetAngles(),
        IsRagdolled = ragdollData.IsRagdolled,
        GroundContact = ragdollData.Perception.GroundContact,
        AnimState = ragdollData.AnimationBlender.CurrentState,
        Energy = ragdollData.DecisionMaker.Energy,
        Caution = ragdollData.DecisionMaker.Caution,
    }
end
