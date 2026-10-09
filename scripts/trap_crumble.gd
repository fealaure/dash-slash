extends StaticBody2D
## Bloco que treme e cai pouco depois que o jogador pisa. Volta após alguns
## segundos.

const DELAY = 0.35
const RESPAWN = 3.0

var _busy: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var detector: Area2D = $Detector


func _ready() -> void:
	detector.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _busy or not body is Player:
		return
	_busy = true
	var tw: Tween = create_tween()
	for i: int in 4:
		tw.tween_property(sprite, "position:x", 1.0 if i % 2 == 0 else -1.0, DELAY / 4.0)
	tw.tween_callback(func() -> void: shape.set_deferred("disabled", true))
	tw.tween_property(sprite, "position", Vector2(0, 40), 0.4).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(sprite, "modulate:a", 0.0, 0.4)
	tw.tween_interval(RESPAWN)
	tw.tween_callback(_restore)


func _restore() -> void:
	sprite.position = Vector2.ZERO
	sprite.modulate.a = 1.0
	shape.set_deferred("disabled", false)
	_busy = false
