extends CharacterBody3D

# ===== 物理参数 =====
@export var push_force = Vector3(3.0,3.0,3.0)  # 推动物体的力

# ===== 移动参数 =====
@export var move_speed: float = 5.0             # 角色移动速度
@export var jump_force: float = 8.0               # 跳跃力度
@export var gravity: float = 20.0                 # 重力强度
@export var sprint_speed: float = 8.0             # 冲刺速度
@export var normal_speed: float = 5.0             # 正常移动速度

# ===== 相机控制参数 =====
@export var camera_sensitivity: float = 0.003      # 鼠标灵敏度
@export var min_vertical_angle: float = -30.0     # 相机垂直旋转最小角度（俯角）
@export var max_vertical_angle: float = 70.0      # 相机垂直旋转最大角度（仰角）
@export var camera_distance: float = 4.0          # 相机与角色的距离
@export var min_distance: float = 1.0             # 相机最小距离
@export var max_distance: float = 10.0             # 相机最大距离
@export var camera_height: float = 1.5            # 相机高度（相对于角色位置）
@export var camera_smooth_factor: float = 0.1     # 相机位置平滑过渡因子

# ===== 碰撞检测参数 =====
#@export var collision_mask: int = 1               # 碰撞检测层掩码
@export var collision_margin: float = 0.1          # 碰撞边距（防止相机过于接近表面）
@export var extra_collision_check: bool = true    # 是否启用额外碰撞检测
@export var ray_count: int = 5                    # 额外碰撞检测射线数量
@export var ray_spread: float = 0.2               # 额外碰撞检测射线分布范围

# ===== 节点引用 =====
@onready var spring_arm: SpringArm3D = $SpringArm3D      # 弹簧臂节点（用于相机碰撞检测）
@onready var camera: Camera3D = $SpringArm3D/Camera3D     # 相机节点
#@onready var character_model: MeshInstance3D = $MeshInstance3D  # 角色模型
#@onready var animation_player: AnimationPlayer = $AnimationPlayer  # 动画播放器
@onready var ray_cast_3d: RayCast3D = $SpringArm3D/Camera3D/RayCast3D  # 用于检测抓钩点的射线
#@onready var gun: CharacterBody3D = $Gun  # 抓钩枪节点


# 相机旋转角度
var horizontal_angle: float = 0.0   # 水平旋转角度（绕Y轴）
var vertical_angle: float = 0.0    # 垂直旋转角度（绕X轴）
var is_sprinting: bool = false      # 是否正在冲刺
var target_spring_arm_position: Vector3 = Vector3.ZERO  # 弹簧臂目标位置（用于平滑过渡）

# 抓钩点位置（Vector3.ZERO表示没有抓钩点）
var grapplePoint: Vector3 = Vector3.ZERO

func _ready():
	
	# 设置鼠标捕获模式（隐藏鼠标指针并锁定在窗口内）
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# 初始化SpringArm3D参数
	spring_arm.spring_length = camera_distance   # 设置弹簧臂长度（相机距离）
	spring_arm.collision_mask = collision_mask   # 设置碰撞检测层掩码
	spring_arm.margin = collision_margin         # 设置碰撞边距
	
	# 设置SpringArm3D的碰撞形状（提高碰撞检测精度）
	var shape = SphereShape3D.new()
	shape.radius = 0.2  # 设置碰撞球体半径
	spring_arm.shape = shape
	
	# 初始化弹簧臂目标位置（相机高度）
	target_spring_arm_position = Vector3(0, camera_height, 0)
	
	# 应用初始相机旋转
	update_camera_rotation()

