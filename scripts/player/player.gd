extends CharacterBody2D

## Player controller with state machine: movement, combat, stealth, boat, health.

signal health_changed(hp: int, max_hp: int)
signal arrows_changed(count: int)
signal player_died
signal stealth_changed(is_stealthed: bool)

enum State { IDLE, RUN, ATTACK, SHOOT, HURT, DEAD, ROWING, DODGE }

@export var speed: float = 200.0
@export var dodge_speed: float = 400.0
@export var attack_range: float = 40.0
@export var attack_cooldown: float = 0.4
@export var shoot_cooldown: float = 0.6
@export var invincibility_time: float = 0.5

var state: State = State.IDLE
var facing_direction: Vector2 = Vector2.DOWN
var can_attack: bool = true
var can_shoot: bool = true
var is_invincible: bool = false
var dodge_timer: float = 0.0
var dodge_direction: Vector2 = Vector2.ZERO
var in_boat: bool = false
var boat_ref: Node2D = null
var interactable_target: Node2D = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var interaction_area: Area2D = $InteractionArea
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var attack_timer: Timer = $AttackTimer
@onready var shoot_timer: Timer = $ShootTimer
@onready var invincibility_timer: Timer = $InvincibilityTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var camera: Camera2D = $Camera2D

var arrow_scene: PackedScene = preload("res://scenes/player/arrow.tscn")

func _ready() -> void:
	add_to_group("player")
	_setup_visuals()
	_connect_signals()
	interaction_area.collision_mask |= 16  # Layer 5: Interaction
	if interaction_area.get_child_count() > 0:
		var col = interaction_area.get_child(0) as CollisionShape2D
		if col and col.shape is CircleShape2D:
			col.shape.radius = 60.0
	health_changed.emit(GameManager.player_stats.hp, GameManager.player_stats.max_hp)
	arrows_changed.emit(GameManager.player_stats.arrows)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if camera:
		camera.zoom = Vector2(1.2, 1.2)

func _setup_visuals() -> void:
	# Use unarmed version in Level 1
	var anim_asset = "res://assets/soldier_anims.png"
	if GameManager.current_level == 0:
		anim_asset = "res://assets/player_unarmed.png"
		
	if FileAccess.file_exists(anim_asset):
		var img = Image.load_from_file(anim_asset)
		_fix_sprite_transparency(img)
		var tex = ImageTexture.create_from_image(img)
		sprite.texture = tex
		# Dynamic scaling to fit a standard size (around 40 pixels tall)
		var tex_h = tex.get_height()
		var frame_h = tex_h / 4.0
		var target_h = 40.0
		var s = target_h / frame_h
		sprite.scale = Vector2(s, s)
		sprite.hframes = 4
		sprite.vframes = 4
		sprite.region_enabled = false
	else:
		sprite.texture = ImageTexture.create_from_image(Image.create(16, 16, false, Image.FORMAT_RGBA8))
		sprite.scale = Vector2(2, 2)
	
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _connect_signals() -> void:
	attack_timer.timeout.connect(func(): can_attack = true)
	shoot_timer.timeout.connect(func(): can_shoot = true)
	invincibility_timer.timeout.connect(_on_invincibility_end)
	interaction_area.area_entered.connect(_on_interaction_entered)
	interaction_area.area_exited.connect(_on_interaction_exited)

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return

	match state:
		State.DODGE:
			_process_dodge(delta)
		State.HURT:
			pass
		_:
			_process_input(delta)

	# Apply stealth visual
	if GameManager.player_stats.is_stealthed:
		sprite.modulate = Color(1, 1, 1, 0.5)
	else:
		sprite.modulate = Color(1, 1, 1, 1.0)

	_apply_procedural_animations(delta)
	_update_sprite_animation(delta)
	move_and_slide()

