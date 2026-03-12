extends CanvasLayer

## Dialogue box - shows speaker and text at bottom of screen.

@onready var panel: PanelContainer = $PanelContainer
@onready var speaker_label: Label = $PanelContainer/VBoxContainer/SpeakerLabel
@onready var text_label: Label = $PanelContainer/VBoxContainer/TextLabel
@onready var continue_label: Label = $PanelContainer/VBoxContainer/ContinueLabel

func _ready() -> void:
	layer = 11
	panel.visible = false
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	DialogueManager.line_displayed.connect(_on_line_displayed)

func _on_dialogue_started() -> void:
	panel.visible = true

func _on_dialogue_ended() -> void:
	panel.visible = false

func _on_line_displayed(speaker: String, text: String) -> void:
	speaker_label.text = speaker
	text_label.text = text
	continue_label.text = "[Press E to continue]"
