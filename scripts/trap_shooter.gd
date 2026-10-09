extends Node2D
## Cabeça de dragão de pedra que dispara dardos contra o jogador que vem da
## esquerda. Pule por cima ou corte o dardo com a espada.

const DART_SCENE = preload("res://scenes/dart.tscn")
const INTERVAL = 1.9
const RANGE = 280.0
const DART_SPEED = 140.0

var _t: float = 0.6


func _physics_process(delta: float) -> void:
	_t -= delta
	if _t > 0.0:
		return
	var player: Node2D = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var dx: float = global_position.x - player.global_position.x
	if dx > 0.0 and dx < RANGE:
		_t = INTERVAL
		var d: Projectile = DART_SCENE.instantiate()
		d.position = position + Vector2(-9.0, -1.0)
		d.velocity = Vector2(-DART_SPEED, 0.0)
		get_parent().add_child(d)
