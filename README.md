# Euphoria Ragdoll System for Garry's Mod

A comprehensive, production-ready Garry's Mod addon that implements Euphoria-accurate ragdoll physics with advanced AI decision-making, environmental interaction, and realistic animation blending.

## Features

### Physics & Ragdoll System
- **Advanced Joint System**: Ball-socket, hinge, fixed, and spring joints with PID-controlled constraint satisfaction
- **Realistic Physics Simulation**: Per-bone force accumulation, velocity damping, and collision response
- **Impact Detection**: Tracks collisions and triggers appropriate reactions based on impact force
- **Bone Mass Distribution**: Accurate mass distribution across the skeleton (torso, limbs, head)
- **Self-Collision**: Prevents bones from intersecting with each other
- **Muscle Contraction**: Simulates muscle-driven stabilization and balance

### AI & Decision Making
- **Perception System**: Vision (with FOV and line-of-sight checks), hearing, and environmental awareness
- **Advanced Decision Tree**: Multi-goal evaluation system with priority weighting
  - Survival (threat detection, falling prevention)
  - Balance maintenance and recovery from ragdoll state
  - Environmental interaction and exploration
  - Energy management and rest
- **Personality Traits**: Aggression, caution, and energy levels that influence behavior
- **Memory System**: Remembers entities, hazards, and events for up to 30 seconds
- **Behavioral Controller**: Executes goals through physical forces and animations

### Animation & Movement
- **Animation State Manager**: Automatically selects between idle, walking, running, falling, and ragdoll states
- **Animation Blending**: Smooth transitions between animation states
- **Breathing Simulation**: Subtle chest movement for living ragdolls
- **Movement Velocity Scaling**: Animations speed up with movement
- **Idle Variation**: Random idle animations to prevent repetitive behavior

### Environmental Interaction
- **Prop Interaction**: Grabbing, pulling, and manipulating physics props
- **World Interaction**: Leaning against walls, climbing stairs, and surface contact detection
- **Environmental Forces**: Wind, water drag, and buoyancy support
- **Hazard Detection**: Identifies and responds to moving props and damage zones
- **Surface Navigation**: Handles slopes, stairs, and uneven terrain

### Networking & Synchronization
- **Server-to-Client Sync**: Regular updates of ragdoll state (position, animation, etc.)
- **Optimized Bandwidth**: Updates sent at 20 Hz with only essential data
- **Reaction Synchronization**: Impacts and reactions replicated to all clients
- **Scalable Architecture**: Supports multiple ragdolls without performance degradation

### Debug & Development
- **Visual Debug Rendering**: 
  - Joint visualization
  - Vision cone and perception debugging
  - Applied force vectors
  - Decision tree display
- **Console Commands**:
  - `euphoria_spawn`: Spawn a test ragdoll
  - `euphoria_react`: Trigger reactions on ragdolls
- **Configuration System**: All parameters adjustable via `config.lua`

## Installation

1. Clone or download this addon into your `garrysmod/addons/` directory
2. Restart Garry's Mod or reload the addon
3. The addon will initialize automatically on map load

## Configuration

Edit `lua/euphoria/config.lua` to adjust:

```lua
-- Physics parameters
PHYSICS.GRAVITY = 600
PHYSICS.AIR_RESISTANCE = 0.1
PHYSICS.BODY_STIFFNESS = 0.8

-- Ragdoll behavior
RAGDOLL.ENABLE_SELF_COLLISION = true
RAGDOLL.ENABLE_MUSCLE_CONTRACTION = true
RAGDOLL.BALANCE_STRENGTH = 1.2

-- AI perception
AI.PERCEPTION_RANGE = 2000
AI.PERIPHERAL_VISION = 120 -- degrees
AI.DECISION_INTERVAL = 0.1 -- seconds

-- And many more options...
```

## Usage

### Spawning Ragdolls

**Via Console (Server)**:
```
ephoria_spawn
```

**Via Lua**:
```lua
local ragdoll = EUPHORIA:SpawnRagdoll(
    Vector(0, 0, 0),      -- Position
    Angle(0, 0, 0),       -- Angles
    "models/player/group01/male_01.mdl"  -- Model
)
```

### Triggering Reactions

**Via Console**:
```
ephoria_react impact 1.0
```

**Via Lua**:
```lua
EUPHORIA:TriggerRagdollReaction(entity, "impact", 1.0)
EUPHORIA:TriggerRagdollReaction(entity, "punch", 0.8)
EUPHORIA:TriggerRagdollReaction(entity, "fall", 1.2)
```

