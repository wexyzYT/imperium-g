extends Camera2D

# Map dimensions
@export var map_width := 1152.0
@export var map_height := 648.0

# Camera settings
@export var speed := 800.0
@export var min_zoom := 1.0
@export var max_zoom := 3.0
@export var zoom_increment := 0.1
var dragging := false
var current_zoom_level := 1.0

func _ready():
	# Set as current camera
	make_current()
	
	# Initialize zoom to fit map
	var viewport_size = get_viewport_rect().size
	var zoom_x = viewport_size.x / map_width
	var zoom_y = viewport_size.y / map_height
	current_zoom_level = max(1.0, min(zoom_x, zoom_y))
	zoom = Vector2(current_zoom_level, current_zoom_level)
	
	# Center camera
	position = Vector2(map_width / 2, map_height / 2)
	
	# Set initial limits
	update_camera_limits()
	get_viewport().size_changed.connect(update_camera_limits)

func _process(delta):
	# Handle keyboard movement
	var input = Vector2.ZERO
	if Input.is_action_pressed("ui_right"): input.x += 1
	if Input.is_action_pressed("ui_left"): input.x -= 1
	if Input.is_action_pressed("ui_down"): input.y += 1
	if Input.is_action_pressed("ui_up"): input.y -= 1
	if input != Vector2.ZERO:
		var move = input.normalized() * (speed / current_zoom_level) * delta
		update_position(position + move)

func _unhandled_input(event):
	# Handle mouse input
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			update_zoom(zoom_increment, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			update_zoom(-zoom_increment, event.position)
	elif event is InputEventMouseMotion and dragging:
		var drag_offset = event.relative / current_zoom_level
		update_position(position - drag_offset)

func update_position(new_position: Vector2):
	# Apply position and clamp
	var viewport_size = get_viewport_rect().size
	var visible_width = viewport_size.x / current_zoom_level
	var visible_height = viewport_size.y / current_zoom_level
	var half_w = visible_width / 2.0
	var half_h = visible_height / 2.0
	
	# Clamp position to allow half viewport beyond map edges
	position.x = clamp(new_position.x, -half_w, map_width + half_w)
	position.y = clamp(new_position.y, -half_h, map_height + half_h)

func update_zoom(incr: float, zoom_anchor: Vector2):
	var old_zoom = current_zoom_level
	current_zoom_level = clamp(current_zoom_level + incr, min_zoom, max_zoom)
	
	if old_zoom == current_zoom_level:
		return
	
	# Adjust position for mouse-centered zoom
	var viewport_size = get_viewport_rect().size
	var mouse_world_before = (zoom_anchor - viewport_size / 2) / old_zoom + position
	var mouse_world_after = (zoom_anchor - viewport_size / 2) / current_zoom_level + position
	var new_position = position + (mouse_world_before - mouse_world_after)
	
	# Apply zoom and update position
	zoom = Vector2(current_zoom_level, current_zoom_level)
	update_position(new_position)
	update_camera_limits()

func update_camera_limits():
        var viewport_size = get_viewport_rect().size
        var visible_width = viewport_size.x / current_zoom_level
        var visible_height = viewport_size.y / current_zoom_level
        var half_w = visible_width / 2.0
        var half_h = visible_height / 2.0

        # Set camera limits
        limit_left = -half_w
        limit_right = map_width + half_w
        limit_top = -half_h
        limit_bottom = map_height + half_h

        # Clamp current position against the new limits
        update_position(position)
