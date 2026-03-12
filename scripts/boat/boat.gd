extends CharacterBody2D

## Player-controlled boat for river sections.

signal boat_entered
signal boat_exited
signal checkpoint_reached(index: int)

@export var boat_speed: float = 220.0
@export var boat_color: Color = Color(0.55, 0.35, 0.15)

@onready var prompt_label: Label = $PromptLabel

var is_occupied: bool = false
var player_ref: Node2D = null
var checkpoints_reached: int = 0
var interaction_timer: float = 0.0

func _ready() -> void:
	add_to_group("boats")
	_setup_visuals()
	_setup_interaction()
	_setup_collision()
	_setup_prompt()
	if $Sprite2D:
		$Sprite2D.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _setup_visuals() -> void:
	if not has_node("Sprite2D"):
		var spr = Sprite2D.new()
		spr.name = "Sprite2D"
		add_child(spr)
	var img = Image.create(48, 24, false, Image.FORMAT_RGBA8)
	# Boat hull
	for x in range(4, 44):
		for y in range(6, 22):
			var color = boat_color
			if y < 10 or y > 18: color = color.darkened(0.2) # Shading
			img.set_pixel(x, y, color)
	# Pointed front
	for x in range(44, 48):
		for y in range(8 + (x - 44), 20 - (x - 44)):
			img.set_pixel(x, y, boat_color.darkened(0.1))
	# Seat
	for x in range(16, 28):
		for y in range(9, 15):
			img.set_pixel(x, y, Color(0.4, 0.25, 0.1))
	# Details (rim)
	for x in range(4, 44):
		img.set_pixel(x, 6, boat_color.lightened(0.2))
		img.set_pixel(x, 21, boat_color.darkened(0.3))
	
	var tex = ImageTexture.create_from_image(img)
	$Sprite2D.texture = tex
	$Sprite2D.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	$Sprite2D.scale = Vector2(1, 1) # Reset to 1 since we're using procedural pixels

func _setup_interaction() -> void:
	if not has_node("InteractionArea"):
		var area = Area2D.new()
		area.name = "InteractionArea"
		area.add_to_group("interactable")
		var col = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 80.0 # Even larger for easier interaction
		col.shape = shape
		area.add_child(col)
		add_child(area)
		area.collision_layer = 16
		area.collision_mask = 1 # Player layer
		area.body_entered.connect(_on_player_body_entered)
		area.body_exited.connect(_on_player_body_exited)

func _setup_prompt() -> void:
	if not has_node("PromptLabel"):
		var label = Label.new()
		label.name = "PromptLabel"
		label.text = "[E] Lên thuyền"
		label.visible = false
		label.position = Vector2(-40, -40)
		var settings = LabelSettings.new()
		settings.font_size = 12
		settings.font_color = Color(1, 1, 0)
		label.label_settings = settings
		add_child(label)

func _setup_collision() -> void:
	if not has_node("CollisionShape2D"):
		var col = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(48, 24)
		col.shape = shape
		add_child(col)
	collision_layer = 4 # Boat layer
	collision_mask = 1 | 8 | 16 # Ground, Houses, Other interactables

func _physics_process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	
	if not is_occupied:
		_check_proximity_prompt(delta)
		return
	var input_dir = Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_up", "move_down")
	
	if input_dir.length() < 0.1:
		input_dir.x = Input.get_axis("ui_left", "ui_right")
		input_dir.y = Input.get_axis("ui_up", "ui_down")
	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
		velocity = input_dir * boat_speed
		$Sprite2D.rotation = velocity.angle()
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 200 * delta)
	# Exit boat
	interaction_timer -= delta
	if Input.is_action_just_pressed("interact") and interaction_timer <= 0:
		exit_boat()
	
	if is_occupied and prompt_label:
		prompt_label.visible = false
		
	# Proximity check for prompt as a backup to signals
	_check_proximity_prompt(delta)
	
	if is_occupied:
		move_and_slide()

func _on_player_body_entered(body: Node2D) -> void:
	if not is_occupied and body.is_in_group("player") and prompt_label:
		prompt_label.visible = true

func _on_player_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and prompt_label:
		prompt_label.visible = false

func interact(player: Node2D) -> void:
	if is_occupied:
		return
	player_ref = player
	is_occupied = true
	interaction_timer = 0.5 # Wait 0.5s before allowing exit
	player.enter_boat(self)
	boat_entered.emit()
	# Add camera to boat
	if player.has_node("Camera2D"):
		var cam = player.get_node("Camera2D")
		cam.reparent(self)

func exit_boat() -> void:
	if not is_occupied:
		return
	is_occupied = false
	if player_ref and is_instance_valid(player_ref):
		# Return camera
		if has_node("Camera2D"):
			var cam = get_node("Camera2D")
			cam.reparent(player_ref)
		player_ref.exit_boat()
	player_ref = null
	boat_exited.emit()

func on_checkpoint(index: int) -> void:
	checkpoints_reached += 1
	checkpoint_reached.emit(index)

func _check_proximity_prompt(_delta: float) -> void:
	if is_occupied: return
	
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty(): return
	
	var p = players[0]
	var dist = global_position.distance_to(p.global_position)
	if prompt_label:
		if dist < 120.0: # Interaction radius
			prompt_label.visible = true
		else:
			prompt_label.visible = false
