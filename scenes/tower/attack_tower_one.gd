extends Node3D

# ========================
# 攻击参数配置
# ========================
@export var now_attack_range: float = 50.0
@export var now_attack_rate: float = 50.0      
@export var now_projectile_damage: float = 50.0
@export var is_used: bool = true

@export var attack_range: float = 10.0         # 攻击范围（单位：米）
@export var attack_rate: float = 1.0           # 攻击频率（每秒攻击次数）
@export var projectile_speed: float = 20.0      # 炮弹初速度（单位：米/秒）
@export var projectile_gravity: float = 9.8     # 重力加速度（单位：米/秒²）
@export var projectile_damage: int = 30         # 炮弹基础伤害值

@export var now_total_power: int = 0                # 当前功率

# ========================
# 目标管理变量
# ========================
var current_target: Node3D = null      # 当前锁定的目标敌人
var enemies_in_range: Array = []       # 在攻击范围内的敌人列表

# ========================
# 组件引用
# ========================
@onready var detection_area = $attack_range # 检测区域节点
#@onready var cannon_pivot = $CannonPivot                  # 炮管旋转节点
#@onready var muzzle = $CannonPivot/Muzzle                 # 炮弹发射点

# ========================
# 炮弹场景
# ========================
# 预加载抛物线炮弹场景
var projectile_scene = preload("res://scenes/tower/parabolic.tscn")

# ========================
# 初始化函数
# ========================
func _ready():
	now_projectile_damage = 50.0
	now_attack_rate = 50.0      
	now_attack_range = 50.0
	# 设置攻击计时器
	var attack_timer = Timer.new()
	attack_timer.wait_time = 1.0 / (attack_rate * now_attack_rate / 50.0)  # 计算每次攻击的间隔时间
	attack_timer.timeout.connect(_on_attack_timer_timeout)  # 连接超时信号
	add_child(attack_timer)  # 将计时器添加到场景树
	attack_timer.start()      # 启动计时器

# ========================
# 每帧处理函数
# ========================
func _physics_process(delta: float) -> void:
	if PlayerState.now_interactive_object == self:
		self.get_child(-1).wait_time = 1.0 / (attack_rate * now_attack_rate / 50.0)
		self.get_node("attack_range/attack_range/CollisionShape3D").shape.radius = (attack_range * now_attack_range / 50.0)
	
	now_total_power = (now_attack_range + now_attack_rate + now_projectile_damage) / 0.5 * 0.3 / 0.9
	
	# 更新目标（每帧检查是否有新目标）
	update_target()
	
	#if current_target:
		#print(current_target.global_position)
	
	# 旋转炮管朝向目标（当前注释掉了，可以取消注释启用）
	# if current_target:
	#     aim_at_target(current_target.global_position)

# ========================
# 目标管理函数
# ========================
func update_target():
	#"""
	#更新当前锁定的目标敌人
	#1. 清除无效目标
	#2. 如果没有目标，选择最近的敌人作为目标
	#"""
	
	# 过滤掉已销毁或无效的敌人
	enemies_in_range = enemies_in_range.filter(func(enemy): 
		return is_instance_valid(enemy) and enemy != null
	)
	
	# 如果没有目标或目标无效，尝试获取新目标
	if !current_target or !is_instance_valid(current_target) or !enemies_in_range.has(current_target):
		current_target = null
		
		# 如果有敌人在范围内，选择最近的敌人
		if enemies_in_range.size() > 0:
			var closest_enemy = null
			var closest_distance = INF  # 初始化为无限大
			
			# 遍历所有在范围内的敌人
			for enemy in enemies_in_range:
				# 计算敌人与塔的距离
				var distance = global_position.distance_to(enemy.global_position)
				
				# 如果距离更近，更新最近敌人
				if distance < closest_distance:
					closest_distance = distance
					closest_enemy = enemy
			
			# 设置最近敌人为目标
			current_target = closest_enemy

# ========================
# 抛物线计算函数
# ========================
func calculate_launch_angle(distance: float, height_diff: float) -> float:
	#"""
	#计算抛物线发射角度（弧度）
	#使用抛体运动公式：v² * sin²θ = g * (g * x² / (2 * v² * cos²θ) + y)
	#
	#参数:
		#distance: 水平距离（米）
		#height_diff: 高度差（米）
	#
	#返回:
		#发射角度（弧度）
	#"""
	
	var v = projectile_speed  # 炮弹初速度
	var g = projectile_gravity # 重力加速度
	var x = distance           # 水平距离
	var y = height_diff        # 高度差
	
	# 计算判别式：v⁴ - g(gx² + 2yv²)
	var discriminant = pow(v, 4) - g * (g * pow(x, 2) + 2 * y * pow(v, 2))
	
	# 如果判别式为负（无实数解），使用默认角度45度
	if discriminant < 0:
		return deg_to_rad(45)  # 转换为弧度
	
	# 计算平方根
	var root = sqrt(discriminant)
	
	# 计算两个可能的发射角度
	var angle1 = atan((pow(v, 2) + root) / (g * x))
	var angle2 = atan((pow(v, 2) - root) / (g * x))
	
	# 选择较小的角度（更平坦的轨迹）
	return min(angle1, angle2)

