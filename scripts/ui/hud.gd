extends CanvasLayer

## HUD - health bar, arrows, objective text, level name.

@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/TopBar/HealthBar
@onready var health_label: Label = $MarginContainer/VBoxContainer/TopBar/HealthLabel
@onready var arrow_label: Label = $MarginContainer/VBoxContainer/TopBar/ArrowLabel
@onready var objective_label: Label = $MarginContainer/VBoxContainer/ObjectivePanel/ObjectiveLabel
@onready var level_label: Label = $MarginContainer/VBoxContainer/TopBar/LevelLabel
@onready var stealth_indicator: Label = $MarginContainer/VBoxContainer/TopBar/StealthLabel

func _ready() -> void:
	layer = 10
	_connect_signals()
	_update_level_name()

func _connect_signals() -> void:
	MissionManager.mission_updated.connect(_on_mission_updated)
	MissionManager.mission_completed.connect(_on_mission_completed)
	# Find player and connect
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		player.health_changed.connect(_on_health_changed)
		player.arrows_changed.connect(_on_arrows_changed)
		player.stealth_changed.connect(_on_stealth_changed)
		_on_health_changed(GameManager.player_stats.hp, GameManager.player_stats.max_hp)
		_on_arrows_changed(GameManager.player_stats.arrows)

func _on_health_changed(hp: int, max_hp: int) -> void:
	health_bar.max_value = max_hp
	health_bar.value = hp
	health_label.text = "HP: %d/%d" % [hp, max_hp]

func _on_arrows_changed(count: int) -> void:
	arrow_label.text = "Tên: %d" % count

func _on_mission_updated(_mission_id: String, objective: String) -> void:
	objective_label.text = objective

func _on_mission_completed(_mission_id: String) -> void:
	objective_label.text = "Nhiệm Vụ Hoàn Thành!"

func _on_stealth_changed(is_stealthed: bool) -> void:
	stealth_indicator.visible = is_stealthed

func _update_level_name() -> void:
	level_label.text = GameManager.get_level_name()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if GameManager.current_state == GameManager.GameState.PLAYING:
			GameManager.pause_game()
			_show_pause_menu()

func _show_pause_menu() -> void:
	var pause = preload("res://scenes/ui/pause_menu.tscn").instantiate()
	add_child(pause)
