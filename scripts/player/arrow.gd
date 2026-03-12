extends Area2D

## Arrow projectile - moves in a direction and damages enemies on hit.

var direction: Vector2 = Vector2.RIGHT
var speed: float = 500.0
var damage: int = 15
var shooter: Node2D = null
var lifetime: float = 3.0

func _ready() -> void:
	add_to_group("projectiles")
	_setup_visuals()
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _setup_visuals() -> void:
	var img = Image.create(12, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.6, 0.4, 0.2))
	# Tip
	for x in range(9, 12):
		for y in range(0, 4):
			img.set_pixel(x, y, Color(0.8, 0.8, 0.8))
	var tex = ImageTexture.create_from_image(img)
	var spr = Sprite2D.new()
	spr.texture = tex
	add_child(spr)
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body == shooter:
		return
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage, global_position)
	elif body.is_in_group("destructible") and body.has_method("take_damage"):
		body.take_damage(damage, global_position)
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.get_parent() == shooter:
		return
	if area.is_in_group("enemies") and area.get_parent().has_method("take_damage"):
		area.get_parent().take_damage(damage, global_position)
		queue_free()
