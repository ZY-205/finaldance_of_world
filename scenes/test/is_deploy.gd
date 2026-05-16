extends Node3D
# 塔防游戏塔放置系统
# 本脚本负责管理游戏中防御塔的放置机制，包括预览、放置位置验证和实际创建

# 网格大小配置
@onready var ray_cast = RayCast3D.new()
const GRID_RANGE = 20   # 网格范围（单元格数量） - 增加这个值来扩大网格
const GRID_SIZE = 2.0  # 网格单元格大小（单位：米）
const GRID_HEIGHT = 0.1 # 网格可视化高度（略高于地面）

# 放置状态枚举
enum PlacementState {
	IDLE,    # 空闲状态（未放置塔）
	PLACING, # 正在放置塔（预览有效位置）
	INVALID  # 放置位置无效
}
var current_state = PlacementState.IDLE  # 当前放置状态

#var is_deploy = false  # 当前是否有网格

# 当前要放置的塔类型
var current_tower_type = null  # 当前选择的塔类型（字符串标识）
var preview_tower = null       # 预览塔的实例
#var grid_material = preload("res://materials/grid_material.tres")  # 网格材质

# 路径区域（不可放置塔的区域）
var path_areas = []  # 存储AABB（轴对齐边界框）表示不可放置区域

func _ready():
	await get_tree().process_frame
	# 场景初始化时调用
	create_grid_visualization()
	show_grid_visualization()
	
	# 示例：定义一些路径区域（在实际游戏中应该从场景中获取）
	# 第一个路径区域：从(-10,0,-2)开始，尺寸为(20,0.1,4)
	path_areas.append(AABB(Vector3(-10, 0, -2), Vector3(20, 0.1, 4)))
	# 第二个路径区域：从(5,0,5)开始，尺寸为(4,0.1,10)
	path_areas.append(AABB(Vector3(5, 0, 5), Vector3(4, 0.1, 10)))
	
	#print(path_areas)

func _input(event):
	if event.is_action_pressed("deploy") and !PlayerState.is_deploy:
		# 创建网格可视化
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		$"..".transition_cameras($"../Player/SpringArm3D/Camera3D",$"../Camera3D")
		show_grid_visualization()
		PlayerState.is_deploy = !PlayerState.is_deploy
	elif event.is_action_pressed("deploy") and PlayerState.is_deploy:
		# 删除网格可视化
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		$"..".transition_cameras($"../Camera3D",$"../Player/SpringArm3D/Camera3D")
		hide_grid_visualization()
		PlayerState.is_deploy = !PlayerState.is_deploy
	
	# 处理输入事件
	if event is InputEventMouseButton and event.pressed and PlayerState.is_deploy:
		# 鼠标左键点击
		if event.button_index == MOUSE_BUTTON_LEFT:
			# 如果当前处于放置状态，尝试放置塔
			if current_state == PlacementState.PLACING:
				try_place_tower()
		
		# 鼠标右键点击 - 取消放置
		if event.button_index == MOUSE_BUTTON_RIGHT:
			cancel_placement()
	
	# 键盘按键处理 - 切换塔类型
	if event is InputEventKey and event.pressed and PlayerState.is_deploy:
		# 按1键选择基础塔
		if event.keycode == KEY_1:
			start_placement("basic_tower")
		# 按2键选择炮塔
		elif event.keycode == KEY_2:
			start_placement("cannon_tower")

func _physics_process(delta: float) -> void:
	# 每帧更新
	# 如果当前处于放置状态，更新预览塔位置
	if current_state == PlacementState.PLACING or current_state == PlacementState.INVALID:
		update_preview_position()

