extends Node

## Dialogue manager - handles NPC conversations and tutorial text.

signal dialogue_started
signal dialogue_ended
signal line_displayed(speaker: String, text: String)

var is_active: bool = false
var current_queue: Array[Dictionary] = []
var current_index: int = 0

func start_dialogue(lines: Array[Dictionary]) -> void:
	if is_active:
		return
	current_queue = lines
	current_index = 0
	is_active = true
	GameManager.current_state = GameManager.GameState.DIALOGUE
	dialogue_started.emit()
	show_current_line()

func show_current_line() -> void:
	if current_index >= current_queue.size():
		end_dialogue()
		return
	var line = current_queue[current_index]
	line_displayed.emit(line.get("speaker", ""), line.get("text", ""))

func advance() -> void:
	if not is_active:
		return
	current_index += 1
	show_current_line()

func end_dialogue() -> void:
	is_active = false
	current_queue.clear()
	current_index = 0
	GameManager.current_state = GameManager.GameState.PLAYING
	dialogue_ended.emit()

func _input(event: InputEvent) -> void:
	if is_active and event.is_action_pressed("interact"):
		advance()
		get_viewport().set_input_as_handled()
