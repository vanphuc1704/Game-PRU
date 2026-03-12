extends "res://scripts/enemies/enemy_base.gd"

## Mongol Commander Boss - multi-phase fight with special attacks.

signal boss_defeated

@export var phase_2_hp_threshold: float = 0.5
var phase: int = 1
var charge_speed: float = 300.0
var is_charging: bool = false
var special_cooldown: float = 4.0
var special_timer: float = 0.0

func _ready() -> void:
	super._ready()
	max_hp = 300
	hp = max_hp
	attack_damage = 25
	speed = 90.0
	chase_speed = 140.0
	attack_range = 50.0
	attack_cooldown = 1.2
	detection_range = 400.0
	enemy_color = Color(0.9, 0.1, 0.1)
	_setup_visuals()
	# Boss is larger
	var img = Image.create(40, 40, false, Image.FORMAT_RGBA8)
	img.fill(enemy_color)
	# Crown/helmet
	for x in range(10, 30):
		for y in range(0, 8):
			img.set_pixel(x, y, Color(1, 0.85, 0))
	# Eyes
	for x in range(12, 18):
		for y in range(12, 18):
			img.set_pixel(x, y, Color(1, 1, 0))
	for x in range(22, 28):
		for y in range(12, 18):
			img.set_pixel(x, y, Color(1, 1, 0))
	var tex = ImageTexture.create_from_image(img)
	sprite.texture = tex

func _physics_process(delta: float) -> void:
	if state == EnemyState.DEAD:
		return
	# Phase check
	if phase == 1 and hp <= max_hp * phase_2_hp_threshold:
		phase = 2
		chase_speed = 180.0
		attack_damage = 35
		attack_cooldown = 0.8
		sprite.modulate = Color(1.2, 0.6, 0.6)
	# Special attack timer
	special_timer -= delta
	if special_timer <= 0 and state == EnemyState.CHASE and player_ref and is_instance_valid(player_ref):
		special_timer = special_cooldown
		_do_special_attack()
		return
	super._physics_process(delta)

func _do_special_attack() -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		return
	# Charge attack
	is_charging = true
	var dir = (player_ref.global_position - global_position).normalized()
	sprite.modulate = Color(1, 0.3, 0)
	velocity = dir * charge_speed
	await get_tree().create_timer(0.5).timeout
	# Damage in area
	if player_ref and is_instance_valid(player_ref):
		var dist = global_position.distance_to(player_ref.global_position)
		if dist < 60 and player_ref.has_method("take_damage"):
			player_ref.take_damage(attack_damage + 10, global_position)
	is_charging = false
	velocity = Vector2.ZERO
	if phase == 2:
		sprite.modulate = Color(1.2, 0.6, 0.6)
	else:
		sprite.modulate = Color(1, 1, 1)

func _die() -> void:
	state = EnemyState.DEAD
	velocity = Vector2.ZERO
	boss_defeated.emit()
	sprite.modulate = Color(1, 1, 0)
	# Boss death animation
	for i in range(5):
		sprite.modulate = Color(1, randf(), randf())
		await get_tree().create_timer(0.3).timeout
	sprite.modulate = Color(0.3, 0.3, 0.3, 0.5)
	enemy_died.emit(self)
	await get_tree().create_timer(1.0).timeout
	queue_free()
