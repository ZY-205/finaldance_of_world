extends RigidBody3D

# 将此脚本附加到每个参与引力系统的RigidBody3D上

func _ready():
	# 添加到引力物体组
	add_to_group("gravitational")
	gravity_scale = 0.0
	
	# 设置物理属性
	#mass = 1000  # 质量 (kg)
	#physics_material_override = PhysicsMaterial.new()
	#physics_material_override.friction = 0.1
	#physics_material_override.bounce = 0
	#
	# 添加碰撞形状
	#var collision_shape = CollisionShape3D.new()
	#collision_shape.shape = SphereShape3D.new()
	#collision_shape.shape.radius = 1.0
	#add_child(collision_shape)
	
	# 添加可视化网格
	#var mesh = MeshInstance3D.new()
	#mesh.mesh = SphereMesh.new()
	#mesh.mesh.radius = 1.0
	#mesh.mesh.height = 2.0
	#add_child(mesh)
	
	# 初始随机速度 (可选)
	#linear_velocity = Vector3(
		#randf_range(-5, 5),
		#randf_range(-5, 5),
		#randf_range(-5, 5)
	#)
