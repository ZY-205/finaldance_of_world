extends CharacterBody3D

# 节点引用
@onready var camera_3d = $Camera3D  # 主相机节点，用于玩家视角
@onready var ray_cast_3d: RayCast3D = $Camera3D/RayCast3D  # 射线检测节点，用于检测抓钩点
@onready var gun: CharacterBody3D = $Gun  # 抓钩枪节点，负责抓钩线的绘制和管理

# 常量定义
const SPEED = 5.0  # 角色移动速度
const JUMP_VELOCITY = 4.5  # 跳跃初速度
const CAMERA_SENS = 0.003  # 相机旋转灵敏度

# 从项目设置获取重力值（与物理引擎同步）
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# 抓钩点位置（Vector3.ZERO表示没有抓钩点）
var grapplePoint: Vector3 = Vector3.ZERO

func _ready():

	# 设置鼠标捕获模式（隐藏鼠标指针并锁定在窗口内）
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _input(event):

	# ESC键退出游戏
	if event.is_action_pressed("ui_cancel"): 
		get_tree().quit()
	
	# 鼠标移动事件 - 控制相机旋转
	if event is InputEventMouseMotion:
		# 水平旋转（绕Y轴）：根据鼠标X轴移动量更新水平角度
		rotation.y -= event.relative.x * CAMERA_SENS
		
		# 垂直旋转（绕X轴）：根据鼠标Y轴移动量更新垂直角度
		rotation.x -= event.relative.y * CAMERA_SENS
		
		# 限制垂直旋转角度（防止相机翻转）
		rotation.x = clamp(rotation.x, -0.5, 1.2)

func _physics_process(delta):

	# 抓钩系统逻辑
	# 当按下鼠标左键、射线检测到碰撞点且当前没有抓钩点时
	if Input.is_action_just_pressed("left_mouse_click") and ray_cast_3d.is_colliding() and not grapplePoint:
		# 获取抓钩点位置
		grapplePoint = ray_cast_3d.get_collision_point()
		# 通知枪节点发射抓钩线
		gun.shoot(grapplePoint)
	
	# 当按下鼠标左键且当前已有抓钩点时
	elif Input.is_action_just_pressed("left_mouse_click") and grapplePoint:
		# 清除抓钩点
		grapplePoint = Vector3.ZERO
		# 通知枪节点移除抓钩线
		gun.remove_line()
	
	# 根据抓钩状态选择移动模式
	if grapplePoint:
		# 抓钩摆动模式
		_grap_swing(delta)
	else:
		# 正常移动模式
		_movement(delta)

	# 应用物理移动
	move_and_slide()

func _movement(delta):

	# 重力处理：当角色不在地面上时应用重力
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 跳跃处理：当按下跳跃键且角色在地面上时应用跳跃力
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 获取输入方向（WASD）
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# 计算移动方向（基于角色当前朝向）
	# transform.basis 是角色的方向矩阵
	# Vector3(input_dir.x, 0, input_dir.y) 将2D输入转换为3D向量
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# 应用移动
	if direction:
		# 如果有输入方向，应用移动速度
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		# 如果没有输入方向，逐渐减速至停止
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
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
	velocity += direction * SPEED * 7 * delta
	
	# 如果到达抓钩点
	if onGrapPoint:
		# 清除抓钩点
		grapplePoint = Vector3.ZERO
		# 通知枪节点移除抓钩线
		gun.remove_line()
