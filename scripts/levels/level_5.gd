extends Node2D

## Level 5 – Battle of Bach Dang
## Boat combat, lure enemies into stakes, final boss fight.

var current_wave: int = 0
var wave_enemies_alive: int = 0
var enemies_lured: int = 0
var boss_spawned: bool = false
var boss_defeated: bool = false
var stake_zone_rect: Rect2

func _ready() -> void:
	GameManager.current_state = GameManager.GameState.PLAYING
	MissionManager.clear_all()
	_build_map()
	_spawn_entities()
	_setup_missions()
	_add_ui()
	# Auto-enter boat
	await get_tree().create_timer(1.0).timeout
	_start_battle()

func _build_map() -> void:
	# Full river map
	var water = ColorRect.new()
	water.color = Color(0.1, 0.25, 0.55)
	water.size = Vector2(6000, 3000)
	water.position = Vector2(-500, -1000)
	water.z_index = -10
	add_child(water)

	# Riverbanks (top and bottom)
	_add_rect(Vector2(-500, -1000), Vector2(6000, 200), Color(0.4, 0.5, 0.2))
	_add_rect(Vector2(-500, 800), Vector2(6000, 200), Color(0.4, 0.5, 0.2))

	# Wooden stakes zone (trap area in center)
	stake_zone_rect = Rect2(1500, 100, 800, 400)
	_add_rect(Vector2(1500, 100), Vector2(800, 400), Color(0.15, 0.3, 0.5, 0.6))
	# Stakes visual
	for i in range(12):
		var sx = 1550 + (i % 4) * 200
		var sy = 150 + (i / 4) * 120
		_add_stake(Vector2(sx, sy))

	# Stake zone label
	_add_sign(Vector2(1700, 60), "⚠ KHU VỰC BÃI CỌC NGẦM ⚠")

	# Left bank trees
	for i in range(10):
		_add_rect(Vector2(-400 + i * 80, -950), Vector2(30, 30), Color(0.15, 0.45, 0.15))
	for i in range(10):
		_add_rect(Vector2(-400 + i * 80, 830), Vector2(30, 30), Color(0.15, 0.45, 0.15))

	# Map boundaries
	_add_wall(Vector2(-500, -1000), Vector2(6000, 20))
	_add_wall(Vector2(-500, 980), Vector2(6000, 20))
	_add_wall(Vector2(-500, -1000), Vector2(20, 2000))
	_add_wall(Vector2(5480, -1000), Vector2(20, 2000))

func _spawn_entities() -> void:
	# Player
	var player_scene = preload("res://scenes/player/player.tscn")
	var player = player_scene.instantiate()
	player.position = Vector2(200, 300)
	add_child(player)

	# Player's boat
	var boat_scene = preload("res://scenes/boat/boat.tscn")
	var boat = boat_scene.instantiate()
	boat.position = Vector2(200, 300)
	boat.name = "PlayerBoat"
	add_child(boat)

	# Allied boats (decorative)
	for i in range(3):
		var ally_boat = ColorRect.new()
		ally_boat.color = Color(0.5, 0.35, 0.15)
		ally_boat.size = Vector2(40, 18)
		ally_boat.position = Vector2(100 + i * 150, 200 + i * 100)
		ally_boat.z_index = 1
		add_child(ally_boat)

	# General on shore
	var npc_scene = preload("res://scenes/npcs/npc.tscn")
	var general = npc_scene.instantiate()
	general.position = Vector2(100, -750)
	general.npc_name = "General Tran"
	general.npc_type = "general"
	general.set_dialogue([
		{"speaker": "Hưng Đạo Đại Vương", "text": "Đây là trận chiến quyết định! Hãy lên thuyền và đối mặt với hạm đội quân Nguyên!"},
		{"speaker": "Hưng Đạo Đại Vương", "text": "Hãy dụ tàu địch vào khu vực bãi cọc - thủy triều xuống sẽ giữ chân chúng!"},
		{"speaker": "Hưng Đạo Đại Vương", "text": "Vì đại nghĩa! Sát Thát!"},
	])
	add_child(general)

func _setup_missions() -> void:
	MissionManager.start_mission("level5", "Trận Đại Chiến Bạch Đằng", [
		{"text": "Lên thuyền chiến", "required": 1},
		{"text": "Chống trả các đợt tấn công", "required": 4},
		{"text": "Dụ địch vào bãi cọc ngầm", "required": 3},
		{"text": "Tiêu diệt Ô Mã Nhi", "required": 1},
	])

func _add_ui() -> void:
	var hud = preload("res://scenes/ui/hud.tscn").instantiate()
	add_child(hud)
	var dlg = preload("res://scenes/ui/dialogue_box.tscn").instantiate()
	add_child(dlg)

func _start_battle() -> void:
	# Auto-board boat
	var players = get_tree().get_nodes_in_group("player")
	var boats = get_tree().get_nodes_in_group("boats")
	if players.size() > 0 and boats.size() > 0:
		boats[0].interact(players[0])
		MissionManager.progress_objective("level5")
	await get_tree().create_timer(2.0).timeout
	_spawn_wave(1)

