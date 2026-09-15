-- Euphoria Ragdoll - Advanced Features & Customization Guide

This document provides advanced customization options and extension points for the Euphoria Ragdoll System.

## Custom Joint Types

To add custom joint types, modify `lua/euphoria/ragdoll/joint_system.lua`:

```lua
JOINT_SYSTEM.TYPES = {
    BALL_SOCKET = 1,
    HINGE = 2,
    FIXED = 3,
    SPRING = 4,
    RAGDOLL = 5,
    CUSTOM = 6,  -- Add your type
}

function Joint:CalculateConstraintForce(bone1, bone2, deltaTime)
    if self.Type == JOINT_SYSTEM.TYPES.CUSTOM then
        -- Custom constraint logic here
    end
end
```

## Extending Behavior Controller

Add custom behaviors to `lua/euphoria/ai/behavior_controller.lua`:

```lua
function BEHAVIOR_CONTROLLER:BehaviorCustom(goal, deltaTime)
    -- Your custom behavior implementation
    local targetEntity = goal.Data.Target
    if targetEntity then
        -- Apply forces based on custom logic
    end
end

-- In the Update method:
elseif goal.Type == "CustomBehavior" then
    self:BehaviorCustom(goal, deltaTime)
end
```

## Personality Systems

Modify AI personality traits:

```lua
local ragdoll = EUPHORIA.RAGDOLLS[entIndex]
ragdoll.DecisionMaker.Aggression = 0.8  -- More aggressive
ragdoll.DecisionMaker.Caution = 0.3     -- Less cautious
ragdoll.DecisionMaker.Energy = 0.5      -- Medium energy
```

## Custom Perception Layers

Add new perception types to `lua/euphoria/ai/perception.lua`:

```lua
function PERCEPTION:UpdateCustomSense(headPos)
    -- Custom sensing logic
    local customThreats = {}
    
    -- Your detection code
    
    self.CustomThreats = customThreats
end
```

## Physics Tuning

### Realistic Ragdoll (Euphoria-Style)

```lua
EUPHORIA:SetConfig("PHYSICS.GRAVITY", 600)
EUPHORIA:SetConfig("PHYSICS.AIR_RESISTANCE", 0.1)
EUPHORIA:SetConfig("PHYSICS.BODY_STIFFNESS", 0.8)
EUPHORIA:SetConfig("RAGDOLL.BALANCE_STRENGTH", 1.2)
```

### Loose/Floppy Ragdoll

```lua
EUPHORIA:SetConfig("PHYSICS.BODY_STIFFNESS", 0.3)
EUPHORIA:SetConfig("PHYSICS.JOINT_FRICTION", 0.2)
EUPHORIA:SetConfig("RAGDOLL.BALANCE_STRENGTH", 0.5)
```

### Stiff/Robot-Like Ragdoll

```lua
EUPHORIA:SetConfig("PHYSICS.BODY_STIFFNESS", 1.5)
EUPHORIA:SetConfig("PHYSICS.JOINT_FRICTION", 0.8)
EUPHORIA:SetConfig("RAGDOLL.BALANCE_STRENGTH", 2.0)
```

## Event Hooks

Listen for ragdoll events:

```lua
-- When a ragdoll is created
hook.Add("EuphoriaRagdollCreated", "MyHook", function(ragdoll, ent)
    print("Ragdoll created:", ent:GetName())
end)

-- When ragdoll takes damage
hook.Add("EuphoriaRagdollDamage", "MyHook", function(ragdoll, force)
    print("Ragdoll damaged with force:", force)
end)

-- When ragdoll stands up
hook.Add("EuphoriaRagdollStandUp", "MyHook", function(ragdoll)
    print("Ragdoll stood up!")
end)
```

## Performance Optimization

### Reduce Perception Range
```lua
EUPHORIA:SetConfig("AI.PERCEPTION_RANGE", 1000)  -- Shorter range = faster
```

