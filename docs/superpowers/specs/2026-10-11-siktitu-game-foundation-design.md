# SikTiTu — Game Foundation Design

**Date:** 2026-10-11
**Status:** Approved for implementation planning

## Context & Intent

SikTiTu is a new game project targeting **Android and Web browser**, built with **Godot 4.x**.

Gameplay flow:
- Player controls a **field officer (petugas lapangan)** POV, walking in 3D through a forest environment (simple/low-poly visual style, not realistic).
- The forest is depicted **on fire**: multiple fire points, thick smoke, orange/burning sky, and animals fleeing in panic.
- At certain triggers, gameplay switches to a **2D duel** (Street-Fighter-like but simplified): left/right movement, jump (up), crouch (down), and skill/spell attacks.
- After the duel resolves, gameplay returns to the 3D exploration scene.

This spec covers the **foundation**: project structure, scene architecture, the exploration↔duel transition, the burning-forest atmosphere (full detail, per decision below), control schemes for both modes, Godot installation, and MCP (Claude Code ↔ Godot editor) integration.

## Success Criteria (acceptance for this foundation phase)

1. Godot 4.x is installed and the `SikTiTu` project opens in the editor.
2. MCP is connected — Claude Code can run/read the project live (scene state, console output, screenshots).
3. `forest_level.tscn` is playable: player walks in 3D, fire/smoke/orange sky are visible, animals flee.
4. `duel_arena.tscn` is playable: fighter can move left/right, jump, crouch, and has placeholder skill/attack state.
5. Exploration → duel → exploration transition works (triggerable manually or via a test trigger).
6. Project is committed to a local git repository.

Out of scope for this phase: real art assets (final models/sprites), actual skill/spell balancing, enemy AI in duel, save/load, Android/Web export tuning (structure should not block it, but polishing export is a later task).

## Architecture & Folder Structure

Project root: `PDI/game/SikTiTu/`

```
SikTiTu/
├── project.godot
├── .gitignore
├── addons/
│   └── godot_mcp/                      # MCP WebSocket bridge plugin
├── autoload/
│   └── game_manager.gd                 # singleton: cross-scene state, transitions
├── scenes/
│   ├── main/
│   │   └── main.tscn                   # entry point, loads exploration
│   ├── exploration/
│   │   ├── forest_level.tscn           # 3D burning forest
│   │   ├── player_3d.tscn              # field officer character
│   │   └── effects/
│   │       ├── fire_effect.tscn        # reusable fire particle+light scene
│   │       └── smoke_effect.tscn       # reusable smoke particle scene
│   └── duel/
│       ├── duel_arena.tscn             # 2D duel scene
│       └── fighter_2d.tscn             # duel character
├── scripts/
│   ├── exploration/
│   │   ├── player_3d_controller.gd
│   │   └── animal_flee_controller.gd
│   └── duel/
│       ├── fighter_2d_controller.gd
│       └── fighter_state.gd
├── tests/                              # GUT test suite
└── assets/
    ├── models/
    ├── sprites/
    ├── audio/
    └── fonts/
```

Rationale: organized by feature (exploration vs. duel), not by file type — matches Godot's scene-as-unit model. `autoload/game_manager.gd` is the only state that persists across scene changes, keeping exploration and duel scenes independently developable and testable.

## Scene Transition Flow (Exploration ↔ Duel)

Approach: **fully separate scenes**, switched via `get_tree().change_scene_to_file()`, coordinated by the `GameManager` autoload singleton. This is Godot's standard pattern for "world map → battle" style games (e.g. Pokémon-style), and avoids running 2D and 3D physics/rendering simultaneously (important for Android/Web performance).

