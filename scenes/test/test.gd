extends Node3D

# 引力系统管理器脚本

const GRAVITATIONAL_CONSTANT = 0.06
const MIN_DISTANCE = 1.0

var gravitational_bodies: Array = []

func _ready():
	# 延迟一帧确保所有节点都已加载
	await get_tree().process_frame
	find_gravitational_bodies()

func find_gravitational_bodies():

	gravitational_bodies.clear()
	
	print("开始查找引力物体...")
	
	# 方法1：使用组查找
	var bodies_from_group = get_tree().get_nodes_in_group("gravitational")
	print("通过组查找到的物体数量: ", bodies_from_group.size())
	
	# 方法2：遍历所有节点手动检查
	var all_rigid_bodies = []
	var all_nodes = get_tree().get_nodes_in_group("gravitational")  # 获取所有节点
	print(all_nodes)
	for node in all_nodes:
		# 检查是否是 RigidBody3D
		if node is RigidBody3D:
			all_rigid_bodies.append(node)
			print("找到 RigidBody3D: ", node.name)
			
			# 检查是否在 gravitational 组中
			if node.is_in_group("gravitational"):
				print(" - 在 gravitational 组中")
				gravitational_bodies.append(node)
			else:
				print(" - 不在 gravitational 组中")
	
	print("所有 RigidBody3D 数量: ", all_rigid_bodies.size())
	print("最终引力物体数量: ", gravitational_bodies.size())
	
	# 如果没有找到任何引力物体，自动添加一些测试物体
	if gravitational_bodies.is_empty():
		print("警告: 未找到引力物体，创建测试物体...")
		#create_test_bodies()

func create_test_bodies():

	# 创建第一个物体
	var body1 = create_gravitational_body("TestBody1", 10.0, 1.0, Color.RED)
	body1.global_position = Vector3(-5, 0, 0)
	body1.add_to_group("gravitational")  # 确保添加到组
	
	# 创建第二个物体
	var body2 = create_gravitational_body("TestBody2", 5.0, 0.8, Color.BLUE)
	body2.global_position = Vector3(5, 0, 0)
	body2.add_to_group("gravitational")  # 确保添加到组
	
	# 重新查找引力物体
	find_gravitational_bodies()

func create_gravitational_body(name: String, mass: float, size: float, color: Color) -> RigidBody3D:

	var body = RigidBody3D.new()
	body.name = name
	body.mass = mass
	
	# 碰撞形状
	var collision = CollisionShape3D.new()
	collision.shape = SphereShape3D.new()
	collision.shape.radius = size
	body.add_child(collision)
	
	# 可视化网格
	var mesh = MeshInstance3D.new()
	mesh.mesh = SphereMesh.new()
	mesh.mesh.radius = size
	mesh.mesh.height = size * 2
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material_override = material
	
	body.add_child(mesh)
	
	add_child(body)
	return body

func _physics_process(delta):
	if gravitational_bodies.is_empty():
		# 如果没有引力物体，跳过计算
		return
	
	update_gravitational_forces(delta)

func update_gravitational_forces(delta):

	for i in range(gravitational_bodies.size()):
		var body1 = gravitational_bodies[i]
		
		for j in range(i + 1, gravitational_bodies.size()):
			var body2 = gravitational_bodies[j]
			apply_gravitational_force(body1, body2, delta)

func apply_gravitational_force(body1: RigidBody3D, body2: RigidBody3D, delta):

	var direction = body2.global_position - body1.global_position
	var distance = max(direction.length(), MIN_DISTANCE)
	
	var force_magnitude = GRAVITATIONAL_CONSTANT * body1.mass * body2.mass / (distance * distance)
	var force_direction = direction.normalized()
	
	body1.apply_central_force(force_direction * force_magnitude * delta)
	body2.apply_central_force(-force_direction * force_magnitude * delta)
