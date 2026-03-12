extends CharacterBody2D

## Base enemy with patrol/chase/attack AI state machine.

signal enemy_died(enemy: Node2D)

enum EnemyState { IDLE, PATROL, CHASE, ATTACK, HURT, DEAD }

@export var max_hp: int = 60
@export var attack_damage: int = 10
@export var speed: float = 100.0
@export var chase_speed: float = 150.0
@export var detection_range: float = 200.0
@export var attack_range: float = 35.0
@export var attack_cooldown: float = 1.0
@export var patrol_points: Array[Vector2] = []
@export var enemy_color: Color = Color(0.8, 0.2, 0.2)

var hp: int
var state: EnemyState = EnemyState.IDLE
var player_ref: CharacterBody2D = null
var current_patrol_index: int = 0
var can_attack: bool = true
var spawn_position: Vector2

@onready var sprite: Sprite2D = $Sprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_timer: Timer = $AttackTimer
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp
	spawn_position = global_position
	_setup_visuals()
	_setup_detection()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	attack_timer.timeout.connect(func(): can_attack = true)
	if patrol_points.is_empty():
		patrol_points.assign([spawn_position + Vector2(100, 0), spawn_position + Vector2(-100, 0)])
	# Start patrol
	state = EnemyState.PATROL

func _setup_visuals() -> void:
	var asset_path = "res://assets/mongol_anims.png"
	if FileAccess.file_exists(asset_path):
		var img = Image.load_from_file(asset_path)
		_fix_sprite_transparency(img)
		var tex = ImageTexture.create_from_image(img)
		sprite.texture = tex
		sprite.hframes = 4
		sprite.vframes = 4
		sprite.modulate = Color(1, 1, 1)
		# Dynamic scaling
		var tex_h = tex.get_height()
		var frame_h = tex_h / 4.0
		var target_h = 40.0
		var s = target_h / frame_h
		sprite.scale = Vector2(s, s)
		sprite.scale = Vector2(s, s)
	else:
		sprite.texture = ImageTexture.create_from_image(Image.create(14, 14, false, Image.FORMAT_RGBA8))
		sprite.scale = Vector2(2, 2)

	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.rotation = 0

var _anim_timer: float = 0.0
func _animate_sprite(delta: float) -> void:
	_anim_timer += delta
	if sprite.hframes > 1 and _anim_timer > 0.15:
		_anim_timer = 0.0
		var row = 0
		match state:
			EnemyState.IDLE: row = 0
			EnemyState.CHASE: row = 1
			EnemyState.ATTACK: row = 2
			_: row = 0
		var start_frame = row * sprite.hframes
		sprite.frame = start_frame + (int(sprite.frame + 1) % sprite.hframes)

func _setup_detection() -> void:
	var shape = CircleShape2D.new()
	shape.radius = detection_range
	if detection_area.get_child_count() > 0:
		var col = detection_area.get_child(0) as CollisionShape2D
		if col:
			col.shape = shape

func _physics_process(delta: float) -> void:
	if state == EnemyState.DEAD:
		return

	_find_player()

	match state:
		EnemyState.IDLE:
			velocity = Vector2.ZERO
			_check_for_player()
		EnemyState.PATROL:
			_do_patrol(delta)
			_check_for_player()
		EnemyState.CHASE:
			_do_chase(delta)
		EnemyState.ATTACK:
			_do_attack()
		EnemyState.HURT:
			pass

	_update_sprite_facing()
	_apply_procedural_animations(delta)
	_animate_sprite(delta)
	move_and_slide()

var _anim_time: float = 0.0

func _apply_procedural_animations(delta: float) -> void:
	_anim_time += delta
	# No more procedural scaling breath
	
	# Menacing vibration when attacking
	if state == EnemyState.ATTACK:
		sprite.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1))
	else:
		sprite.offset = Vector2.ZERO

func _find_player() -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0]

func _check_for_player() -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		return
	var dist = global_position.distance_to(player_ref.global_position)
	var det_range = detection_range
	if GameManager.player_stats.is_stealthed:
		det_range *= 0.4
	if dist < det_range:
		state = EnemyState.CHASE

func _do_patrol(_delta: float) -> void:
	if patrol_points.is_empty():
		state = EnemyState.IDLE
		return
	var target = patrol_points[current_patrol_index]
	var dir = (target - global_position).normalized()
	velocity = dir * speed * 0.5
	if global_position.distance_to(target) < 10:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		# Brief pause
		state = EnemyState.IDLE
		await get_tree().create_timer(1.0).timeout
		if state == EnemyState.IDLE:
			state = EnemyState.PATROL

func _do_chase(_delta: float) -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		state = EnemyState.PATROL
		return
	var dist = global_position.distance_to(player_ref.global_position)
	var det_range = detection_range
	if GameManager.player_stats.is_stealthed:
		det_range *= 0.4
	if dist > det_range * 1.5:
		state = EnemyState.PATROL
		return
	if dist < attack_range:
		state = EnemyState.ATTACK
		return
	var dir = (player_ref.global_position - global_position).normalized()
	velocity = dir * chase_speed

func _do_attack() -> void:
	velocity = Vector2.ZERO
	if player_ref == null or not is_instance_valid(player_ref):
		state = EnemyState.PATROL
		return
	var dist = global_position.distance_to(player_ref.global_position)
	if dist > attack_range * 1.5:
		state = EnemyState.CHASE
		return
	if can_attack:
		_perform_attack()

func _perform_attack() -> void:
	can_attack = false
	attack_timer.start(attack_cooldown)
	# Melee hit
	if player_ref and is_instance_valid(player_ref):
		var dist = global_position.distance_to(player_ref.global_position)
		if dist < attack_range * 1.5 and player_ref.has_method("take_damage"):
			player_ref.take_damage(attack_damage, global_position)
	# Attack flash
	sprite.modulate = Color(1, 0.5, 0.5)
	await get_tree().create_timer(0.2).timeout
	sprite.modulate = Color(1, 1, 1)

func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	if state == EnemyState.DEAD:
		return
	hp -= amount
	state = EnemyState.HURT
	# Flash white
	sprite.modulate = Color(10, 10, 10)
	# Knockback
	if from_position != Vector2.ZERO:
		var kb = (global_position - from_position).normalized() * 80
		velocity = kb
	await get_tree().create_timer(0.15).timeout
	sprite.modulate = Color(1, 1, 1)
	if hp <= 0:
		_die()
	else:
		state = EnemyState.CHASE

func _die() -> void:
	state = EnemyState.DEAD
	velocity = Vector2.ZERO
	sprite.modulate = Color(0.3, 0.3, 0.3, 0.6)
	enemy_died.emit(self)
	# Disable collision
	collision_layer = 0
	collision_mask = 0
	await get_tree().create_timer(1.5).timeout
	queue_free()

func _update_sprite_facing() -> void:
	if velocity.x < 0: sprite.flip_h = true
	elif velocity.x > 0: sprite.flip_h = false
	sprite.rotation = 0

func _fix_sprite_transparency(img: Image) -> void:
	img.convert(Image.FORMAT_RGBA8)
	for x in range(img.get_width()):
		for y in range(img.get_height()):
			var c = img.get_pixel(x, y)
			if c.r > 0.95 and c.g > 0.95 and c.b > 0.95:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
