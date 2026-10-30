extends Control

const Model = preload("res://scripts/simulation.gd")
const FONT = preload("res://assets/NanumGothic-Regular.ttf")
const CHIME = preload("res://assets/chime.wav")
const NAVY = Color("102538")
const DEEP = Color("143d54")
const TEAL = Color("1c6271")
const CREAM = Color("f4e9c9")
const CYAN = Color("95dbd4")
const CORAL = Color("ff907a")
const LIME = Color("b9d986")
const MUTED = Color("a7c8c8")
const SAVE_PATH = "user://coral_save.cfg"

var game = Model.new()
var screen := "title"
var high_score := 0
var runs := 0
var elapsed := 0.0
var hover := -1
var last_touch_msec := -1000
var last_touch_position := Vector2.INF
var audio: AudioStreamPlayer

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	audio = AudioStreamPlayer.new()
	audio.stream = CHIME
	audio.volume_db = -16
	add_child(audio)
	var file := ConfigFile.new()
	if file.load(SAVE_PATH) == OK:
		high_score = clampi(int(file.get_value("progress", "best_health", 0)), 0, 100)
		runs = maxi(0, int(file.get_value("progress", "runs", 0)))
		var saved: Variant = file.get_value("progress", "current", {})
		if saved is Dictionary and game.restore(saved) and game.status == "playing":
			screen = "title"
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _save() -> void:
	var file := ConfigFile.new()
	file.set_value("progress", "best_health", high_score)
	file.set_value("progress", "runs", runs)
	file.set_value("progress", "current", game.snapshot() if game.status == "playing" and game.day > 1 else {})
	file.save(SAVE_PATH)

func advance() -> void:
	if screen == "title":
		if game.day > 1 and game.status == "playing":
			screen = "play"
		else:
			screen = "tutorial"
	elif screen == "tutorial":
		runs += 1
		game.reset(runs * 23 + 7)
		screen = "play"
		_save()
	elif screen == "result":
		game.reset(0)
		screen = "title"
		_save()
	queue_redraw()

