extends Node2D

## Level 3 – Scout Mission
## Stealth through enemy patrols. Fight small groups. Optional: rescue villagers.

var patrols_passed: int = 0
var enemies_killed: int = 0
var villagers_rescued: int = 0
var camp_cleared: bool = false

func _ready() -> void:
	GameManager.current_state = GameManager.GameState.PLAYING
	MissionManager.clear_all()
	_build_map()
	_spawn_entities()
	_setup_missions()
	_add_ui()

func _build_map() -> void:
	# Forest ground
	var ground = ColorRect.new()
	ground.color = Color(0.2, 0.4, 0.15)
	ground.size = Vector2(5000, 3000)
	ground.position = Vector2(-500, -500)
	ground.z_index = -10
	add_child(ground)

	# Forest path
	_add_rect(Vector2(-100, -30), Vector2(4500, 60), Color(0.45, 0.35, 0.2))

	# Dense forest areas (darker patches)
	for i in range(8):
		var px = randf_range(0, 3500)
		var py = randf_range(-400, 400)
		_add_rect(Vector2(px, py), Vector2(randf_range(100,200), randf_range(100,200)), Color(0.12, 0.3, 0.1, 0.5))

	# Stealth zones (patrol areas with alert triggers)
	_add_patrol_zone(Vector2(500, -200), Vector2(300, 400))
	_add_patrol_zone(Vector2(1200, -200), Vector2(300, 400))

	# Enemy camp
	_add_rect(Vector2(2200, -300), Vector2(500, 600), Color(0.5, 0.35, 0.2))
	_add_camp_structure(Vector2(2300, -200))
	_add_camp_structure(Vector2(2500, -100))
	_add_camp_structure(Vector2(2400, 100))

	# Villager prison area
	_add_rect(Vector2(2800, -100), Vector2(200, 200), Color(0.35, 0.25, 0.15))
	# Cage bars
	for i in range(0, 200, 15):
		_add_rect(Vector2(2800 + i, -100), Vector2(3, 200), Color(0.4, 0.4, 0.4))

	# Trees everywhere
	for i in range(40):
		var tx = randf_range(-300, 3800)
		var ty = randf_range(-450, 450)
		_add_tree(Vector2(tx, ty))

	# Map boundaries
	_add_wall(Vector2(-500, -500), Vector2(5000, 20))
	_add_wall(Vector2(-500, 480), Vector2(5000, 20))
	_add_wall(Vector2(-500, -500), Vector2(20, 1000))
	_add_wall(Vector2(4480, -500), Vector2(20, 1000))

func _spawn_entities() -> void:
	# Player start
	var player_scene = preload("res://scenes/player/player.tscn")
	var player = player_scene.instantiate()
	player.position = Vector2(0, 0)
	add_child(player)

	# Scout ally
	var npc_scene = preload("res://scenes/npcs/npc.tscn")
	var scout = npc_scene.instantiate()
	scout.position = Vector2(-80, 0)
	scout.npc_name = "Scout Leader"
	scout.npc_type = "soldier"
	scout.set_dialogue([
		{"speaker": "Đội trưởng Trinh sát", "text": "Chúng ta phải thám sát phía trước. Nhấn Q để vào chế độ ẩn nấp."},
		{"speaker": "Đội trưởng Trinh sát", "text": "Khi ẩn nấp, địch sẽ khó phát hiện nhưng ngươi sẽ di chuyển chậm hơn."},
		{"speaker": "Đội trưởng Trinh sát", "text": "Hãy lẻn qua các khu vực tuần tra, sau đó dọn sạch doanh trại địch."},
		{"speaker": "Đội trưởng Trinh sát", "text": "Có thể có dân làng bị bắt - hãy cố gắng giải cứu họ!"},
	])
	add_child(scout)

	# Patrol enemies (2 patrol zones with 2 enemies each)
	var enemy_scene = preload("res://scenes/enemies/enemy.tscn")
	# Patrol 1
	for i in range(2):
		var e = enemy_scene.instantiate()
		e.position = Vector2(550 + i * 100, -50 + i * 100)
		e.detection_range = 180.0
		e.patrol_points.assign([
			Vector2(500, -150 + i * 200),
			Vector2(750, -150 + i * 200)
		])
		e.name = "Patrol1_" + str(i)
		add_child(e)
		e.enemy_died.connect(_on_enemy_died)

	# Patrol 2
	for i in range(2):
		var e = enemy_scene.instantiate()
		e.position = Vector2(1250 + i * 80, -80 + i * 160)
		e.detection_range = 180.0
		e.patrol_points.assign([
			Vector2(1200, -100 + i * 200),
			Vector2(1450, -100 + i * 200)
		])
		e.name = "Patrol2_" + str(i)
		add_child(e)
		e.enemy_died.connect(_on_enemy_died)

	# Camp enemies (5 - mix of infantry and archers)
	for i in range(3):
		var e = enemy_scene.instantiate()
		e.position = Vector2(2250 + i * 100, -150 + i * 120)
		e.detection_range = 200.0
		e.max_hp = 60
		e.hp = 60
		e.name = "Camp_infantry_" + str(i)
		e.set_script(preload("res://scripts/enemies/enemy_infantry.gd"))
		add_child(e)
		e.enemy_died.connect(_on_camp_enemy_died)

	for i in range(2):
		var e = enemy_scene.instantiate()
		e.position = Vector2(2350 + i * 150, 50 + i * 80)
		e.detection_range = 220.0
		e.name = "Camp_archer_" + str(i)
		e.set_script(preload("res://scripts/enemies/enemy_archer.gd"))
		add_child(e)
		e.enemy_died.connect(_on_camp_enemy_died)

	# Captured villagers (behind cage)
	for i in range(2):
		var v = npc_scene.instantiate()
		v.position = Vector2(2870, -30 + i * 60)
		v.npc_name = "Prisoner"
		v.npc_type = "villager"
		v.name = "Prisoner_" + str(i)
		v.set_dialogue([
			{"speaker": "Dân làng", "text": "Cảm ơn ơn nghĩa cứu mạng! Quân Nguyên đang âm mưu một cuộc tấn công đường thủy!"},
		])
		v.interacted.connect(_on_villager_rescued)
		add_child(v)

	# Stealth detection zones
	_add_stealth_zone(Vector2(500, -200), Vector2(300, 400), 0)
	_add_stealth_zone(Vector2(1200, -200), Vector2(300, 400), 1)

