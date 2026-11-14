extends Control
## Crew and suit setup, following the supplied Project Dawn gameplay reference.

signal start_requested(role_index: int, suit_color: Color, gear_color: Color)

const FONT = preload("res://ui/fonts/PressStart2P-Regular.ttf")
const CrewSprites = preload("res://ui/components/crew_sprites.gd")
const DESIGN_SIZE := Vector2(1280.0, 720.0)
const ROLE_TEXTURES: Array[Texture2D] = [
	preload("res://ui/art/characters/reference_engineer.png"),
	preload("res://ui/art/characters/reference_scientist.png"),
	preload("res://ui/art/characters/reference_navigator.png"),
	preload("res://ui/art/characters/reference_quartermaster.png")
]
const ROLE_NAMES: Array[String] = ["ENGINEER", "SCIENTIST", "NAVIGATOR", "QUARTERMASTER"]
const ROLE_DESCRIPTIONS: Array[String] = [
	"BUILDS · DRILLS · HEATERS",
	"INSTRUMENTS · ICE · CROPS",
	"LAUNCHES · FUEL · TELESCOPE",
	"POWER · CABLES · CARGO"
]
const ROLE_COLORS: Array[Color] = [Color("ff8d35"), Color("00bde9"), Color("db61a0"), Color("ffc04a")]
const SUIT_COLORS: Array[Color] = [
	Color("3a4466"), Color("f77622"), Color("e43b44"), Color("63c74d"),
	Color("0099db"), Color("2ce8f5"), Color("b55088"), Color("feae34"), Color("ead4aa")
]
const GEAR_COLORS: Array[Color] = [Color("c0cbdc"), Color("2ce8f5"), Color("fee761"), Color("feae34"), Color("e43b44"), Color("f6757a"), Color("5a6988")]
const PANEL := Color("20203d")
const NAVY := Color("15152a")
const GOLD := Color("ffb735")
const CREAM := Color("f3e5bc")
const MUTED := Color("a6aec7")

var pixel_scale := 1.0
var pixel_offset := Vector2.ZERO
var selected_role := 0
var selected_suit := 0
var selected_gear := 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	grab_focus()
	queue_redraw()

func _draw() -> void:
	pixel_scale = minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	pixel_offset = (size - DESIGN_SIZE * pixel_scale) * 0.5
	draw_set_transform(pixel_offset, 0.0, Vector2.ONE * pixel_scale)
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), NAVY, true)
	for y in range(0, 720, 8):
		draw_line(Vector2(0, y), Vector2(1280, y), Color(0.08, 0.08, 0.16, 0.24), 1.0)
	draw_rect(Rect2(22, 18, 1236, 680), Color("333653"), false, 4.0)
	_draw_panel(Rect2(44, 42, 690, 622))
	_draw_panel(Rect2(752, 42, 484, 622))
	_draw_crew_panel()
	_draw_customization_panel()
	draw_rect(Rect2(44, 670, 1192, 34), NAVY, true)
	draw_string(FONT, Vector2(64, 694), "TAB / ARROWS: PICK ROLE    ·    CLICK A COLOR    ·    ENTER: START", HORIZONTAL_ALIGNMENT_LEFT, 900, 8, CREAM)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_panel(rect: Rect2) -> void:
	draw_rect(rect, PANEL, true)
	draw_rect(rect, GOLD, false, 4.0)
	draw_rect(Rect2(rect.position.x + 5, rect.position.y + 5, rect.size.x - 10, rect.size.y - 10), Color("282844"), false, 2.0)

func _draw_crew_panel() -> void:
	draw_string(FONT, Vector2(72, 96), "YOUR CREW", HORIZONTAL_ALIGNMENT_LEFT, 570, 22, Color("ffe064"))
	draw_string(FONT, Vector2(72, 132), "YOU CAN SWITCH ROLES DURING THE MISSION.", HORIZONTAL_ALIGNMENT_LEFT, 610, 8, CREAM)
	draw_string(FONT, Vector2(72, 153), "CHOOSE WHO YOU CONTROL FIRST.", HORIZONTAL_ALIGNMENT_LEFT, 610, 8, CREAM)
	for index in range(ROLE_NAMES.size()):
		var column := index % 2
		var row := index >> 1
		var rect := Rect2(72.0 + float(column) * 322.0, 182.0 + float(row) * 132.0, 302.0, 108.0)
		var active := index == selected_role
		draw_rect(rect, Color("25223e") if active else Color("19182e"), true)
		draw_rect(rect, Color("ffe064") if active else Color("58617f"), false, 3.0)
		_draw_character(CrewSprites.sprite(index, SUIT_COLORS[selected_suit], GEAR_COLORS[selected_gear]) if index == selected_role else ROLE_TEXTURES[index], rect.position + Vector2(22, 24), ROLE_COLORS[index])
		draw_string(FONT, rect.position + Vector2(90, 37), ROLE_NAMES[index], HORIZONTAL_ALIGNMENT_LEFT, 198, 9, CREAM)
		draw_string(FONT, rect.position + Vector2(90, 61), "YOU / HOST" if active else "OPEN · CERES AUTOPILOT", HORIZONTAL_ALIGNMENT_LEFT, 198, 7, GOLD if active else Color("f1ca73"))
		draw_string(FONT, rect.position + Vector2(90, 86), ROLE_DESCRIPTIONS[index], HORIZONTAL_ALIGNMENT_LEFT, 198, 6, MUTED)
	var info := Rect2(72, 462, 626, 158)
	draw_rect(info, Color("19182e"), true)
	draw_rect(info, Color("58617f"), false, 2.0)
	draw_string(FONT, Vector2(94, 498), "YOUR CREW WORKS TOGETHER", HORIZONTAL_ALIGNMENT_LEFT, 580, 9, Color("ffe064"))
	draw_string(FONT, Vector2(94, 530), "ALL FOUR SCIENTISTS ARE ON YOUR TEAM.", HORIZONTAL_ALIGNMENT_LEFT, 580, 8, CREAM)
	draw_string(FONT, Vector2(94, 554), "TAB SWITCHES THE ACTIVE ROLE.", HORIZONTAL_ALIGNMENT_LEFT, 580, 8, MUTED)
	draw_string(FONT, Vector2(94, 578), "F CALLS THE REST OF THE CREW TO FOLLOW.", HORIZONTAL_ALIGNMENT_LEFT, 580, 8, MUTED)

