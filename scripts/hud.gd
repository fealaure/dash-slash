class_name HUD
extends CanvasLayer
## HUD mobile: vida, gemas, tempo, mensagens e dois botões de toque.
## Metade ESQUERDA da tela = ATAQUE, metade DIREITA = PULO (multi-toque).

const HEART_TEX = preload("res://assets/generated/heart.png")

var _touches: Dictionary = {}  # índice do toque -> nome da action

@onready var hearts: HBoxContainer = $Hearts
@onready var gem_label: Label = $GemLabel
@onready var time_label: Label = $TimeLabel
@onready var message: Label = $Message
@onready var attack_button: Panel = $AttackButton
@onready var jump_button: Panel = $JumpButton


static func format_time(t: float) -> String:
	return "%d:%05.2f" % [floori(t / 60.0), fmod(t, 60.0)]


func setup(max_health: int, total_gems: int) -> void:
	for c: Node in hearts.get_children():
		c.queue_free()
	for i: int in max_health:
		var h: TextureRect = TextureRect.new()
		h.texture = HEART_TEX
		h.custom_minimum_size = Vector2(22, 22)
		h.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		h.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hearts.add_child(h)
	set_gems(0, total_gems)
	set_time(0.0)


func set_health(current: int, _maximum: int) -> void:
	for i: int in hearts.get_child_count():
		var h: CanvasItem = hearts.get_child(i)
		h.modulate = Color.WHITE if i < current else Color(0.2, 0.2, 0.3, 0.6)


func set_gems(count: int, total: int) -> void:
	gem_label.text = "◆ %d/%d" % [count, total]


func set_time(t: float) -> void:
	time_label.text = format_time(t)


func show_message(text: String) -> void:
	message.text = text
	message.visible = true


func hide_message() -> void:
	message.visible = false


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			var half: float = get_viewport().get_visible_rect().size.x * 0.5
			var action: String = "jump" if touch.position.x >= half else "attack"
			_touches[touch.index] = action
			Input.action_press(action)
		elif _touches.has(touch.index):
			var action: String = _touches[touch.index]
			_touches.erase(touch.index)
			if not _touches.values().has(action):
				Input.action_release(action)


func _process(_delta: float) -> void:
	_set_pressed_look(attack_button, Input.is_action_pressed("attack"))
	_set_pressed_look(jump_button, Input.is_action_pressed("jump"))


func _set_pressed_look(button: Panel, pressed: bool) -> void:
	button.modulate.a = 1.0 if pressed else 0.55
	button.scale = Vector2(0.92, 0.92) if pressed else Vector2.ONE
