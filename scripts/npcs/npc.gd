extends StaticBody2D

## Generic NPC - General, Villager, Allied Soldier. Interact to trigger dialogue.

@export var npc_name: String = "Villager"
@export var npc_type: String = "villager"  # "general", "villager", "soldier"
@export var dialogue_lines: Array[Dictionary] = []
@export var npc_color: Color = Color(0.2, 0.7, 0.3)

signal interacted(npc: Node2D)

func _ready() -> void:
	add_to_group("npcs")
	_setup_visuals()
	_setup_interaction()
	$Sprite2D.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _setup_visuals() -> void:
	if not has_node("Sprite2D"):
		var _new_spr = Sprite2D.new()
		_new_spr.name = "Sprite2D"
		add_child(_new_spr)
	var spr = $Sprite2D
	
	var asset_path = "res://assets/soldier_anims.png"
	match npc_type:
		"general": asset_path = "res://assets/general_anims.png"
		"villager": asset_path = "res://assets/villager_anims.png"
		"soldier": asset_path = "res://assets/soldier_anims.png"

	if FileAccess.file_exists(asset_path):
		var img = Image.load_from_file(asset_path)
		_fix_sprite_transparency(img)
		var tex = ImageTexture.create_from_image(img)
		spr.texture = tex
		spr.hframes = 4
		spr.vframes = 4
		spr.frame = 0
		spr.modulate = Color(1, 1, 1) # Reset modulate
		# Dynamic scaling to fit standard 40px height
		var tex_h = tex.get_height()
		var frame_h = tex_h / 4.0
		var target_h = 40.0
		var s = target_h / frame_h
		spr.scale = Vector2(s, s)
	else:
		spr.texture = ImageTexture.create_from_image(Image.create(16, 16, false, Image.FORMAT_RGBA8))
		spr.scale = Vector2(2, 2)
	
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.rotation = 0

func _update_sprite_facing(dir: Vector2) -> void:
	if dir.x < 0: $Sprite2D.flip_h = true
	elif dir.x > 0: $Sprite2D.flip_h = false

var _anim_timer: float = 0.0
func _process(delta: float) -> void:
	_anim_timer += delta
	if $Sprite2D.hframes > 1 and _anim_timer > 0.2:
		_anim_timer = 0.0
		$Sprite2D.frame = ($Sprite2D.frame + 1) % $Sprite2D.hframes
	# Dithered idle animation logic
	# No more scaling breath, it ruins pixel art sharpness
	pass

func _setup_interaction() -> void:
	if not has_node("InteractionArea"):
		var area = Area2D.new()
		area.name = "InteractionArea"
		area.add_to_group("interactable")
		var col = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 40.0
		col.shape = shape
		area.add_child(col)
		add_child(area)
		area.collision_layer = 16  # Layer 5 = Interaction
		area.collision_mask = 0
	else:
		$InteractionArea.add_to_group("interactable")

func interact(_player: Node2D) -> void:
	interacted.emit(self)
	if dialogue_lines.size() > 0:
		DialogueManager.start_dialogue(dialogue_lines)

func set_dialogue(lines: Array) -> void:
	dialogue_lines.assign(lines)

func _fix_sprite_transparency(img: Image) -> void:
	img.convert(Image.FORMAT_RGBA8)
	for x in range(img.get_width()):
		for y in range(img.get_height()):
			var c = img.get_pixel(x, y)
			if c.r > 0.95 and c.g > 0.95 and c.b > 0.95:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
