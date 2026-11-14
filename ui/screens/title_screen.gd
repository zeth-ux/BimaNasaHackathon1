extends Control
## Pixel-art title screen based on the supplied Project Dawn reference.

signal start_requested
signal host_requested(player_name: String)
signal join_requested(address: String, player_name: String)

const FONT = preload("res://ui/fonts/PressStart2P-Regular.ttf")
const DESIGN_SIZE := Vector2(1280.0, 720.0)
const MENU_BUTTONS := [
	Rect2(414.0, 316.0, 452.0, 58.0),
	Rect2(414.0, 386.0, 452.0, 58.0),
	Rect2(414.0, 456.0, 452.0, 58.0)
]
const NAVY := Color("17152c")
const GOLD := Color("ffb735")
const CREAM := Color("f6e7bc")
const PURPLE := Color("633b70")
const CORAL := Color("ef7478")

var pixel_scale := 1.0
var pixel_offset := Vector2.ZERO
var selected_option := 0
var status_message := "CO-OP DEMO  ·  1–4 PLAYERS  ·  EARTH  ·  MOON  ·  MARS"
var connection_dialog: ConfirmationDialog
var player_name_input: LineEdit
var address_input: LineEdit
var connection_mode := "host"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build_connection_dialog()
	queue_redraw()