### Increase Decision Interval
```lua
EUPHORIA:SetConfig("AI.DECISION_INTERVAL", 0.2)  -- Less frequent decisions
```

### Network Optimization
```lua
-- In lua/euphoria/server/networked_ragdoll.lua
local updateInterval = 0.1  -- Reduce sync frequency (10 Hz)
```

## Creating Specialized Ragdoll Types

```lua
function EUPHORIA:CreateSpecializedRagdoll(ent, type)
    local ragdoll = self:CreateRagdoll(ent)
    
    if type == "athlete" then
        ragdoll.DecisionMaker.Energy = 1.0
        ragdoll.DecisionMaker.Aggression = 0.7
        EUPHORIA:SetConfig("RAGDOLL.BALANCE_STRENGTH", 1.5)
    elseif type == "elderly" then
        ragdoll.DecisionMaker.Energy = 0.5
        ragdoll.DecisionMaker.Caution = 0.9
        EUPHORIA:SetConfig("RAGDOLL.BALANCE_STRENGTH", 0.8)
    end
    
    return ragdoll
end
```

## Debugging Custom Behaviors

Enable detailed logging:

```lua
function EUPHORIA:DebugRagdoll(entIndex)
    local ragdoll = self.RAGDOLLS[entIndex]
    if not ragdoll then return end
    
    print("=== Ragdoll Debug Info ===")
    print("Entity:", ragdoll.Entity:GetName())
    print("Current Goal:", ragdoll.DecisionMaker:GetCurrentGoal().Type)
    print("Animation State:", ragdoll.AnimationBlender:GetCurrentState())
    print("Visible Entities:", #ragdoll.Perception.VisibleEntities)
    print("Ground Contact:", ragdoll.Perception.GroundContact)
    print("Stability Factor:", ragdoll.StabilityFactor)
    print("==========================")
end
```

## Integration with Existing Systems

### With NPC Systems
```lua
hook.Add("OnNPCKilled", "EuphoriaRagdoll", function(npc)
    if npc:IsValid() then
        EUPHORIA:SpawnRagdoll(npc:GetPos(), npc:GetAngles(), npc:GetModel())
    end
end)
```

### With Damage Systems
```lua
hook.Add("EntityTakeDamage", "EuphoriaRagdollDamage", function(ent, dmg)
    local ragdoll = EUPHORIA.RAGDOLLS[ent:EntIndex()]
    if ragdoll then
        local force = dmg:GetDamage() / 100
        EUPHORIA:TriggerRagdollReaction(ent, "impact", force)
    end
end)
```

## Advanced Physics

### Ragdoll Constraints

Modify joint limits in `lua/euphoria/ragdoll/joint_system.lua`:

```lua
function Joint:New(bone1Index, bone2Index, jointType)
    -- ...
    self.RotationLimit = 45  -- Max rotation degrees
    self.LinearLimit = 50    -- Max stretch distance
    self.MaxStrain = 10000   -- Breaking point
end
```

### Collision Response

Customize in `lua/euphoria/physics/collision_handler.lua`:

```lua
local reflection = bone.Velocity - (2 * bone.Velocity:Dot(collision.HitNormal) * collision.HitNormal)
bone.Velocity = reflection * 0.6  -- Bounce coefficient (0-1)
```

Lower values = more dampening, higher values = more bouncy.

## Multiplayer Considerations

- Ragdoll state is synced at 20 Hz by default
- Physics runs on server, replicated to clients
- Consider lag compensation for reactions
- Network bandwidth scales with number of ragdolls

## Common Issues & Solutions

**Ragdoll stuck in ground:**
- Increase `RAGDOLL.BALANCE_STRENGTH`
- Check collision trace code
- Verify bone positions

**Jerky animation:**
- Increase `ANIMATION.BLEND_SPEED`
- Reduce `AI.DECISION_INTERVAL`

**Memory leaks:**
- Ensure ragdolls are properly cleaned up
- Check EntityRemoved hook
- Monitor EUPHORIA.RAGDOLLS table size
