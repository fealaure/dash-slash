class_name EnemyBat
extends Node2D
## Morcego que flutua em padrão de onda. Morre com 1 golpe.

@export var amplitude: Vector2 = Vector2(14.0, 10.0)
@export var speed: float = 1.4

var dead: bool = false
var _origin: Vector2
var _t: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_origin = position
	_t = randf() * TAU
	sprite.play("fly")


func _process(delta: float) -> void:
	if dead:
		return
	_t += delta * speed
	var prev_x: float = position.x
	position = _origin + Vector2(sin(_t) * amplitude.x, sin(_t * 2.0) * amplitude.y)
	sprite.flip_h = position.x < prev_x


func hit() -> void:
	if dead:
		return
	dead = true
	FX.burst(get_parent(), global_position, Color(0.75, 0.3, 1.0))
	queue_free()
