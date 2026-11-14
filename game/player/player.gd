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
