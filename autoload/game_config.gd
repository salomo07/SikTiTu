extends Node

## Cross-scene fight configuration (autoload). Menus write it; the Fighter and
## MatchManager read it. Kept named "GameConfig" so the adapted shoto engine
## (fight/**) can reference /root/GameConfig unchanged.

# --- Match setup (read by MatchManager / Fighter) ---
var p2_is_cpu: bool = true
var cpu_difficulty: String = "medium"
var show_boxes: bool = false          # F1 toggles hit/hurt boxes (training view)

# --- Selection (written by hero_select / arena_select) ---
var p1_hero_id: String = ""
var p2_hero_id: String = ""
var arena_id: String = ""

# --- Networking ---
var online: bool = false              # true => P2 input comes from the network
var local_player_index: int = 1       # which side this client controls online (1 or 2)

func _ready() -> void:
	if p1_hero_id == "":
		p1_hero_id = HeroDB.default_id()
	if p2_hero_id == "":
		p2_hero_id = HeroDB.default_id()
	if arena_id == "":
		arena_id = ArenaDB.default_id()

func set_mode(cpu: bool, difficulty: String) -> void:
	p2_is_cpu = cpu
	cpu_difficulty = difficulty

## Resolve the hero chosen for a fighter slot ("p1" / "p2") into the values the
## Fighter needs: the stat archetype (character_id) and the silhouette color.
func hero_for_slot(slot: String) -> Dictionary:
	var id := p1_hero_id if slot == "p1" else p2_hero_id
	return HeroDB.get_hero(id)

func current_arena() -> Dictionary:
	return ArenaDB.get_arena(arena_id)
