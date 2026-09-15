# Euphoria Ragdoll - Debug & Issue Report

## Critical Issues Found & Fixed

### 1. **Module Returns Not Stored**
**Severity:** CRITICAL  
**File:** `init.lua`, `ragdoll.lua`, `spawn.lua`

**Problem:**
```lua
include("euphoria/ragdoll/ragdoll.lua")
```
Modules are included but return values are not stored, so functions can't be called.

**Fix:** Store returned modules as global references.

### 2. **Joint System Initialization Missing**
**Severity:** CRITICAL  
**File:** `ragdoll.lua`, line 61

**Problem:**
```lua
if ragdoll.CollisionHandler then
    ragdoll.CollisionHandler:Update(ragdoll, deltaTime)
end
```
CollisionHandler is never initialized but code tries to use it.

**Fix:** Initialize collision handler in Initialize function.

### 3. **Division by Zero in Physics**
**Severity:** HIGH  
**File:** `ragdoll_base.lua`, line 133

**Problem:**
```lua
local acceleration = bone.Force / bone.Mass
```
If bone.Mass is 0, division by zero causes crash.

**Fix:** Add safety check for mass.

### 4. **Angle Math Operations Not Supported**
**Severity:** HIGH  
**File:** `joint_system.lua`, line 72

**Problem:**
```lua
local force = (error * kp) + (errorDerivative * kd) + (self.ErrorIntegral * ki)
self.LastError = error  -- error is Vector, not Angle
```
Trying to add/subtract Angle objects directly.

**Fix:** Only use Vector math for forces.

### 5. **Bone Index Array Iteration Bug**
**Severity:** HIGH  
**File:** `ragdoll.lua`, lines 89, 115

**Problem:**
```lua
for i = 0, math.min(10, #ragdoll.Bones) do
    if ragdoll.Bones[i] then
```
Iterating 0-based but Lua tables are 1-based. Will skip bone 0.

**Fix:** Use ipairs() or adjust loop.

### 6. **Missing Network String Initialization**
**Severity:** HIGH  
**File:** `spawn.lua`, `networked_ragdoll.lua`

**Problem:**
Network strings are added in spawn.lua but code runs before SERVER is fully initialized.

**Fix:** Move to proper server initialization.

### 7. **Per-Frame Include Overhead**
**Severity:** MEDIUM  
**File:** `ragdoll.lua`, line 61

**Problem:**
```lua
local jointSystem = include("euphoria/ragdoll/joint_system.lua")
jointSystem:SolveJoints(ragdoll, deltaTime)
```
Include called every frame. Should be cached.

**Fix:** Cache module references.

### 8. **Perception FindInSphere Requires Position**
**Severity:** MEDIUM  
**File:** `perception.lua`, lines 59, 104, 154

**Problem:**
Calling `ents.FindInSphere()` with Vector before checking if headBone exists.

**Fix:** Add null checks before calling.

### 9. **Client-Side Entity References**
**Severity:** MEDIUM  
**File:** `client/render.lua`, line 56

**Problem:**
Client tries to access EUPHORIA:GetConfig() but EUPHORIA might not be initialized on client.

**Fix:** Add client-side initialization.

### 10. **Ragdoll Spawn Returns Nil on Failure**
**Severity:** MEDIUM  
**File:** `spawn.lua`, line 10-11

**Problem:**
No error handling when entity creation fails. Code assumes ent is valid.

**Fix:** Add proper error handling.

### 11. **Bone Position Not Synced to Entity**
**Severity:** HIGH  
**File:** `ragdoll_base.lua`, `ragdoll.lua`

**Problem:**
Bone positions are updated in simulation but never actually applied to the entity's bone system. Ragdoll appears static.

**Fix:** Need to apply bone positions back to entity.

### 12. **Think Hook Accumulation**
**Severity:** MEDIUM  
**File:** `spawn.lua`, line 37

**Problem:**
Think hook never removed. Memory leak with many ragdolls.

**Fix:** Add proper cleanup in EntityRemoved hook.

### 13. **VectorRand() Not Standard GMod Function**
**Severity:** MEDIUM  
**File:** `ragdoll.lua`, line 91

**Problem:**
`VectorRand()` doesn't exist in standard GMod. Should use math.random.

**Fix:** Replace with proper random vector generation.

### 14. **Empty Config Values**
**Severity:** HIGH  
**File:** `config.lua` not fully loaded

**Problem:**
Config is set but some systems call GetConfig before it's fully initialized.

**Fix:** Ensure config loads first.

### 15. **Entity Validation Missing**
**Severity:** MEDIUM  
**File:** Multiple files

**Problem:**
Many functions assume entities are valid without checking.

**Fix:** Add `if not ent:IsValid() then return end` checks.

---

## Performance Issues

1. **Excessive Tracing:** Ground contact checked every frame with 2 traces per ragdoll
2. **Sphere Queries:** ents.FindInSphere called multiple times per perception update
3. **String Operations:** string.find() used in loops
4. **Per-Frame Includes:** Modules re-included every update

## Memory Issues

1. **Entity References:** Ragdoll tables hold strong references to entities
2. **Think Hooks:** Not properly cleaned up
3. **Memory Arrays:** Impact history and memory tables never trimmed

## Recommendations

✅ **Use provided bug fix files** - Contains all corrections  
✅ **Add error handling** - Wrap critical functions in pcall()  
✅ **Profile before use** - Monitor CPU/memory with many ragdolls  
✅ **Test on various models** - Not all player models have same bone names  
✅ **Cache references** - Don't include/lookup every frame  