# 开始放置新塔
func start_placement(tower_type: String):
	#"""
	#开始放置新塔
	#参数:
		#tower_type: 塔类型标识符
	#"""
	# 如果已经在放置状态，先取消当前放置
	if current_state == PlacementState.PLACING or current_state == PlacementState.INVALID:
		cancel_placement()
	
	# 设置当前塔类型和状态
	current_tower_type = tower_type
	current_state = PlacementState.PLACING
	
	# 创建预览塔
	preview_tower = create_tower_preview(tower_type)
	add_child(preview_tower)
	
	# 更新预览位置
	update_preview_position()

# 取消放置
func cancel_placement():
	#"""取消当前放置操作"""
	# 如果存在预览塔，销毁它
	if preview_tower:
		preview_tower.queue_free()
		preview_tower = null
	
	# 重置状态
	current_state = PlacementState.IDLE
	current_tower_type = null

# 尝试放置塔
func try_place_tower():
	#"""尝试在当前位置放置塔"""
	# 检查位置是否有效
	if !is_valid_placement():
		return
	
	# 创建实际的塔
	var new_tower = create_actual_tower(current_tower_type)
	# 设置新塔的位置为预览塔的位置
	new_tower.global_transform = preview_tower.global_transform
	add_child(new_tower)
	
	# 重置放置状态
	cancel_placement()

# 更新预览位置
func update_preview_position():
	#"""根据鼠标位置更新预览塔的位置"""
	# 获取鼠标位置
	var mouse_pos = get_viewport().get_mouse_position()
	# 获取当前相机
	var camera = get_viewport().get_camera_3d()
	var ray_length = 10000  # 射线长度
	
	# 创建从相机发出的射线
	var from = camera.project_ray_origin(mouse_pos)  # 射线起点
	var to = from + camera.project_ray_normal(mouse_pos) * ray_length  # 射线终点
	
	# 进行射线检测
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true  # 与区域碰撞
	query.collision_mask = 2  # 地面层（碰撞层掩码）
	
	var result = space_state.intersect_ray(query)
	
	if result:
		# 将位置对齐到网格
		var grid_pos = snap_to_grid(result.position)
		
		# 更新预览塔位置
		preview_tower.global_position = grid_pos
		
		# 检查位置是否有效并更新状态和颜色
		if is_valid_placement():
			# 有效位置 - 绿色半透明
			set_preview_color(Color(0, 1, 0, 0.5))
			current_state = PlacementState.PLACING
		else:
			# 无效位置 - 红色半透明
			set_preview_color(Color(1, 0, 0, 0.5))
			current_state = PlacementState.INVALID

# 将位置对齐到网格
func snap_to_grid(position: Vector3) -> Vector3:
	#"""
	#将位置对齐到最近的网格点
	#参数:
		#position: 原始位置
	#返回:
		#对齐到网格后的位置
	#"""
	# 将X和Z坐标对齐到网格
	var x = snapped(position.x, GRID_SIZE)
	var z = snapped(position.z, GRID_SIZE)
	
	# 使用射线检测获取地面的实际高度
	var space_state = get_world_3d().direct_space_state
	var from = Vector3(x, position.y + 10, z)  # 起点（高于地面）
	var to = Vector3(x, position.y - 10, z)    # 终点（低于地面）
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 2   # 地面层
	
	# 执行射线检测
	var result = space_state.intersect_ray(query)
	if result:
		# 返回对齐到网格的地面位置
		return Vector3(x, result.position.y, z)
	
	# 如果没有检测到地面，返回原始位置的网格对齐版本
	return Vector3(x, position.y, z)

func is_valid_placement() -> bool:
	if !preview_tower:
		return false
	
	# 检查是否在路径上（不可放置区域）
	for area in path_areas:
		if area.has_point(preview_tower.global_position):
			return false
	
	# 检查是否与其他塔重叠
	var towers = get_tree().get_nodes_in_group("towers")  # 获取所有已放置的塔
	for tower in towers:
		# 如果与现有塔距离小于网格尺寸的90%，则认为重叠
		if tower.global_position.distance_to(preview_tower.global_position) < GRID_SIZE * 0.9:
			return false
	
	# 新增：检查特定碰撞层
	if !is_valid_collision_layer(preview_tower.global_position):
		return false
	
	return true