Flow:
1. `main.tscn` runs first → loads `forest_level.tscn`.
2. Player explores the burning forest (`CharacterBody3D`, WASD + camera).
3. Entering an encounter trigger (`Area3D`) calls `GameManager.start_duel(enemy_id)`.
4. `GameManager` stores state needed across the switch (player's forest position, HP, `enemy_id`), then calls `change_scene_to_file("duel_arena.tscn")`.
5. `duel_arena.tscn` runs the 2D duel between `fighter_2d.tscn` (player) and the opponent.
6. On duel resolution, `GameManager.end_duel(result)` is called → returns to `forest_level.tscn`, restoring the player's pre-encounter position.

Rejected alternative: a single scene toggling 2D/3D visibility — rejected because it runs both physics worlds concurrently for no benefit at this scope, adding unnecessary rendering cost on low-end Android/Web targets.

## Burning Forest Atmosphere (`forest_level.tscn`) — Full Detail

Decision: implemented at full detail now (not stubbed), per explicit request. This is understood to be a larger task than the bare movement skeleton and will be scoped as its own implementation step(s).

Components:

1. **Sky & lighting**
   - `WorldEnvironment` with `ProceduralSkyMaterial`, orange/red gradient sky-to-horizon.
   - `DirectionalLight3D` tuned to a warm orange-red tint, reduced intensity (smoke-occluded daylight feel).
   - Optional `OmniLight3D` instances at fire points for local light, flicker driven by a `Tween`/noise function in script.

2. **Fire** — `scenes/exploration/effects/fire_effect.tscn`
   - `GPUParticles3D` with emissive orange-red material, paired with a small `OmniLight3D`.
   - Built as a reusable scene, instanced multiple times across `forest_level.tscn`.

3. **Smoke** — `scenes/exploration/effects/smoke_effect.tscn`
   - `GPUParticles3D`, gray semi-transparent particles rising with turbulence; higher density near fire points; additional ambient smoke/fog instances reduce long-distance visibility across the scene.

4. **Fleeing animals** — `scripts/exploration/animal_flee_controller.gd`
   - Multiple low-poly animal types (`CharacterBody3D` + `NavigationAgent3D`).
   - AI: detect nearest danger point (player/fire) within a radius → path away via `NavigationAgent3D` (avoiding tree obstacles) → per-type randomized flee speed for varied urgency.
   - `AnimalSpawner.gd` places animals at start positions, each fleeing toward a designated safe zone outside the fire area.

5. **Performance guardrails**: fire/smoke instance count and animal count are driven by tunable constants (`MAX_FIRE_POINTS`, `MAX_ANIMALS`) so density can be reduced for low-end Android/Web without structural changes.

## Control Schemes

**Exploration (3D) — `player_3d_controller.gd`:**
- `CharacterBody3D` with standard gravity.
- WASD/arrow keys move relative to camera facing (third-person / over-shoulder).
- `SpringArm3D` + `Camera3D` follow the player; mouse-orbit camera (can be disabled later for a mobile touch control scheme).

**Duel (2D) — `fighter_2d_controller.gd` + `fighter_state.gd`:**
Side-view fighting game controls, confirmed interpretation:
- **Left/Right** — move toward/away from opponent (X axis).
- **Up** — jump (temporary Y-axis motion under gravity).
- **Down** — crouch (hitbox change, stationary).
- **Skill/Spell** — separate action button(s), triggers attack/skill animation and hit/hurt boxes (including possible projectile skills).

State machine: `Idle → Walk → Jump → Crouch → Attack/Skill → Hit/Stagger`, implemented via a lightweight state machine script (`fighter_state.gd`), driving an `AnimationPlayer`/`AnimationTree`.

## Godot Installation

- Install via winget: `winget install --id GodotEngine.GodotEngine` (GDScript-only build; sufficient for this project — no C# requirement identified).
- Record the resolved executable path for use by the MCP server and later command-line export steps.

## MCP Integration (Claude Code ↔ Godot Editor)

Using **godot-mcp** (Coding-Solo), a Node.js-based MCP server that bridges to the Godot editor over a local WebSocket connection via an in-editor plugin.

Setup steps:
1. Install `godot-mcp` (exact install command/version verified against the current repo/npm listing at implementation time, not assumed from training data).
2. Copy the `addons/godot_mcp/` plugin into the `SikTiTu` project; enable it via Project Settings → Plugins.
3. Register the MCP server with Claude Code (`claude mcp add`, project scope) pointing at the Node server entry point, with the Godot executable path available to it.
4. With the Godot editor open and the plugin enabled, Claude Code can run the project, read/write scene files, read console/error output, and capture editor screenshots via MCP.

Capability level chosen: **full editor control** (run project, read/write scenes, debug output, screenshots) — not read-only.

## Testing

Godot projects are primarily validated by manual play-testing for visual/gameplay feel (particles, animal AI, movement feel) — this is normal for game development, not a coverage gap.

For logic that is unit-testable, add the **GUT (Godot Unit Test)** addon with initial tests covering:
- `GameManager` transition correctness (`start_duel`/`end_duel` store and restore state correctly).
- `fighter_state.gd` state machine validity (e.g., invalid transitions like re-entering Attack while already attacking are rejected).

## Git

- `git init` at `PDI/game/SikTiTu`.
- Standard Godot `.gitignore` (`.godot/`, local-path-sensitive parts of `export_presets.cfg`, `*.translation`, etc.).
- First commit made once the foundation (structure + skeleton scenes) is built and verified running in the editor.
