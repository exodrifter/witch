class_name ChatMessage
extends Control

@onready var blur: ColorRect = %Blur
@onready var label: Label = %Name
@onready var message: ChatMessageBody = %MessageBody

var destroy_requested: bool
var auto_alpha: AutoFloat
var auto_blur: AutoFloat

var image_cache: ImageCache:
	set(value):
		if image_cache != value:
			image_cache = value
			queue_redraw()

var message_data: GMessageData:
	set(value):
		if message_data != value:
			message_data = value
			queue_redraw()

func _ready() -> void:
	auto_alpha = AutoFloat.new(0, CriticalDampingMode.new(10))
	auto_alpha.desired = 1
	modulate.a = 0

	auto_blur = AutoFloat.new(0, CriticalDampingMode.new(10))
	auto_blur.desired = 3
	var shader: ShaderMaterial = blur.material
	shader.set_shader_parameter("lod", 0)

func _process(delta: float) -> void:
	modulate.a = auto_alpha.update(delta)

	var blur_amount := auto_blur.update(delta)
	var shader: ShaderMaterial = blur.material
	shader.set_shader_parameter("lod", blur_amount)

	if destroy_requested \
			and is_zero_approx(modulate.a) \
			and is_zero_approx(blur_amount):
		queue_free()

func _draw() -> void:
	message.image_cache = image_cache

	if is_instance_valid(message_data):
		label.text = message_data.chatter.name
		message.message = message_data.message

func _request_destroy() -> void:
	destroy_requested = true
	auto_alpha.desired = 0
	auto_blur.desired = 0