### Accessing Ragdoll Data

```lua
local ragdollData = EUPHORIA.RAGDOLLS[entIndex]

if ragdollData then
    print("Is Ragdolled:", ragdollData.IsRagdolled)
    print("Ground Contact:", ragdollData.Perception.GroundContact)
    print("Animation State:", ragdollData.AnimationBlender.CurrentState)
    print("Energy Level:", ragdollData.DecisionMaker.Energy)
    print("Caution Level:", ragdollData.DecisionMaker.Caution)
end
```

## Architecture

### Directory Structure

```
lua/euphoria/
├── init.lua                    -- Main initialization
├── config.lua                  -- Configuration
├── ragdoll/
│   ├── ragdoll_base.lua       -- Base ragdoll class
│   ├── joint_system.lua       -- Joint constraints
│   └── ragdoll.lua            -- Implementation
├── ai/
│   ├── perception.lua         -- Sensory input
│   ├── decision_maker.lua     -- Goal selection
│   └── behavior_controller.lua -- Action execution
├── physics/
│   ├── collision_handler.lua  -- Collision detection
│   └── environment.lua        -- Environmental forces
├── animation/
│   └── animation_blender.lua  -- Animation state management
├── interaction/
│   ├── prop_interaction.lua   -- Prop grabbing
│   └── world_interaction.lua  -- World geometry
├── debug/
│   └── debug_renderer.lua     -- Debug visualization
├── server/
│   ├── spawn.lua             -- Spawning system
│   └── networked_ragdoll.lua -- Network synchronization
└── client/
    └── render.lua            -- Client-side rendering
```

### Core Systems

1. **Ragdoll Base**: Manages bones, joints, and basic physics simulation
2. **Joint System**: Implements constraint satisfaction using PID controllers
3. **Perception**: Detects entities and environmental hazards
4. **Decision Maker**: Evaluates goals and selects best action
5. **Behavior Controller**: Executes behaviors through force application
6. **Animation Blender**: Manages animation states and transitions
7. **Interaction Systems**: Handles props and world geometry

## Performance Considerations

- Update interval: 20 Hz for physics simulation
- Network sync: 20 Hz (adjustable)
- Each ragdoll processes ~10 bones
- Perception checks run at configurable intervals
- Scales linearly with number of ragdolls

## Advanced Customization

### Creating Custom Behaviors

```lua
local ragdoll = EUPHORIA.RAGDOLLS[entIndex]

-- Add custom goal
local customGoal = {
    Type = "MyCustomBehavior",
    Priority = 0.7,
    Score = 100,
    Data = {}
}

-- The decision maker will consider this goal
```

### Extending Joint Types

Edit `lua/euphoria/ragdoll/joint_system.lua` to add new joint types and constraints.

### Custom Reactions

Add reaction types in `lua/euphoria/ragdoll/ragdoll.lua` `React()` method.

## Troubleshooting

**Ragdoll not moving:**
- Check that physics forces are being applied correctly
- Verify the model has valid bones
- Enable debug rendering to visualize forces

**Ragdoll too stiff/loose:**
- Adjust `PHYSICS.BODY_STIFFNESS` in config
- Modify joint `StiffnessFactor` values

**Performance issues:**
- Reduce `AI.DECISION_INTERVAL` to run AI less frequently
- Increase network sync interval in networked_ragdoll.lua
- Reduce number of simultaneous ragdolls

**Animation not playing:**
- Ensure model has required animations
- Check AnimationBlender state transitions

## Debug Mode

Enable debug rendering:

```lua
EUPHORIA:SetConfig("DEBUG.ENABLE_RENDERING", true)
EUPHORIA:SetConfig("DEBUG.SHOW_JOINTS", true)
EUPHORIA:SetConfig("DEBUG.SHOW_PERCEPTION", true)
EUPHORIA:SetConfig("DEBUG.SHOW_FORCES", true)
EUPHORIA:SetConfig("DEBUG.SHOW_DECISION_TREE", true)
```

## License

This addon is provided as-is for use with Garry's Mod.

## Credits

Developed as a comprehensive implementation of Euphoria-style physics simulation in Lua.

## Future Enhancements

- Inverse kinematics for more natural animations
- Sound effects for impacts and reactions
- Persistent ragdoll state across map changes
- Multi-ragdoll interaction (touching, pushing)
- Ragdoll damage model with limb breaking
- Ragdoll clothing and attachment systems
- Advanced pathfinding for exploration
- Emotion system affecting behavior
