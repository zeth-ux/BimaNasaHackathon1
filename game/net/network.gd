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