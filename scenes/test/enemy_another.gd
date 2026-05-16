extends CharacterBody3D

# 移动参数
@export var move_speed: float = 2.0          # 移动速度
@export var rotation_speed: float = 3.0      # 旋转速度
@export var stopping_distance: float = 1.0    # 停止距离
@export var knockback_resistance: float = 0.1
# 目标位置
var target_position: Vector3 = Vector3.ZERO
var gravity
var current_push_force: Vector3 = Vector3.ZERO


func _ready():
	add_to_group("enemy")
	
	# 设置初始目标位置（示例）
	target_position = Vector3(0, 0, 0)
	
	# 设置物理属性
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	floor_max_angle = 0.8  # 最大爬坡角度

func _physics_process(delta):
	if current_push_force.length() > 0.1:
		velocity += current_push_force
		current_push_force = Vector3.ZERO
	# 重力处理
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# 计算移动方向
	var direction = calculate_movement_direction()
	
	if direction:
		# 应用移动
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		
		# 旋转朝向目标
		rotate_towards_target(direction, delta)
	else:
		# 减速停止
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
	
	# 应用移动
	move_and_slide()
	
	# 检测碰撞
	handle_collisions()

# 计算移动方向
func calculate_movement_direction() -> Vector3:
	# 计算到目标的向量
	var to_target = target_position - global_position
	var distance = to_target.length()
	
	# 如果已经在停止距离内，不移动
	if distance <= stopping_distance:
		return Vector3.ZERO
	
	# 返回归一化的水平方向
	return Vector3(to_target.x, 0, to_target.z).normalized()

# 旋转朝向目标
func rotate_towards_target(direction: Vector3, delta: float):
	# 计算目标角度
	var target_angle = atan2(direction.x, direction.z)
	
	# 平滑旋转
	rotation.y = lerp_angle(rotation.y, target_angle, rotation_speed * delta)

# 处理碰撞
func handle_collisions():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider is CharacterBody3D and collider.is_in_group("player"):
			print("敌人撞到了玩家!")
			# 这里可以添加伤害逻辑或反弹效果
			#collider.apply_damage(10)
			
			# 敌人反弹
			var bounce_direction = -collision.get_normal()
			velocity = bounce_direction * move_speed * 0.5

func apply_push_force(force: Vector3):
	# 应用击退力（考虑抗性）
	current_push_force = force * (1.0 - knockback_resistance)

# 设置新目标
func set_new_target(new_target: Vector3):
	target_position = new_target
	print("新目标设置: ", target_position)

# 玩家伤害函数（示例）
func apply_damage(amount: int):
	# 实现伤害逻辑
	print("玩家受到伤害: ", amount)
