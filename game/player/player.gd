extends CharacterBody2D
## Top-down player for local co-op. Owner: Sufi (gameplay). Visuals: Zaliq/Wafi.
##
## How Zaliq/Wafi add art (no code changes needed):
##   Add an AnimatedSprite2D child named "Sprite" with animations named
##   idle_down, idle_up, idle_side, walk_down, walk_up, walk_side
##   (side animations face RIGHT; the script flips them for left).
##   While there is no "Sprite" child, a coloured placeholder is drawn.
##
## Other scripts use:
##   player_index        which keyboard set controls this player (0..3)
##   can_move            false while the player is inside a mini-game or dialogue
##   facing / is_moving  read-only state for animation, footsteps, etc.
##   signal interact_requested(player)   emitted when the interact key is pressed

const InputSetup := preload("res://game/input_setup.gd")

signal interact_requested(player: CharacterBody2D)

## Placeholder colours, also handy for HUD markers. Same order as P1..P4.
const PLAYER_COLORS := [Color("#ffcf4a"), Color("#4ad6ff"), Color("#7dff7a"), Color("#ff7ad9")]

@export_range(0, 3) var player_index := 0
@export var max_speed := 70.0        ## pixels per second (world pixels, before camera zoom)
@export var acceleration := 900.0    ## how fast it reaches max speed; higher = snappier
@export var friction := 1200.0       ## how fast it stops when keys are released

var can_move := true
var facing := Vector2.DOWN
var is_moving := false

var _sprite: AnimatedSprite2D


func _ready() -> void:
	InputSetup.ensure()
	_sprite = get_node_or_null("Sprite") as AnimatedSprite2D
	if get_node_or_null("CollisionShape2D") == null:
		# Feet-sized box: in top-down games only the feet should hit walls.
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var rect := RectangleShape2D.new()
		rect.size = Vector2(10, 6)
		shape.shape = rect
		shape.position = Vector2(0, -3)
		add_child(shape)
	# Layer 2 = players, mask 1 = world. Players pass through each other (like Among Us).
	collision_layer = 2
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	queue_redraw()
	# Opened on its own with F6? Add a still, zoomed camera so you can see it move.
	if get_parent() == get_tree().root:
		var cam := Camera2D.new()
		cam.zoom = Vector2(4, 4)
		get_parent().add_child.call_deferred(cam)


func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	if can_move:
		input = Input.get_vector(
			InputSetup.action(player_index, "left"), InputSetup.action(player_index, "right"),
			InputSetup.action(player_index, "up"), InputSetup.action(player_index, "down"))
	step(input, delta)
	move_and_slide()
	_update_animation()


## Movement maths, separated from input so tests can drive it directly.
func step(input: Vector2, delta: float) -> void:
	if input.length() > 1.0:
		input = input.normalized()   # diagonal is not faster than straight
	if input != Vector2.ZERO:
		velocity = velocity.move_toward(input * max_speed, acceleration * delta)
		facing = _snap_to_4(input)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	is_moving = velocity.length() > 1.0


func _unhandled_input(event: InputEvent) -> void:
	if can_move and event.is_action_pressed(InputSetup.action(player_index, "interact")):
		interact_requested.emit(self)
		get_viewport().set_input_as_handled()


func _snap_to_4(v: Vector2) -> Vector2:
	if absf(v.x) > absf(v.y):
		return Vector2.RIGHT if v.x > 0 else Vector2.LEFT
	return Vector2.DOWN if v.y > 0 else Vector2.UP


func _update_animation() -> void:
	if _sprite == null:
		queue_redraw()   # placeholder shows facing
		return
	var dir := "down" if facing == Vector2.DOWN else "up" if facing == Vector2.UP else "side"
	var anim := ("walk_" if is_moving else "idle_") + dir
	_sprite.flip_h = facing == Vector2.LEFT
	if _sprite.sprite_frames and _sprite.sprite_frames.has_animation(anim) and _sprite.animation != anim:
		_sprite.play(anim)


## Placeholder body (only while there is no art): 12x18 px, origin at the feet.
func _draw() -> void:
	if _sprite != null:
		return
	var c: Color = PLAYER_COLORS[player_index % PLAYER_COLORS.size()]
	draw_rect(Rect2(-6, -18, 12, 18), c)                          # suit
	draw_rect(Rect2(-6, -18, 12, 18), Color.BLACK, false, 1.0)    # outline
	var visor := Rect2(-1 + facing.x * 3, -15 + maxf(facing.y, -0.5) * 2, 6, 4)
	if facing == Vector2.UP:
		visor = Rect2(-4, -16, 8, 2)                              # back of helmet
	draw_rect(visor, Color("#9fd8ff"))
