extends SceneTree

func _initialize() -> void:
	var scene = load("res://main.tscn")
	if scene == null:
		printerr("FAIL: main scene missing")
		quit(1)
		return
	var ui = scene.instantiate()
	root.add_child.call_deferred(ui)
	verify.call_deferred(ui)

func verify(ui: Node) -> void:
	ui.game.reset(0)
	ui.screen = "title"
	assert(ui.screen == "title")
	ui.advance()
	assert(ui.screen == "tutorial")
	ui.advance()
	assert(ui.screen == "play")
	ui.choose(0)
	assert(ui.game.day == 2)
	var saved_file := ConfigFile.new()
	assert(saved_file.load("user://coral_save.cfg") == OK)
	var saved: Variant = saved_file.get_value("progress", "current", {})
	assert(saved is Dictionary and saved.get("day", 0) == 2)
	ui.game.health = 0
	ui.game.oxygen = 0
	ui.choose(0)
	assert(ui.screen == "result" and ui.game.status == "lost")
	ui.advance()
	assert(ui.screen == "title")
	ui.game.reset(53)
	ui.screen = "play"
	for action in [0, 0, 1, 1, 2, 2, 0]:
		ui.choose(action)
	assert(ui.screen == "result" and ui.game.status == "won")
	assert(ui.high_score == ui.game.health)
	assert(saved_file.load("user://coral_save.cfg") == OK)
	assert(saved_file.get_value("progress", "best_health", 0) == ui.high_score)
	assert(saved_file.get_value("progress", "current", null) == {})
	ui.advance()
	assert(ui.screen == "title" and ui.high_score > 0)
	var touch := InputEventScreenTouch.new()
	touch.position = Vector2(195, 608)
	touch.pressed = true
	var emulated_mouse := InputEventMouseButton.new()
	emulated_mouse.position = touch.position
	emulated_mouse.button_index = MOUSE_BUTTON_LEFT
	emulated_mouse.pressed = true
	ui._gui_input(touch)
	ui._gui_input(emulated_mouse)
	assert(ui.screen == "tutorial", "One touch must not also start a new play session")
	# Browser compatibility mouse presses can arrive after a frame or a transition.
	OS.delay_msec(320)
	ui._gui_input(emulated_mouse)
	assert(ui.screen == "tutorial", "Delayed compatibility mouse must not cross into play")
	# A distinct real desktop click remains usable immediately after a touch.
	emulated_mouse.position = Vector2(210, 655)
	ui._gui_input(emulated_mouse)
	assert(ui.screen == "play" and ui.game.day == 1, "Distinct desktop click starts play")
	touch.position = Vector2(75, 580)
	emulated_mouse.position = touch.position
	ui._gui_input(touch)
	assert(ui.game.day == 2)
	OS.delay_msec(320)
	ui._gui_input(emulated_mouse)
	assert(ui.game.day == 2, "Delayed compatibility mouse must not take a second day")
	OS.delay_msec(1000)
	ui._gui_input(emulated_mouse)
	assert(ui.game.day == 3, "Later deliberate desktop click must still act")
	OS.delay_msec(320)
	ui._gui_input(touch)
	assert(ui.game.day == 4, "A new touch at the same position must act even after a previous touch")
	ui._gui_input(emulated_mouse)
	assert(ui.game.day == 4, "The repeated touch's compatibility mouse must not act")
	ui.game.reset(53)
	ui.screen = "play"
	for key in [KEY_1, KEY_2, KEY_3]:
		var keyboard := InputEventKey.new()
		keyboard.keycode = key
		keyboard.pressed = true
		ui._unhandled_key_input(keyboard)
	assert(ui.game.day == 4, "Keyboard 1/2/3 must each advance one day")
	print("PASS: title → tutorial → play → failure/restart → seven-day victory/high score; touch/mouse dedup, repeated touch, desktop click, keyboard 1/2/3")
	ui.free()
	quit(0)