func _setup_missions() -> void:
	MissionManager.start_mission("level3", "Nhiệm Vụ Do Thám", [
		{"text": "Vượt qua các trạm tuần tra", "required": 2},
		{"text": "Dọn sạch doanh trại địch", "required": 5},
		{"text": "Giải cứu dân làng (không bắt buộc)", "required": 1},
	])

func _add_ui() -> void:
	var hud = preload("res://scenes/ui/hud.tscn").instantiate()
	add_child(hud)
	var dlg = preload("res://scenes/ui/dialogue_box.tscn").instantiate()
	add_child(dlg)

func _add_stealth_zone(pos: Vector2, size: Vector2, zone_index: int) -> void:
	var zone = Area2D.new()
	zone.position = pos + size / 2
	zone.collision_layer = 0
	zone.collision_mask = 1
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	zone.add_child(col)
	add_child(zone)

	var passed = false
	zone.body_exited.connect(func(body):
		if not passed and body.is_in_group("player"):
			passed = true
			patrols_passed += 1
			MissionManager.progress_objective("level3")
	)

func _on_enemy_died(_enemy: Node2D) -> void:
	enemies_killed += 1

var camp_enemies_killed: int = 0
func _on_camp_enemy_died(_enemy: Node2D) -> void:
	camp_enemies_killed += 1
	MissionManager.progress_objective("level3")
	if camp_enemies_killed >= 5:
		camp_cleared = true

func _on_villager_rescued(_npc: Node2D) -> void:
	villagers_rescued += 1
	MissionManager.progress_objective("level3")
	if villagers_rescued >= 1:
		_on_level_complete()

func _on_level_complete() -> void:
	await get_tree().create_timer(1.0).timeout
	DialogueManager.start_dialogue([
		{"speaker": "Đội trưởng Trinh sát", "text": "Đã thu thập đủ thông tin! Hạm đội quân Nguyên sắp tiến vào sông Bạch Đằng!"},
		{"speaker": "Đội trưởng Trinh sát", "text": "Chúng ta phải chuẩn bị bãi cọc gỗ. Đi thôi!"},
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
			dot.size = Vector2(10, 10)
			dot.position = Vector2(randf_range(0, size.x), randf_range(0, size.y))
			rect.add_child(dot)
	rect.z_index = -5
	add_child(rect)

func _add_tree(pos: Vector2) -> void:
	var tree_node = StaticBody2D.new()
	tree_node.position = pos
	tree_node.collision_layer = 8
	var trunk = ColorRect.new()
	trunk.color = Color(0.35, 0.2, 0.08)
	trunk.size = Vector2(8, 16)
	trunk.position = Vector2(-4, -8)
	tree_node.add_child(trunk)
	var canopy = ColorRect.new()
	canopy.color = Color(0.1 + randf() * 0.1, 0.35 + randf() * 0.2, 0.1)
	canopy.size = Vector2(30, 30)
	canopy.position = Vector2(-15, -32)
	canopy.z_index = 2
	tree_node.add_child(canopy)
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 8.0
	col.shape = shape
	tree_node.add_child(col)
	add_child(tree_node)

func _add_patrol_zone(pos: Vector2, size: Vector2) -> void:
	var zone_vis = ColorRect.new()
	zone_vis.color = Color(1, 0.3, 0.3, 0.08)
	zone_vis.size = size
	zone_vis.position = pos
	zone_vis.z_index = -4
	add_child(zone_vis)

func _add_camp_structure(pos: Vector2) -> void:
	# Tent base
	var tent = ColorRect.new()
	tent.color = Color(0.4, 0.3, 0.2)
	tent.size = Vector2(60, 50)
	tent.position = pos
	tent.z_index = -3
	add_child(tent)
	
	# Tent flaps
	var flaps = ColorRect.new()
	flaps.color = Color(0.3, 0.2, 0.1)
	flaps.size = Vector2(10, 30)
	flaps.position = pos + Vector2(25, 20)
	add_child(flaps)

	# Tent roof
	var top = ColorRect.new()
	top.color = Color(0.5, 0.4, 0.3)
	top.size = Vector2(70, 15)
	top.position = pos + Vector2(-5, -10)
	top.z_index = -2
	add_child(top)
	
	# Tent poles
	for i in range(2):
		var pole = ColorRect.new()
		pole.color = Color(0.2, 0.1, 0.0)
		pole.size = Vector2(4, 50)
		pole.position = pos + Vector2(i * 56, -5)
		pole.z_index = -4
		add_child(pole)

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
