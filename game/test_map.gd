extends Node2D
## Test map: 4 connected rooms (2x2) built from placeholder blocks.
## Owner: Sufi (gameplay). Open game/test_map.tscn and press F6.
##   F1..F4  number of players · P1 WASD · P2 Arrows · P3 IJKL · P4 Numpad 8456
## The whole map is shown at once for now; the room camera comes in step 4.
## Real rooms will be painted with tiles later; this file only tests movement.

const InputSetup := preload("res://game/input_setup.gd")
const RoomGrid := preload("res://game/world/room_grid.gd")
const PlayerScene := preload("res://game/player/player.tscn")
const RoomCamera := preload("res://game/camera/room_camera.gd")

## Which rooms exist. Doors are made automatically between neighbouring rooms.
const ROOMS: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
const WALL := 8.0     ## wall thickness inside each room's edge
const DOOR := 32.0    ## doorway width

## Camera variables for room_camera.gd
var players: Array = []
var hud: Label
var camera: Camera2D
var _blocks: Array[Rect2] = []   # for drawing


func _ready() -> void:
	get_viewport().canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	InputSetup.ensure()

	for room in ROOMS:
	    _build_room(room)

    camera = RoomCamera.new()
	add_child(camera)
	_build_hud()
	set_player_count(4)


func set_player_count(n: int) -> void:
	for p in players:
		p.queue_free()
	players.clear()
	var start := RoomGrid.room_center(Vector2i(0, 0))
	for i in n:
		var p = PlayerScene.instantiate()
		p.player_index = i
		p.position = start + Vector2(-10 + (i % 2) * 20, -4 + (i / 2) * 18)   # 2x2 group, lined up with the doors
        add_child(p)
		players.append(p)
	camera.target = players[0]     # step 5 gives every player their own camera


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.physical_keycode
		if k >= KEY_F1 and k <= KEY_F4:
			set_player_count(k - KEY_F1 + 1)


func _process(_delta: float) -> void:
	var lines := ["TEST MAP  ·  F1-F4: players (%d)" % players.size()]
	for p in players:
		var r: Vector2i = RoomGrid.room_of(p.position)
		lines.append("P%d (%s): room %d,%d" % [p.player_index + 1, InputSetup.LABELS[p.player_index], r.x, r.y])
	hud.text = "\n".join(lines)


# ---------------------------------------------------------------- rooms

func _build_room(room: Vector2i) -> void:
	var r := RoomGrid.room_rect(room)
	var has := func(dx: int, dy: int) -> bool: return (room + Vector2i(dx, dy)) in ROOMS
	_wall_h(r.position.y, r, has.call(0, -1))                 # top
	_wall_h(r.end.y - WALL, r, has.call(0, 1))                # bottom
	_wall_v(r.position.x, r, has.call(-1, 0))                 # left
	_wall_v(r.end.x - WALL, r, has.call(1, 0))                # right
	# Some furniture so there is something to bump into (kept off the door lines).
	_add_block(Rect2(r.position + Vector2(40, 30), Vector2(48, 16)))
	_add_block(Rect2(r.position + Vector2(232, 134), Vector2(48, 16)))


## Horizontal wall along a room edge, with a doorway in the middle if there is a neighbour.
func _wall_h(y: float, r: Rect2, door: bool) -> void:
	if not door:
		_add_block(Rect2(r.position.x, y, r.size.x, WALL))
		return
	var half := (r.size.x - DOOR) / 2.0
	_add_block(Rect2(r.position.x, y, half, WALL))
	_add_block(Rect2(r.position.x + half + DOOR, y, half, WALL))


func _wall_v(x: float, r: Rect2, door: bool) -> void:
	if not door:
		_add_block(Rect2(x, r.position.y, WALL, r.size.y))
		return
	var half := (r.size.y - DOOR) / 2.0
	_add_block(Rect2(x, r.position.y, WALL, half))
	_add_block(Rect2(x, r.position.y + half + DOOR, WALL, half))


func _add_block(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.position = rect.get_center()
	body.add_child(shape)
	add_child(body)
	_blocks.append(rect)


func _draw() -> void:
	for room in ROOMS:
		var r := RoomGrid.room_rect(room)
		draw_rect(r, Color("#2a2f45") if (room.x + room.y) % 2 == 0 else Color("#2f3550"))
	for b in _blocks:
		draw_rect(b, Color("#5b6385"))
		draw_rect(b, Color("#14172a"), false, 1.0)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(12, 8)
	hud.add_theme_color_override("font_outline_color", Color.BLACK)
	hud.add_theme_constant_override("outline_size", 4)
	layer.add_child(hud)