func _input(event):

	# 鼠标移动事件 - 控制相机旋转
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# 水平旋转（绕Y轴）
		# 根据鼠标X轴移动量更新水平角度
		horizontal_angle -= event.relative.x * camera_sensitivity
		
		# 垂直旋转（绕X轴）
		# 根据鼠标Y轴移动量更新垂直角度
		vertical_angle -= event.relative.y * camera_sensitivity
		# 限制垂直角度在指定范围内（防止相机翻转）
		vertical_angle = clamp(
			vertical_angle, 
			deg_to_rad(min_vertical_angle), 
			deg_to_rad(max_vertical_angle)
		)
		
		# 应用新的相机旋转
		update_camera_rotation()
	
	# 鼠标滚轮事件 - 调整相机距离
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			# 滚轮向上 - 减小相机距离
			camera_distance = clamp(camera_distance - 0.5, min_distance, max_distance)
			spring_arm.spring_length = camera_distance
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			# 滚轮向下 - 增大相机距离
			camera_distance = clamp(camera_distance + 0.5, min_distance, max_distance)
			spring_arm.spring_length = camera_distance
	
	# ESC键事件 - 切换鼠标捕获模式
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
		
	
	if Input.is_action_just_pressed("interactive"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			# 如果当前是捕获模式，则切换到可见模式
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			# 如果当前是可见模式，则切换到捕获模式
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float):

	
	# 高级碰撞检测（防止相机穿模）
	if extra_collision_check:
		advanced_collision_check()
	
	# 相机平滑跟随（避免相机移动过于生硬）
	spring_arm.position = spring_arm.position.lerp(target_spring_arm_position, camera_smooth_factor)
	
	# 更新角色动画
	#update_animation()
	
		# 抓钩系统逻辑
	## 当按下鼠标左键、射线检测到碰撞点且当前没有抓钩点时
	#if Input.is_action_just_pressed("left_mouse_click") and ray_cast_3d.is_colliding() and not grapplePoint:
		## 获取抓钩点位置
		#grapplePoint = ray_cast_3d.get_collision_point()
		## 通知枪节点发射抓钩线
		#gun.shoot(grapplePoint)
	#
	## 当按下鼠标左键且当前已有抓钩点时
	#elif Input.is_action_just_pressed("left_mouse_click") and grapplePoint:
		## 清除抓钩点
		#grapplePoint = Vector3.ZERO
		## 通知枪节点移除抓钩线
		#gun.remove_line()
	#
	## 根据抓钩状态选择移动模式
	#if grapplePoint:
		## 抓钩摆动模式
		#_grap_swing(delta)
	#else:
		## 正常移动模式
	_movement(delta)
		
	# 执行物理移动
	move_and_slide()
	
	#apply_push_force_to_enemies()
	
	 # 检测碰撞并推动物体
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# 如果是可推动的刚体
		if collider is RigidBody3D:
			# 计算推动方向（角色移动方向）
			var push_direction = collision.get_normal()
			# 对物体施加力
			collider.apply_central_impulse(-push_direction * push_force)


# 对碰撞的敌人施加力
#func apply_push_force_to_enemies():
	#for i in get_slide_collision_count():
		#var collision = get_slide_collision(i)
		#var collider = collision.get_collider()
		#
		## 检查是否是敌人
		#if collider and collider.is_in_group("enemy"):
			## 计算推动方向（从玩家指向敌人）
			#var push_direction = (collider.global_position - global_position).normalized()
			#
			## 施加力
			#collider.apply_push_force(push_direction * push_force)
	

func update_camera_rotation():
	if !PlayerState.is_deploy:
		# 水平旋转应用于玩家节点（绕Y轴）
		# 这样整个角色会随着相机水平旋转，保持相机在角色后方
		rotation.y = horizontal_angle
		
		# 垂直旋转应用于SpringArm节点（绕X轴）
		# 这样相机可以上下俯仰而不影响角色方向
		spring_arm.rotation.x = vertical_angle
		
		# 设置目标相机高度
		target_spring_arm_position.y = camera_height

func advanced_collision_check():

	# 获取物理空间状态
	var space_state = get_world_3d().direct_space_state
	var collision_points = []  # 存储碰撞点
	
	# 发射多条射线检测碰撞
	for i in range(ray_count):
		# 计算随机偏移（增加检测范围）
		var offset = Vector3(
			randf_range(-ray_spread, ray_spread),
			randf_range(-ray_spread, ray_spread),
			randf_range(-ray_spread, ray_spread)
		)
		
		# 创建射线查询参数
		var query = PhysicsRayQueryParameters3D.new()
		query.from = global_position  # 射线起点（角色位置）
		query.to = camera.global_position + offset  # 射线终点（相机位置+偏移）
		query.collision_mask = collision_mask  # 碰撞层掩码
		
		# 执行射线检测
		var collision = space_state.intersect_ray(query)
		if collision:
			# 如果有碰撞，记录碰撞点
			collision_points.append(collision.position)
	
	# 如果有碰撞点，调整相机位置
	if collision_points.size() > 0:
		var avg_point = Vector3.ZERO  # 平均碰撞点
		
		# 计算所有碰撞点的平均值
		for point in collision_points:
			avg_point += point
		avg_point /= collision_points.size()
		
		# 计算安全位置（从角色位置到碰撞点减去边距）
		var safe_position = avg_point - global_position
		safe_position = safe_position.normalized() * (safe_position.length() - collision_margin)
		
		# 临时覆盖相机位置（避免穿模）
		camera.position = safe_position

