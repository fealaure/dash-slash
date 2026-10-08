class_name Player
extends CharacterBody2D
## Ninja com corrida automática (direita -> esquerda), pulo, agarrar/pular de
## parede, ataque de espada e dano com knockback estilo Castlevania.

signal health_changed(current: int, maximum: int)
signal gems_changed(total: int)
signal started
signal died

const RUN_SPEED = 100.0
const GRAVITY = 1000.0
const MAX_FALL = 420.0
const JUMP_VELOCITY = -360.0
const JUMP_CUT = 0.5
const WALL_JUMP_VELOCITY = Vector2(150.0, -340.0)
const WALL_SLIDE_SPEED = 45.0
const MANTLE_HEIGHT = 14
const COYOTE_TIME = 0.08
const JUMP_BUFFER = 0.12
const ATTACK_DURATION = 0.18
const ATTACK_COOLDOWN = 0.26
const KNOCKBACK = Vector2(150.0, -230.0)
const HURT_STUN = 0.35
const INVINCIBLE_TIME = 1.2
## Câmera mostra mais espaço à esquerda (direção da corrida) e acima (verticalidade)
const CAMERA_OFFSET = Vector2(-70, -40)

@export var max_health: int = 3
## -1 = corre para a esquerda, 1 = direita
@export var main_direction: int = -1

var active: bool = false
var is_dead: bool = false
var health: int = 3
var gems: int = 0
var facing: int = -1
var air_speed: float = RUN_SPEED
var death_y: float = 100000.0

var _wall_dir: int = 0
var _clinging: bool = false
var _attack_dir: int = -1
var _coyote: float = 0.0
var _wall_coyote: float = 0.0
var _jump_buffer: float = 0.0
var _attack_timer: float = 0.0
var _attack_cooldown: float = 0.0
var _stun: float = 0.0
var _invincible: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var slash_fx: Sprite2D = $SlashFX
@onready var hurtbox: Area2D = $Hurtbox
@onready var sword: Area2D = $SwordHitbox
@onready var sword_shape: CollisionShape2D = $SwordHitbox/CollisionShape2D
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	health = max_health
	facing = main_direction
	_attack_dir = facing
	sprite.play("run")
	sprite.pause()


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not active:
		if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("attack"):
			active = true
			sprite.play("run")
			started.emit()
		return

	_tick_timers(delta)

	if Input.is_action_just_pressed("jump"):
		_jump_buffer = JUMP_BUFFER
	if Input.is_action_just_pressed("attack"):
		_try_attack()

	var on_floor: bool = is_on_floor()
	if on_floor:
		_coyote = COYOTE_TIME
		if _stun <= 0.0:
			facing = main_direction
			air_speed = RUN_SPEED

	# Parede à frente enquanto no ar -> pode agarrar / pular de parede
	var touching_wall: bool = false
	if not on_floor and is_on_wall():
		var n: Vector2 = get_wall_normal()
		if n.x != 0.0 and int(signf(n.x)) == -facing:
			touching_wall = true
			_wall_dir = facing
			_wall_coyote = COYOTE_TIME
	# Ajuda de borda: se o topo da parede está logo acima, sobe nela
	if touching_wall and _stun <= 0.0 and _try_mantle():
		touching_wall = false
		_wall_coyote = 0.0
	_clinging = touching_wall and velocity.y >= 0.0 and _stun <= 0.0

	# Gravidade
	velocity.y += GRAVITY * delta
	velocity.y = minf(velocity.y, WALL_SLIDE_SPEED if _clinging else MAX_FALL)

	if _stun > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 250.0 * delta)
	else:
		_handle_jump()
		velocity.x = facing * (RUN_SPEED if is_on_floor() else air_speed)

	move_and_slide()

	_process_attack()
	_check_damage()
	_update_visuals()

	if global_position.y > death_y:
		die()


func _tick_timers(delta: float) -> void:
	_coyote -= delta
	_wall_coyote -= delta
	_jump_buffer -= delta
	_attack_timer -= delta
	_attack_cooldown -= delta
	_stun -= delta
	_invincible -= delta


func _handle_jump() -> void:
	if _jump_buffer > 0.0:
		if _coyote > 0.0:
			velocity.y = JUMP_VELOCITY
			_jump_buffer = 0.0
			_coyote = 0.0
		elif _wall_coyote > 0.0:
			# Pula para longe da parede
			facing = -_wall_dir
			air_speed = WALL_JUMP_VELOCITY.x
			velocity.y = WALL_JUMP_VELOCITY.y
			_jump_buffer = 0.0
			_wall_coyote = 0.0
			_clinging = false
	# Pulo variável: soltar o botão corta a subida
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT


