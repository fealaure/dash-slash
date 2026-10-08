class_name Goal
extends Area2D
## Portal no fim da fase.

signal reached


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not (body as Player).is_dead:
		reached.emit()
