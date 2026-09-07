class_name HudView
extends Control

## Displays game status, turn instructions, scoreboards, and round over alerts.

@onready var turn_label: Label = $TopBar/Margin/HBox/TurnLabel
@onready var score_label: Label = $TopBar/Margin/HBox/ScoreLabel
@onready var prompt_label: Label = $PromptPanel/PromptLabel

func update_status(turn_text: String, score_text: String, prompt_text: String) -> void:
	if turn_label != null:
		turn_label.text = turn_text
	if score_label != null:
		score_label.text = score_text
	if prompt_label != null:
		prompt_label.text = prompt_text

func show_announcement(text: String, duration: float = 2.0) -> void:
	if prompt_label != null:
		prompt_label.text = text
		var tween := create_tween()
		prompt_label.modulate = Color(1, 0.9, 0.2)
		tween.tween_property(prompt_label, "modulate", Color.WHITE, duration)
