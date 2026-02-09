# HighScoreEntry.gd
# UI for entering player name when achieving a high score

extends Control

signal name_entered(player_name: String)

var player_name: String = ""
var score: int = 0
var max_name_length: int = 20

# UI elements (to be created in _ready)
var label_prompt: Label
var label_score: Label
var line_edit: LineEdit
var button_submit: Button

func _ready():
	visible = false
	_create_ui()

func _create_ui():
	# Create container
	var panel = PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -200
	panel.offset_top = -100
	panel.offset_right = 200
	panel.offset_bottom = 100
	add_child(panel)
	
	# Create vertical layout
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	
	# Title label
	var title = Label.new()
	title.text = "NEW HIGH SCORE!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	
	# Score label
	label_score = Label.new()
	label_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_score.add_theme_font_size_override("font_size", 18)
	vbox.add_child(label_score)
	
	# Prompt
	label_prompt = Label.new()
	label_prompt.text = "Enter your name:"
	label_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label_prompt)
	
	# Name input
	line_edit = LineEdit.new()
	line_edit.max_length = max_name_length
	line_edit.placeholder_text = "Your Name"
	line_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	line_edit.text_submitted.connect(_on_name_submitted)
	vbox.add_child(line_edit)
	
	# Submit button
	button_submit = Button.new()
	button_submit.text = "Submit"
	button_submit.pressed.connect(_on_submit_pressed)
	vbox.add_child(button_submit)

func show_entry(p_score: int):
	score = p_score
	player_name = ""
	if label_score:
		label_score.text = "Score: " + str(score)
	if line_edit:
		line_edit.text = ""
		line_edit.grab_focus()
	visible = true

func _on_submit_pressed():
	_submit_name()

func _on_name_submitted(_text: String):
	_submit_name()

func _submit_name():
	if line_edit:
		player_name = line_edit.text.strip_edges()
	if player_name.is_empty():
		player_name = "Anonymous"
	
	emit_signal("name_entered", player_name)
	visible = false
