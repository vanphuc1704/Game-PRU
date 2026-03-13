extends Node2D

## Level 4 – Prepare the Trap
## Transport logs, place underwater stakes, defeat mini-boss outpost.

var logs_transported: int = 0
var stakes_placed: int = 0
var outpost_cleared: bool = false
var carrying_log: bool = false

func _ready() -> void:
	GameManager.current_state = GameManager.GameState.PLAYING
	MissionManager.clear_all()
	_build_map()
	_spawn_entities()
	_setup_missions()
	_add_ui()

func _build_map() -> void:
	# Ground - riverbank area
	var ground = ColorRect.new()
	ground.color = Color(0.35, 0.5, 0.2)
	ground.size = Vector2(10000, 10000)
	ground.position = Vector2(-4000, -4000)
	ground.z_index = -10
	add_child(ground)

	# River (wide horizontal band)
	_add_rect(Vector2(-4000, 200), Vector2(12000, 5000), Color(0.12, 0.3, 0.6))
	# Riverbank edge
	_add_rect(Vector2(-4000, 170), Vector2(12000, 40), Color(0.5, 0.4, 0.2))

	# Log storage area (left)
	_add_rect(Vector2(0, -200), Vector2(300, 200), Color(0.5, 0.35, 0.15))
	_add_sign(Vector2(50, -230), "KHO CỌC GỖ")

	# Stake placement zone markers in river
	for i in range(4):
		_add_stake_zone(Vector2(800 + i * 300, 350), i)

	# Outpost (right side)
	_add_rect(Vector2(2800, -300), Vector2(400, 400), Color(0.5, 0.35, 0.2))
	_add_camp_structure(Vector2(2850, -250))
	_add_camp_structure(Vector2(3050, -200))
	_add_camp_structure(Vector2(2950, -50))

	# Trees and vegetation
	for i in range(25):
		var tx = randf_range(-300, 3500)
		var ty = randf_range(-800, 150)
		_add_tree(Vector2(tx, ty))

	# Map boundaries
	_add_wall(Vector2(-500, -1000), Vector2(5000, 20))
	_add_wall(Vector2(-500, 700), Vector2(5000, 20))
	_add_wall(Vector2(-500, -1000), Vector2(20, 1800))
	_add_wall(Vector2(4480, -1000), Vector2(20, 1800))

func _spawn_entities() -> void:
	# Player
	var player_scene = preload("res://scenes/player/player.tscn")
	var player = player_scene.instantiate()
	player.position = Vector2(100, -50)
	add_child(player)

	# Engineer NPC
	var npc_scene = preload("res://scenes/npcs/npc.tscn")
	var engineer = npc_scene.instantiate()
	engineer.position = Vector2(200, -100)
	engineer.npc_name = "Engineer"
	engineer.npc_type = "soldier"
	engineer.set_dialogue([
		{"speaker": "Quân sư", "text": "Dũng sĩ! Chúng ta cần phải chuẩn bị bãi cọc ngầm!"},
		{"speaker": "Quân sư", "text": "Hãy nhặt các cọc gỗ (phím E) từ kho và mang chúng xuống sông."},
		{"speaker": "Quân sư", "text": "Cắm chúng xuống các vị trí đã đánh dấu dưới lòng sông."},
		{"speaker": "Quân sư", "text": "Sau đó, chúng ta phải dọn dẹp đồn lũy quân Nguyên gần đó."},
	])
	add_child(engineer)

	# Logs to pick up (4 logs)
	for i in range(4):
		_add_log(Vector2(50 + i * 60, -100))

	# Outpost enemies (4 infantry + mini boss)
	var enemy_scene = preload("res://scenes/enemies/enemy.tscn")
	for i in range(4):
		var e = enemy_scene.instantiate()
		e.position = Vector2(2880 + (i % 2) * 120, -200 + i * 80)
		e.detection_range = 200.0
		e.max_hp = 70
		e.hp = 70
		e.name = "Outpost_" + str(i)
		add_child(e)
		e.enemy_died.connect(_on_outpost_enemy_died)

	# Mini-boss
	var boss_scene = preload("res://scenes/enemies/boss.tscn")
	var mini_boss = boss_scene.instantiate()
	mini_boss.position = Vector2(3000, -100)
	mini_boss.max_hp = 150
	mini_boss.hp = 150
	mini_boss.attack_damage = 20
	mini_boss.name = "MiniBoss"
	add_child(mini_boss)
	mini_boss.enemy_died.connect(_on_outpost_enemy_died)

var outpost_kills: int = 0
func _setup_missions() -> void:
	MissionManager.start_mission("level4", "Chuẩn Bị Trận Địa", [
		{"text": "Vận chuyển cọc gỗ ra sông", "required": 4},
		{"text": "Cắm cọc xuống lòng sông", "required": 4},
		{"text": "Dọn dẹp tiền đồn quân Nguyên", "required": 5},
	])

