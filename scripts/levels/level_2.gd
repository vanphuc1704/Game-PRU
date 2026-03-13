extends Node2D

## Level 2 – Soldier Training
## Sword dummies, archery targets, boat rowing checkpoints.

var dummies_destroyed: int = 0
var targets_hit: int = 0
var boat_checkpoints: int = 0
var current_phase: String = "dummies"

func _ready() -> void:
	GameManager.current_state = GameManager.GameState.PLAYING
	MissionManager.clear_all()
	_build_map()
	_spawn_entities()
	_setup_missions()
	_add_ui()

func _build_map() -> void:
	# Ground
	var ground = ColorRect.new()
	ground.color = Color(0.4, 0.6, 0.3)
	ground.size = Vector2(10000, 10000)
	ground.position = Vector2(-4000, -4000)
	ground.z_index = -10
	add_child(ground)

	# Training yard (dirt area)
	_add_rect(Vector2(-200, -300), Vector2(600, 600), Color(0.6, 0.45, 0.25))

	# Archery range (right side)
	_add_rect(Vector2(600, -200), Vector2(500, 300), Color(0.55, 0.42, 0.22))

	# River area (bottom)
	_add_rect(Vector2(-4000, 500), Vector2(10000, 4000), Color(0.15, 0.35, 0.65))
	# Riverbank
	_add_rect(Vector2(-4000, 470), Vector2(10000, 40), Color(0.5, 0.4, 0.2))

	# Labels (signs)
	_add_sign(Vector2(-100, -320), "HUẤN LUYỆN KIẾM THUẬT")
	_add_sign(Vector2(650, -220), "BÃI TẬP BẮN")
	_add_sign(Vector2(100, 440), "BẾN THUYỀN")

	# Fences around training
	for i in range(0, 600, 40):
		_add_fence(Vector2(-200 + i, -310))
		_add_fence(Vector2(-200 + i, 310))

	# Map boundaries
	_add_wall(Vector2(-500, -500), Vector2(4000, 20))
	_add_wall(Vector2(-500, 900), Vector2(4000, 20))
	_add_wall(Vector2(-500, -500), Vector2(20, 1400))
	_add_wall(Vector2(3480, -500), Vector2(20, 1400))

func _spawn_entities() -> void:
	# Player
	var player_scene = preload("res://scenes/player/player.tscn")
	var player = player_scene.instantiate()
	player.position = Vector2(-50, 0)
	add_child(player)

	# Instructor NPC
	var npc_scene = preload("res://scenes/npcs/npc.tscn")
	var instructor = npc_scene.instantiate()
	instructor.position = Vector2(0, -150)
	instructor.npc_name = "Instructor"
	instructor.npc_type = "soldier"
	instructor.name = "Instructor"
	instructor.set_dialogue([
		{"speaker": "Giáo hữu", "text": "Chào mừng ngươi đến võ đường!"},
		{"speaker": "Giáo hữu", "text": "Đầu tiên, hãy phá hủy 3 hình nhân bằng kiếm (Chuột trái)."},
		{"speaker": "Giáo hữu", "text": "Sau đó bắn trúng 3 bia tập bằng cung (Chuột phải)."},
		{"speaker": "Giáo hữu", "text": "Cuối cùng, hãy chèo thuyền qua các mốc kiểm tra trên sông."},
	])
	add_child(instructor)

	# Sword training dummies (3)
	for i in range(3):
		_add_dummy(Vector2(50 + i * 120, -50))

	# Archery targets (3)
	for i in range(3):
		_add_target(Vector2(900, -120 + i * 100))

	# Boat at dock
	var boat_scene = preload("res://scenes/boat/boat.tscn")
	var boat = boat_scene.instantiate()
	boat.position = Vector2(200, 550)
	boat.name = "TrainingBoat"
	add_child(boat)

	# Boat checkpoints (3)
	for i in range(3):
		_add_checkpoint(Vector2(600 + i * 500, 650), i)

func _setup_missions() -> void:
	MissionManager.start_mission("level2", "Rèn Luyện Quân Sĩ", [
		{"text": "Phá hủy hình nhân thế mạng", "required": 3},
		{"text": "Bắn trúng bia tập", "required": 3},
		{"text": "Chèo thuyền qua các mốc", "required": 3},
	])

func _add_ui() -> void:
	var hud = preload("res://scenes/ui/hud.tscn").instantiate()
	add_child(hud)
	var dlg = preload("res://scenes/ui/dialogue_box.tscn").instantiate()
	add_child(dlg)

