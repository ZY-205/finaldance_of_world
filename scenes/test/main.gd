extends Node3D

func _ready() -> void:
	start_game()

func start_game():
	var enemy = preload("res://scenes/test/enemy.tscn")
	for i in range(0,10):
		await get_tree().create_timer(2).timeout
		var temp = enemy.instantiate()
		temp.global_position = $birth.global_position
		add_child(temp)


# 假设场景中有 camera1 和 camera2 两个 Camera2D 节点
func transition_cameras(from: Camera3D, to: Camera3D, duration: float = 1.0):
	# 创建 Tween
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	
	# 保存原始属性（可选）
	var original_position = from.global_position
	var original_rotation = from.rotation
	
	tween.parallel().tween_property(from, "global_position", to.global_position, duration)
	tween.parallel().tween_property(from, "global_rotation", to.global_rotation, duration)
	
	
	print(to.rotation - from.get_parent().rotation)
	await tween.finished
	
	from.global_position = original_position
	from.rotation = original_rotation
	
	# 禁用当前摄像机
	from.current = false
	
	# 设置目标摄像机初始状态（与起始摄像机一致）
	#to.global_position = original_position
	#to.zoom = original_zoom
	to.current = true
	
	# 动画过渡到目标摄像机属性
	#tween.tween_property(to, "global_position", to.global_position, duration)
	#tween.tween_property(to, "zoom", to.zoom, duration)