func _draw() -> void:
	pixel_scale = minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	pixel_offset = (size - DESIGN_SIZE * pixel_scale) * 0.5
	draw_set_transform(pixel_offset, 0.0, Vector2.ONE * pixel_scale)
	_draw_landscape()
	_draw_title_panel()
	_draw_menu_buttons()
	_draw_footer()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_landscape() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), NAVY, true)
	# Starlight and the layered dusk sky.
	for star in [Vector2(84, 188), Vector2(178, 231), Vector2(301, 177), Vector2(482, 264), Vector2(711, 194), Vector2(889, 254), Vector2(1112, 202), Vector2(1202, 279), Vector2(1014, 325), Vector2(648, 306)]:
		draw_rect(Rect2(star, Vector2(4, 4)), CREAM, true)
	draw_rect(Rect2(0, 164, 1280, 100), Color("292344"), true)
	draw_rect(Rect2(0, 264, 1280, 90), Color("573664"), true)
	draw_rect(Rect2(0, 354, 1280, 92), PURPLE, true)
	draw_rect(Rect2(0, 446, 1280, 88), Color("b84d78"), true)
	draw_rect(Rect2(0, 534, 1280, 48), CORAL, true)
	draw_rect(Rect2(0, 582, 1280, 40), Color("f2ad77"), true)
	# Thin scanlines keep the sky and ground crisp at larger window sizes.
	for y in range(168, 620, 6):
		draw_line(Vector2(0, y), Vector2(1280, y), Color(0.13, 0.08, 0.19, 0.13), 1.0)
	# Sunset and bands across the sun.
	for stripe in range(5):
		var sun_y := 482.0 + float(stripe) * 12.0
		var inset := 10.0 + float(stripe) * 3.0
		draw_rect(Rect2(942.0 + inset, sun_y, 150.0 - inset * 2.0, 11.0), Color("ffd45a"), true)
	# Pixel mountain silhouettes.
	var far_peaks := PackedVector2Array([
		Vector2(0, 565), Vector2(42, 532), Vector2(76, 548), Vector2(111, 507), Vector2(154, 544),
		Vector2(208, 520), Vector2(254, 557), Vector2(316, 515), Vector2(360, 539), Vector2(426, 482),
		Vector2(480, 527), Vector2(533, 489), Vector2(593, 539), Vector2(650, 500), Vector2(702, 543),
		Vector2(774, 480), Vector2(829, 532), Vector2(889, 494), Vector2(940, 544), Vector2(1002, 509),
		Vector2(1055, 539), Vector2(1120, 490), Vector2(1172, 527), Vector2(1280, 475), Vector2(1280, 640), Vector2(0, 640)
	])
	draw_colored_polygon(far_peaks, PURPLE)
	var near_peaks := PackedVector2Array([
		Vector2(0, 605), Vector2(60, 563), Vector2(110, 579), Vector2(166, 540), Vector2(222, 583),
		Vector2(274, 555), Vector2(330, 607), Vector2(386, 563), Vector2(450, 596), Vector2(510, 546),
		Vector2(573, 599), Vector2(630, 560), Vector2(685, 604), Vector2(743, 552), Vector2(806, 589),
		Vector2(862, 542), Vector2(922, 596), Vector2(978, 559), Vector2(1042, 608), Vector2(1095, 566),
		Vector2(1154, 594), Vector2(1201, 548), Vector2(1280, 571), Vector2(1280, 650), Vector2(0, 650)
	])
	draw_colored_polygon(near_peaks, Color("25253f"))
	# Ground, runway blocks and rocket silhouette.
	draw_rect(Rect2(0, 620, 1280, 100), Color("352633"), true)
	for x in range(20, 1280, 64):
		draw_rect(Rect2(x, 625 + float((x / 64) % 3) * 3.0, 6, 4), Color("d98769"), true)
	# Small launch platform on the left.
	draw_rect(Rect2(136, 590, 116, 28), Color("303954"), true)
	draw_rect(Rect2(146, 582, 94, 8), Color("61718d"), true)
	draw_rect(Rect2(162, 618, 11, 9), Color("182036"), true)
	draw_rect(Rect2(214, 618, 11, 9), Color("182036"), true)
	# A chunky, readable first-light rocket on its pad.
	draw_rect(Rect2(1092, 500, 80, 118), Color("121b30"), true)
	for y in range(506, 610, 16):
		draw_rect(Rect2(1098, y, 68, 7), Color("28324d"), true)
	draw_colored_polygon(PackedVector2Array([Vector2(1122, 416), Vector2(1142, 386), Vector2(1162, 416)]), Color("f5d7a6"))
	draw_rect(Rect2(1122, 416, 40, 122), Color("d8e0df"), true)
	draw_rect(Rect2(1122, 416, 40, 122), Color("24243b"), false, 3.0)
	draw_rect(Rect2(1122, 450, 40, 16), Color("ef5b67"), true)
	draw_rect(Rect2(1132, 470, 20, 25), Color("73c6d4"), true)
	draw_rect(Rect2(1112, 528, 8, 22), Color("f09832"), true)
	draw_rect(Rect2(1164, 528, 8, 22), Color("f09832"), true)
	draw_colored_polygon(PackedVector2Array([Vector2(1128, 538), Vector2(1135, 538), Vector2(1131, 565)]), Color("ffc252"))
	draw_colored_polygon(PackedVector2Array([Vector2(1148, 538), Vector2(1156, 538), Vector2(1152, 561)]), Color("f06b55"))

func _draw_title_panel() -> void:
	draw_rect(Rect2(28, 28, 1224, 126), NAVY, true)
	draw_rect(Rect2(28, 28, 1224, 126), GOLD, false, 4.0)
	draw_string(FONT, Vector2(217, 94), "PROJECT DAWN", HORIZONTAL_ALIGNMENT_CENTER, 846, 54, GOLD)
	draw_string(FONT, Vector2(190, 130), "DESIGN REAL SPACE MISSIONS. HEAL THE SKY. BRING HUMANITY HOME.", HORIZONTAL_ALIGNMENT_CENTER, 900, 14, CREAM)

