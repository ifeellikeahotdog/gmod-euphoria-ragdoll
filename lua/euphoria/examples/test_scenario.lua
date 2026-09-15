-- Example Map with Euphoria Ragdolls
-- Demonstrates usage and features

-- Wait for euphoria to load
if not EUPHORIA or not EUPHORIA.RAGDOLLS then
    timer.Simple(1, function()
        if EUPHORIA then
            print("[Example] Euphoria Ragdoll System loaded!")
            EUPHORIA_EXAMPLE:Initialize()
        end
    end)
    return
end

EUPHORIA_EXAMPLE = {}

function EUPHORIA_EXAMPLE:Initialize()
    print("[Example] Initializing Euphoria example scenarios...")
    
    if SERVER then
        self:SpawnTestRagdolls()
        self:SetupReactionTriggers()
    end
end

function EUPHORIA_EXAMPLE:SpawnTestRagdolls()
    -- Spawn multiple ragdolls at different locations
    local spawnPoints = {
        Vector(0, 0, 100),
        Vector(200, 0, 100),
        Vector(-200, 0, 100),
        Vector(0, 200, 100),
    }
    
    for _, pos in ipairs(spawnPoints) do
        timer.Simple(0.5, function()
            local ent = EUPHORIA:SpawnRagdoll(pos, Angle(0, 0, 0))
            if ent then
                print("[Example] Spawned ragdoll at", pos)
            end
        end)
    end
end

function EUPHORIA_EXAMPLE:SetupReactionTriggers()
    -- Setup damage triggers that cause reactions
    hook.Add("EntityTakeDamage", "EuphoriaExampleDamage", function(ent, dmgInfo)
        if not ent:IsValid() then return end
        
        local ragdollData = EUPHORIA.RAGDOLLS[ent:EntIndex()]
        if ragdollData then
            local damageForce = dmgInfo:GetDamage() / 100
            EUPHORIA:TriggerRagdollReaction(ent, "impact", math.min(damageForce, 2.0))
        end
    end)
end

if EUPHORIA then
    EUPHORIA_EXAMPLE:Initialize()
end
