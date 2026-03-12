extends Node2D

## Level 1 – Call to Arms (Tutorial)
## Village under attack. Meet the General. Learn combat basics.

var talked_to_general: bool = false
var witnessing_complete: bool = false

func _ready() -> void:
	GameManager.current_state = GameManager.GameState.CUTSCENE
	MissionManager.clear_all()
	_build_map()
	_spawn_entities()
	_setup_missions()
	_add_ui()
	_start_intro_cinematic()

func _build_map() -> void:
	# Ground layer - village
	var ground = ColorRect.new()
	ground.color = Color(0.35, 0.55, 0.25)  # Green grass
	ground.size = Vector2(4000, 3000)
	ground.position = Vector2(-1000, -1000)
	ground.z_index = -10
	add_child(ground)

	# Village paths (dirt)
	_add_rect(Vector2(-200, -50), Vector2(1800, 120), Color(0.55, 0.4, 0.25))  # Main path
	_add_rect(Vector2(450, -400), Vector2(100, 800), Color(0.55, 0.4, 0.25))  # Cross path
	_add_rect(Vector2(1100, -200), Vector2(100, 600), Color(0.55, 0.4, 0.25)) # Burning area path

	# Safe Houses
	_add_house(Vector2(100, -200))
	_add_house(Vector2(400, -300))
	_add_house(Vector2(700, -250))
	_add_house(Vector2(100, 200))
	_add_house(Vector2(500, 150))
	
	# Transitioning to destruction
	_add_house(Vector2(950, 250))

	# Burning Houses
	_add_house(Vector2(1200, -150), true)
	_add_house(Vector2(1450, 50), true)
	_add_house(Vector2(1300, 300), true)

	# Trees
	for i in range(80):
		var tx = randf_range(-800, 2600)
		var ty = randf_range(-800, 1300)
		# Avoid paths and main house areas
		if (abs(tx - 600) > 350 or abs(ty - 50) > 350) and (abs(tx - 1300) > 300 or abs(ty) > 300):
			_add_tree(Vector2(tx, ty))

	# Map boundaries
	_add_wall(Vector2(-1000, -1000), Vector2(4000, 20))  # Top
	_add_wall(Vector2(-1000, 1500), Vector2(4000, 20))   # Bottom
	_add_wall(Vector2(-1000, -1000), Vector2(20, 2500))   # Left
	_add_wall(Vector2(2800, -1000), Vector2(20, 2500))   # Right

func _spawn_entities() -> void:
	# Player
	var player_scene = preload("res://scenes/player/player.tscn")
	var player = player_scene.instantiate()
	player.position = Vector2(-200, 50)
	add_child(player)

	# General NPC
	var npc_scene = preload("res://scenes/npcs/npc.tscn")
	var general = npc_scene.instantiate()
	general.position = Vector2(400, -20)
	general.npc_name = "General Tran"
	general.npc_type = "general"
	general.name = "General"
	add_child(general)
	general.set_dialogue([
		{"speaker": "Hưng Đạo Đại Vương", "text": "Kìa thám dũng trẻ! Ngươi đã thấy cảnh tượng kinh hoàng này chưa?"},
		{"speaker": "Hưng Đạo Đại Vương", "text": "Giặc Nguyên hung bạo đang giày xéo xóm làng ta. Chúng đốt phá, cướp bóc không ghê tay."},
		{"speaker": "Hưng Đạo Đại Vương", "text": "Ta đang triệu tập binh sĩ tại trại huấn luyện phía Đông."},
		{"speaker": "Hưng Đạo Đại Vương", "text": "Ngươi có sẵn sàng cầm vũ khí để bảo vệ giang sơn này không?"},
		{"speaker": "Người chơi", "text": "Thưa Đại Vương, tôi sẵn sàng! Nhưng tôi chưa bao giờ cầm kiếm..."},
		{"speaker": "Hưng Đạo Đại Vương", "text": "Đừng lo, lòng yêu nước sẽ dẫn lối. Hãy đi theo ta về doanh trại để bắt đầu huấn luyện!"},
	])
	general.interacted.connect(_on_general_interacted)

	# Villagers
	for i in range(3):
		var villager = npc_scene.instantiate()
		villager.position = Vector2(150 + i * 200, 150)
		villager.npc_name = "Villager"
		villager.npc_type = "villager"
		villager.set_dialogue([
			{"speaker": "Dân làng", "text": "Làm ơn cứu chúng tôi với! Giặc Nguyên đang đến!"},
		])
		add_child(villager)

	# Mongols (Atmosphere, in burning area)
	var enemy_scene = preload("res://scenes/enemies/enemy.tscn")
	var enemy_pos = [Vector2(1250, 0), Vector2(1400, 150), Vector2(1150, 200), Vector2(1300, -50)]
	for pos in enemy_pos:
		var enemy = enemy_scene.instantiate()
		enemy.position = pos
		enemy.detection_range = 0.0 # Ignore player
		enemy.max_hp = 999
		add_child(enemy)

func _setup_missions() -> void:
	MissionManager.start_mission("level1", "Họa Xâm Lăng", [
		{"text": "Chứng kiến cảnh làng xóm bị tàn phá", "required": 1},
		{"text": "Báo danh với Hưng Đạo Vương", "required": 1},
	])

func _add_ui() -> void:
	var hud = preload("res://scenes/ui/hud.tscn").instantiate()
	add_child(hud)
	var dlg = preload("res://scenes/ui/dialogue_box.tscn").instantiate()
	add_child(dlg)

