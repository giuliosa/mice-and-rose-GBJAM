extends KinematicBody2D

const JUMP_FORCE = 600
const MOVE_SPEED = 200
const GRAVITY = 50
const MAX_SPEED = 2000
const FRICTION_AIR = 0.85
const FRICTION_GROUND = 0.85
const CHAIN_PULL = 70

var velocity = Vector2(0,0)		# The velocity of the player (kept over time)
var chain_velocity := Vector2(0,0)
var can_jump := false			# Whether the player used their air-jump
var is_attacking := false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if event.pressed:
			# We prees the button -> shoot()
			$Chain.shoot($Position2D.position)
			is_attacking = true
	elif event.is_action_released("ui_cancel"):
		# We released the button -> release()
		$Chain.release()
		is_attacking = false

# This function is called every physics frame
func _physics_process(_delta: float) -> void:
	# Walking
	var walk = (Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")) * MOVE_SPEED
	
	if walk:
		$AnimationPlayer.play("Walk")
	else: 
		$AnimationPlayer.play("Idle")
	
	if is_attacking:
		$AnimationPlayer.play("Attack")
			
	
	# Handle position of aim
	if Input.is_action_pressed("ui_left") and Input.is_action_pressed("ui_up"):
		$Position2D.position.x = -16
		$Position2D.position.y = -16
		$Sprite.flip_h = true
		
	elif Input.is_action_pressed("ui_right") and Input.is_action_pressed("ui_up"):
		$Position2D.position.x = 16
		$Position2D.position.y = -16
		$Sprite.flip_h = false
		
	elif Input.is_action_pressed("ui_right"):
		$Position2D.position.x = 16
		$Position2D.position.y = 0
		$Sprite.flip_h = false
		
	elif Input.is_action_pressed("ui_up"):
		$Position2D.position.x = 0
		$Position2D.position.y = -16
		
	elif Input.is_action_pressed("ui_left"):
		$Position2D.position.x = -16
		$Position2D.position.y = 0
		$Sprite.flip_h = true

	# Falling
	velocity.y += GRAVITY

	# Hook physics
	if $Chain.hooked:
		# `to_local($Chain.tip).normalized()` is the direction that the chain is pulling
		chain_velocity = to_local($Chain.tip).normalized() * CHAIN_PULL
		if chain_velocity.y > 0:
			# Pulling down isn't as strong
			chain_velocity.y *= 0.55
		else:
			# Pulling up is stronger
			chain_velocity.y *= 1.65
		if sign(chain_velocity.x) != sign(walk):
			# if we are trying to walk in a different
			# direction than the chain is pulling
			# reduce its pull
			chain_velocity.x *= 0.7
	else:
		# Not hooked -> no chain velocity
		chain_velocity = Vector2(0,0)
	velocity += chain_velocity

	velocity.x += walk		# apply the walking
	move_and_slide(velocity, Vector2.UP)	# Actually apply all the forces
	velocity.x -= walk		# take away the walk speed again
	# ^ This is done so we don't build up walk speed over time

	# Manage friction and refresh jump and stuff
	velocity.y = clamp(velocity.y, -MAX_SPEED, MAX_SPEED)	# Make sure we are in our limits
	velocity.x = clamp(velocity.x, -MAX_SPEED, MAX_SPEED)
	var grounded = is_on_floor()
	if grounded:
		velocity.x *= FRICTION_GROUND	# Apply friction only on x (we are not moving on y anyway)
		can_jump = true 				# We refresh our air-jump
		if velocity.y >= 5:		# Keep the y-velocity small such that
			velocity.y = 5		# gravity doesn't make this number huge
	elif is_on_ceiling() and velocity.y <= -5:	# Same on ceilings
		velocity.y = -5

	# Apply air friction
	if !grounded:
		velocity.x *= FRICTION_AIR
		if velocity.y > 0:
			velocity.y *= FRICTION_AIR

	# Jumping
	if Input.is_action_just_pressed("ui_accept"):
		if grounded:
			velocity.y = -JUMP_FORCE	# Apply the jump-force
		elif can_jump:
			can_jump = false	# Used air-jump
			velocity.y = -JUMP_FORCE

