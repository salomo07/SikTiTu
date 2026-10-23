extends Node

## Minimal networked-versus transport for the Fight mode (ENet).
##
## Model: the HOST owns Player 1, the CLIENT owns Player 2. Each peer sends its
## own fighter's input frame every physics tick; the other side feeds the latest
## received frame into a NetInput source. This is delayed-lockstep streaming (no
## rollback) -- enough for a working online match on a LAN / low latency; rollback
## netcode is a later upgrade.
##
## The match reads GameConfig.online / local_player_index; the menu's host/join
## screen calls host()/join() here before launching the match.

signal peer_connected(id: int)
signal peer_disconnected(id: int)
signal connection_failed()
signal connection_succeeded()

const DEFAULT_PORT := 7799

# Latest input frame received from the remote peer, as a plain dict (see
# InputFrame fields). NetInput reads this.
var remote_frame: Dictionary = {}
var connected := false


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)


## Start hosting. Returns OK or an error code.
func host(port: int = DEFAULT_PORT) -> int:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, 1)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	GameConfig.online = true
	GameConfig.p2_is_cpu = false
	GameConfig.local_player_index = 1   # host = P1
	return OK


## Join a host. Returns OK or an error code.
func join(address: String, port: int = DEFAULT_PORT) -> int:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	GameConfig.online = true
	GameConfig.p2_is_cpu = false
	GameConfig.local_player_index = 2   # client = P2
	return OK


func disconnect_net() -> void:
	connected = false
	remote_frame = {}
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null


## Send this peer's fighter input frame to the other side (called each tick).
func send_frame(frame: Dictionary) -> void:
	if multiplayer.multiplayer_peer == null:
		return
	_receive_frame.rpc(frame)


@rpc("any_peer", "unreliable_ordered", "call_remote")
func _receive_frame(frame: Dictionary) -> void:
	remote_frame = frame


func _on_peer_connected(id: int) -> void:
	connected = true
	peer_connected.emit(id)


func _on_peer_disconnected(id: int) -> void:
	connected = false
	peer_disconnected.emit(id)


func _on_connected_to_server() -> void:
	connected = true
	connection_succeeded.emit()


func _on_connection_failed() -> void:
	connected = false
	connection_failed.emit()