func _start_intro_cinematic() -> void:
	var cam = Camera2D.new()
	cam.position = Vector2(1300, 50) # Look at burning area
	cam.zoom = Vector2(0.8, 0.8) # Reveal the wider destruction
	add_child(cam)
	cam.make_current()

	await get_tree().create_timer(1.5).timeout
	
	DialogueManager.start_dialogue([
		{"speaker": "Người chơi", "text": "Trời ơi! Làng của tôi đang bị giặc càn quét..."},
		{"speaker": "Người chơi", "text": "Bọn chúng quá đông và tàn ác, mình phải chạy thoát và tìm Tướng quân báo tin!"}
	])
	
	DialogueManager.dialogue_ended.connect(func():
		cam.queue_free()
		GameManager.current_state = GameManager.GameState.PLAYING
		MissionManager.progress_objective("level1")
	, CONNECT_ONE_SHOT)

func _on_general_interacted(_npc: Node2D) -> void:
	if not talked_to_general:
		talked_to_general = true
		MissionManager.progress_objective("level1")
		witnessing_complete = true
		DialogueManager.dialogue_ended.connect(_on_level_complete, CONNECT_ONE_SHOT)

func _on_enemy_died(_enemy: Node2D) -> void:
	pass

func _on_level_complete() -> void:
	await get_tree().create_timer(1.0).timeout
	GameManager.next_level()

# Helper functions for building the map
func _add_rect(pos: Vector2, size: Vector2, color: Color) -> void:
	var rect = ColorRect.new()
	rect.position = pos
	rect.size = size
	rect.color = color
	# Add subtle pixel noise to ground
	if size.x > 500:
		for i in range(10):
			var dot = ColorRect.new()
			dot.color = color.darkened(0.1)
			dot.size = Vector2(10, 10)
			dot.position = Vector2(randf_range(0, size.x), randf_range(0, size.y))
			rect.add_child(dot)
	rect.z_index = -5
	add_child(rect)

var _house_texture: Texture2D = null

func _get_house_texture() -> Texture2D:
	if _house_texture: return _house_texture
	var path = "res://assets/house_large.png"
	if FileAccess.file_exists(path):
		var img = Image.load_from_file(path)
		img.convert(Image.FORMAT_RGBA8)
		for x in range(img.get_width()):
			for y in range(img.get_height()):
				var c = img.get_pixel(x, y)
				if c.r > 0.95 and c.g > 0.95 and c.b > 0.95:
					img.set_pixel(x, y, Color(0, 0, 0, 0))
		_house_texture = ImageTexture.create_from_image(img)
	return _house_texture

func _add_house(pos: Vector2, is_burning: bool = false) -> void:
	var house = StaticBody2D.new()
	house.position = pos
	house.collision_layer = 8
	
	var spr = Sprite2D.new()
	var tex = _get_house_texture()
	if tex:
		spr.texture = tex
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		# Scale if asset is 128x128 but we want it quite large
		spr.scale = Vector2(2, 2)
		if is_burning:
			spr.modulate = Color(1.0, 0.5, 0.4) # Fiery tint
	else:
		# Fallback box if asset missing
		var rect = ColorRect.new()
		rect.color = Color(0.6, 0.35, 0.15) if not is_burning else Color(1.0, 0.4, 0.2)
		rect.size = Vector2(120, 100)
		rect.position = Vector2(-60, -50)
		house.add_child(rect)

	house.add_child(spr)

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(180, 140)
	col.shape = shape
	col.position = Vector2(0, 20)
	house.add_child(col)
	
	add_child(house)
	
	if is_burning:
		_add_fire(pos + Vector2(0, -60))
		_add_fire(pos + Vector2(-50, 20))
		_add_fire(pos + Vector2(60, 40))

func _add_tree(pos: Vector2) -> void:
	var tree = StaticBody2D.new()
	tree.position = pos
	tree.collision_layer = 8
	# Trunk
	var trunk = ColorRect.new()
	trunk.color = Color(0.35, 0.2, 0.1)
	trunk.size = Vector2(16, 40)
	trunk.position = Vector2(-8, -30)
	tree.add_child(trunk)
	# Canopy layers for more depth
	var colors = [Color(0.1, 0.35, 0.15), Color(0.15, 0.45, 0.2), Color(0.2, 0.55, 0.25)]
	for i in range(3):
		var cap = ColorRect.new()
		cap.color = colors[i]
		var size = 100 - i * 30
		cap.size = Vector2(size, size)
		cap.position = Vector2(-size / 2.0, -70 - i * 20)
		cap.z_index = 2 + i
		tree.add_child(cap)
	# Collision
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 16.0
	col.shape = shape
	col.position = Vector2(0, -10)
	tree.add_child(col)
	add_child(tree)

func _add_fire(pos: Vector2) -> void:
	# Animated fire effect using particles
	var particles = CPUParticles2D.new()
	particles.position = pos
	particles.amount = 20
	particles.lifetime = 1.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(30, 10)
	particles.direction = Vector2(0, -1)
	particles.spread = 30.0
	particles.gravity = Vector2(0, -50)
	particles.initial_velocity_min = 20.0
	particles.initial_velocity_max = 50.0
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 6.0
	particles.color = Color(1, 0.5, 0.1)
	particles.z_index = 5
	add_child(particles)

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
