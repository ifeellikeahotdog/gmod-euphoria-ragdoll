-- Euphoria Ragdoll System
-- Complete Integration Example

if not EUPHORIA then
    print("[Error] Euphoria system not loaded!")
    return
end

-- ============================================================================
-- SYSTEM INTEGRATION TEST
-- ============================================================================

if SERVER then
    -- Helper function to spawn and test a ragdoll
    function EUPHORIA:TestRagdoll()
        local testRagdoll = self:SpawnRagdoll(
            Vector(0, 0, 100),
            Angle(0, 0, 0),
            "models/player/group01/male_01.mdl"
        )
        
        if testRagdoll and testRagdoll:IsValid() then
            print("[Test] Successfully created ragdoll")
            
            -- Give it initial velocity
            testRagdoll:SetVelocity(Vector(100, 0, 0))
            
            -- Test reaction after 2 seconds
            timer.Simple(2, function()
                if testRagdoll and testRagdoll:IsValid() then
                    self:TriggerRagdollReaction(testRagdoll, "impact", 1.0)
                    print("[Test] Triggered impact reaction")
                end
            end)
            
            return testRagdoll
        else
            print("[Error] Failed to create test ragdoll")
            return nil
        end
    end
end

-- ============================================================================
-- GLOBAL HOOKS
-- ============================================================================

if SERVER then
    -- Cleanup ragdolls when they're removed
    hook.Add("EntityRemoved", "EuphoriaRagdollCleanup", function(ent)
        if not ent:IsValid() then return end
        
        local ragdollData = EUPHORIA.RAGDOLLS[ent:EntIndex()]
        if ragdollData then
            EUPHORIA.RAGDOLLS[ent:EntIndex()] = nil
            hook.Remove("Think", "EuphoriaRagdoll_" .. ent:EntIndex())
            print("[Euphoria] Cleaned up ragdoll")
        end
    end)
end

-- ============================================================================
-- CONSOLE VARIABLES & COMMANDS
-- ============================================================================

if game.IsDedicated() or IsListenServer() then
    -- Debug visualization toggle
    CreateConVar("euphoria_debug_render", "0", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
    CreateConVar("euphoria_debug_joints", "0", bit.bor(FCVAR_ARCHIVE))
    CreateConVar("euphoria_debug_perception", "0", bit.bor(FCVAR_ARCHIVE))
    CreateConVar("euphoria_debug_forces", "0", bit.bor(FCVAR_ARCHIVE))
    
    concommand.Add("euphoria_test", function(ply, cmd, args)
        EUPHORIA:TestRagdoll()
    end)
    
    concommand.Add("euphoria_config", function(ply, cmd, args)
        if args[1] then
            local path = args[1]
            local value = tonumber(args[2])
            if value then
                EUPHORIA:SetConfig(path, value)
                print("[Euphoria] Set", path, "to", value)
            end
        else
            print("Usage: euphoria_config <path> <value>")
            print("Example: euphoria_config PHYSICS.GRAVITY 800")
        end
    end)
    
    concommand.Add("euphoria_stats", function(ply, cmd, args)
        print("\n=== Euphoria Statistics ===")
        print("Active Ragdolls:", table.Count(EUPHORIA.RAGDOLLS))
        
        for entIdx, ragdoll in pairs(EUPHORIA.RAGDOLLS) do
            if ragdoll.Entity and ragdoll.Entity:IsValid() then
                print(string.format(
                    "  - %s: IsRagdolled=%s, GroundContact=%s, Energy=%.2f",
                    ragdoll.Entity:GetName(),
                    tostring(ragdoll.IsRagdolled),
                    tostring(ragdoll.Perception.GroundContact),
                    ragdoll.DecisionMaker.Energy
                ))
            end
        end
        print("=========================\n")
    end)
end

print("[Euphoria] Integration layer loaded successfully!")
