-- Euphoria Configuration System

EUPHORIA.CONFIG = {
    -- Physics Configuration
    PHYSICS = {
        GRAVITY = 600,
        AIR_RESISTANCE = 0.1,
        BODY_STIFFNESS = 0.8,
        JOINT_FRICTION = 0.5,
        COLLISION_DAMPING = 0.3,
        MAX_FORCE = 5000,
    },

    -- Ragdoll Configuration
    RAGDOLL = {
        ENABLE_SELF_COLLISION = true,
        ENABLE_MUSCLE_CONTRACTION = true,
        ENABLE_BALANCE = true,
        BALANCE_STRENGTH = 1.2,
        MUSCLE_POWER = 1.0,
        LIMB_MASS_RATIO = 0.15, -- per body part
        TORSO_MASS = 40,
    },

    -- AI Configuration
    AI = {
        PERCEPTION_RANGE = 2000,
        PERIPHERAL_VISION = 120, -- degrees
        DECISION_INTERVAL = 0.1, -- seconds
        REACTION_TIME = 0.05,
        MEMORY_DURATION = 30,
    },

    -- Animation Configuration
    ANIMATION = {
        BLEND_SPEED = 0.15,
        MOVEMENT_SPEED_FACTOR = 1.5,
        BREATHING_CYCLE = 3.0,
        IDLE_VARIATION = 0.3,
    },

    -- Interaction Configuration
    INTERACTION = {
        GRAB_RANGE = 150,
        PROP_FORCE_MULTIPLIER = 1.5,
        LEAN_ANGLE = 45,
        STEP_HEIGHT = 18,
    },

    -- Debug Configuration
    DEBUG = {
        ENABLE_RENDERING = false,
        SHOW_JOINTS = false,
        SHOW_PERCEPTION = false,
        SHOW_FORCES = false,
        SHOW_DECISION_TREE = false,
    }
}

-- Helper functions for config
function EUPHORIA:GetConfig(path)
    local parts = string.Split(path, ".")
    local value = EUPHORIA.CONFIG
    
    for _, part in ipairs(parts) do
        if type(value) == "table" and value[part] then
            value = value[part]
        else
            return nil
        end
    end
    
    return value
end

function EUPHORIA:SetConfig(path, value)
    local parts = string.Split(path, ".")
    local last = table.remove(parts)
    local current = EUPHORIA.CONFIG
    
    for _, part in ipairs(parts) do
        if not current[part] then
            current[part] = {}
        end
        current = current[part]
    end
    
    current[last] = value
end
