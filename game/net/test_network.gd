extends Control
## Network test screen. Owner: Sufi. Open game/net/test_network.tscn and run it
## in 2+ windows (Debug > Customize Run Instances...). Window 1: Host. Others: Join.
## Host clicks "Start" -> every window loads the test map. Barebones on purpose;
## the real lobby (N2) is styled by Zaliq.

var _name: LineEdit
var _address: LineEdit
var _status: Label
var _list: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.position = Vector2(40, 40)
	box.custom_minimum_size = Vector2(420, 0)
	box.add_theme_constant_override("separation", 10)
	add_child(box)

	var title := Label.new()
	title.text = "NETWORK TEST (N1)"
	box.add_child(title)
	_name = _field(box, "Your name", "Player")
	_address = _field(box, "Host address (for Join)", "127.0.0.1")

	var row := HBoxContainer.new()
	box.add_child(row)
	_button(row, "Host", func(): _show_error(Network.host(_name.text), "host"))
	_button(row, "Join", func(): _show_error(Network.join(_address.text, _name.text), "join"))
	_button(row, "Leave", func(): Network.leave(); _status.text = "Offline")
	_button(row, "Start (host)", func(): Network.start_game("res://game/test_map.tscn"))

	_status = Label.new()
	_status.text = Network.get_meta("last_message", "Offline")
	box.add_child(_status)
	_list = Label.new()
	box.add_child(_list)

	Network.players_changed.connect(_refresh)
	Network.joined.connect(func(): _status.text = "Connected as %s (%s)" % [
		"HOST" if Network.is_host() else "guest", _name.text])
	Network.join_failed.connect(func(reason): _status.text = "Join failed: " + reason)
	Network.disconnected.connect(func(reason): _status.text = "Disconnected: " + reason)
	_refresh()


func _refresh() -> void:
	var lines := ["Players (%d/%d):" % [Network.players.size(), Network.MAX_PLAYERS]]
	var ids := Network.players.keys()
	ids.sort_custom(func(a, b): return Network.players[a]["slot"] < Network.players[b]["slot"])
	for id in ids:
		var p: Dictionary = Network.players[id]
		lines.append("  P%d  %s%s%s" % [p["slot"] + 1, p["name"],
			"  (host)" if id == 1 else "", "  ← you" if id == Network.my_id() else ""])
	_list.text = "\n".join(lines)


func _show_error(err: Error, what: String) -> void:
	if err != OK:
		_status.text = "Could not %s: %s" % [what, error_string(err)]
	elif what == "join":
		_status.text = "Connecting to %s ..." % _address.text


func _field(parent: Node, label: String, value: String) -> LineEdit:
	var l := Label.new()
	l.text = label
	parent.add_child(l)
	var e := LineEdit.new()
	e.text = value
	parent.add_child(e)
	return e


func _button(parent: Node, text: String, action: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.pressed.connect(action)
	parent.add_child(b)