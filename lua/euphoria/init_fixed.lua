-- BUGFIX: Module Loading System
-- Properly caches and initializes all modules

EUPHORIA = EUPHORIA or {}
EUPHORIA.VERSION = "1.0.0"
EUPHORIA.RAGDOLLS = {}
EUPHORIA.CONFIG = {}
EUPHORIA.MODULES = {}  -- NEW: Cache modules

-- Load configuration
include("euphoria/config.lua")

-- NEW: Helper to safely load modules
local function LoadModule(path)
    if EUPHORIA.MODULES[path] then
        return EUPHORIA.MODULES[path]
    end
    local module = include(path)
    if module then
        EUPHORIA.MODULES[path] = module
    end
    return module
end

-- Load core systems with caching
local ragdollBase = LoadModule("euphoria/ragdoll/ragdoll_base.lua")
local jointSystem = LoadModule("euphoria/ragdoll/joint_system.lua")
local ragdollImpl = LoadModule("euphoria/ragdoll/ragdoll.lua")
local perception = LoadModule("euphoria/ai/perception.lua")
local decisionMaker = LoadModule("euphoria/ai/decision_maker.lua")
local behaviorController = LoadModule("euphoria/ai/behavior_controller.lua")
local collisionHandler = LoadModule("euphoria/physics/collision_handler.lua")
local environment = LoadModule("euphoria/physics/environment.lua")
local animationBlender = LoadModule("euphoria/animation/animation_blender.lua")
local propInteraction = LoadModule("euphoria/interaction/prop_interaction.lua")
local worldInteraction = LoadModule("euphoria/interaction/world_interaction.lua")
local debugRenderer = LoadModule("euphoria/debug/debug_renderer.lua")

-- Make modules accessible via EUPHORIA
EUPHORIA.MODULES.RagdollBase = ragdollBase
EUPHORIA.MODULES.JointSystem = jointSystem
EUPHORIA.MODULES.RagdollImpl = ragdollImpl
EUPHORIA.MODULES.Perception = perception
EUPHORIA.MODULES.DecisionMaker = decisionMaker
EUPHORIA.MODULES.BehaviorController = behaviorController
EUPHORIA.MODULES.CollisionHandler = collisionHandler
EUPHORIA.MODULES.Environment = environment
EUPHORIA.MODULES.AnimationBlender = animationBlender
EUPHORIA.MODULES.PropInteraction = propInteraction
EUPHORIA.MODULES.WorldInteraction = worldInteraction
EUPHORIA.MODULES.DebugRenderer = debugRenderer

-- Initialize hooks
if SERVER then
    LoadModule("euphoria/server/spawn.lua")
    LoadModule("euphoria/server/networked_ragdoll.lua")
end

if CLIENT then
    LoadModule("euphoria/client/render.lua")
end

if engine.ActiveGamemode() then
    print("[Euphoria] Ragdoll System v" .. EUPHORIA.VERSION .. " loaded successfully!")
end