func _try_mantle() -> bool:
	var ahead: Vector2 = Vector2(facing * 3.0, 0.0)
	for h: int in range(2, MANTLE_HEIGHT + 1, 2):
		var lifted: Transform2D = global_transform.translated(Vector2(0.0, -h))
		if not test_move(global_transform, Vector2(0.0, -h)) and not test_move(lifted, ahead):
			global_position.y -= h
			global_position.x += facing * 2.0
			velocity.y = minf(velocity.y, 0.0)
			return true
	return false


func _try_attack() -> void:
	if _attack_cooldown > 0.0 or _stun > 0.0:
		return
	_attack_timer = ATTACK_DURATION
	_attack_cooldown = ATTACK_COOLDOWN
	# Agarrado na parede, o golpe sai para o lado oposto da parede
	_attack_dir = -_wall_dir if _clinging else facing
	sword_shape.position.x = 18.0 * _attack_dir
	slash_fx.position.x = 18.0 * _attack_dir
	slash_fx.flip_h = _attack_dir < 0
	slash_fx.visible = true
	slash_fx.modulate.a = 1.0
	sprite.play("slash")
	sprite.frame = 0


func _process_attack() -> void:
	if _attack_timer <= 0.0:
		slash_fx.visible = false
		return
	slash_fx.modulate.a = clampf(_attack_timer / ATTACK_DURATION, 0.0, 1.0)
	for area: Area2D in sword.get_overlapping_areas():
		var target: Node = area.get_parent()
		if target.has_method("hit") and not target.get("dead"):
			target.call("hit")
			FX.hit_stop(get_tree())
			shake(3.0)


func _check_damage() -> void:
	if _invincible > 0.0:
		return
	for area: Area2D in hurtbox.get_overlapping_areas():
		var src: Node = area.get_parent() if area.get_parent().has_method("hit") else area
		if src.get("dead"):
			continue
		take_damage(area.global_position.x)
		return


func take_damage(source_x: float) -> void:
	if _invincible > 0.0 or is_dead:
		return
	health -= 1
	health_changed.emit(health, max_health)
	shake(5.0)
	if health <= 0:
		die()
		return
	var dir: float = signf(global_position.x - source_x)
	if dir == 0.0:
		dir = -facing
	if _clinging:
		dir = -_wall_dir
	velocity = Vector2(dir * KNOCKBACK.x, KNOCKBACK.y)
	_stun = HURT_STUN
	_invincible = INVINCIBLE_TIME
	_attack_timer = 0.0
	_clinging = false


func add_gem() -> void:
	gems += 1
	gems_changed.emit(gems)


func die() -> void:
	if is_dead:
		return
	is_dead = true
	health = 0
	health_changed.emit(health, max_health)
	slash_fx.visible = false
	sprite.play("jump")
	sprite.modulate = Color(1, 0.3, 0.3)
	FX.burst(get_parent(), global_position + Vector2(0, -12), Color(0.9, 0.15, 0.2), 24)
	var tw: Tween = create_tween()
	tw.tween_property(sprite, "rotation", TAU * 2.0 * -facing, 0.6)
	tw.parallel().tween_property(sprite, "modulate:a", 0.0, 0.6)
	died.emit()


func freeze() -> void:
	active = false
	velocity = Vector2.ZERO
	sprite.play("run")
	sprite.pause()


func shake(strength: float) -> void:
	var tw: Tween = create_tween()
	for i: int in 4:
		var jitter: Vector2 = Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		tw.tween_property(camera, "offset", CAMERA_OFFSET + jitter, 0.03)
	tw.tween_property(camera, "offset", CAMERA_OFFSET, 0.03)


func _update_visuals() -> void:
	# Piscar durante invencibilidade
	if _invincible > 0.0:
		sprite.modulate.a = 0.3 if int(_invincible * 20.0) % 2 == 0 else 1.0
	else:
		sprite.modulate.a = 1.0

	var anim: String
	var dir: int = facing
	if _attack_timer > 0.0:
		anim = "slash"
		dir = _attack_dir
	elif _clinging:
		anim = "cling"
		dir = _wall_dir
	elif not is_on_floor():
		anim = "jump"
	else:
		anim = "run"
	if sprite.animation != anim:
		sprite.play(anim)
	sprite.flip_h = dir < 0