var _frame_timer: float = 0.0
func _update_sprite_animation(delta: float) -> void:
	if sprite.hframes <= 1: return
	
	_frame_timer += delta
	var frame_duration = 0.15
	if _frame_timer >= frame_duration:
		_frame_timer = 0.0
		var row = 0
		match state:
			State.IDLE: row = 0
			State.RUN: row = 1
			State.ATTACK: row = 2
			State.DEAD: row = 3
			_: row = 0
		
		var start_frame = row * sprite.hframes
		sprite.frame = start_frame + (int(sprite.frame + 1) % sprite.hframes)

var _anim_time: float = 0.0
func _apply_procedural_animations(delta: float) -> void:
	_anim_time += delta
	# Breathing
	var breath = 1.0 + sin(_anim_time * 2.0) * 0.02
	# Base scale is now dynamic, so we just modulate it
	
	# Walking wiggle
	if velocity.length() > 0.1:
		sprite.rotation += sin(_anim_time * 15.0) * 0.05
	else:
		sprite.rotation = lerp_angle(sprite.rotation, 0, 10 * delta)

func _process_input(_delta: float) -> void:
	var input_dir = Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_up", "move_down")
	
	# Fallback to UI defaults if custom actions not defined
	if input_dir.length() < 0.1:
		input_dir.x = Input.get_axis("ui_left", "ui_right")
		input_dir.y = Input.get_axis("ui_up", "ui_down")

	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
		facing_direction = input_dir
		velocity = input_dir * speed
		state = State.RUN
	else:
		velocity = Vector2.ZERO
		if state == State.RUN:
			state = State.IDLE

	# Character orientation
	if velocity.x < 0: sprite.flip_h = true
	elif velocity.x > 0: sprite.flip_h = false

	# Attack
	if Input.is_action_just_pressed("attack") and can_attack and state != State.SHOOT:
		if GameManager.current_level > 0: # No combat in Level 1
			_do_attack()
		else:
			DialogueManager.start_dialogue([{"speaker": "Người chơi", "text": "Mình chưa có vũ khí, và cũng chưa biết cách chiến đấu... Phải tìm Trần Hưng Đạo!"}])

	# Shoot
	if Input.is_action_just_pressed("shoot") and can_shoot and GameManager.player_stats.arrows > 0:
		if GameManager.current_level > 0: # No combat in Level 1
			_do_shoot()

	# Interact
	if Input.is_action_just_pressed("interact") or Input.is_key_pressed(KEY_E):
		# Prevent double trigger if both action and key are mapped
		if Input.is_action_just_pressed("interact"):
			pass # Already handled by event
		
		# Only act if just pressed (to avoid spamming)
		if Input.is_action_just_pressed("interact") or (Input.is_key_pressed(KEY_E) and not GameManager.player_stats.get("e_held", false)):
			GameManager.player_stats.e_held = true
			if interactable_target:
				_do_interact()
			else:
				_find_and_interact_fallback()
	
	if not Input.is_key_pressed(KEY_E):
		GameManager.player_stats.e_held = false

	# Stealth toggle
	if Input.is_action_just_pressed("stealth"):
		_toggle_stealth()

	# Dodge
	if Input.is_action_just_pressed("dodge") and state != State.DODGE:
		_do_dodge()

func _update_sprite_rotation() -> void:
	# Keep sprite upright but flip horizontally
	if facing_direction.x < 0: sprite.flip_h = true
	elif facing_direction.x > 0: sprite.flip_h = false

func _do_attack() -> void:
	state = State.ATTACK
	can_attack = false
	attack_timer.start(attack_cooldown)

	# Position attack area in facing direction
	attack_area.position = facing_direction * attack_range
	attack_area.monitoring = true

	# Deal damage to enemies in area
	await get_tree().create_timer(0.1).timeout
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(GameManager.player_stats.attack_damage, global_position)
		elif body.is_in_group("destructible") and body.has_method("take_damage"):
			body.take_damage(GameManager.player_stats.attack_damage, global_position)

	await get_tree().create_timer(0.2).timeout
	attack_area.monitoring = false
	if state == State.ATTACK:
		state = State.IDLE

