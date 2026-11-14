extends Control
## Main scene. Owner: Zaliq. Title -> crew setup -> wake-up room -> bunker map.

const TitleScreen = preload("res://ui/screens/title_screen.gd")
const CrewSelect = preload("res://ui/screens/crew_select.gd")
const StoryIntro = preload("res://ui/screens/story_intro.gd")
const EarthMap = preload("res://ui/screens/earth_map.gd")
const RoomInterface = preload("res://ui/screens/room_interface.gd")
const WakeUpRoom = preload("res://ui/screens/wake_up_room.gd")

var map_screen: Control
var active_room_screen: Control
var crew_screen: Control
var wake_room_screen: Control
var title_screen: Control
var pending_role := 0

func _ready() -> void:
	# Start edge-to-edge on the user's display. F11 can restore a normal window.
	get_window().mode = Window.MODE_FULLSCREEN
	Network.joined.connect(_on_network_joined)
	Network.join_failed.connect(_on_network_join_failed)
	_show_title()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		get_window().mode = Window.MODE_WINDOWED if get_window().mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
		get_viewport().set_input_as_handled()

func _show_title() -> void:
	var title: Control = TitleScreen.new()
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title.connect("start_requested", Callable(self, "_start_solo"))
	title.connect("host_requested", Callable(self, "_host_crew"))
	title.connect("join_requested", Callable(self, "_join_crew"))
	title_screen = title
	add_child(title)

func _start_solo() -> void:
	Network.leave()
	pending_role = 0
	_show_story_intro()

func _host_crew(player_name: String) -> void:
	var result: int = Network.host(player_name)
	if result != OK:
		title_screen.call("set_status", "HOST FAILED  ·  ERROR %d" % result)

func _join_crew(address: String, player_name: String) -> void:
	var result: int = Network.join(address, player_name)
	if result != OK:
		title_screen.call("set_status", "JOIN FAILED  ·  ERROR %d" % result)
	else:
		title_screen.call("set_status", "CONNECTING TO  %s" % address)

func _on_network_joined() -> void:
	pending_role = clampi(Network.my_slot(), 0, 3)
	_show_story_intro()

func _on_network_join_failed(reason: String) -> void:
	if title_screen != null and is_instance_valid(title_screen):
		title_screen.call("set_status", reason)

func _show_story_intro() -> void:
	for child in get_children():
		child.queue_free()
	var intro: Control = StoryIntro.new()
	intro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro.connect("continue_requested", Callable(self, "_begin_mission"))
	add_child(intro)

func _begin_mission() -> void:
	_show_crew_select()

func _show_crew_select() -> void:
	for child in get_children():
		child.queue_free()
	var crew: Control = CrewSelect.new()
	crew.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	crew.connect("start_requested", Callable(self, "_start_mission"))
	crew_screen = crew
	add_child(crew)

func _start_mission(role_index: int, suit_color: Color, gear_color: Color) -> void:
	for child in get_children():
		child.queue_free()
	var room: Control = WakeUpRoom.new()
	room.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	room.set("selected_role", role_index)
	room.set("selected_suit_color", suit_color)
	room.set("selected_gear_color", gear_color)
	room.set("wake_prompt", false)
	room.connect("map_requested", Callable(self, "_show_map"))
	wake_room_screen = room
	add_child(room)

func _show_map() -> void:
	if wake_room_screen != null:
		wake_room_screen.hide()
		wake_room_screen.set_process(false)
		wake_room_screen.set_process_input(false)
	for child in get_children():
		if child != wake_room_screen:
			child.queue_free()
	var map_control: Control = EarthMap.new()
	map_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if wake_room_screen != null:
		map_control.set("selected_role", wake_room_screen.get("selected_role"))
		map_control.set("starting_role", wake_room_screen.get("starting_role"))
		map_control.set("selected_suit_color", wake_room_screen.get("selected_suit_color"))
		map_control.set("crew_following", wake_room_screen.get("crew_following"))
	map_control.connect("room_requested", Callable(self, "_open_room"))
	map_control.connect("back_requested", Callable(self, "_return_to_wake_room"))
	map_screen = map_control
	add_child(map_control)

func _open_room(room: Dictionary) -> void:
	if map_screen == null:
		return
	map_screen.hide()
	map_screen.set_process(false)
	map_screen.set_process_input(false)
	_create_room_screen(room)

func _create_room_screen(room: Dictionary, entry_side: int = -1) -> void:
	var room_screen: Control = RoomInterface.new()
	room_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	room_screen.set("room_data", room)
	room_screen.set("entry_side", entry_side)
	if map_screen != null:
		room_screen.set("connected_rooms", map_screen.call("get_room_doors", str(room.get("id", ""))))
	room_screen.connect("back_requested", Callable(self, "_return_to_map"))
	room_screen.connect("door_requested", Callable(self, "_open_connected_room"))
	active_room_screen = room_screen
	add_child(room_screen)

func _open_connected_room(room: Dictionary, entry_side: int) -> void:
	if active_room_screen != null:
		active_room_screen.queue_free()
		active_room_screen = null
	_create_room_screen(room, entry_side)

func _return_to_map() -> void:
	if active_room_screen != null:
		active_room_screen.queue_free()
		active_room_screen = null
	if map_screen != null:
		map_screen.show()
		map_screen.set_process(true)
		map_screen.set_process_input(true)

func _return_to_wake_room() -> void:
	if active_room_screen != null:
		active_room_screen.queue_free()
		active_room_screen = null
	if map_screen != null:
		map_screen.queue_free()
		map_screen = null
	if wake_room_screen != null:
		wake_room_screen.show()
		wake_room_screen.set_process(true)
		wake_room_screen.set_process_input(true)
