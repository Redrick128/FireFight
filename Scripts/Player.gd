class_name Player

extends CharacterBody3D

var speed
const WALK_SPEED = 4.0
const SPRINT_SPEED = 6.0
const JUMP_VELOCITY = 4.8
const SENSITIVITY = 0.004

#bob variables
const BOB_FREQ = 1.4
const BOB_AMP = 0.05
var t_bob = 0.0

#fov variables
const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 9.8

@onready var temp_fps_label: Label = $CanvasLayer/TEMP_FPS_LABEL

@onready var head = $Head
@onready var camera = $Head/Camera3D
@export var gun : Node3D

var p_Is_mouse_visible : bool = false

# gunz
@export var AmmoSpawn : Node3D
@export var BulletStorage : Node3D
const BULLET_SCENE = preload("uid://qgrnt48okjh7")
@export var AmmoCount : int = 5

@export var HandSlot : int = 0

# Melee
@export var MeleeWeapon : Node3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion and not p_Is_mouse_visible:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))


func _physics_process(delta):
	var FPS = Engine.get_frames_per_second()
	temp_fps_label.text = "FPS : " + str(FPS)
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("Space") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Handle Sprint.
	if Input.is_action_pressed("Shift"):
		speed = SPRINT_SPEED
		if Input.is_action_just_pressed("S") and speed == SPRINT_SPEED:
			print("tripped") # wil make next year - Redrick 11/29/2025 # Pagod ko next year naman - Redrick 1/19/2026
	else:
		speed = WALK_SPEED

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("A", "D", "W", "S")
	var direction = (head.transform.basis * transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
	
	# Head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	
	## FOV
	#var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	#var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	#camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	move_and_slide()
	
	
	if Input.is_action_just_pressed("Escape"):
		get_tree().quit()
		
	if Input.is_action_just_pressed("1"):
		p_Is_mouse_visible = !p_Is_mouse_visible  # flip the boolean
		Input.set_mouse_mode(
			Input.MOUSE_MODE_VISIBLE if p_Is_mouse_visible else Input.MOUSE_MODE_CAPTURED)
	
	if HandSlot == 0:
		gun.visible = true
		MeleeWeapon.visible = false
	elif HandSlot == 1:
		gun.visible = false
		MeleeWeapon.visible = true



func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

var cooldown = false  # script-level variable
var reload_cooldown = false

func shoot(): 
	if cooldown or AmmoCount <= 0:
		return  # stop shooting if on cooldown

	cooldown = true  # start cooldown
	
	if !AmmoCount == 0 or !AmmoCount <= 0:
		# Instantiate bullet
		var Bullet = BULLET_SCENE.instantiate()
		Bullet.global_transform = AmmoSpawn.global_transform
		Bullet.direction = -AmmoSpawn.global_transform.basis.z.normalized()
		BulletStorage.add_child(Bullet)

		# Play shooting sound
		var shooting_sound = gun.get_node("FiringSound")
		shooting_sound.play()
		
		AmmoCount = AmmoCount - 1
		print(AmmoCount)
		
	
	var GunTimer = 0.0
	var AnimationPlayerG = gun.get_node("InBuild/AnimationPlayer")
	var fired = false
	# This loop simulates non-blocking passage of time per frame
	while not fired:
		var delta = get_process_delta_time()  # time since last frame
		GunTimer += delta
		if GunTimer >= 0.8: 
			fired = true
			AnimationPlayerG.play("Fire01")
		# yield to let the engine run the next frame
		await get_tree().process_frame
		
	# Wait for cooldown duration
	await get_tree().create_timer(1.2).timeout
	cooldown = false  # end cooldown

func reload():
	if reload_cooldown or AmmoCount > 4:
		return  # stop shooting if on cooldown
	
	reload_cooldown = true  # start cooldown
	
	var Sound = gun.get_node("ReloadingSound")
	var AnimationPlayerG = gun.get_node("InBuild/AnimationPlayer")
	if AmmoCount < 5:
		Sound.play()
		AnimationPlayerG.play("Reload01")
		AmmoCount = 5
		# Wait for cooldown duration
		await get_tree().create_timer(2.0).timeout
		reload_cooldown = false  # end cooldown
	

# Pain incoming
# DA Health And player punishment system
## How much blood does the player have in their body. Yes its needed.
@export var PlayerBloodAmount : float = 5.7 # In liters yes its weird.

## BUFFER OF DOOOOM ##

func SwitchWeapon():
	if HandSlot == 1:
		HandSlot = 0
		print(HandSlot)
	else:
		HandSlot = 1
		print(HandSlot)

@warning_ignore("unused_parameter") # Yeah its annoying
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("2"):
		SwitchWeapon()
	
	if Input.is_action_just_pressed("LMB"):
		if HandSlot == 0:
			shoot()
		elif HandSlot == 1:
			print("meep")
	if Input.is_action_just_pressed("R"):
		if HandSlot == 0:
			reload()
