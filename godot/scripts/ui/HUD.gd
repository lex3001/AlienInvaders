extends CanvasLayer

class_name HUD

var game = null
var score_label: Label = null
var lives_label: Label = null

func _ready():
	score_label = Label.new()
	score_label.position = Vector2(10, 5)
	score_label.add_theme_font_size_override("font_size", 16)
	add_child(score_label)
	
	lives_label = Label.new()
	lives_label.position = Vector2(200, 5)
	lives_label.add_theme_font_size_override("font_size", 16)
	add_child(lives_label)

func set_game(p_game):
	game = p_game

func _process(_delta):
	if game:
		if score_label:
			score_label.text = "SCORE: " + str(game.score)
		if lives_label:
			lives_label.text = "LIVES: " + str(game.lives)

