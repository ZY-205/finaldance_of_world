extends Control


func _physics_process(delta: float) -> void:
	$VBoxContainer/Panel/Label.text = "木头:" + str(GameData.wood_number)
	$VBoxContainer/Panel2/Label.text = "石头:" + str(GameData.rock_number)