# ========================
# 攻击计时器回调函数
# ========================
func _on_attack_timer_timeout():
	#"""
	#攻击计时器超时时调用
	#如果有有效目标，发射炮弹
	#"""
	if current_target and is_instance_valid(current_target) and is_used:
		#print("attack")
		fire_projectile(current_target)

# ========================
# 发射炮弹函数
# ========================
func fire_projectile(target: Node3D):
	#print("try_attack")
	#"""
	#向目标发射抛物线炮弹
	#
	#参数:
		#target: 目标敌人节点
	#"""
	
	# 创建炮弹实例
	await get_tree().process_frame
	var projectile = projectile_scene.instantiate()
	#if projectile:
		#print("yes")
	#else:
		#print("no")
	# 设置炮弹初始位置为炮口位置
	#projectile.global_position = $Marker3D.global_position
	
	# 计算发射方向（从炮口指向目标）
	var direction = (target.global_position - $Marker3D.global_position).normalized()
	
	# 计算水平距离（忽略Y轴）
	var horizontal_distance = Vector2(
		target.global_position.x - $Marker3D.global_position.x,
		target.global_position.z - $Marker3D.global_position.z
	).length()
	
	# 计算高度差（目标Y坐标减去炮口Y坐标）
	var height_diff = target.global_position.y - $Marker3D.global_position.y
	
	# 计算发射角度
	var angle = calculate_launch_angle(horizontal_distance, height_diff)
	
	# 计算速度分量
	var horizontal_speed = projectile_speed * cos(angle)  # 水平速度分量
	var vertical_speed = projectile_speed * sin(angle)    # 垂直速度分量
	
	# 组合速度向量
	var velocity = Vector3(
		direction.x * horizontal_speed,  # X方向速度
		vertical_speed,                  # Y方向速度
		direction.z * horizontal_speed   # Z方向速度
	)
	
	# 设置炮弹初始速度和重力
	projectile.set_initial_velocity(velocity, projectile_gravity)
	
	# 设置炮弹目标
	projectile.set_target(target)
	
	# 设置炮弹伤害
	projectile.set_damage((projectile_damage * now_projectile_damage / 50.0))
	
	# 将炮弹添加到Projectiles节点下
	$Marker3D.add_child(projectile)

# ========================
# 区域检测回调函数
# ========================

# 敌人进入检测区域
func _on_detection_area_body_entered(body):
	#"""
	#当有物体进入检测区域时调用
	#
	#参数:
		#body: 进入区域的物体
	#"""
	
	# 检查是否是敌人且不在列表中
	if body.is_in_group("enemy") and not enemies_in_range.has(body):
		# 添加到敌人列表
		enemies_in_range.append(body)

# 敌人离开检测区域
func _on_detection_area_body_exited(body):
	#"""
	#当有物体离开检测区域时调用
	#
	#参数:
		#body: 离开区域的物体
	#"""
	
	# 如果物体在敌人列表中
	if enemies_in_range.has(body):
		# 从列表中移除
		enemies_in_range.erase(body)
		
		# 如果离开的是当前目标，清除当前目标
		if current_target == body:
			current_target = null


func _on_attack_range_body_entered(body: Node3D) -> void:
	#print("enter")
	#"""
	#当有物体进入检测区域时调用
	#
	#参数:
		#body: 进入区域的物体
	#"""
	
	# 检查是否是敌人且不在列表中
	if body.is_in_group("enemy") and not enemies_in_range.has(body):
		# 添加到敌人列表
		enemies_in_range.append(body)


func _on_attack_range_body_exited(body: Node3D) -> void:
	#print("exit")
	#"""
	#当有物体离开检测区域时调用
	#
	#参数:
		#body: 离开区域的物体
	#"""
	
	# 如果物体在敌人列表中
	if enemies_in_range.has(body):
		# 从列表中移除
		enemies_in_range.erase(body)
		
		# 如果离开的是当前目标，清除当前目标
		if current_target == body:
			current_target = null


func _on_area_3d_body_shape_entered(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	if body.is_in_group("player"):
		PlayerState.last_interactive_object = PlayerState.now_interactive_object
		PlayerState.now_interactive_object = self
