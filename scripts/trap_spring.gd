extends Area2D
## Mola: ao pisar, o jogador é lançado bem alto.

const LAUNCH = -560.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player and body.velocity.y >= 0.0:
		(body as Player).bounce(LAUNCH)
		var tw: Tween = create_tween()
		sprite.scale = Vector2(1.2, 0.6)
		tw.tween_property(sprite, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC)