func _draw_customization_panel() -> void:
	draw_string(FONT, Vector2(786, 96), "SOLO CREW", HORIZONTAL_ALIGNMENT_LEFT, 420, 22, Color("ffe064"))
	draw_string(FONT, Vector2(786, 142), "SUIT COLOUR", HORIZONTAL_ALIGNMENT_LEFT, 420, 9, MUTED)
	for index in range(SUIT_COLORS.size()):
		var row := int(index / 7.0)
		var column := index % 7
		var rect := Rect2(788.0 + float(column) * 68.0, 162.0 + float(row) * 64.0, 48.0, 48.0)
		draw_rect(rect, Color("111327"), true)
		draw_rect(rect.grow(-6), SUIT_COLORS[index], true)
		if selected_suit == index:
			draw_rect(rect.grow(-2), Color("ffe064"), false, 3.0)
	draw_string(FONT, Vector2(786, 300), "VISOR & PACK", HORIZONTAL_ALIGNMENT_LEFT, 420, 9, MUTED)
	for index in range(GEAR_COLORS.size()):
		var rect := Rect2(788.0 + float(index) * 68.0, 320.0, 48.0, 48.0)
		draw_rect(rect, Color("111327"), true)
		draw_rect(rect.grow(-6), GEAR_COLORS[index], true)
		if selected_gear == index:
			draw_rect(rect.grow(-2), Color("ffe064"), false, 3.0)
	_draw_character(CrewSprites.sprite(selected_role, SUIT_COLORS[selected_suit], GEAR_COLORS[selected_gear]), Vector2(938, 404), Color.WHITE)
	draw_rect(Rect2(955, 416, 16, 8), GEAR_COLORS[selected_gear], true)
	draw_rect(Rect2(943, 434, 9, 16), SUIT_COLORS[selected_suit].darkened(0.35), true)
	draw_string(FONT, Vector2(786, 466), ROLE_NAMES[selected_role] + " / PREVIEW", HORIZONTAL_ALIGNMENT_LEFT, 420, 8, CREAM)
	var start := Rect2(788, 558, 402, 70)
	draw_rect(start.grow(4), NAVY, true)
	draw_rect(start, Color("ffb735"), true)
	draw_rect(Rect2(start.position.x, start.end.y - 7, start.size.x, 7), Color("be5a2d"), true)
	draw_rect(start, Color("ffe064"), false, 3.0)
	draw_string(FONT, Vector2(start.position.x + 22, start.position.y + 44), "START MISSION  >>", HORIZONTAL_ALIGNMENT_CENTER, start.size.x - 44, 14, NAVY)

func _draw_character(texture: Texture2D, position: Vector2, tint: Color) -> void:
	draw_texture_rect_region(texture, Rect2(position, Vector2(48, 48)), Rect2(0, 0, 16, 16), Color.WHITE)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click(_canvas_mouse_position())
		accept_event()
	elif event is InputEventKey and event.pressed and not event.echo:
		var key := (event as InputEventKey).physical_keycode
		if key == KEY_ENTER or key == KEY_SPACE:
			_start()
		elif key == KEY_TAB or key == KEY_RIGHT or key == KEY_DOWN:
			selected_role = (selected_role + 1) % ROLE_NAMES.size()
			queue_redraw()
		elif key == KEY_LEFT or key == KEY_UP:
			selected_role = posmod(selected_role - 1, ROLE_NAMES.size())
			queue_redraw()
		elif key >= KEY_1 and key <= KEY_4:
			selected_role = key - KEY_1
			queue_redraw()
		accept_event()

func _handle_click(point: Vector2) -> void:
	if Rect2(788, 558, 402, 70).has_point(point):
		_start()
		return
	for index in range(ROLE_NAMES.size()):
		var column := index % 2
		var row := index >> 1
		var role_rect := Rect2(72.0 + float(column) * 322.0, 182.0 + float(row) * 132.0, 302.0, 108.0)
		if role_rect.has_point(point):
			selected_role = index
			queue_redraw()
			return
	for index in range(SUIT_COLORS.size()):
		var row := int(index / 7.0)
		var column := index % 7
		if Rect2(788.0 + float(column) * 68.0, 162.0 + float(row) * 64.0, 48.0, 48.0).has_point(point):
			selected_suit = index
			queue_redraw()
			return
	for index in range(GEAR_COLORS.size()):
		if Rect2(788.0 + float(index) * 68.0, 320.0, 48.0, 48.0).has_point(point):
			selected_gear = index
			queue_redraw()
			return

func _start() -> void:
	start_requested.emit(selected_role, SUIT_COLORS[selected_suit], GEAR_COLORS[selected_gear])

func _canvas_mouse_position() -> Vector2:
	if pixel_scale <= 0.0:
		return Vector2.ZERO
	return (get_global_mouse_position() - pixel_offset) / pixel_scale