func _add_dummy(pos: Vector2) -> void:
	var dummy = StaticBody2D.new()
	dummy.position = pos
	dummy.add_to_group("destructible")
	dummy.collision_layer = 2
	var hp = 20
	# Visual
	var spr = Sprite2D.new()
	var img = Image.create(10, 16, false, Image.FORMAT_RGBA8) # Half-size for pixel look
	# Post
	img.fill_rect(Rect2i(4, 8, 2, 8), Color(0.5, 0.3, 0.1))
	# Cross arm
	img.fill_rect(Rect2i(1, 4, 8, 2), Color(0.5, 0.3, 0.1))
	# Head
	img.fill_rect(Rect2i(3, 0, 4, 5), Color(0.7, 0.6, 0.4))
	spr.texture = ImageTexture.create_from_image(img)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.scale = Vector2(2, 2)
	spr.name = "Sprite2D"
	dummy.add_child(spr)
	# Collision
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(20, 32)
	col.shape = shape
	dummy.add_child(col)
	# Damage method
	dummy.set_meta("hp", hp)
	dummy.set_script(preload("res://scripts/levels/destructible.gd"))
	add_child(dummy)
	dummy.tree_exiting.connect(func():
		dummies_destroyed += 1
		if current_phase == "dummies":
			MissionManager.progress_objective("level2")
			if dummies_destroyed >= 3:
				current_phase = "archery"
	)

func _add_target(pos: Vector2) -> void:
	var target = StaticBody2D.new()
	target.position = pos
	target.add_to_group("destructible")
	target.collision_layer = 2
	# Visual
	var spr = Sprite2D.new()
	var img = Image.create(12, 12, false, Image.FORMAT_RGBA8)
	# Target rings (simplified for pixel look)
	img.fill(Color(1, 0, 0))
	img.fill_rect(Rect2i(2, 2, 8, 8), Color(1, 1, 1))
	img.fill_rect(Rect2i(4, 4, 4, 4), Color(1, 0, 0))
	
	spr.texture = ImageTexture.create_from_image(img)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.scale = Vector2(2, 2)
	spr.name = "Sprite2D"
	target.add_child(spr)
	# Collision
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(24, 24)
	col.shape = shape
	target.add_child(col)
	target.set_meta("hp", 15)
	target.set_script(preload("res://scripts/levels/destructible.gd"))
	add_child(target)
	target.tree_exiting.connect(func():
		targets_hit += 1
		if current_phase == "archery":
			MissionManager.progress_objective("level2")
			if targets_hit >= 3:
				current_phase = "boat"
	)

func _add_checkpoint(pos: Vector2, index: int) -> void:
	var cp = Area2D.new()
	cp.position = pos
	cp.collision_layer = 0
	cp.collision_mask = 4 # Boat layer
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 50.0
	col.shape = shape
	cp.add_child(col)

	# Visual marker
	var spr = ColorRect.new()
	spr.color = Color(1, 1, 0, 0.3)
	spr.size = Vector2(80, 80)
	spr.position = Vector2(-40, -40)
	cp.add_child(spr)

	# Flag
	var flag = ColorRect.new()
	flag.color = Color(1, 0.2, 0.2)
	flag.size = Vector2(20, 15)
	flag.position = Vector2(-10, -50)
	cp.add_child(flag)

	var label = Label.new()
	label.text = str(index + 1)
	label.position = Vector2(-5, -50)
	cp.add_child(label)

	add_child(cp)
	var triggered = false
	cp.body_entered.connect(func(body):
		if not triggered and body.is_in_group("boats"):
			triggered = true
			spr.color = Color(0, 1, 0, 0.3)
			boat_checkpoints += 1
			if current_phase == "boat":
				MissionManager.progress_objective("level2")
				if boat_checkpoints >= 3:
					_on_level_complete()
	)

func _on_level_complete() -> void:
	await get_tree().create_timer(1.0).timeout
	DialogueManager.start_dialogue([
		{"speaker": "Giáo hữu", "text": "Xuất sắc! Ngươi đã hoàn thành bài huấn luyện!"},
		{"speaker": "Giáo hữu", "text": "Chủ tướng đang cần ngươi cho một nhiệm vụ do thám. Lên đường ngay!"},
	])
	DialogueManager.dialogue_ended.connect(func():
		await get_tree().create_timer(0.5).timeout
		GameManager.next_level()
	, CONNECT_ONE_SHOT)

func _add_rect(pos: Vector2, size: Vector2, color: Color) -> void:
	var rect = ColorRect.new()
	rect.color = color
	rect.size = size
	rect.position = pos
	# Add subtle pixel noise to ground
	if size.x > 300:
		for i in range(15):
			var dot = ColorRect.new()
			dot.color = color.darkened(0.1)
			dot.size = Vector2(8, 8)
			dot.position = Vector2(randf_range(0, size.x), randf_range(0, size.y))
			rect.add_child(dot)
	rect.z_index = -5
	add_child(rect)

func _add_sign(pos: Vector2, text: String) -> void:
	var label = Label.new()
	label.text = text
	label.position = pos
	label.z_index = 5
	var settings = LabelSettings.new()
	settings.font_size = 16
	settings.font_color = Color(0.9, 0.8, 0.5)
	settings.outline_size = 2
	settings.outline_color = Color(0, 0, 0)
	label.label_settings = settings
	add_child(label)

func _add_fence(pos: Vector2) -> void:
	var fence = ColorRect.new()
	fence.color = Color(0.5, 0.35, 0.15)
	fence.size = Vector2(35, 6)
	fence.position = pos
	fence.z_index = -3
	add_child(fence)

func _add_wall(pos: Vector2, size: Vector2) -> void:
	var wall = StaticBody2D.new()
	wall.position = pos
	wall.collision_layer = 8
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	col.position = size / 2
	wall.add_child(col)
	add_child(wall)
