extends Node3D

# 物理常量
const GRAVITATIONAL_CONSTANT = 6.67430e-11  # 引力常数 (m³/kg/s²)
const SCALE_FACTOR = 1e-9  # 尺度缩放因子，避免数值过大

# 行星数据（已缩放）
var planets = [
	{
		"name": "Mercury", 
		"mass": 3.301e23 * SCALE_FACTOR, 
		"distance": 57.9e9 * SCALE_FACTOR, 
		"size": 2.440e6 * SCALE_FACTOR, 
		"color": Color(0.8, 0.8, 0.8)
	},
	{
		"name": "Venus", 
		"mass": 4.867e24 * SCALE_FACTOR, 
		"distance": 108.2e9 * SCALE_FACTOR, 
		"size": 6.052e6 * SCALE_FACTOR, 
		"color": Color(0.9, 0.7, 0.2)
	},
	{
		"name": "Earth", 
		"mass": 5.972e24 * SCALE_FACTOR, 
		"distance": 149.6e9 * SCALE_FACTOR, 
		"size": 6.371e6 * SCALE_FACTOR, 
		"color": Color(0.2, 0.4, 1.0)
	},
	{
		"name": "Mars", 
		"mass": 6.417e23 * SCALE_FACTOR, 
		"distance": 227.9e9 * SCALE_FACTOR, 
		"size": 3.390e6 * SCALE_FACTOR, 
		"color": Color(1.0, 0.3, 0.2)
	}
]

var sun: RigidBody3D
var gravitational_bodies: Array = []

func _ready():
	create_solar_system()
	setup_gravitational_system()

func create_solar_system():
	# 创建太阳
	sun = create_gravitational_body("Sun", 1.989e30 * SCALE_FACTOR, 6.957e8 * SCALE_FACTOR, Color(1, 0.8, 0))
	sun.global_position = Vector3.ZERO
	gravitational_bodies.append(sun)
	
	# 创建行星并设置初始轨道速度
	for planet_data in planets:
		var planet = create_gravitational_body(
			planet_data["name"], 
			planet_data["mass"], 
			planet_data["size"], 
			planet_data["color"]
		)
		planet.global_position = Vector3(planet_data["distance"], 0, 0)
		
		# 计算轨道速度 (v = √(G*M/r))
		var orbital_speed = sqrt(GRAVITATIONAL_CONSTANT * sun.mass / planet_data["distance"])
		planet.linear_velocity = Vector3(0, 0, orbital_speed)
		
		gravitational_bodies.append(planet)
		print("创建行星: ", planet_data["name"], " 轨道速度: ", orbital_speed)

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

func setup_gravitational_system():
	# 将所有天体添加到引力组
	for body in gravitational_bodies:
		body.add_to_group("gravitational")
	
	print("太阳系创建完成，天体数量: ", gravitational_bodies.size())

func _physics_process(delta):
	# 更新引力相互作用
	update_gravitational_forces(delta)

func update_gravitational_forces(delta):
	# 简化的引力更新（实际可能需要更复杂的N体问题求解）
	for i in range(gravitational_bodies.size()):
		var body1 = gravitational_bodies[i]
		for j in range(i + 1, gravitational_bodies.size()):
			var body2 = gravitational_bodies[j]
			apply_gravitational_force(body1, body2, delta)

func apply_gravitational_force(body1: RigidBody3D, body2: RigidBody3D, delta):
	var direction = body2.global_position - body1.global_position
	var distance = direction.length()
	
	# 避免除零错误
	if distance < 0.1:
		return
	
	var force_magnitude = GRAVITATIONAL_CONSTANT * body1.mass * body2.mass / (distance * distance)
	var force_direction = direction.normalized()
	
	body1.apply_central_force(force_direction * force_magnitude * delta)
	body2.apply_central_force(-force_direction * force_magnitude * delta)