func is_valid_collision_layer(position: Vector3) -> bool:
	var space_state = get_world_3d().direct_space_state
	
	# 方法1: 使用射线检测
	var from = position + Vector3(0, 10, 0)  # 从上方开始
	var to = position - Vector3(0, 20, 0)    # 向下检测
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 0xFFFFFFFF  # 检测所有层
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	
	if result:
		# 检查碰撞对象的层
		var collider = result.collider
		if collider is CollisionObject3D:
			# 检查是否在禁止建造的层上
			if collider.collision_layer == 8:
				return false
			# 检查是否在允许建造的层上
			if collider.collision_layer != 2:
				return false
	else:
		# 如果没有检测到任何碰撞，可能是在空中，不允许建造
		return false
	
	return true

# 设置预览塔颜色
func set_preview_color(color: Color):
	#"""
	#设置预览塔的颜色
	#参数:
		#color: 要设置的颜色
	#"""
	if preview_tower:
		# 获取预览塔的材质
		var material = preview_tower.get_surface_override_material(0)
		if material:
			# 设置材质的颜色
			material.albedo_color = color

#

func create_grid_visualization():
	
	# 使用 GRID_RANGE 变量控制网格范围
	var grid_mesh = ArrayMesh.new()  # 创建新的网格
	var vertices = PackedVector3Array()  # 顶点数组
	
	# 获取物理空间状态
	var space_state = get_world_3d().direct_space_state
	
	# 细分参数 - 控制每条线的细分点数
	var subdivisions = 20  # 每条线细分成20段
	
	# 创建垂直的线（X轴方向，固定X，变化Z）
	for i in range(-GRID_RANGE, GRID_RANGE + 1):
		var x = i * GRID_SIZE + 0.55
		
		# 创建细分点
		for j in range(-GRID_RANGE, GRID_RANGE):
			# 计算Z坐标范围
			var z_start = j * GRID_SIZE
			var z_end = (j + 1) * GRID_SIZE
			
			# 在Z方向细分
			for k in range(0, subdivisions):
				# 计算细分点的Z坐标
				var z_current = z_start + (k * GRID_SIZE) / subdivisions
				var z_next = z_start + ((k + 1) * GRID_SIZE) / subdivisions
				
				# 获取细分点的地面高度
				var height_current = get_ground_height(Vector3(x, 0, z_current), space_state)
				var height_next = get_ground_height(Vector3(x, 0, z_next), space_state)
				
				# 添加垂直方向的线段（固定X，变化Z）
				vertices.push_back(Vector3(x, height_current, z_current))
				vertices.push_back(Vector3(x, height_next, z_next))
	
	# 创建水平的线（Z轴方向，固定Z，变化X）
	for j in range(-GRID_RANGE, GRID_RANGE + 1):
		var z = j * GRID_SIZE + 0.55
		
		# 创建细分点
		for i in range(-GRID_RANGE, GRID_RANGE):
			# 计算X坐标范围
			var x_start = i * GRID_SIZE
			var x_end = (i + 1) * GRID_SIZE
			
			# 在X方向细分
			for k in range(0, subdivisions):
				# 计算细分点的X坐标
				var x_current = x_start + (k * GRID_SIZE) / subdivisions
				var x_next = x_start + ((k + 1) * GRID_SIZE) / subdivisions
				
				# 获取细分点的地面高度
				var height_current = get_ground_height(Vector3(x_current, 0, z), space_state)
				var height_next = get_ground_height(Vector3(x_next, 0, z), space_state)
				
				# 添加水平方向的线段（固定Z，变化X）
				vertices.push_back(Vector3(x_current, height_current, z))
				vertices.push_back(Vector3(x_next, height_next, z))
	
	# 创建网格数据
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	
	# 添加表面到网格（使用线条图元）
	grid_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	
	# 创建网格实例
	var grid_node = MeshInstance3D.new()
	grid_node.mesh = grid_mesh
	
	# 创建网格材质
	var grid_material = StandardMaterial3D.new()
	grid_material.albedo_color = Color(1, 1, 1, 0.3)  # 白色半透明
	grid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	grid_material.flags_unshaded = true  # 不受光照影响
	
	grid_node.set_surface_override_material(0, grid_material)
	add_child(grid_node)
	
	return grid_node

