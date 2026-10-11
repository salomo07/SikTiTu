# SikTiTu Game Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up a working Godot 4.x foundation for SikTiTu: installed engine, MCP-connected editor, a playable burning-forest 3D exploration scene, a playable 2D duel scene, and a working transition between them.

**Architecture:** Godot 4.x project with feature-based folder structure. Two fully separate scenes (3D exploration, 2D duel) coordinated by a `GameManager` autoload singleton via `change_scene_to_file`. Pure/testable logic (state machines, flee-target math, input registration) lives in plain GDScript classes covered by GUT unit tests; scene composition and visual effects (particles, lighting, navigation) are built in-editor (via MCP or directly) and verified by manual play-testing, per the project's stated testing philosophy.

**Tech Stack:** Godot 4.x (GDScript), GUT (Godot Unit Test) addon, godot-mcp (Coding-Solo) for editor↔Claude Code bridge, git.

**Spec:** `docs/superpowers/specs/2026-10-11-siktitu-game-foundation-design.md`

## Global Constraints

- Project root: `PDI/game/SikTiTu/` (already git-initialized; spec doc already committed).
- Godot version: 4.x, GDScript-only build (no C#/.NET requirement).
- Folder structure must match the spec's layout exactly (`autoload/`, `scenes/exploration/`, `scenes/duel/`, `scripts/exploration/`, `scripts/duel/`, `tests/`, `assets/`).
- Scene transitions use fully separate scenes (no simultaneous 2D+3D physics) — never implement a "toggle visibility" alternative.
- Duel controls: Left/Right = move, Up = jump, Down = crouch, skill buttons = attack/skill (confirmed interpretation).
- Particle/animal density must be driven by named constants (`MAX_FIRE_POINTS`, `MAX_ANIMALS`) so it can be tuned down for Android/Web later.
- Every code task follows red→green→commit; scene/visual tasks follow build→manually verify via MCP→commit.
- Exact install commands/versions for GUT and godot-mcp must be verified against the current repo/listing at execution time, not assumed from memory — each relevant task has an explicit "verify current method" step for this.

## Review Focus

- **Re-triggering a duel encounter:** walking back into the same `Area3D` encounter zone right after a duel ends must not immediately restart another duel (covered in Task 16 with a `triggered` guard + test of `GameManager`'s duel-active guard).
- **Stale state between duels:** starting a second duel must not leak `current_enemy_id`/`player_hp` from the previous one (covered in Task 5's `GameManager` tests).
- **Floor-less player falls forever:** forest and duel floors must have real `CollisionShape3D`/`CollisionShape2D` geometry, not just visual meshes (covered in Tasks 9/10/14 verification steps).
- **Unbaked navigation breaks animal flee:** `NavigationAgent3D` silently does nothing useful without a baked `NavigationRegion3D` — Task 13 explicitly bakes navigation and verifies animals actually move, not just that the script runs.
- **Input action name collisions:** custom actions (`move_left`, `duel_jump`, etc.) must not collide with Godot's built-in `ui_*` actions in a way that causes double-handling — Task 4's tests assert the exact custom action names exist and are idempotent to register twice.

---

## File Structure

```
SikTiTu/
├── project.godot                                  [Task 2]
├── .gitignore                                      [Task 2]
├── addons/
│   ├── gut/                                        [Task 3, vendored]
│   └── godot_mcp/                                  [Task 8, vendored]
├── autoload/
│   ├── input_setup.gd                              [Task 4]
│   └── game_manager.gd                             [Task 5]
├── scripts/
│   ├── duel/
│   │   ├── fighter_state.gd                        [Task 6]
│   │   └── fighter_2d_controller.gd                [Task 14]
│   └── exploration/
│       ├── player_3d_controller.gd                 [Task 9]
│       └── animal_flee_controller.gd               [Task 7, 13]
├── scenes/
│   ├── main/
│   │   └── main.tscn                               [Task 9]
│   ├── exploration/
│   │   ├── player_3d.tscn                          [Task 9]
│   │   ├── forest_level.tscn                       [Task 10, 12, 13, 16]
│   │   ├── animal.tscn                             [Task 13]
│   │   └── effects/
│   │       ├── fire_effect.tscn                    [Task 11]
│   │       └── smoke_effect.tscn                   [Task 11]
│   └── duel/
│       ├── fighter_2d.tscn                         [Task 14]
│       └── duel_arena.tscn                         [Task 15, 16]
├── tests/
│   └── unit/
│       ├── test_input_setup.gd                     [Task 4]
│       ├── test_game_manager.gd                    [Task 5]
│       ├── test_fighter_state.gd                   [Task 6]
│       └── test_animal_flee_controller.gd          [Task 7]
└── assets/
    ├── models/, sprites/, audio/, fonts/            [created empty, Task 2]
```

---

### Task 1: Install Godot 4.x and record its executable path

**Files:** none (tooling step)

**Interfaces:**
- Produces: `$GODOT` — the resolved absolute path to the Godot 4.x executable, referenced by every later task's run commands.

- [ ] **Step 1: Install Godot via winget**

Run:
```powershell
winget install --id GodotEngine.GodotEngine -e --accept-source-agreements --accept-package-agreements
```

- [ ] **Step 2: Resolve the installed executable path**

Run:
```powershell
Get-Command godot -ErrorAction SilentlyContinue
Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter "Godot*.exe" -ErrorAction SilentlyContinue | Select-Object -First 5 FullName
```
Record the full path to the `.exe` (console build preferred if both console and non-console variants exist, since CLI test runs need visible output). Call this path `$GODOT` for all later steps in this plan.

- [ ] **Step 3: Verify the install**

Run: `& "$GODOT" --version`
Expected: prints a version string starting with `4.`

- [ ] **Step 4: Commit**

No files changed in this task — nothing to commit. Proceed to Task 2.

---

### Task 2: Scaffold the Godot project and folder structure

**Files:**
- Create: `project.godot`
- Create: `.gitignore`
- Create: `assets/models/.gitkeep`, `assets/sprites/.gitkeep`, `assets/audio/.gitkeep`, `assets/fonts/.gitkeep`
- Create: `scenes/main/`, `scenes/exploration/effects/`, `scenes/duel/`, `scripts/exploration/`, `scripts/duel/`, `autoload/`, `tests/unit/` (empty dirs, created via `.gitkeep` or first real file in a later task)

**Interfaces:**
- Produces: an openable Godot 4.x project named `SikTiTu` at the repo root, with the full folder layout from the File Structure section ready to receive files.

- [ ] **Step 1: Create the folder tree**

Run:
```bash
cd "C:\Users\mit01\PDI\game\SikTiTu"
mkdir -p assets/models assets/sprites assets/audio assets/fonts
mkdir -p scenes/main scenes/exploration/effects scenes/duel
mkdir -p scripts/exploration scripts/duel
mkdir -p autoload tests/unit addons
touch assets/models/.gitkeep assets/sprites/.gitkeep assets/audio/.gitkeep assets/fonts/.gitkeep
```

- [ ] **Step 2: Create `project.godot`**

```ini
; Engine configuration file.
; It's best edited using the editor UI and not directly,
; since the parameters that go here are not all obvious.

config_version=5

[application]

config/name="SikTiTu"
run/main_scene="res://scenes/main/main.tscn"
config/features=PackedStringArray("4.3", "GL Compatibility")
config/icon="res://icon.svg"

[rendering]

renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
```

Note: `renderer/rendering_method="gl_compatibility"` is chosen because it is the Godot 4.x renderer that runs on both Android and Web export targets without extra driver requirements — Forward+ does not run on Web.

- [ ] **Step 3: Create `.gitignore`**

```gitignore
# Godot 4+ specific ignores
.godot/
.import/
export.cfg
export_credentials.cfg

# Imported translations (automatically generated from CSV files)
*.translation

# Mono-specific ignores
.mono/
data_*/

# System/IDE
.DS_Store
Thumbs.db
```

- [ ] **Step 4: Verify the project opens**

Run: `& "$GODOT" --headless --path "C:\Users\mit01\PDI\game\SikTiTu" --quit`
Expected: exits cleanly (exit code 0) with no error about a missing/invalid project — this confirms `project.godot` is well-formed. (The project has no scene content yet, which is expected at this point.)

- [ ] **Step 5: Commit**

```bash
git add project.godot .gitignore assets scenes scripts autoload tests
git commit -m "chore: scaffold SikTiTu Godot project structure"
```

---

### Task 3: Install the GUT testing addon

**Files:**
- Create: `addons/gut/` (vendored third-party addon, contents from upstream GUT repo)

**Interfaces:**
- Produces: `addons/gut/gut_cmdln.gd`, used by every later task's "run tests" step as:
  `& "$GODOT" --headless --path "<project>" -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`

- [ ] **Step 1: Verify current GUT install method**

Before downloading, check the current recommended install method and latest stable tag at `https://github.com/bitwes/Gut` (README/Releases) — the exact tag below may be superseded; use the latest stable release tag at execution time instead of assuming this one is current.

- [ ] **Step 2: Vendor the addon**

Run:
```bash
cd "C:\Users\mit01\PDI\game\SikTiTu"
git clone --depth 1 --branch <latest-stable-tag> https://github.com/bitwes/Gut.git /tmp/gut_src
cp -r /tmp/gut_src/addons/gut addons/gut
rm -rf /tmp/gut_src
```

- [ ] **Step 3: Enable the plugin**

Open `project.godot` and add, under a new `[editor_plugins]` section:
```ini
[editor_plugins]

enabled=PackedStringArray("res://addons/gut/plugin.cfg")
```

- [ ] **Step 4: Write a throwaway smoke test to confirm the runner works**

Create `tests/unit/test_gut_smoke.gd`:
```gdscript
extends GutTest

func test_gut_runner_executes():
	assert_eq(1 + 1, 2)
```

- [ ] **Step 5: Run it**

Run: `& "$GODOT" --headless --path "C:\Users\mit01\PDI\game\SikTiTu" -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: output reports 1 test, 1 pass, 0 fail.

- [ ] **Step 6: Delete the smoke test**

```bash
rm tests/unit/test_gut_smoke.gd
```
It served only to confirm the runner works; real tests start in Task 4.

- [ ] **Step 7: Commit**

```bash
git add addons/gut project.godot
git commit -m "chore: vendor GUT testing addon"
```

---

### Task 4: Input action registration (`input_setup.gd` autoload)

**Files:**
- Create: `autoload/input_setup.gd`
- Test: `tests/unit/test_input_setup.gd`

**Interfaces:**
- Produces: input actions `move_forward`, `move_back`, `move_left`, `move_right` (3D exploration), `duel_left`, `duel_right`, `duel_jump`, `duel_crouch`, `duel_skill_1`, `duel_skill_2` (2D duel) — registered in `InputMap` at runtime. Later tasks (9, 14) read these exact action names via `Input.get_vector`/`Input.get_axis`/`Input.is_action_just_pressed`.

- [ ] **Step 1: Write the failing test**

Create `tests/unit/test_input_setup.gd`:
```gdscript
extends GutTest

const ACTIONS := [
	"move_forward", "move_back", "move_left", "move_right",
	"duel_left", "duel_right", "duel_jump", "duel_crouch",
	"duel_skill_1", "duel_skill_2",
]

func before_each():
	for action_name in ACTIONS:
		if InputMap.has_action(action_name):
			InputMap.erase_action(action_name)

func after_each():
	for action_name in ACTIONS:
		if InputMap.has_action(action_name):
			InputMap.erase_action(action_name)

func test_register_actions_creates_all_expected_actions():
	var input_setup = load("res://autoload/input_setup.gd").new()
	input_setup.register_actions()

	for action_name in ACTIONS:
		assert_true(InputMap.has_action(action_name), "missing action: %s" % action_name)

func test_register_actions_is_idempotent():
	var input_setup = load("res://autoload/input_setup.gd").new()
	input_setup.register_actions()
	input_setup.register_actions()

	assert_eq(InputMap.action_get_events("move_forward").size(), 1)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "$GODOT" --headless --path "C:\Users\mit01\PDI\game\SikTiTu" -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_input_setup.gd -gexit`
Expected: FAIL — `load("res://autoload/input_setup.gd")` returns null / script not found.

- [ ] **Step 3: Write minimal implementation**

Create `autoload/input_setup.gd`:
```gdscript
extends Node

func _ready() -> void:
	register_actions()

func register_actions() -> void:
	_add_action_with_key("move_forward", KEY_W)
	_add_action_with_key("move_back", KEY_S)
	_add_action_with_key("move_left", KEY_A)
	_add_action_with_key("move_right", KEY_D)
	_add_action_with_key("duel_left", KEY_LEFT)
	_add_action_with_key("duel_right", KEY_RIGHT)
	_add_action_with_key("duel_jump", KEY_UP)
	_add_action_with_key("duel_crouch", KEY_DOWN)
	_add_action_with_key("duel_skill_1", KEY_J)
	_add_action_with_key("duel_skill_2", KEY_K)

func _add_action_with_key(action_name: String, keycode: Key) -> void:
	if InputMap.has_action(action_name):
		return
	InputMap.add_action(action_name)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action_name, event)
```

- [ ] **Step 4: Run test to verify it passes**

Run: `& "$GODOT" --headless --path "C:\Users\mit01\PDI\game\SikTiTu" -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_input_setup.gd -gexit`
Expected: PASS, 2 tests, 0 fail.

- [ ] **Step 5: Register the autoload in `project.godot`**

Add to `project.godot`:
```ini
[autoload]

InputSetup="*res://autoload/input_setup.gd"
```
(The `*` prefix makes it load before other autoloads that may depend on input being ready.)

- [ ] **Step 6: Commit**

```bash
git add autoload/input_setup.gd tests/unit/test_input_setup.gd project.godot
git commit -m "feat: register custom input actions via InputSetup autoload"
```

---

### Task 5: `GameManager` autoload — cross-scene state and duel transitions

**Files:**
- Create: `autoload/game_manager.gd`
- Test: `tests/unit/test_game_manager.gd`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `GameManager.start_duel(enemy_id: String, forest_position: Vector3) -> void`, `GameManager.end_duel(result: String) -> void`, `GameManager.is_in_duel: bool`, `GameManager.current_enemy_id: String`, `GameManager.player_forest_position: Vector3`, `GameManager.auto_change_scene: bool` (test seam), signals `duel_started(enemy_id: String)` / `duel_ended(result: String)`. Task 16's `Area3D` trigger calls `start_duel`; the duel scene's win/lose logic calls `end_duel`.

- [ ] **Step 1: Write the failing tests**

Create `tests/unit/test_game_manager.gd`:
```gdscript
extends GutTest

var game_manager

func before_each():
	game_manager = load("res://autoload/game_manager.gd").new()
	game_manager.auto_change_scene = false
	add_child_autofree(game_manager)

func test_start_duel_stores_enemy_id_and_position():
	var test_position := Vector3(1, 0, 5)
	game_manager.start_duel("wolf_01", test_position)

	assert_eq(game_manager.current_enemy_id, "wolf_01")
	assert_eq(game_manager.player_forest_position, test_position)
	assert_true(game_manager.is_in_duel)

func test_end_duel_clears_duel_flag():
	game_manager.start_duel("wolf_01", Vector3.ZERO)
	game_manager.end_duel("win")

	assert_false(game_manager.is_in_duel)

func test_start_duel_emits_signal_with_enemy_id():
	watch_signals(game_manager)
	game_manager.start_duel("wolf_01", Vector3.ZERO)

	assert_signal_emitted_with_parameters(game_manager, "duel_started", ["wolf_01"])

func test_start_duel_is_ignored_while_already_in_duel():
	game_manager.start_duel("wolf_01", Vector3(1, 0, 1))
	game_manager.start_duel("bear_02", Vector3(9, 0, 9))

	assert_eq(game_manager.current_enemy_id, "wolf_01", "second start_duel call must be ignored while a duel is active")
	assert_eq(game_manager.player_forest_position, Vector3(1, 0, 1))
```
The last test pins the re-trigger guard from the Review Focus section: calling `start_duel` while a duel is already active must not overwrite state or re-fire the transition.

- [ ] **Step 2: Run tests to verify they fail**

Run: `& "$GODOT" --headless --path "C:\Users\mit01\PDI\game\SikTiTu" -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_game_manager.gd -gexit`
Expected: FAIL — script not found.

- [ ] **Step 3: Write minimal implementation**

Create `autoload/game_manager.gd`:
```gdscript
extends Node

signal duel_started(enemy_id: String)
signal duel_ended(result: String)

var player_forest_position: Vector3 = Vector3.ZERO
var player_hp: int = 100
var current_enemy_id: String = ""
var is_in_duel: bool = false

## Set to false in tests to verify state changes without triggering real scene loads.
var auto_change_scene: bool = true

const FOREST_SCENE_PATH := "res://scenes/exploration/forest_level.tscn"
const DUEL_SCENE_PATH := "res://scenes/duel/duel_arena.tscn"

func start_duel(enemy_id: String, forest_position: Vector3) -> void:
	if is_in_duel:
		return
	current_enemy_id = enemy_id
	player_forest_position = forest_position
	is_in_duel = true
	duel_started.emit(enemy_id)
	if auto_change_scene:
		get_tree().change_scene_to_file(DUEL_SCENE_PATH)

func end_duel(result: String) -> void:
	if not is_in_duel:
		return
	is_in_duel = false
	duel_ended.emit(result)
	if auto_change_scene:
		get_tree().change_scene_to_file(FOREST_SCENE_PATH)
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `& "$GODOT" --headless --path "C:\Users\mit01\PDI\game\SikTiTu" -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_game_manager.gd -gexit`
Expected: PASS, 4 tests, 0 fail.

- [ ] **Step 5: Register the autoload**

Add to `project.godot`'s `[autoload]` section (after `InputSetup`):
```ini
GameManager="*res://autoload/game_manager.gd"
```

- [ ] **Step 6: Commit**

```bash
git add autoload/game_manager.gd tests/unit/test_game_manager.gd project.godot
git commit -m "feat: add GameManager autoload for exploration/duel transitions"
```

---

### Task 6: `FighterState` state machine

**Files:**
- Create: `scripts/duel/fighter_state.gd`
- Test: `tests/unit/test_fighter_state.gd`

**Interfaces:**
- Produces: `class_name FighterState`, `enum FighterState.State {IDLE, WALK, JUMP, CROUCH, ATTACK, HIT}`, `FighterState.current_state`, `FighterState.transition_to(next_state) -> bool`, `FighterState.can_transition_to(next_state) -> bool`, signal `state_changed(previous, next)`. Task 14's `fighter_2d_controller.gd` drives this state machine from input.

- [ ] **Step 1: Write the failing tests**

Create `tests/unit/test_fighter_state.gd`:
```gdscript
extends GutTest

var fighter_state

func before_each():
	fighter_state = load("res://scripts/duel/fighter_state.gd").new()

func test_starts_in_idle_state():
	assert_eq(fighter_state.current_state, FighterState.State.IDLE)

func test_idle_to_attack_is_valid():
	var success = fighter_state.transition_to(FighterState.State.ATTACK)
	assert_true(success)
	assert_eq(fighter_state.current_state, FighterState.State.ATTACK)

func test_attack_to_attack_is_rejected():
	fighter_state.transition_to(FighterState.State.ATTACK)
	var success = fighter_state.transition_to(FighterState.State.ATTACK)
	assert_false(success)
	assert_eq(fighter_state.current_state, FighterState.State.ATTACK)

func test_jump_to_crouch_is_rejected():
	fighter_state.transition_to(FighterState.State.JUMP)
	var success = fighter_state.transition_to(FighterState.State.CROUCH)
	assert_false(success)
	assert_eq(fighter_state.current_state, FighterState.State.JUMP)

func test_any_state_can_transition_to_hit():
	fighter_state.transition_to(FighterState.State.ATTACK)
	var success = fighter_state.transition_to(FighterState.State.HIT)
	assert_true(success)
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `& "$GODOT" --headless --path "C:\Users\mit01\PDI\game\SikTiTu" -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_fighter_state.gd -gexit`
Expected: FAIL — script not found.

- [ ] **Step 3: Write minimal implementation**

Create `scripts/duel/fighter_state.gd`:
```gdscript
extends Node
class_name FighterState

enum State {IDLE, WALK, JUMP, CROUCH, ATTACK, HIT}

var current_state: State = State.IDLE

const VALID_TRANSITIONS := {
	State.IDLE: [State.WALK, State.JUMP, State.CROUCH, State.ATTACK, State.HIT],
	State.WALK: [State.IDLE, State.JUMP, State.CROUCH, State.ATTACK, State.HIT],
	State.JUMP: [State.IDLE, State.HIT],
	State.CROUCH: [State.IDLE, State.ATTACK, State.HIT],
	State.ATTACK: [State.IDLE, State.HIT],
	State.HIT: [State.IDLE],
}

signal state_changed(previous: State, next: State)

func can_transition_to(next_state: State) -> bool:
	return VALID_TRANSITIONS[current_state].has(next_state)

func transition_to(next_state: State) -> bool:
	if not can_transition_to(next_state):
		return false
	var previous := current_state
	current_state = next_state
	state_changed.emit(previous, next_state)
	return true
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `& "$GODOT" --headless --path "C:\Users\mit01\PDI\game\SikTiTu" -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_fighter_state.gd -gexit`
Expected: PASS, 5 tests, 0 fail.

- [ ] **Step 5: Commit**

```bash
git add scripts/duel/fighter_state.gd tests/unit/test_fighter_state.gd
git commit -m "feat: add FighterState state machine for duel character"
```

---

### Task 7: `AnimalFleeController` — pure flee-target math

**Files:**
- Create: `scripts/exploration/animal_flee_controller.gd`
- Test: `tests/unit/test_animal_flee_controller.gd`

**Interfaces:**
- Produces: `class_name AnimalFleeController`, `static func compute_flee_target(my_position: Vector3, danger_position: Vector3, flee_distance: float) -> Vector3`, instance API `set_danger(position: Vector3)`, `clear_danger()`, exported `flee_speed: float`, `detection_radius: float`. Task 13 attaches this script to animal scenes and relies on `compute_flee_target` plus `_physics_process` driving a `NavigationAgent3D` child named `NavigationAgent3D`.

- [ ] **Step 1: Write the failing tests**

Create `tests/unit/test_animal_flee_controller.gd`:
```gdscript
extends GutTest

func test_flee_target_moves_away_from_danger_on_x_axis():
	var my_pos := Vector3(5, 0, 0)
	var danger_pos := Vector3(0, 0, 0)
	var target = AnimalFleeController.compute_flee_target(my_pos, danger_pos, 10.0)

	assert_almost_eq(target.x, 15.0, 0.01)
	assert_almost_eq(target.z, 0.0, 0.01)

func test_flee_target_defaults_to_forward_when_overlapping_danger():
	var my_pos := Vector3(0, 0, 0)
	var danger_pos := Vector3(0, 0, 0)
	var target = AnimalFleeController.compute_flee_target(my_pos, danger_pos, 10.0)

	assert_almost_eq(target.z, -10.0, 0.01)

func test_flee_target_respects_flee_distance():
	var my_pos := Vector3(2, 0, 0)
	var danger_pos := Vector3(0, 0, 0)
	var target = AnimalFleeController.compute_flee_target(my_pos, danger_pos, 3.0)

	assert_almost_eq(target.x, 5.0, 0.01)
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `& "$GODOT" --headless --path "C:\Users\mit01\PDI\game\SikTiTu" -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_animal_flee_controller.gd -gexit`
Expected: FAIL — script not found.

- [ ] **Step 3: Write minimal implementation**

Create `scripts/exploration/animal_flee_controller.gd`:
```gdscript
extends CharacterBody3D
class_name AnimalFleeController

@export var flee_speed: float = 6.0
@export var detection_radius: float = 12.0
@export var flee_distance: float = 20.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var danger_position: Vector3 = Vector3.ZERO
var has_danger: bool = false

func set_danger(position: Vector3) -> void:
	danger_position = position
	has_danger = true

func clear_danger() -> void:
	has_danger = false

static func compute_flee_target(my_position: Vector3, danger_position: Vector3, flee_distance: float) -> Vector3:
	var away_direction := my_position - danger_position
	if away_direction.length() < 0.001:
		away_direction = Vector3.FORWARD
	away_direction = away_direction.normalized()
	return my_position + away_direction * flee_distance

func _physics_process(_delta: float) -> void:
	if not has_danger:
		return
	if global_position.distance_to(danger_position) > detection_radius:
		return

	nav_agent.target_position = compute_flee_target(global_position, danger_position, flee_distance)
	var next_path_position := nav_agent.get_next_path_position()
	var direction := (next_path_position - global_position)
	direction.y = 0
	if direction.length() > 0.01:
		velocity = direction.normalized() * flee_speed
	move_and_slide()
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `& "$GODOT" --headless --path "C:\Users\mit01\PDI\game\SikTiTu" -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_animal_flee_controller.gd -gexit`
Expected: PASS, 3 tests, 0 fail.

- [ ] **Step 5: Commit**

```bash
git add scripts/exploration/animal_flee_controller.gd tests/unit/test_animal_flee_controller.gd
git commit -m "feat: add AnimalFleeController with tested flee-target math"
```

---

### Task 8: Install and connect godot-mcp

**Files:**
- Create: `addons/godot_mcp/` (vendored plugin, contents from the godot-mcp repo)
- No test (tooling/connectivity task)

**Interfaces:**
- Produces: a running MCP server registered with Claude Code, connected over WebSocket to a Godot editor instance with the `godot_mcp` plugin enabled. Tasks 9–16 use this connection (or the Godot editor directly, if MCP is unavailable in a given environment) to build and verify scenes.

- [ ] **Step 1: Verify current install method**

Check `https://github.com/Coding-Solo/godot-mcp` (or current canonical source) README for the up-to-date install/run command and plugin copy location — the steps below are the known-good shape as of this plan's writing; confirm the exact package name/command before running.

- [ ] **Step 2: Install the MCP server package**

Run (adjust package name/command per Step 1's verification):
```bash
npm install -g godot-mcp
```

- [ ] **Step 3: Vendor the editor plugin into the project**

Copy the `addons/godot_mcp/` folder shipped with the `godot-mcp` package into `C:\Users\mit01\PDI\game\SikTiTu\addons\godot_mcp\`.

- [ ] **Step 4: Enable the plugin**

Add to `project.godot`'s `[editor_plugins]` `enabled` array (alongside `gut`):
```ini
enabled=PackedStringArray("res://addons/gut/plugin.cfg", "res://addons/godot_mcp/plugin.cfg")
```

- [ ] **Step 5: Register the MCP server with Claude Code**

Run (project scope, so it's only active for this project):
```bash
claude mcp add godot-mcp --scope project -- npx godot-mcp
```
Set any required environment variable pointing at `$GODOT` (the executable path from Task 1) per the server's documented configuration.

- [ ] **Step 6: Verify the connection**

Open the project in the Godot editor (`& "$GODOT" --editor --path "C:\Users\mit01\PDI\game\SikTiTu"`), confirm the plugin is active (no errors in the editor's Output panel), then from Claude Code call an MCP tool (e.g. a "get editor status" or "list scenes" tool) and confirm it returns a response rather than a connection error.

- [ ] **Step 7: Commit**

```bash
git add addons/godot_mcp project.godot
git commit -m "chore: vendor godot-mcp editor plugin and enable it"
```

---

### Task 9: Entry scene, player scene, and 3D movement controller

**Files:**
- Create: `scripts/exploration/player_3d_controller.gd`
- Create: `scenes/exploration/player_3d.tscn`
- Create: `scenes/main/main.tscn`

**Interfaces:**
- Consumes: input actions `move_forward`/`move_back`/`move_left`/`move_right` (Task 4).
- Produces: `player_3d.tscn` — a `CharacterBody3D` root with child `CameraPivot` (`Node3D`) holding a `SpringArm3D` + `Camera3D`, and `CollisionShape3D`. `main.tscn` — root `Node` whose `_ready()` loads `forest_level.tscn` (built in Task 10) via `GameManager`-style `change_scene_to_file`, so it stays a thin bootstrap.

- [ ] **Step 1: Write `player_3d_controller.gd`**

Create `scripts/exploration/player_3d_controller.gd`:
```gdscript
extends CharacterBody3D

@export var move_speed: float = 5.0
@export var gravity: float = 9.8

@onready var camera_pivot: Node3D = $CameraPivot

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var camera_basis := camera_pivot.global_transform.basis
	var direction := camera_basis.x * input_dir.x + camera_basis.z * input_dir.y
	direction.y = 0

	if direction.length() > 0.01:
		direction = direction.normalized()
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()
```

- [ ] **Step 2: Build `player_3d.tscn`**

Using the Godot editor (directly or via MCP scene-editing tools), create a new 3D scene:
- Root node: `CharacterBody3D`, renamed `Player3D`, script = `scripts/exploration/player_3d_controller.gd`.
- Child: `CollisionShape3D` with a `CapsuleShape3D` (height 1.8, radius 0.4).
- Child: `MeshInstance3D` with a `CapsuleMesh` (same dimensions) as a placeholder visual, with a simple `StandardMaterial3D` (any distinct color, e.g. blue) assigned.
- Child: `Node3D` named `CameraPivot`, positioned at the player's head height (local Y ≈ 1.6).
  - Child of `CameraPivot`: `SpringArm3D`, `spring_length` = 4.0, rotated to look slightly down (-20° on X).
    - Child of `SpringArm3D`: `Camera3D`, `current` = true.

Save as `scenes/exploration/player_3d.tscn`.

- [ ] **Step 3: Build `main.tscn`**

Create a new scene, root node `Node` named `Main`, no script required if `GameManager`'s constants are used directly — instead, set `project.godot`'s `run/main_scene` (already set in Task 2) to this scene, and give `Main` a trivial script:

Create `scripts/main_bootstrap.gd`:
```gdscript
extends Node

func _ready() -> void:
	get_tree().change_scene_to_file("res://scenes/exploration/forest_level.tscn")
```
Attach this script to the `Main` root node. Save as `scenes/main/main.tscn`.

(`forest_level.tscn` does not exist yet — this scene will fail to run standalone until Task 10 is complete. That is expected and verified in Task 10, not here.)

- [ ] **Step 4: Verify `player_3d.tscn` in isolation**

Run: `& "$GODOT" --path "C:\Users\mit01\PDI\game\SikTiTu" scenes/exploration/player_3d.tscn`
Expected: a window opens showing the capsule on an empty background (no ground yet — falling is expected since there's no floor). Press WASD and confirm horizontal movement happens before it falls out of view. Close the window.

- [ ] **Step 5: Commit**

```bash
git add scripts/exploration/player_3d_controller.gd scenes/exploration/player_3d.tscn scripts/main_bootstrap.gd scenes/main/main.tscn
git commit -m "feat: add player 3D controller and main bootstrap scene"
```

---

### Task 10: Base `forest_level.tscn` (ground, player instanced, basic bounds)

**Files:**
- Create: `scenes/exploration/forest_level.tscn`

**Interfaces:**
- Consumes: `scenes/exploration/player_3d.tscn` (Task 9).
- Produces: a scene with a walkable floor and the player instanced, ready for Tasks 11–13 to add effects/animals onto. Node path `$Player3D` is relied on by Task 16's encounter trigger.

- [ ] **Step 1: Build the base scene**

Using the editor/MCP, create a new 3D scene:
- Root: `Node3D` named `ForestLevel`.
- Child: `StaticBody3D` named `Ground`, with `CollisionShape3D` (`BoxShape3D`, size 100×1×100, position Y = -0.5) and `MeshInstance3D` (matching `BoxMesh`, simple green/brown `StandardMaterial3D`).
- Instance `scenes/exploration/player_3d.tscn` as a child named `Player3D`, positioned at (0, 1, 0).
- Add a handful of simple tree placeholders: 6–10 `StaticBody3D` nodes (name prefix `Tree`), each with a `CollisionShape3D` (`CylinderShape3D`, radius 0.5, height 4) and matching `MeshInstance3D` (brown `CylinderMesh` trunk is sufficient as a placeholder), scattered at varied X/Z positions within the ground bounds (leave a clear area near the player's spawn).

Save as `scenes/exploration/forest_level.tscn`.

- [ ] **Step 2: Verify via `main.tscn`**

Run: `& "$GODOT" --path "C:\Users\mit01\PDI\game\SikTiTu" scenes/main/main.tscn`
Expected: window opens, loads into the forest, player capsule stands on the ground (does not fall through), WASD moves the player and collides with tree trunks instead of passing through them. Close the window.

- [ ] **Step 3: Commit**

```bash
git add scenes/exploration/forest_level.tscn
git commit -m "feat: add base forest_level scene with ground, trees, and player"
```

---

### Task 11: Reusable fire and smoke effect scenes

**Files:**
- Create: `scenes/exploration/effects/fire_effect.tscn`
- Create: `scenes/exploration/effects/smoke_effect.tscn`

**Interfaces:**
- Produces: two self-contained, instanceable scenes. `fire_effect.tscn` root `Node3D` named `FireEffect` (children: `GPUParticles3D`, `OmniLight3D`). `smoke_effect.tscn` root `Node3D` named `SmokeEffect` (child: `GPUParticles3D`). Task 12 instances both multiple times into `forest_level.tscn`.

- [ ] **Step 1: Build `fire_effect.tscn`**

Create a new 3D scene:
- Root: `Node3D` named `FireEffect`.
- Child: `GPUParticles3D` named `FireParticles`:
  - `amount` = 32, `lifetime` = 1.0, `emitting` = true.
  - `process_material`: new `ParticleProcessMaterial` — `direction` = (0, 1, 0), `spread` = 20, `initial_velocity_min/max` = 1.0/2.0, `gravity` = (0, 0.5, 0) (slight upward drift), `scale_min/max` = 0.2/0.5, `color` = orange-red (e.g. `#FF6A00`).
  - `draw_pass_1`: a `QuadMesh` (size 0.3×0.3) with an unshaded `StandardMaterial3D`, `transparency` = alpha, `albedo_color` matching the particle color, `emission_enabled` = true with a matching emission color so it reads as glowing.
- Child: `OmniLight3D` named `FireLight`, `light_color` = orange (`#FF8C00`), `omni_range` = 6.0, `light_energy` = 2.0.

Save as `scenes/exploration/effects/fire_effect.tscn`.

- [ ] **Step 2: Build `smoke_effect.tscn`**

Create a new 3D scene:
- Root: `Node3D` named `SmokeEffect`.
- Child: `GPUParticles3D` named `SmokeParticles`:
  - `amount` = 24, `lifetime` = 4.0, `emitting` = true.
  - `process_material`: `direction` = (0, 1, 0), `spread` = 30, `initial_velocity_min/max` = 0.5/1.2, `gravity` = (0, 0.2, 0), `scale_min/max` = 1.0/2.5 (particles grow as they rise), `color` = gray with alpha (`#4A4A4ABB`), `turbulence_enabled` = true (noise strength ~0.3) if available in the engine version, otherwise skip turbulence and keep basic upward drift.
  - `draw_pass_1`: `QuadMesh` (size 1.0×1.0) with unshaded, alpha-blended `StandardMaterial3D` matching the gray smoke color.

Save as `scenes/exploration/effects/smoke_effect.tscn`.

- [ ] **Step 3: Verify each effect in isolation**

Run: `& "$GODOT" --path "C:\Users\mit01\PDI\game\SikTiTu" scenes/exploration/effects/fire_effect.tscn`
Expected: window shows glowing orange particles rising with a local light glow. Close.

Run: `& "$GODOT" --path "C:\Users\mit01\PDI\game\SikTiTu" scenes/exploration/effects/smoke_effect.tscn`
Expected: window shows gray semi-transparent particles rising and expanding. Close.

- [ ] **Step 4: Commit**

```bash
git add scenes/exploration/effects/fire_effect.tscn scenes/exploration/effects/smoke_effect.tscn
git commit -m "feat: add reusable fire and smoke particle effect scenes"
```

---

### Task 12: Populate the forest with fire/smoke, orange sky, and tuned lighting

**Files:**
- Modify: `scenes/exploration/forest_level.tscn`

**Interfaces:**
- Consumes: `fire_effect.tscn`, `smoke_effect.tscn` (Task 11).
- Produces: `forest_level.tscn` with the burning-sky atmosphere described in the spec, plus named constants for density (`MAX_FIRE_POINTS`, `MAX_ANIMALS`) added to a small scene-level config script so Task 13 can reuse `MAX_ANIMALS`.

- [ ] **Step 1: Add a scene config script for density constants**

Create `scripts/exploration/forest_level_config.gd`:
```gdscript
extends Node3D

const MAX_FIRE_POINTS := 5
const MAX_ANIMALS := 4
```
Attach this script to the `ForestLevel` root node (replacing its default no-script state).

- [ ] **Step 2: Add `WorldEnvironment` with orange sky**

In `forest_level.tscn`, add a child `WorldEnvironment` named `Environment`:
- `environment`: new `Environment` resource.
  - `background_mode` = Sky.
  - `sky`: new `Sky` resource with a `ProceduralSkyMaterial`:
    - `sky_top_color` = deep orange-red (`#B33A00`)
    - `sky_horizon_color` = bright orange (`#FF7A1A`)
    - `ground_bottom_color` = dark gray-brown (`#2B2420`)
    - `ground_horizon_color` = orange (`#D1591A`)
  - `ambient_light_source` = Sky, `ambient_light_energy` = 0.6 (dimmer than default, as if light is filtered through smoke).
  - `fog_enabled` = true, `fog_light_color` = gray-orange (`#8A6B55`), `fog_density` = 0.015 (visible haze without fully obscuring the scene).

- [ ] **Step 3: Tune `DirectionalLight3D`**

Add (if not already present) a `DirectionalLight3D` named `SunLight`:
- `light_color` = warm orange (`#FFA559`)
- `light_energy` = 0.7 (reduced from default 1.0, smoke-occluded feel)
- rotated to a low angle (e.g. -35° on X) for long, dramatic shadows.

- [ ] **Step 4: Instance fire and smoke points**

Add a child `Node3D` named `FirePoints`. Under it, instance `fire_effect.tscn` `MAX_FIRE_POINTS` (5) times, each renamed `FirePoint1`..`FirePoint5`, positioned at distinct spots among the tree placeholders from Task 10 (avoid the player's spawn and the clear path).

Add a child `Node3D` named `SmokePoints`. Under it, instance `smoke_effect.tscn` at the same 5 positions (offset slightly upward, e.g. +1.5 Y, so smoke rises from roughly where the fire is) plus 2 extra ambient smoke instances spread further out for general haze.

- [ ] **Step 5: Verify**

Run: `& "$GODOT" --path "C:\Users\mit01\PDI\game\SikTiTu" scenes/main/main.tscn`
Expected: orange/red sky visible, multiple fire points with glowing light and rising smoke visible across the scene, overall scene reads as hazy/dim compared to a default daylight scene, player still walks and collides normally. Close.

- [ ] **Step 6: Commit**

```bash
git add scenes/exploration/forest_level.tscn scripts/exploration/forest_level_config.gd
git commit -m "feat: add burning-sky atmosphere to forest_level (fire, smoke, orange sky, dim lighting)"
```

---

### Task 13: Fleeing animals wired into the forest

**Files:**
- Create: `scenes/exploration/animal.tscn`
- Create: `scripts/exploration/animal_spawner.gd`
- Modify: `scenes/exploration/forest_level.tscn`

**Interfaces:**
- Consumes: `scripts/exploration/animal_flee_controller.gd` (Task 7), `forest_level_config.gd`'s `MAX_ANIMALS` (Task 12).
- Produces: `animal.tscn` instanced `MAX_ANIMALS` times in `forest_level.tscn`, each fleeing from the nearest fire point once in range.

- [ ] **Step 1: Build `animal.tscn`**

Create a new 3D scene:
- Root: `CharacterBody3D` named `Animal`, script = `scripts/exploration/animal_flee_controller.gd`.
- Child: `CollisionShape3D` with `CapsuleShape3D` (height 0.8, radius 0.3).
- Child: `MeshInstance3D` with a `CapsuleMesh` (same dimensions), simple brown/tan `StandardMaterial3D` placeholder.
- Child: `NavigationAgent3D` named `NavigationAgent3D` (matches the `$NavigationAgent3D` lookup in the controller script), default radius/avoidance settings.

Save as `scenes/exploration/animal.tscn`.

- [ ] **Step 2: Add a `NavigationRegion3D` to the forest**

In `forest_level.tscn`, add a child `NavigationRegion3D` named `Navigation`, as a parent wrapping the `Ground` node (reparent `Ground` under `Navigation`, or add a `NavigationRegion3D` sibling whose navigation mesh covers the same ground footprint — either is acceptable as long as the ground area is navigable).

Bake the navigation mesh: in the Godot editor, select the `NavigationRegion3D` node and use its "Bake NavigationMesh" action so animals have a real navmesh to path on. (This step must be done in the editor UI or via an MCP tool that triggers baking — it is not expressible as plain scene-file text, since baking generates derived navmesh data.)

- [ ] **Step 3: Write the spawner script**

Create `scripts/exploration/animal_spawner.gd`:
```gdscript
extends Node3D

const ANIMAL_SCENE := preload("res://scenes/exploration/animal.tscn")

@export var spawn_positions: Array[Vector3] = []
@export var danger_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	var config := get_node("/root/ForestLevel") as Node
	var max_animals: int = config.MAX_ANIMALS if config != null else spawn_positions.size()
	var count: int = min(max_animals, spawn_positions.size())

	for i in range(count):
		var animal := ANIMAL_SCENE.instantiate()
		add_child(animal)
		animal.global_position = spawn_positions[i]
		animal.set_danger(danger_position)
```
Note: `get_node("/root/ForestLevel")` assumes `ForestLevel` is the current scene's root name (set in Task 10) — this is valid only when `forest_level.tscn` is the active/running scene, which matches how it's always reached (via `main.tscn` or `GameManager`).

- [ ] **Step 4: Wire the spawner into `forest_level.tscn`**

Add a child `Node3D` named `AnimalSpawner`, script = `scripts/exploration/animal_spawner.gd`. Set its `spawn_positions` export to 4 positions scattered around the clear area (not overlapping trees or fire points), and `danger_position` to the position of `FirePoint1` (read that position from the editor and copy it in).

- [ ] **Step 5: Verify**

Run: `& "$GODOT" --path "C:\Users\mit01\PDI\game\SikTiTu" scenes/main/main.tscn`
Expected: 4 animal capsules appear at their spawn points and, since they start within `detection_radius` of the danger position, visibly move away from it along the baked navmesh (not stuck in place, not clipping through trees). Close.

- [ ] **Step 6: Commit**

```bash
git add scenes/exploration/animal.tscn scripts/exploration/animal_spawner.gd scenes/exploration/forest_level.tscn
git commit -m "feat: spawn fleeing animals in forest_level using baked navigation"
```

---

### Task 14: `fighter_2d.tscn` with 2D movement/jump/crouch/skill controller

**Files:**
- Create: `scripts/duel/fighter_2d_controller.gd`
- Create: `scenes/duel/fighter_2d.tscn`

**Interfaces:**
- Consumes: `scripts/duel/fighter_state.gd` (Task 6), input actions `duel_left`/`duel_right`/`duel_jump`/`duel_crouch`/`duel_skill_1`/`duel_skill_2` (Task 4).
- Produces: `fighter_2d.tscn` — a `CharacterBody2D` with child `FighterState` node, usable both as the player fighter and (re-instanced, input-disabled) as a stand-in opponent in Task 15.

- [ ] **Step 1: Write `fighter_2d_controller.gd`**

Create `scripts/duel/fighter_2d_controller.gd`:
```gdscript
extends CharacterBody2D

@export var move_speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var gravity: float = 900.0
@export var input_enabled: bool = true

@onready var state_machine: FighterState = $FighterState

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if input_enabled:
		_handle_input()

	move_and_slide()

func _handle_input() -> void:
	if state_machine.current_state == FighterState.State.HIT:
		return

	if Input.is_action_just_pressed("duel_skill_1") or Input.is_action_just_pressed("duel_skill_2"):
		if state_machine.transition_to(FighterState.State.ATTACK):
			velocity.x = 0
		return

	if state_machine.current_state == FighterState.State.ATTACK:
		return

	if Input.is_action_just_pressed("duel_jump") and is_on_floor():
		state_machine.transition_to(FighterState.State.JUMP)
		velocity.y = jump_velocity
		return

	if Input.is_action_pressed("duel_crouch") and is_on_floor():
		state_machine.transition_to(FighterState.State.CROUCH)
		velocity.x = 0
		return
	elif state_machine.current_state == FighterState.State.CROUCH:
		state_machine.transition_to(FighterState.State.IDLE)

	var horizontal := Input.get_axis("duel_left", "duel_right")
	velocity.x = horizontal * move_speed

	if is_on_floor():
		if horizontal != 0:
			state_machine.transition_to(FighterState.State.WALK)
		elif state_machine.current_state in [FighterState.State.WALK, FighterState.State.JUMP]:
			state_machine.transition_to(FighterState.State.IDLE)
```

- [ ] **Step 2: Build `fighter_2d.tscn`**

Create a new 2D scene:
- Root: `CharacterBody2D` named `Fighter2D`, script = `scripts/duel/fighter_2d_controller.gd`.
- Child: `CollisionShape2D` with a `RectangleShape2D` (size ~40×80).
- Child: `ColorRect` sized to match the collision shape, as a placeholder visual (distinct color, e.g. blue), positioned so its top-left aligns with the collision shape's bounds.
- Child: `Node`, script = `scripts/duel/fighter_state.gd`, renamed `FighterState` (matches `$FighterState` lookup).

Save as `scenes/duel/fighter_2d.tscn`.

- [ ] **Step 3: Verify in isolation**

Run: `& "$GODOT" --path "C:\Users\mit01\PDI\game\SikTiTu" scenes/duel/fighter_2d.tscn`
Expected: window shows the fighter rectangle falling (no floor yet — expected). Before it falls out of frame, confirm Left/Right arrow keys move it horizontally and Up/Down are accepted without errors in the Output panel. Close.

- [ ] **Step 4: Commit**

```bash
git add scripts/duel/fighter_2d_controller.gd scenes/duel/fighter_2d.tscn
git commit -m "feat: add fighter_2d scene with movement/jump/crouch/skill controller"
```

---

### Task 15: `duel_arena.tscn`

**Files:**
- Create: `scenes/duel/duel_arena.tscn`

**Interfaces:**
- Consumes: `scenes/duel/fighter_2d.tscn` (Task 14).
- Produces: a playable 2D arena with a player-controlled fighter and a stationary (input-disabled) opponent, ready for Task 16 to wire win/lose → `GameManager.end_duel`.

- [ ] **Step 1: Build the scene**

Create a new 2D scene:
- Root: `Node2D` named `DuelArena`.
- Child: `StaticBody2D` named `Floor`, with `CollisionShape2D` (`RectangleShape2D`, wide and thin, e.g. 800×40) positioned near the bottom of the view, and a matching `ColorRect` visual.
- Instance `scenes/duel/fighter_2d.tscn` as `PlayerFighter`, positioned on the left side standing on the floor, `input_enabled` = true (default).
- Instance `scenes/duel/fighter_2d.tscn` again as `OpponentFighter`, positioned on the right side standing on the floor, `input_enabled` = false (set this override on the instance).
- Child: `Camera2D` named `ArenaCamera`, positioned to frame both fighters, `current` = true.

Save as `scenes/duel/duel_arena.tscn`.

- [ ] **Step 2: Verify**

Run: `& "$GODOT" --path "C:\Users\mit01\PDI\game\SikTiTu" scenes/duel/duel_arena.tscn`
Expected: both fighters stand on the floor (no falling through), `PlayerFighter` responds to Left/Right/Up/Down/skill keys, `OpponentFighter` stays still (input disabled). Close.

- [ ] **Step 3: Commit**

```bash
git add scenes/duel/duel_arena.tscn
git commit -m "feat: add duel_arena scene with player and stationary opponent fighters"
```

---

### Task 16: Wire the exploration ↔ duel transition end-to-end

**Files:**
- Modify: `scenes/exploration/forest_level.tscn`
- Modify: `scenes/duel/duel_arena.tscn`
- Create: `scripts/exploration/encounter_trigger.gd`
- Create: `scripts/duel/duel_resolution.gd`

**Interfaces:**
- Consumes: `GameManager.start_duel`/`end_duel` (Task 5), `forest_level.tscn`'s `$Player3D` (Task 9/10), `duel_arena.tscn`'s fighters (Task 15).
- Produces: a complete, manually-testable loop: walk into a trigger in the forest → duel scene loads → placeholder win condition ends the duel → forest reloads with the player restored near their pre-encounter position.

- [ ] **Step 1: Write the encounter trigger script**

Create `scripts/exploration/encounter_trigger.gd`:
```gdscript
extends Area3D

@export var enemy_id: String = "wolf_01"

var _triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if _triggered:
		return
	if not body.is_in_group("player"):
		return
	_triggered = true
	GameManager.start_duel(enemy_id, body.global_position)
```
This guards against re-triggering the same encounter zone repeatedly while the player stands in it (Review Focus: re-triggering).

- [ ] **Step 2: Add the trigger to `forest_level.tscn`**

Add a child `Area3D` named `EncounterTrigger`, script = `scripts/exploration/encounter_trigger.gd`, with a `CollisionShape3D` (`BoxShape3D`, size 3×3×3) positioned along the player's clear walking path (so walking forward reaches it). Set `collision_layer`/`collision_mask` so it detects the player body (same physics layer the player's `CharacterBody3D` uses, or Godot's default layer if none were customized).

On `Player3D` in `player_3d.tscn` (Task 9), add it to the `player` group: select the `Player3D` root node, add group `player` via the Node panel's Groups tab. (This is required for `encounter_trigger.gd`'s `body.is_in_group("player")` check to pass.)

- [ ] **Step 3: Write the duel resolution script**

Create `scripts/duel/duel_resolution.gd`:
```gdscript
extends Node2D

func _ready() -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("duel_skill_1"):
		# Placeholder win condition for foundation verification: pressing the
		# skill button resolves the duel as a win. Real combat/HP resolution
		# is out of scope for this foundation plan.
		GameManager.end_duel("win")
```

- [ ] **Step 4: Attach resolution script to `duel_arena.tscn`**

Attach `scripts/duel/duel_resolution.gd` to the `DuelArena` root node.

- [ ] **Step 5: Verify the full loop manually**

Run: `& "$GODOT" --path "C:\Users\mit01\PDI\game\SikTiTu" scenes/main/main.tscn`
1. Confirm the forest loads with fire/smoke/animals as before.
2. Walk the player into the `EncounterTrigger` area.
3. Expected: scene switches to `duel_arena.tscn`, both fighters visible.
4. Press the skill key (J).
5. Expected: scene switches back to `forest_level.tscn`.
6. Confirm walking back into the same trigger zone does **not** immediately re-trigger a duel (it was a one-shot `_triggered` guard on that `Area3D` instance — re-entering the newly-reloaded scene's fresh trigger instance is expected to work again, since the scene was reloaded; this verifies the guard works within a single scene lifetime, which is what Task 5's "ignore start_duel while already in duel" test and this trigger's `_triggered` flag together guarantee).

Close the window.

- [ ] **Step 6: Commit**

```bash
git add scenes/exploration/forest_level.tscn scenes/duel/duel_arena.tscn scripts/exploration/encounter_trigger.gd scripts/duel/duel_resolution.gd
git commit -m "feat: wire exploration-to-duel-to-exploration transition end-to-end"
```

---

### Task 17: Final verification against acceptance criteria

**Files:** none (verification task)

**Interfaces:** none — this task only runs checks.

- [ ] **Step 1: Run the full unit test suite**

Run: `& "$GODOT" --headless --path "C:\Users\mit01\PDI\game\SikTiTu" -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: all tests across `test_input_setup.gd`, `test_game_manager.gd`, `test_fighter_state.gd`, `test_animal_flee_controller.gd` pass, 0 failures.

- [ ] **Step 2: Walk through the spec's 6 acceptance criteria**

1. Godot 4.x installed, project opens — confirmed in Task 1/2.
2. MCP connected — confirmed in Task 8.
3. `forest_level.tscn` playable with fire/smoke/orange sky/fleeing animals — confirmed in Tasks 10–13.
4. `duel_arena.tscn` playable with left/right/jump/crouch/skill — confirmed in Tasks 14–15.
5. Exploration → duel → exploration transition works — confirmed in Task 16.
6. Project committed to git — confirmed by the commit at the end of every task.

Re-run the Task 16 Step 5 manual walkthrough once more end-to-end as the final sign-off.

- [ ] **Step 3: Tag the foundation milestone**

```bash
git tag -a v0.1-foundation -m "SikTiTu game foundation: exploration/duel loop with MCP-connected Godot project"
```

No further commit needed — this task is verification-only.