func _spawn_wave(wave: int) -> void:
	current_wave = wave
	var enemy_count = 2 + wave
	wave_enemies_alive = enemy_count

	var enemy_scene = preload("res://scenes/enemies/enemy.tscn")
	for i in range(enemy_count):
		var e = enemy_scene.instantiate()
		e.position = Vector2(4500, -400 + i * 200)
		e.speed = 70.0
		e.chase_speed = 100.0
		e.detection_range = 500.0
		e.attack_range = 180.0
		e.max_hp = 50
		e.hp = 50
		e.name = "Wave%d_Enemy_%d" % [wave, i]
		e.set_script(preload("res://scripts/enemies/enemy_boat.gd"))
		add_child(e)
		e.enemy_died.connect(_on_wave_enemy_died)

func _on_wave_enemy_died(enemy: Node2D) -> void:
	wave_enemies_alive -= 1
	# Check if enemy died in stake zone
	if stake_zone_rect.has_point(enemy.global_position):
		enemies_lured += 1
		if enemies_lured <= 3:
			MissionManager.progress_objective("level5")

	MissionManager.progress_objective("level5")

	if wave_enemies_alive <= 0:
		if current_wave < 2:
			await get_tree().create_timer(2.0).timeout
			_spawn_wave(current_wave + 1)
		elif not boss_spawned:
			_spawn_boss()

func _spawn_boss() -> void:
	boss_spawned = true
	DialogueManager.start_dialogue([
		{"speaker": "Trinh sát", "text": "Chiến thuyền của Ô Mã Nhi đang tiến đến!"},
		{"speaker": "Hưng Đạo Đại Vương", "text": "Thời cơ đã đến! Hãy tiêu diệt chủ tướng giặc, chiến thắng sẽ thuộc về ta!"},
	])
	await DialogueManager.dialogue_ended
	
	var boss_scene = preload("res://scenes/enemies/boss.tscn")
	var boss = boss_scene.instantiate()
	boss.position = Vector2(4800, 300)
	boss.name = "FinalBoss"
	boss.max_hp = 300
	boss.hp = 300
	boss.speed = 60.0
	boss.chase_speed = 100.0
	boss.detection_range = 600.0
	add_child(boss)
	boss.boss_defeated.connect(_on_boss_defeated)
	# Boss boat visual
	var boat_vis = ColorRect.new()
	boat_vis.color = Color(0.4, 0.15, 0.1)
	boat_vis.size = Vector2(60, 30)
	boat_vis.position = Vector2(-30, -15)
	boat_vis.z_index = -1
	boss.add_child(boat_vis)

func _on_boss_defeated() -> void:
	boss_defeated = true
	MissionManager.progress_objective("level5")
	await get_tree().create_timer(1.5).timeout
	DialogueManager.start_dialogue([
		{"speaker": "Hưng Đạo Đại Vương", "text": "THẮNG RỒI! Hạm đội quân Nguyên đã bị tiêu diệt hoàn toàn!"},
		{"speaker": "Hưng Đạo Đại Vương", "text": "Bãi cọc ngầm đã nghiền nát chiến thuyền của chúng!"},
		{"speaker": "Hưng Đạo Đại Vương", "text": "Giang sơn ta từ nay sạch bóng quân thù! Đại Việt muôn năm!"},
		{"speaker": "Hưng Đạo Đại Vương", "text": "Ngươi đã chiến đấu rất dũng cảm. Đất nước sẽ mãi ghi nhớ công lao này."},
	])
	DialogueManager.dialogue_ended.connect(func():
		await get_tree().create_timer(1.0).timeout
		GameManager.next_level()  # Goes to victory screen
	, CONNECT_ONE_SHOT)

func _add_rect(pos: Vector2, size: Vector2, color: Color) -> void:
	var rect = ColorRect.new()
	rect.color = color
	rect.size = size
	rect.position = pos
	# Add subtle pixel noise to water/ground
	if size.x > 300:
		for i in range(20):
			var dot = ColorRect.new()
			dot.color = color.darkened(0.1)
			dot.size = Vector2(10, 10)
			dot.position = Vector2(randf_range(0, size.x), randf_range(0, size.y))
			rect.add_child(dot)
	rect.z_index = -5
	add_child(rect)

func _add_stake(pos: Vector2) -> void:
	var stake = ColorRect.new()
	stake.color = Color(0.55, 0.35, 0.15)
	stake.size = Vector2(6, 25)
	stake.position = pos
	stake.z_index = 1
	add_child(stake)
	# Create damage zone
	var area = Area2D.new()
	area.position = pos + Vector2(3, 12)
	area.collision_layer = 8
	area.collision_mask = 2
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 20.0
	col.shape = shape
	area.add_child(col)
	add_child(area)
	# Damage enemies that touch stakes
	area.body_entered.connect(func(body):
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(30, area.global_position)
	)

func _add_sign(pos: Vector2, text: String) -> void:
	var label = Label.new()
	label.text = text
	label.position = pos
	label.z_index = 5
	var settings = LabelSettings.new()
	settings.font_size = 18
	settings.font_color = Color(1, 0.9, 0.3)
	settings.outline_size = 3
	settings.outline_color = Color(0, 0, 0)
	label.label_settings = settings
	add_child(label)

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
