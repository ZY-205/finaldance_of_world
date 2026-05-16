extends RigidBody3D

# 炮弹参数
var initial_velocity: Vector3 = Vector3.ZERO
var gravity: float = 9.8
var damage: int = 30
var target: Node3D = null
var launch_time: float = 0.0

# 组件引用
#@onready var trail_particles = $TrailParticles
#@onready var explosion_particles = $ExplosionParticles

func _ready():
	print("already")
	await get_tree().create_timer(0.1).timeout
	# 初始设置
	gravity_scale = 0.0  # 禁用内置重力
	contact_monitor = true
	max_contacts_reported = 1
	#body_entered.connect(_on_body_entered)
	
	# 应用初始速度
	linear_velocity = initial_velocity
	#print(linear_velocity)
	# 开始粒子效果
	#trail_particles.emitting = true
	launch_time = Time.get_ticks_msec()

func _physics_process(delta):
	# 应用自定义重力
	apply_central_force(Vector3(0, -gravity * mass, 0))
	
	# 检查超时（避免炮弹永远存在）
	#if Time.get_ticks_msec() - launch_time > 10000:  # 10秒后消失
		#explode()

func set_initial_velocity(velocity: Vector3, grav: float):
	#print("set_initial_velocity")
	initial_velocity = velocity
	gravity = grav

func set_target(t: Node3D):
	#print("set_target")
	target = t

func set_damage(dmg: int):
	#print("set_damage")
	damage = dmg

#func _on_body_entered(body):
	## 命中目标


func explode():
	# 停止轨迹粒子
	#trail_particles.emitting = false
	#
	## 播放爆炸粒子
	#explosion_particles.emitting = true
	#explosion_particles.global_position = global_position
	#
	## 分离粒子系统
	#remove_child(explosion_particles)
	#get_parent().add_child(explosion_particles)
	
	# 销毁炮弹
	#print("die")
	self.queue_free()
	
	# 可选：添加爆炸伤害区域
	#create_explosion_area()

#func create_explosion_area():
	#var explosion_area = Area3D.new()
	#explosion_area.global_position = global_position
	#
	#var collision_shape = CollisionShape3D.new()
	#collision_shape.shape = SphereShape3D.new()
	#collision_shape.shape.radius = 3.0
	#explosion_area.add_child(collision_shape)
	
	#get_parent().add_child(explosion_area)
	#
	## 连接信号
	#explosion_area.body_entered.connect(_on_explosion_body_entered.bind(explosion_area))
	#
	## 设置定时销毁
	#var timer = Timer.new()
	#timer.wait_time = 0.5
	#timer.one_shot = true
	#timer.timeout.connect(explosion_area.queue_free)
	#explosion_area.add_child(timer)
	#timer.start()

func _on_explosion_body_entered(body, area: Area3D):
	if body.is_in_group("enemiy") and body.has_method("take_damage"):
		# 距离衰减伤害
		var distance = body.global_position.distance_to(area.global_position)
		var damage_multiplier = max(0, 1.0 - distance / 3.0)
		body.take_damage(damage * damage_multiplier)


func _on_area_3d_body_shape_entered(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	await get_tree().process_frame
	#print("die")
	
	# 爆炸效果
	explode()


func _on_area_3d_2_body_entered(body: Node3D) -> void:
	if body == target and body.is_in_group("enemy"):
		# 应用伤害
		if body.has_method("take_damage"):
			body.take_damage(damage)