func _draw_menu_buttons() -> void:
	var labels := ["PLAY SOLO  >>", "HOST A CREW  >>", "JOIN A CREW  >>"]
	for index in range(MENU_BUTTONS.size()):
		var rect: Rect2 = MENU_BUTTONS[index]
		var active := index == selected_option or rect.has_point(_canvas_mouse_position())
		var fill := Color("ffc33e") if active else Color("392a4b")
		draw_rect(rect.grow(4), Color("17152c"), true)
		draw_rect(rect, fill, true)
		draw_rect(Rect2(rect.position.x, rect.end.y - 7.0, rect.size.x, 7.0), Color("be5a2d"), true)
		draw_rect(rect, GOLD if active else Color("58617f"), false, 3.0)
		draw_string(FONT, Vector2(rect.position.x + 18, rect.position.y + 38), labels[index], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 36, 15, NAVY if active else CREAM)

func _draw_footer() -> void:
	draw_rect(Rect2(52, 648, 708, 42), NAVY, true)
	draw_rect(Rect2(52, 648, 708, 42), Color("465474"), false, 3.0)
	draw_string(FONT, Vector2(66, 675), status_message, HORIZONTAL_ALIGNMENT_LEFT, 682, 7, CREAM)
	draw_string(FONT, Vector2(640, 708), "WASD / ARROWS: SELECT  ·  ENTER: CONFIRM", HORIZONTAL_ALIGNMENT_CENTER, 720, 7, CREAM)

func _canvas_mouse_position() -> Vector2:
	if pixel_scale <= 0.0:
		return Vector2.ZERO
	return (get_global_mouse_position() - pixel_offset) / pixel_scale

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var point := _canvas_mouse_position()
		for index in range(MENU_BUTTONS.size()):
			if MENU_BUTTONS[index].has_point(point):
				selected_option = index
				_activate_option(index)
				accept_event()
				return
	elif event is InputEventMouseMotion:
		queue_redraw()
	elif event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		if key_event.physical_keycode == KEY_DOWN or key_event.physical_keycode == KEY_S:
			selected_option = (selected_option + 1) % MENU_BUTTONS.size()
			queue_redraw()
			accept_event()
		elif key_event.physical_keycode == KEY_UP or key_event.physical_keycode == KEY_W:
			selected_option = posmod(selected_option - 1, MENU_BUTTONS.size())
			queue_redraw()
			accept_event()
		elif key_event.physical_keycode == KEY_ENTER or key_event.physical_keycode == KEY_SPACE:
			_activate_option(selected_option)
			accept_event()

func _activate_option(index: int) -> void:
	match index:
		0: start_requested.emit()
		1: _open_connection_dialog("host")
		2: _open_connection_dialog("join")

func _build_connection_dialog() -> void:
	connection_dialog = ConfirmationDialog.new()
	connection_dialog.title = "CREW CONNECTION"
	connection_dialog.confirmed.connect(_submit_connection)
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(390.0, 132.0)
	content.add_theme_constant_override("separation", 10)
	var name_label := Label.new()
	name_label.text = "CALLSIGN"
	content.add_child(name_label)
	player_name_input = LineEdit.new()
	player_name_input.placeholder_text = "Your name"
	player_name_input.text = "Engineer"
	content.add_child(player_name_input)
	address_input = LineEdit.new()
	address_input.placeholder_text = "Host IP address"
	address_input.text = "127.0.0.1"
	content.add_child(address_input)
	connection_dialog.add_child(content)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(connection_dialog)
	connection_dialog.get_ok_button().text = "CONTINUE"

func _open_connection_dialog(mode: String) -> void:
	connection_mode = mode
	connection_dialog.title = "HOST A CREW" if mode == "host" else "JOIN A CREW"
	address_input.visible = mode == "join"
	connection_dialog.popup_centered(Vector2i(470, 260))
	player_name_input.grab_focus()

func _submit_connection() -> void:
	if connection_mode == "host":
		host_requested.emit(player_name_input.text.strip_edges())
	else:
		join_requested.emit(address_input.text.strip_edges(), player_name_input.text.strip_edges())

func set_status(message: String) -> void:
	status_message = message
	queue_redraw()
