-- Euphoria Ragdoll System - Main Initialization
-- Advanced ragdoll physics with Euphoria-accurate reactions

EUPHORIA = EUPHORIA or {}
EUPHORIA.VERSION = "1.0.0"
EUPHORIA.RAGDOLLS = {}
EUPHORIA.CONFIG = {}

-- Load configuration
include("euphoria/config.lua")

-- Load core systems
include("euphoria/ragdoll/ragdoll_base.lua")
include("euphoria/ragdoll/joint_system.lua")
include("euphoria/ragdoll/ragdoll.lua")
include("euphoria/ai/perception.lua")
include("euphoria/ai/decision_maker.lua")
include("euphoria/ai/behavior_controller.lua")
include("euphoria/physics/collision_handler.lua")
include("euphoria/physics/environment.lua")
include("euphoria/animation/animation_blender.lua")
include("euphoria/interaction/prop_interaction.lua")
include("euphoria/interaction/world_interaction.lua")
include("euphoria/debug/debug_renderer.lua")

-- Initialize hooks
if SERVER then
    include("euphoria/server/spawn.lua")
    include("euphoria/server/networked_ragdoll.lua")
end

if CLIENT then
    include("euphoria/client/render.lua")
end

if engine.ActiveGamemode() then
    print("[Euphoria] Ragdoll System v" .. EUPHORIA.VERSION .. " loaded successfully!")
end