func calculate_move_direction(input_dir: Vector2) -> Vector3:

	# 获取相机的水平前方向量（忽略俯仰角）
	# 相机的前方向量是-basis.z（因为相机的Z轴指向屏幕内）
	var camera_forward = -camera.global_transform.basis.z
	camera_forward.y = 0  # 忽略Y分量（保持水平移动）
	camera_forward = camera_forward.normalized()  # 归一化
	
	# 获取相机的水平右方向量（忽略俯仰角）
	var camera_right = camera.global_transform.basis.x
	camera_right.y = 0  # 忽略Y分量
	camera_right = camera_right.normalized()  # 归一化
	
	# 计算移动方向（基于相机方向）
	var direction = Vector3.ZERO
	
	# 前后移动：输入向量的Y分量（-input_dir.y因为W键是向前）
	direction += camera_forward * -input_dir.y
	
	# 左右移动：输入向量的X分量
	direction += camera_right * input_dir.x
	
	# 返回归一化的方向向量
	return direction.normalized()

#func rotate_character_model(move_direction: Vector3):
#
	## 计算目标角度（从移动方向向量获取Y轴旋转角度）
	## atan2(x, z) 返回在XZ平面上的角度
	#var target_angle = atan2(move_direction.x, move_direction.z)
	#
	## 平滑旋转角色模型
	## 使用角度插值避免突然转向
	#character_model.rotation.y = lerp_angle(
		#character_model.rotation.y,  # 当前角度
		#target_angle,                # 目标角度
		#0.2                          # 插值系数（0.0-1.0）
	#)
#
#func update_animation():
#
	## 检查角色是否在移动（速度长度大于0.1）
	#var is_moving = velocity.length() > 0.1
	#
	## 如果有动画播放器，根据移动状态播放相应动画
	#if animation_player:
		#if is_moving:
			#if is_sprinting:
				## 冲刺动画
				#animation_player.play("run")
			#else:
				## 行走动画
				#animation_player.play("walk")
		#else:
			## 空闲动画
			#animation_player.play("idle")
			
			
func _movement(delta):
# 重力处理
	if not is_on_floor():
		# 如果角色不在地面上，应用重力
		velocity.y -= gravity * delta
	
	# 跳跃处理
	if Input.is_action_just_pressed("jump") and is_on_floor():
		# 如果按下跳跃键且角色在地面上，应用跳跃力
		velocity.y = jump_force
	
	# 冲刺检测
	if Input.is_action_pressed("sprint"):
		# 如果按下冲刺键，使用冲刺速度
		move_speed = sprint_speed
		is_sprinting = true
	else:
		# 否则使用正常速度
		move_speed = normal_speed
		is_sprinting = false
	
	# 获取移动输入（WASD）
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	# 计算基于相机朝向的移动方向
	var move_direction: Vector3 = calculate_move_direction(input_dir)
	
	# 如果角色正在移动，旋转角色模型使其面向移动方向
	#if move_direction.length() > 0:
		#rotate_character_model(move_direction)
	
	# 应用移动速度
	if move_direction:
		# 如果有移动方向，应用移动速度
		velocity.x = move_direction.x * move_speed
		velocity.z = move_direction.z * move_speed
	else:
		# 如果没有移动方向，逐渐减速至停止
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
	
	

func _grap_swing(delta):
	
	# 检查是否到达抓钩点（距离小于1单位）
	var onGrapPoint = grapplePoint.distance_to(global_position) < 1

	# 计算抓钩方向：
	# 1. global_position.direction_to(grapplePoint) - 获取从角色位置指向抓钩点的单位向量
	# 2. abs(transform.basis.z) - 获取角色前方方向的绝对值（可能是为了某种特定效果）
	# 3. 将两者相乘得到最终的方向向量
	var direction = abs(transform.basis.z) * global_position.direction_to(grapplePoint) 

	# 应用抓钩摆动力：
	# 方向向量 * 速度 * 倍数 * 时间增量
	velocity += direction * move_speed * 7 * delta
	
	# 如果到达抓钩点
	if onGrapPoint:
		# 清除抓钩点
		grapplePoint = Vector3.ZERO
		# 通知枪节点移除抓钩线
		#gun.remove_line()

# ===== 输入映射设置说明 =====
# 在项目设置 > 输入映射中添加以下映射：
# - move_left: A键（向左移动）
# - move_right: D键（向右移动）
# - move_forward: W键（向前移动）
# - move_back: S键（向后移动）
# - jump: 空格键（跳跃）
# - sprint: Shift键（冲刺）
# - ui_cancel: ESC键（切换鼠标捕获模式）