func choose(which: int) -> void:
	if screen != "play" or not game.act(which):
		return
	if audio: audio.play()
	if game.status != "playing":
		screen = "result"
		if game.status == "won": high_score = maxi(high_score, game.health)
	_save()
	queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: choose(0)
			KEY_2: choose(1)
			KEY_3: choose(2)
			KEY_ENTER, KEY_SPACE: advance()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		last_touch_msec = Time.get_ticks_msec()
		last_touch_position = event.position
		_tap(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# On Web, a touch can generate a delayed compatibility mouse press.
		# Only discard a recent press at the same point; a real desktop click
		# elsewhere and every new touch still have their own action.
		if Time.get_ticks_msec() - last_touch_msec < 1000 and event.position.distance_to(last_touch_position) < 14.0:
			return
		_tap(event.position)

func _tap(p: Vector2) -> void:
	if screen == "play":
		if p.y >= 526 and p.y <= 654 and p.x >= 20 and p.x <= 370:
			choose(clampi(int((p.x - 20) / 118), 0, 2))
	else:
		if p.y > 475: advance()

func _label(text: String, x: float, y: float, size: int, color: Color = CREAM, center: bool = false) -> void:
	var width := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(FONT, Vector2(x - width * 0.5 if center else x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _panel(rect: Rect2, color: Color, radius: int = 18) -> void:
	draw_rect(Rect2(rect.position + Vector2(radius, 0), rect.size - Vector2(radius * 2, 0)), color)
	draw_rect(Rect2(rect.position + Vector2(0, radius), rect.size - Vector2(0, radius * 2)), color)
	for dx in [radius, rect.size.x - radius]:
		for dy in [radius, rect.size.y - radius]:
			draw_circle(rect.position + Vector2(dx, dy), radius, color)

func _bubble(pos: Vector2, r: float, alpha: float = 0.6) -> void:
	draw_arc(pos, r, 0, TAU, 18, Color(CYAN, alpha), 1.5, true)
	draw_circle(pos + Vector2(-r * 0.3, -r * 0.35), 1.4, Color(1, 1, 1, alpha))

func _fish(pos: Vector2, scale_factor: float, shade: Color, flip: float = 1.0) -> void:
	var s := scale_factor
	var t := flip
	draw_colored_polygon(PackedVector2Array([pos + Vector2(-13*t,-2)*s,pos + Vector2(-30*t,-11)*s,pos + Vector2(-26*t,9)*s]), shade.darkened(0.14))
	draw_set_transform(pos, 0, Vector2(s*t, s))
	_filled_ellipse(Vector2.ZERO, Vector2(19, 10), shade)
	draw_colored_polygon(PackedVector2Array([Vector2(-3,-6),Vector2(2,-17),Vector2(8,-6)]), shade.lightened(0.2))
	draw_circle(Vector2(10,-2), 2.3, NAVY)
	draw_circle(Vector2(10.6,-2.8), 0.8, CREAM)
	draw_set_transform(Vector2.ZERO)

func _filled_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_colored_polygon(pts, color)

func _coral(branch: Vector2, color: Color, s: float) -> void:
	var base := branch
	draw_line(base, base + Vector2(0,-56)*s, color, 8*s, true)
	for side in [-1, 1]:
		var tip := base + Vector2(side * 27, -62)*s
		draw_line(base + Vector2(0,-25)*s, tip, color, 6*s, true)
		draw_line(tip, tip + Vector2(side*6,-21)*s, color, 4*s, true)
		draw_line(base + Vector2(side*13,-43)*s, base + Vector2(side*27,-48)*s, color, 4*s, true)
	for offset in [Vector2(0,-56), Vector2(-33,-83), Vector2(33,-83), Vector2(-27,-48), Vector2(27,-48)]:
		draw_circle(base + offset*s, 5*s, color.lightened(0.14))

func _aquarium(area: Rect2) -> void:
	_panel(area, DEEP, 23)
	draw_rect(Rect2(area.position + Vector2(7, 10), area.size - Vector2(14, 20)), Color("1a5363"))
	var tint := 0.0 if screen != "play" else clampf((game.pollution - 35) / 120.0, 0, 0.43)
	draw_rect(Rect2(area.position + Vector2(8,10), area.size - Vector2(16,20)), Color("70664a", tint))
	for i in 5:
		var x := area.position.x + 52 + i * 58.0
		draw_colored_polygon(PackedVector2Array([Vector2(x,area.position.y+14),Vector2(x+18,area.position.y+14),Vector2(x+85,area.end.y-30),Vector2(x+52,area.end.y-30)]), Color(0.7, 1, 0.95, 0.025))
	var floor_y := area.end.y - 28
	draw_colored_polygon(PackedVector2Array([Vector2(area.position.x+8,floor_y),Vector2(area.position.x+60,floor_y-9),Vector2(area.position.x+140,floor_y+3),Vector2(area.position.x+240,floor_y-11),Vector2(area.end.x-8,floor_y),Vector2(area.end.x-8,area.end.y-10),Vector2(area.position.x+8,area.end.y-10)]), Color("d4b78d"))
	for i in 9:
		var xx := area.position.x + 25 + i*38
		draw_circle(Vector2(xx,area.end.y-15-(i%3)*2), 2+(i%3), Color("f4e9c9"))
	_coral(Vector2(area.position.x+77,floor_y), CORAL, 0.85)
	_coral(Vector2(area.position.x+270,floor_y), LIME, 0.65)
	_coral(Vector2(area.position.x+328,floor_y), Color("e7b7a4"), 0.42)
	for i in 4:
		var sway := sin(elapsed*1.8+i)*5
		var x := area.position.x + 130 + i*16
		draw_line(Vector2(x,floor_y), Vector2(x+sway,floor_y-50-i%2*20), Color("71afa0"), 3, true)
	_fish(Vector2(area.position.x+206+sin(elapsed*0.7)*18,area.position.y+105+sin(elapsed*1.2)*5), 1.05, CORAL)
	_fish(Vector2(area.position.x+295-sin(elapsed*0.5)*14,area.position.y+65), 0.66, LIME, -1)
	_fish(Vector2(area.position.x+110+sin(elapsed*0.9)*10,area.position.y+160), 0.55, CYAN)
	for i in 12:
		var x := area.position.x + 34 + (i*59)%int(area.size.x-55)
		var y := area.end.y - fposmod(elapsed*(16+i%3*7)+i*33, area.size.y-30) - 15
		_bubble(Vector2(x+sin(elapsed+i)*3,y), 2.5+i%3*1.6, 0.35)
	draw_rect(Rect2(area.position + Vector2(7,8), Vector2(area.size.x-14,2)), Color(CYAN,0.6))

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(390,700)), NAVY)
	for i in 25:
		var x := float((i*71+29)%390)
		var y := float((i*109+17)%700)
		draw_circle(Vector2(x,y), 1.0 if i%3 else 1.8, Color(CYAN,0.12))
	if screen == "title": _draw_title()
	elif screen == "tutorial": _draw_tutorial()
	elif screen == "play": _draw_play()
	else: _draw_result()

func _brand() -> void:
	_label("◈  POCKET REEF  /  작은 수중 기록", 195, 37, 13, CYAN, true)
	draw_line(Vector2(25,53),Vector2(365,53),Color(CYAN,0.3),1)

func _button(rect: Rect2, text: String, fill: Color = CORAL) -> void:
	_panel(rect, fill, 16)
	_label(text, rect.position.x + rect.size.x*0.5, rect.position.y+rect.size.y*0.5+7, 19, NAVY, true)

func _draw_title() -> void:
	_brand()
	_label("산호 수조",195,113,43,CREAM,true)
	_label("일곱 번의 선택, 하나의 작은 바다",195,144,16,MUTED,true)
	_aquarium(Rect2(20,175,350,310))
	_label("오늘의 바다를 돌봐 주세요",195,525,18,CREAM,true)
	_label("먹이 · 환기 · 청소 / 하루에 단 한 번",195,551,14,MUTED,true)
	_button(Rect2(35,578,320,62),"돌보기 시작  →")
	_label("최고 건강 %d  ·  도전 %d회" % [high_score,runs],195,669,13,MUTED,true)
	if game.day > 1 and game.status == "playing":
		_label("이어하기: %d일 차" % game.day,195,568,13,LIME,true)

func _draw_tutorial() -> void:
	_brand()
	_label("수조 관리 노트",195,112,35,CREAM,true)
	_label("7일 동안 산호의 건강을 지켜요",195,141,16,MUTED,true)
	_aquarium(Rect2(20,164,350,214))
	var lines := ["01  먹이   ·   허기 ↓  오염 ↑", "02  환기   ·   산소 ↑", "03  청소   ·   오염 ↓"]
	for i in 3:
		_panel(Rect2(30,400+i*53,330,44),Color("214458"),12)
		_label(lines[i],48,429+i*53,17,[CORAL,CYAN,LIME][i])
	_label("하루에 하나만 선택 · 키보드 1 / 2 / 3",195,588,13,MUTED,true)
	_label("산소 부족·오염·허기가 건강을 깎아요",195,609,13,MUTED,true)
	_button(Rect2(35,625,320,55),"첫날 시작  →",LIME)

func _bar(name: String, val: int, y: int, color: Color, danger: bool) -> void:
	_label(name,29,y,15,CREAM)
	_label("%d" % val,353,y,15,CORAL if danger else CYAN,true)
	_panel(Rect2(88,y-13,230,12),Color("2a4757"),6)
	if val > 0:
		_panel(Rect2(88,y-13,230.0*val/100.0,12),CORAL if danger else color,mini(6, int(230.0*val/100.0/2)))

func _draw_play() -> void:
	_brand()
	_label("DAY %02d / 07" % mini(game.day,7),28,94,31,CREAM)
	_label("건강 %d" % game.health,334,91,21,LIME if game.health>=40 else CORAL,true)
	_label("오늘의 선택이 내일의 바다를 만들어요",29,116,13,MUTED)
	_aquarium(Rect2(20,135,350,242))
	_panel(Rect2(20,388,350,133),Color("1c384b"),16)
	_bar("산소",game.oxygen,420,CYAN,game.oxygen<35)
	_bar("오염",game.pollution,457,LIME,game.pollution>60)
	_bar("허기",game.hunger,494,CORAL,game.hunger>65)
	var names := ["먹이", "환기", "청소"]
	var symbols := ["●", "○", "◎"]
	var descriptions := ["허기 낮추기", "산소 채우기", "오염 줄이기"]
	for i in 3:
		var x := 20+i*118
		_panel(Rect2(x,532,112,116),[Color("6c444c"),Color("285f6a"),Color("4b6555")][i],15)
		_label(symbols[i],x+56,568,28,[CORAL,CYAN,LIME][i],true)
		_label("%d  %s" % [i+1,names[i]],x+56,596,17,CREAM,true)
		_label(descriptions[i],x+56,626,12,MUTED,true)
	_label("어제의 사건 · %s" % game.last_event,195,678,13,MUTED,true)

func _draw_result() -> void:
	_brand()
	_label("일곱 날의 기록",195,112,36,CREAM,true)
	_aquarium(Rect2(20,157,350,314))
	_panel(Rect2(36,392,318,148),Color("1c384b"),20)
	if game.status == "won":
		_label("산호가 빛나요!",195,436,29,LIME,true)
		_label("7일 동안 작은 바다를 지켰어요",195,473,16,CREAM,true)
	else:
		_label("수조가 잠들었어요",195,436,27,CORAL,true)
		_label("다시 균형을 찾아볼까요?",195,473,16,CREAM,true)
	_label("건강 %d  ·  최고 %d" % [game.health,high_score],195,511,15,CYAN,true)
	_button(Rect2(35,571,320,64),"다시 도전  →")
	_label("매번 다른 해류가 찾아옵니다",195,669,13,MUTED,true)