func get_ground_height(position: Vector3, space_state: PhysicsDirectSpaceState3D) -> float:
	
	# 从高处向下发射射线检测地面
	var from = position + Vector3(0, 1000, 0)  # 从100单位高处开始
	var to = position - Vector3(0, 1000, 0)    # 向下100单位
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 2  # 地面层（根据您的项目设置调整）
	
	var result = space_state.intersect_ray(query)
	#print(result)
	if result:
		# 返回碰撞点的Y坐标
		#print(111)
		return result.position.y+0.01
		
	else:
		#print(222)
		# 如果没有检测到地面，返回默认高度
		return position.y+0.01


func show_grid_visualization():
	get_children()[0].show()

func hide_grid_visualization():
	get_children()[0].hide()


# 创建预览塔（使用半透明材质）
func create_tower_preview(tower_type: String) -> MeshInstance3D:
	#"""
	#创建预览塔（半透明）
	#参数:
		#tower_type: 塔类型标识符
	#返回:
		#MeshInstance3D: 预览塔的网格实例
	#"""
	var tower_mesh = null  # 塔的网格
	
	# 根据塔类型创建不同的预览模型
	match tower_type:
		"basic_tower":
			# 基础塔 - 圆柱体
			var cylinder = CylinderMesh.new()
			cylinder.top_radius = 0.5    # 顶部半径
			cylinder.bottom_radius = 0.8  # 底部半径
			cylinder.height = 2.0         # 高度
			tower_mesh = cylinder
		"cannon_tower":
			# 炮塔 - 球体
			var sphere = SphereMesh.new()
			sphere.radius = 0.8   # 半径
			sphere.height = 1.6    # 高度
			tower_mesh = sphere
		_:
			# 默认塔 - 立方体
			var box = BoxMesh.new()
			box.size = Vector3(1.5, 2.0, 1.5)  # 尺寸
			tower_mesh = box
	
	# 创建网格实例
	var preview = MeshInstance3D.new()
	preview.mesh = tower_mesh
	
	# 创建半透明材质
	var material = StandardMaterial3D.new()
	material.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA  # 启用透明度
	material.albedo_color = Color(0, 1, 0, 0.5)  # 初始绿色半透明
	preview.set_surface_override_material(0, material)  # 应用材质
	
	return preview

# 创建实际的塔
func create_actual_tower(tower_type: String) -> Node3D:
	#"""
	#创建实际的塔（可交互）
	#参数:
		#tower_type: 塔类型标识符
	#返回:
		#Node3D: 塔的根节点
	#"""
	# 创建塔根节点
	var tower = Node3D.new()
	
	# 添加网格
	var mesh_instance #= create_tower_preview(tower_type).duplicate()  # 复制预览塔
	# 设置材质为不透明
	#mesh_instance.get_surface_override_material(0).albedo_color.a = 1.0
	mesh_instance = preload("res://scenes/tower/attack_tower_one.tscn")
	mesh_instance = mesh_instance.instantiate()
	tower.add_child(mesh_instance)
	
	# 添加碰撞体
	var collision = CollisionShape3D.new()
	var shape = CylinderShape3D.new()  # 圆柱形碰撞体
	shape.radius = 0.8  # 半径
	shape.height = 2.0   # 高度
	collision.shape = shape
	tower.add_child(collision)
	
	# 添加到塔组（用于后续查找和碰撞检测）
	tower.add_to_group("towers")
	
	return tower
