extends RigidBody3D

# 移动参数
@export var move_speed: float = 5.0          # 移动速度
@export var rotation_speed: float = 3.0       # 旋转速度
@export var stopping_distance: float = 2.0    # 停止距离（离目标多近时停止）
@export var health: float = 100 
# 目标位置
var target_position: Vector3 = Vector3.ZERO

# 主塔引用（从组中获取）
var main_tower: Node3D = null

func _ready():
	add_to_group("enemy")
	
	# 从"main_tower"组中获取主塔引用
	var main_towers = get_tree().get_nodes_in_group("main_tower")
	if main_towers.size() > 0:
		main_tower = main_towers[0]
		print("找到主塔: ", main_tower.name)
	else:
		print("警告: 未找到主塔节点")
	
	# 设置物理属性
	#gravity_scale = 0.0  # 禁用重力
	mass = 5           # 质量
	linear_damp = 5    # 线性阻尼（减少滑动）
	angular_damp = 10   # 角阻尼（减少旋转晃动）

func _physics_process(delta):
	# 更新目标位置（如果主塔存在）
	if main_tower:
		target_position = main_tower.global_position
	
	# 计算移动方向
	var direction = calculate_movement_direction()

	if direction:
		# 应用移动力
		apply_movement_force(direction, delta)
		
		# 旋转朝向目标
		rotate_towards_target(direction, delta)
	
	# 更新标签显示（如果存在Label3D）
	update_label()

# 计算移动方向
func calculate_movement_direction() -> Vector3:
	#if target_position == Vector3.ZERO:
		#return Vector3.ZERO
	
	# 计算到目标的向量
	var to_target = target_position - global_position
	var distance = to_target.length()
	#print(distance)
	# 如果已经在停止距离内，不移动
	if distance <= stopping_distance:
		return Vector3.ZERO
	
	# 返回归一化的方向
	return to_target.normalized()

# 应用移动力
func apply_movement_force(direction: Vector3, delta: float):
	
	# 计算目标速度
	var target_velocity = direction * move_speed
	
	# 计算速度误差（当前速度与目标速度的差）
	var velocity_error = target_velocity - linear_velocity
	
	# 应用修正力（比例控制）
	var correction_force = velocity_error * mass * 5.0
	#print(correction_force)
	apply_central_force(correction_force)
 
# 旋转朝向目标
func rotate_towards_target(direction: Vector3, delta: float):
	# 忽略Y轴分量（在水平面旋转）
	var horizontal_direction = Vector3(direction.x, 0, direction.z).normalized()
	
	if horizontal_direction.length() > 0.1:
		# 计算目标朝向
		var target_basis = Basis.looking_at(horizontal_direction, Vector3.UP)
		
		# 使用四元数进行平滑旋转插值
		var current_quat = Quaternion(global_transform.basis)
		var target_quat = Quaternion(target_basis)
		var new_quat = current_quat.slerp(target_quat, rotation_speed * delta)
		
		# 应用新旋转
		global_transform.basis = Basis(new_quat)

# 更新标签显示
func update_label():
	var label = get_node_or_null("Label3D")
	if label:
		var distance = global_position.distance_to(target_position)
		label.text = "目标距离: " + str(int(distance)) + "m\n速度: " + str(int(linear_velocity.length())) + "m/s"

# 公共方法：设置新目标
func set_new_target(new_target: Vector3):
	target_position = new_target
	print("新目标设置: ", target_position)

# 公共方法：设置移动速度
func set_move_speed(new_speed: float):
	move_speed = new_speed

# 检测碰撞
func _on_body_entered(body):
	if body.is_in_group("main_tower"):
		print("敌人到达主塔!")
		# 这里可以添加攻击逻辑或销毁敌人
		queue_free()

func take_damage(damage):
	health -= damage
	if health <= 0:
		self.queue_free()

# 可选：添加调试可视化
#func _draw_debug_info():
	# 绘制到目标的线
	#DebugDraw3D.draw_line(global_position, target_position, Color.RED)
	#
	# 绘制移动方向
	#var direction = (target_position - global_position).normalized()
	#DebugDraw3D.draw_line(global_position, global_position + direction * 3, Color.GREEN)
	#
	# 绘制速度向量
	#DebugDraw3D.draw_line(global_position, global_position + linear_velocity, Color.BLUE)


func _on_area_3d_body_entered(body: Node3D) -> void:
	self.global_position += Vector3(0,2.2,0)
