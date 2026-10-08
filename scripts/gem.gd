class_name Gem
extends Area2D
## Gema colecionável (recompensa das rotas alternativas).

var _t: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_t = randf() * TAU
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_t += delta * 3.0
	sprite.position.y = sin(_t) * 2.0


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		(body as Player).add_gem()
		FX.burst(get_parent(), global_position, Color(0.4, 0.9, 1.0), 10)
		queue_free()
