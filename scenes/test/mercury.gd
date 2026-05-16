extends RigidBody3D

# 圆周运动参数
var center: Vector3 = Vector3.ZERO  # 旋转中心点
var radius: float = 50             # 旋转半径
var angular_speed: float = 1.0     # 角速度 (弧度/秒)
var rotation_speed: float = 2.0     # 自转速度 (弧度/秒)
var gravity_increase_rate: float = 5.0  # 引力每秒增加量
# 当前角度
var current_angle: float = 0.0

func _ready():
	# 初始位置
	global_position = center + Vector3(radius, 0, 0)
	
	# 初始速度 (切线方向)
	linear_velocity = Vector3(0, 0, angular_speed * radius)
	
	# 初始角速度 (自转)
	angular_velocity = Vector3(0, rotation_speed, 0)
	
	# 禁用重力
	gravity_scale = 0.0

func _physics_process(delta):
	# 更新角度
	current_angle += angular_speed * delta
	
	
	# 计算目标位置
	var target_position = center + Vector3(
		radius * cos(current_angle),
		0,
		radius * sin(current_angle)
	)
	
	# 计算当前位置到目标位置的向量
	var position_error = target_position - global_position
	
	# 应用位置修正力
	gravity_increase_rate += delta * 5.0  # 每秒增加5个单位
	var position_correction_force = position_error * mass * (10.0 + gravity_increase_rate)
	apply_central_force(position_correction_force)
	
	# 计算切线方向 (运动方向)
	var tangent_direction = Vector3(-sin(current_angle), 0, cos(current_angle)).normalized()
	
	# 计算当前速度方向
	var current_direction = linear_velocity.normalized()
	
	# 计算方向误差
	var direction_error = tangent_direction - current_direction
	
	# 应用方向修正力
	var direction_correction_force = direction_error * mass * angular_speed * radius * 5.0
	apply_central_force(direction_correction_force)
	
	# 保持自转
	angular_velocity = Vector3(0, rotation_speed, 0)
	
	# 保持朝向运动方向
	var target_rotation = Basis.looking_at(tangent_direction, Vector3.UP)
	rotation = rotation.slerp(target_rotation.get_euler(), 0.1)
