extends Node

## Global game state manager - handles level transitions, game state, and persistence.

signal level_changed(level_index: int)
signal game_over(victory: bool)
signal player_died

enum GameState { MENU, PLAYING, PAUSED, DIALOGUE, CUTSCENE, GAME_OVER }

var current_state: GameState = GameState.MENU
var current_level: int = 0
var player_stats: Dictionary = {
	"max_hp": 100,
	"hp": 100,
	"attack_damage": 20,
	"arrow_damage": 15,
	"arrows": 20,
	"speed": 200.0,
	"is_stealthed": false,
	"in_boat": false
}

var levels: Array[String] = [
	"res://scenes/levels/level_1.tscn",
	"res://scenes/levels/level_2.tscn",
	"res://scenes/levels/level_3.tscn",
	"res://scenes/levels/level_4.tscn",
	"res://scenes/levels/level_5.tscn"
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func start_game() -> void:
	current_level = 0
	reset_player_stats()
	current_state = GameState.PLAYING
	load_level(current_level)

func reset_player_stats() -> void:
	player_stats.hp = player_stats.max_hp
	player_stats.arrows = 20
	player_stats.is_stealthed = false
	player_stats.in_boat = false

func load_level(index: int) -> void:
	current_level = index
	if index >= levels.size():
		show_victory()
		return
	get_tree().change_scene_to_file(levels[index])
	level_changed.emit(index)

func next_level() -> void:
	current_level += 1
	if current_level >= levels.size():
		show_victory()
	else:
		reset_player_stats()
		load_level(current_level)

func restart_level() -> void:
	reset_player_stats()
	load_level(current_level)

func go_to_main_menu() -> void:
	current_state = GameState.MENU
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func show_victory() -> void:
	current_state = GameState.GAME_OVER
	game_over.emit(true)
	get_tree().change_scene_to_file("res://scenes/ui/victory_screen.tscn")

func show_game_over_screen() -> void:
	current_state = GameState.GAME_OVER
	game_over.emit(false)
	get_tree().change_scene_to_file("res://scenes/ui/game_over_screen.tscn")

func pause_game() -> void:
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
		get_tree().paused = true

func resume_game() -> void:
	if current_state == GameState.PAUSED:
		current_state = GameState.PLAYING
		get_tree().paused = false

func on_player_died() -> void:
	player_died.emit()
	await get_tree().create_timer(2.0).timeout
	show_game_over_screen()

func damage_player(amount: int) -> void:
	player_stats.hp = max(0, player_stats.hp - amount)
	if player_stats.hp <= 0:
		on_player_died()

func heal_player(amount: int) -> void:
	player_stats.hp = min(player_stats.max_hp, player_stats.hp + amount)

func get_level_name() -> String:
	var names = ["Call to Arms", "Soldier Training", "Scout Mission", "Prepare the Trap", "Battle of Bach Dang"]
	if current_level < names.size():
		return names[current_level]
	return "Unknown"
