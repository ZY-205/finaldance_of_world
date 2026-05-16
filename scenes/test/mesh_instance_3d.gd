extends Node3D

# 高光材质
var highlight_material: StandardMaterial3D

func _ready():
	# 创建高光材质
	highlight_material = StandardMaterial3D.new()
	highlight_material.emission_enabled = true
	highlight_material.emission = Color(1, 1, 0.8)  # 淡黄色高光
	highlight_material.emission_energy = 0.3
	


func _on_area_3d_area_entered(area: Area3D) -> void:
	self.material_override = highlight_material


func _on_area_3d_area_exited(area: Area3D) -> void:
	self.material_override = null
