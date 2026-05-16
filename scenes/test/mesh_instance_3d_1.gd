extends MeshInstance3D


func _ready() -> void:
	# 为体素模型创建专用材质
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.metallic = 0.1
	material.roughness = 0.8
	self.material_override = material


	# 为体素模型添加碰撞体
	self.create_trimesh_collision()
