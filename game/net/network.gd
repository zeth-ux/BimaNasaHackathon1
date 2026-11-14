extends Node
## Network: who is connected, and host/join/leave. Autoload name: "Network".
## Owner: Sufi (gameplay). Peer-to-peer: one player's game is the HOST, others join it.
##
## N1 uses ENet (direct IP, works from the editor for testing).
## N4 swaps in WebRTC + room codes for the web build; nothing else has to change,
## because the rest of the game only uses the functions and signals below.
##
##   Network.host("Sufi")                 -> become the host (you are player slot 0)
##   Network.join("127.0.0.1", "Zaliq")   -> join a host
##   Network.leave()
##   Network.players   { peer_id: {"name": "Sufi", "slot": 0}, ... }   same on every device
##   Network.is_host() / Network.my_id() / Network.my_slot()
##
## Signals: players_changed, joined (you are in), join_failed(reason), disconnected(reason)

signal players_changed
signal joined
signal join_failed(reason: String)
signal disconnected(reason: String)

const PORT := 7777
const MAX_PLAYERS := 4

var players := {}          ## peer_id -> {"name": String, "slot": int}
var _my_name := ""


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


# ---------------------------------------------------------------- public API

func host(player_name: String) -> Error:
	leave()
	var peer := ENetMultiplayerPeer.new()
	# Room for one extra guest, so a 5th player gets a clear "team is full" message.
	var err := peer.create_server(PORT, MAX_PLAYERS)
	if err != OK:
		return err   # usually: port already in use (another host is running on this machine)
	multiplayer.multiplayer_peer = peer
	_my_name = player_name
	players = {1: {"name": clean_name(player_name), "slot": 0}}
	players_changed.emit()
	joined.emit()
	return OK


func join(address: String, player_name: String) -> Error:
	leave()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, PORT)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	_my_name = player_name
	return OK   # result arrives later as `joined` or `join_failed`


func leave() -> void:
	if multiplayer.multiplayer_peer and not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer):
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	if not players.is_empty():
		players = {}
		players_changed.emit()


func is_online() -> bool:
	return not players.is_empty()


func is_host() -> bool:
	return is_online() and multiplayer.is_server()


func my_id() -> int:
	return multiplayer.get_unique_id()


func my_slot() -> int:
	return players.get(my_id(), {}).get("slot", -1)


# ---------------------------------------------------------------- pure rules (tested)

## Lowest free slot 0..MAX_PLAYERS-1, or -1 when full. Slot = colour and spawn point.
static func free_slot(current: Dictionary) -> int:
	var used := {}
	for info in current.values():
		used[info["slot"]] = true
	for s in MAX_PLAYERS:
		if not used.has(s):
			return s
	return -1


static func clean_name(raw: String) -> String:
	var n := raw.strip_edges().substr(0, 16)
	return n if n != "" else "Player"


# ---------------------------------------------------------------- host side

func _on_peer_connected(_id: int) -> void:
	pass   # host waits for the newcomer to send its name (_register)


@rpc("any_peer", "reliable")
func _register(player_name: String) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	var slot := free_slot(players)
	if slot == -1:
		_refused.rpc_id(id, "The team is full (%d players)." % MAX_PLAYERS)
		return
	players[id] = {"name": clean_name(player_name), "slot": slot}
	_sync_players.rpc(players)        # everyone (including the newcomer) gets the full list
	players_changed.emit()


func _on_peer_disconnected(id: int) -> void:
	if multiplayer.is_server() and players.erase(id):
		_sync_players.rpc(players)
		players_changed.emit()


# ---------------------------------------------------------------- client side

func _on_connected_to_server() -> void:
	_register.rpc_id(1, _my_name)


@rpc("authority", "reliable")
func _sync_players(list: Dictionary) -> void:
	var was_in := players.has(my_id())
	players = list
	players_changed.emit()
	if not was_in and players.has(my_id()):
		joined.emit()


@rpc("authority", "reliable")
func _refused(reason: String) -> void:
	leave()
	join_failed.emit(reason)


func _on_connection_failed() -> void:
	leave()
	join_failed.emit("Could not reach the host. Check the address and that the host is running.")


func _on_server_disconnected() -> void:
	leave()
	disconnected.emit("The host left the game.")
