extends Control

@onready var attack_speed_number: Label = $VBoxContainer/attack_speed/attack_speed_number
@onready var attack_speed_h_slider: HSlider = $VBoxContainer/attack_speed/HSlider
@onready var attack_range_number: Label = $VBoxContainer/attack_range/attack_range_number
@onready var attack_range_h_slider: HSlider = $VBoxContainer/attack_range/HSlider
@onready var damage_multiplier_number: Label = $VBoxContainer/damage_multiplier/damage_multiplier_number
@onready var damage_multiplier_h_slider: HSlider = $VBoxContainer/damage_multiplier/HSlider
@onready var total_power_number: Label = $VBoxContainer/total_power/total_power_number
@onready var check_button: CheckButton = $VBoxContainer/is_used/CheckButton


func _physics_process(delta: float) -> void:
	#print(PlayerState.now_interactive_object)
	if PlayerState.last_interactive_object != PlayerState.now_interactive_object and PlayerState.last_interactive_object != null:
		attack_speed_h_slider.value = PlayerState.now_interactive_object.now_attack_rate
		attack_range_h_slider.value  = PlayerState.now_interactive_object.now_attack_range
		damage_multiplier_h_slider.value  = PlayerState.now_interactive_object.now_projectile_damage
		check_button.button_pressed =  PlayerState.now_interactive_object.is_used
		PlayerState.last_interactive_object = null
		
	if PlayerState.now_interactive_object:
		PlayerState.now_interactive_object.now_attack_rate = attack_speed_h_slider.value
		PlayerState.now_interactive_object.now_attack_range = attack_range_h_slider.value
		PlayerState.now_interactive_object.now_projectile_damage = damage_multiplier_h_slider.value
		PlayerState.now_interactive_object.is_used = check_button.button_pressed
		
		attack_speed_number.text = "攻击速度:" + str(PlayerState.now_interactive_object.now_attack_rate)
		attack_range_number.text = "攻击范围:" + str(PlayerState.now_interactive_object.now_attack_range)
		damage_multiplier_number.text = "伤害倍率:" + str(PlayerState.now_interactive_object.now_projectile_damage)
		total_power_number.text = "总功率:" + str(PlayerState.now_interactive_object.now_total_power)