func _do_shoot() -> void:
	state = State.SHOOT
	can_shoot = false
	shoot_timer.start(shoot_cooldown)

	GameManager.player_stats.arrows -= 1
	arrows_changed.emit(GameManager.player_stats.arrows)

	# Spawn arrow
	var arrow = arrow_scene.instantiate()
	arrow.global_position = global_position + facing_direction * 20
	arrow.direction = facing_direction
	arrow.damage = GameManager.player_stats.arrow_damage
	arrow.shooter = self
	get_tree().current_scene.add_child(arrow)

	await get_tree().create_timer(0.3).timeout
	if state == State.SHOOT:
		state = State.IDLE

func _do_interact() -> void:
	if interactable_target and interactable_target.has_method("interact"):
		interactable_target.interact(self)

func _toggle_stealth() -> void:
	GameManager.player_stats.is_stealthed = !GameManager.player_stats.is_stealthed
	stealth_changed.emit(GameManager.player_stats.is_stealthed)
	if GameManager.player_stats.is_stealthed:
		speed = 120.0
	else:
		speed = 200.0

func _do_dodge() -> void:
	state = State.DODGE
	dodge_direction = facing_direction
	dodge_timer = 0.2
	is_invincible = true

func _process_dodge(delta: float) -> void:
	dodge_timer -= delta
	velocity = dodge_direction * dodge_speed
	if dodge_timer <= 0:
		state = State.IDLE
		is_invincible = false

func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	if is_invincible or state == State.DEAD:
		return
	GameManager.damage_player(amount)
	health_changed.emit(GameManager.player_stats.hp, GameManager.player_stats.max_hp)

	if GameManager.player_stats.hp <= 0:
		state = State.DEAD
		player_died.emit()
		sprite.modulate = Color(0.5, 0.1, 0.1)
		velocity = Vector2.ZERO
		return

	state = State.HURT
	is_invincible = true
	invincibility_timer.start(invincibility_time)

	# Knockback
	if from_position != Vector2.ZERO:
		var knockback = (global_position - from_position).normalized() * 150
		velocity = knockback

	# Flash red
	sprite.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.15).timeout
	if not GameManager.player_stats.is_stealthed:
		sprite.modulate = Color(1, 1, 1)
	if state == State.HURT:
		state = State.IDLE

func _on_invincibility_end() -> void:
	is_invincible = false

func _on_interaction_entered(area: Area2D) -> void:
	if area.is_in_group("interactable"):
		interactable_target = area.get_parent()

func _on_interaction_exited(area: Area2D) -> void:
	if area.is_in_group("interactable"):
		if interactable_target == area.get_parent():
			interactable_target = null

func enter_boat(boat: Node2D) -> void:
	in_boat = true
	boat_ref = boat
	GameManager.player_stats.in_boat = true
	visible = false
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	# Move to boat center to ensure no physics jitter
	global_position = boat.global_position

func exit_boat() -> void:
	in_boat = false
	visible = true
	GameManager.player_stats.in_boat = false
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	if boat_ref:
		global_position = boat_ref.global_position + Vector2(0, 40)
		boat_ref = null

func add_arrows(count: int) -> void:
	GameManager.player_stats.arrows += count
	arrows_changed.emit(GameManager.player_stats.arrows)

func _fix_sprite_transparency(img: Image) -> void:
	# Convert white background (approx) to transparent
	# Most local generated pixel art has a #FFFFFF or near-white background
	img.convert(Image.FORMAT_RGBA8)
	for x in range(img.get_width()):
		for y in range(img.get_height()):
			var c = img.get_pixel(x, y)
			# If it's pure white or very close to it (the "checkerboard" fake transparency)
			if c.r > 0.95 and c.g > 0.95 and c.b > 0.95:
				img.set_pixel(x, y, Color(0, 0, 0, 0))

func _find_and_interact_fallback() -> void:
	var interactables = get_tree().get_nodes_in_group("interactable")
	var closest = null
	var min_dist = 100.0 # Interaction radius fallback
	
	for area in interactables:
		var dist = global_position.distance_to(area.global_position)
		if dist < min_dist:
			min_dist = dist
			closest = area.get_parent()
			
	if closest and closest.has_method("interact"):
		closest.interact(self)