func _add_ui() -> void:
	var hud = preload("res://scenes/ui/hud.tscn").instantiate()
	add_child(hud)
	var dlg = preload("res://scenes/ui/dialogue_box.tscn").instantiate()
	add_child(dlg)

func _add_log(pos: Vector2) -> void:
	var log_node = Area2D.new()
	log_node.position = pos
	log_node.collision_layer = 16
	log_node.collision_mask = 0
	log_node.add_to_group("interactable")
	log_node.set_script(preload("res://scripts/levels/pickup_item.gd"))
	# Visual
	var spr = ColorRect.new()
	spr.color = Color(0.5, 0.3, 0.1)
	spr.size = Vector2(40, 12)
	spr.position = Vector2(-20, -6)
	log_node.add_child(spr)
	# Ring detail
	var ring = ColorRect.new()
	ring.color = Color(0.4, 0.25, 0.08)
	ring.size = Vector2(10, 12)
	ring.position = Vector2(-5, -6)
	log_node.add_child(ring)
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(40, 12)
	col.shape = shape
	log_node.add_child(col)

	add_child(log_node)
	log_node.picked_up.connect(func(): _pick_up_log())

func _pick_up_log() -> void:
	if carrying_log:
		return
	carrying_log = true
	logs_transported += 1
	MissionManager.progress_objective("level4")
	# Show carry indicator
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var indicator = ColorRect.new()
		indicator.color = Color(0.5, 0.3, 0.1)
		indicator.size = Vector2(30, 8)
		indicator.position = Vector2(-15, -25)
		indicator.name = "CarryIndicator"
		players[0].add_child(indicator)

func _add_stake_zone(pos: Vector2, index: int) -> void:
	var zone = Area2D.new()
	zone.position = pos
	zone.collision_layer = 0
	zone.collision_mask = 1

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 40.0
	col.shape = shape
	zone.add_child(col)

	# Visual marker
	var marker = ColorRect.new()
	marker.color = Color(1, 1, 0, 0.25)
	marker.size = Vector2(60, 60)
	marker.position = Vector2(-30, -30)
	zone.add_child(marker)
	marker.name = "Marker"

	var label = Label.new()
	label.text = "Cắm Cọc [E]"
	label.position = Vector2(-35, -50)
	var settings = LabelSettings.new()
	settings.font_size = 10
	settings.font_color = Color(1, 1, 0)
	label.label_settings = settings
	zone.add_child(label)

	add_child(zone)
	var placed = false
	zone.body_entered.connect(func(body):
		if body.is_in_group("player") and not placed:
			# Wait for interact input
			_register_stake_zone(zone, marker, index)
	)

var active_stake_zone: Area2D = null
func _register_stake_zone(zone: Area2D, marker: Node, index: int) -> void:
	active_stake_zone = zone
	zone.set_meta("marker", marker)
	zone.set_meta("placed", false)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and carrying_log and active_stake_zone and not active_stake_zone.get_meta("placed", false):
		_place_stake()

func _place_stake() -> void:
	carrying_log = false
	active_stake_zone.set_meta("placed", true)
	stakes_placed += 1
	# Remove carry indicator
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0].has_node("CarryIndicator"):
		players[0].get_node("CarryIndicator").queue_free()
	# Show stake placed
	var marker = active_stake_zone.get_meta("marker")
	if marker:
		marker.color = Color(0, 1, 0, 0.4)
	# Add stake visual
	var stake = ColorRect.new()
	stake.color = Color(0.5, 0.35, 0.15)
	stake.size = Vector2(6, 30)
	stake.position = active_stake_zone.position + Vector2(-3, -15)
	stake.z_index = 1
	add_child(stake)

	MissionManager.progress_objective("level4")
	active_stake_zone = null

func _on_outpost_enemy_died(_enemy: Node2D) -> void:
	outpost_kills += 1
	MissionManager.progress_objective("level4")
	if outpost_kills >= 5:
		outpost_cleared = true
		_on_level_complete()

func _on_level_complete() -> void:
	await get_tree().create_timer(1.0).timeout
	DialogueManager.start_dialogue([
		{"speaker": "Quân sư", "text": "Bãi cọc đã sẵn sàng! Trận địa đã hoàn tất!"},
		{"speaker": "Quân sư", "text": "Bây giờ chúng ta sẽ chờ hạm đội quân Nguyên tại sông Bạch Đằng!"},
		{"speaker": "Hưng Đạo Đại Vương", "text": "Thời khắc đã tới, hỡi các chiến sĩ. Vận mệnh giang sơn nằm trong tay các ngươi!"},
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
	canopy.color = Color(0.15, 0.45, 0.15)
	canopy.size = Vector2(28, 28)
	canopy.position = Vector2(-14, -30)
	canopy.z_index = 2
	tree_node.add_child(canopy)
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 8.0
	col.shape = shape
	tree_node.add_child(col)
	add_child(tree_node)

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
