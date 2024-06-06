extends CharacterBody2D


class_name Player

signal points_scored(points: int)

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
enum PlayerMode {
	SMALL,
	BIG,
	SHOOTING
}

# On ready
const POINTS_LABEL_SCENE = preload("res://Scenes/points_label.tscn")


# References
@onready var body_collision_shape = $BodyCollisionShape
@onready var area_collision_shape = $Area2D/AreaCollisionShape
@onready var animated_sprite_2d = $AnimatedSprite2D as PlayerAnimatedSprite
@onready var area_2d = $Area2D

@export_group("Locomotion")
@export var run_speed_damping = 0.5
@export var speed = 100.0
@export var jump_velocity = -350
@export_group("")


@export_group("Stomping enemies")
@export var min_stomp_degree = 35
@export var max_stomp_degree = 145
@export var stomp_y_velocity = -150
@export_group("")

var player_mode = PlayerMode.SMALL

# state flags for Player
var is_dead = false

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
		
	# handle jumps
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5
	
	# handle movement axis
	var direction = Input.get_axis("left", "right")
	
	if direction:
		#linear interpolation based on the value of the weight 
		velocity.x = lerpf(velocity.x, speed * direction, run_speed_damping * delta)
		
	else:
		velocity.x = move_toward(velocity.x, 0, speed * delta)
		
	animated_sprite_2d.trigger_animation(velocity, direction, player_mode)
	
	move_and_slide()
		


func _on_area_2d_area_entered(area):
	
	if area is Enemy:
		handle_enemy_collision(area)	



func handle_enemy_collision(enemy: Enemy):
	if enemy == null and is_dead:
		return
	var level_manager = get_tree().get_first_node_in_group("level_manager")
	if is_instance_of(enemy, Koopa) and (enemy as Koopa).in_a_shell:
		(enemy as Koopa).on_stomp(global_position)
		spawn_points_label(enemy)
		#level_manager.on_points_scored(100)
	else:
		var angle_of_collision = rad_to_deg(position.angle_to_point(enemy.position))
		
		if angle_of_collision > min_stomp_degree && max_stomp_degree > angle_of_collision:
			enemy.die()
			on_enemy_stomped()
			spawn_points_label(enemy)
			#level_manager.on_points_scored(100)
		else:
			die()
	
func spawn_points_label(enemy):
	var points_label = POINTS_LABEL_SCENE.instantiate()
	points_label.position = enemy.position + Vector2(-20, -20)
	get_tree().root.add_child(points_label)
	
	if(!is_dead):	
		points_scored.emit(100)

func on_enemy_stomped():
	velocity.y = stomp_y_velocity
	
func die():
	if player_mode == PlayerMode.SMALL:
		is_dead = true
		animated_sprite_2d.play("death")

		area_2d.set_collision_mask_value(3, false)
		set_collision_layer_value(1, false)

		set_physics_process(false)
		
		var death_tween = get_tree().create_tween()
		death_tween.tween_property(self, "position", position  + Vector2(0, -48), 0.5)
		death_tween.chain().tween_property(self, "position", position + Vector2(0, 256), 1)
		death_tween.tween_callback(func (): get_tree().reload_current_scene())
		
	else:
		#big_to_small()
		print("died")
