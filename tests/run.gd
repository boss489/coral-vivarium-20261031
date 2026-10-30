extends SceneTree

const Model = preload("res://scripts/simulation.gd")
var failed := 0

func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)
	else:
		print("PASS: ", label)

func _initialize() -> void:
	var a = Model.new()
	a.reset(17)
	check(a.day == 1 and a.oxygen == 65 and a.pollution == 20 and a.hunger == 25 and a.health == 75, "initial state")
	var b = Model.new()
	b.reset(17)
	for action in [0, 1, 2, 0, 1, 2, 0]:
		a.act(action)
		b.act(action)
	check(a.snapshot() == b.snapshot(), "seed reproducibility")
	check(a.status != "playing", "seven actions finish")
	var c = Model.new()
	c.reset(3)
	check(not c.act(-1) and c.day == 1, "invalid action rejected")
	check(c.act(0) and c.day == 2, "one action advances a day")
	var d = Model.new()
	d.reset(4)
	d.oxygen = 2
	d.pollution = 90
	d.hunger = 90
	d.health = 5
	d.act(0)
	check(d.status == "lost", "critical condition loses")
	var e = Model.new()
	e.reset(11)
	e.oxygen = 98
	e.pollution = 1
	e.hunger = 1
	e.health = 100
	for action in [1, 2, 0, 1, 2, 0, 1]:
		e.act(action)
	check(e.status == "won" and e.day == 8, "healthy seven-day victory")
	var f = Model.new()
	f.reset(19)
	for action in [0, 1, 2]:
		f.act(action)
	var copy = Model.new()
	check(copy.restore(f.snapshot()) and copy.snapshot() == f.snapshot(), "save roundtrip")
	check(not copy.restore({"day": -10}), "corrupt save rejected")
	print("TOTAL FAILURES: ", failed)
	quit(0 if failed == 0 else 1)
