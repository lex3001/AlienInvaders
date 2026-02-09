# HighScores.gd
# VB6-compatible high score reader for AI.HS

extends RefCounted

class_name HighScores

const KEYS = [
	0,
	0xBFF5, 0x663D, 0x5AC5, 0x70D5, 0x969B, 0xCEB5, 0x1D90, 0x7BA0,
	0xD9A3, 0x34, 0xC8A3, 0x3132, 0x506, 0x8328, 0xC011, 0x65F4,
	0xA8C0, 0x1631, 0x100F, 0xDEBF, 0xC730, 0xB726, 0x93E7, 0xA673,
	0x880C, 0x9D3F, 0xAD78, 0x3B74, 0x58EA, 0x3EC8, 0xD2B3, 0x2047,
	0xE5F7, 0x5984, 0xFDCE, 0x4C99, 0x14A4, 0xFD47, 0xA24, 0xB987,
	0x1C63, 0x5F3B, 0x6C83, 0xE656, 0x681E, 0xF8BB, 0x87DC, 0x567D,
	0xA9D0, 0x747A, 0x5657, 0xFEC6, 0xB1F9, 0xF34D, 0xC67C, 0xDA30,
	0xD90D, 0x9B6C, 0x28FA, 0x681F, 0x6CE5, 0xF424, 0x12B3, 0x3BE9,
	0x28AD, 0xBA37, 0x5FFD, 0x186B, 0xE384, 0xDE7A, 0xFA22, 0x4CB1,
	0xE33E, 0x9516, 0x3610, 0x4F1, 0x9585, 0x7667, 0xB999, 0x2C1,
	0xA783, 0x3020, 0x4BE4, 0xEDB, 0xFD98, 0xD114, 0xEB8A, 0x434F,
	0xAF3A, 0x8F8D, 0xDA19, 0xD41, 0x4840, 0xD3B8, 0xCDA4, 0xF156,
	0x69D5, 0x6957, 0x6F61, 0xF54B, 0x34B, 0x416E, 0xCCB8, 0x122E,
	0x5025, 0xB0E5, 0x475A, 0xB922, 0xAA5B, 0x2E4C, 0x5547, 0x6BDE,
	0xB1D9, 0x6931, 0xEFA6, 0x2EFE, 0x79FF, 0x519B, 0xE301, 0xFF91,
	0x1A62, 0x5983, 0xB206, 0x3AF9, 0xFEF9, 0xCC65, 0xD397, 0x838D
]

var scores: Array[Dictionary] = []

func load_default() -> void:
	if _ensure_user_file("AI.HS"):
		load_from_file("user://AI.HS")
	elif FileAccess.file_exists("res://AI.HS"):
		load_from_file("res://AI.HS")
	else:
		_clear_scores()

func load_from_file(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		_clear_scores()
		return

	scores.clear()
	for record_index in range(1, 11):
		var data: Array[int] = []
		for i in range(128):
			data.append(file.get_32())

		var checksum: int = 0
		var name_chars: PackedStringArray = []
		for i in range(1, 51):
			var key = _get_key(i, record_index)
			var value = data[i - 1] ^ key
			checksum += value
			name_chars.append(String.chr(value & 0xFF))

		var score_key = _get_key(51, record_index)
		var score = data[50] ^ score_key
		checksum += score

		for i in range(52, 128):
			var key2 = _get_key(i, record_index)
			var value2 = data[i - 1] ^ key2
			checksum += value2

		var saved_key = _get_key(128, record_index)
		var saved_checksum = data[127] ^ saved_key
		if saved_checksum != checksum:
			score = 0

		var name = "".join(name_chars).rstrip(" ")
		scores.append({"name": name, "score": score})

func _get_key(index: int, record_index: int) -> int:
	var key_index = (index % (KEYS.size() - 1)) + 1
	return KEYS[key_index] + index + record_index

func _clear_scores() -> void:
	scores.clear()
	for i in range(10):
		scores.append({"name": "", "score": 0})

func _ensure_user_file(file_name: String) -> bool:
	var user_path = "user://" + file_name
	if FileAccess.file_exists(user_path):
		return true
	if not FileAccess.file_exists("res://" + file_name):
		return false
	var src = FileAccess.open("res://" + file_name, FileAccess.READ)
	if src == null:
		return false
	var dst = FileAccess.open(user_path, FileAccess.WRITE)
	if dst == null:
		return false
	dst.store_buffer(src.get_buffer(src.get_length()))
	src.close()
	dst.close()
	return true
