extends Node3D

# 长按参数
@export var long_press_duration: float = 1.0
@export var action_name: String = "interactive"

# 状态变量
var press_time: float = 0.0
var is_long_press_triggered: bool = false
var in_range: bool = false


func _on_area_3d_body_shape_entered(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	$interactive.show()
	in_range = true


func _on_area_3d_body_shape_exited(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	$interactive.hide()
	in_range = false


func _process(delta):
	# 检测按键是否按下
	if Input.is_action_pressed(action_name) and in_range:
		press_time += delta
		
		# 检查是否达到长按时间
		if press_time >= long_press_duration and not is_long_press_triggered:
			is_long_press_triggered = true
			on_long_press()
	
	# 检测按键释放
	if Input.is_action_just_released(action_name):
		# 如果释放时未达到长按时间，执行短按
		if press_time < long_press_duration:
			on_short_press()
		
		# 重置状态
		press_time = 0.0
		is_long_press_triggered = false

func on_short_press():
	print("短按触发")

func on_long_press():
	GameData.wood_number += 1
