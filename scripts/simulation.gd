extends RefCounted

var day := 1
var oxygen := 65
var pollution := 20
var hunger := 25
var health := 75
var seed := 0
var status := "playing"
var last_event := "잔잔한 물결"
var last_action := -1

const EVENTS := [
	{"name": "맑은 조류", "o": 5, "p": 0, "h": 0},
	{"name": "모래 구름", "o": -3, "p": 9, "h": 0},
	{"name": "바쁜 물고기", "o": -2, "p": 2, "h": 8},
	{"name": "고요한 밤", "o": 2, "p": -3, "h": 2},
	{"name": "따뜻한 해류", "o": -5, "p": 4, "h": 0}
]

func reset(new_seed: int) -> void:
	seed = max(0, new_seed)
	day = 1
	oxygen = 65
	pollution = 20
	hunger = 25
	health = 75
	status = "playing"
	last_event = "잔잔한 물결"
	last_action = -1

func act(action: int) -> bool:
	if status != "playing" or action < 0 or action > 2:
		return false
	var event: Dictionary = EVENTS[(seed + day * 3 + (seed / 5)) % EVENTS.size()]
	oxygen += -10 + int(event.o)
	pollution += 8 + int(event.p)
	hunger += 12 + int(event.h)
	match action:
		0:
			hunger -= 39
			pollution += 8
		1:
			oxygen += 36
			pollution += 2
		2:
			pollution -= 36
			oxygen += 4
	oxygen = clampi(oxygen, 0, 100)
	pollution = clampi(pollution, 0, 100)
	hunger = clampi(hunger, 0, 100)
	var stress := 0
	if oxygen < 35: stress += 14
	if pollution > 60: stress += 13
	if hunger > 65: stress += 13
	health = clampi(health - stress + (3 if stress == 0 else 0), 0, 100)
	last_event = str(event.name)
	last_action = action
	day += 1
	if health <= 0 or oxygen <= 10 or pollution >= 95 or hunger >= 95:
		status = "lost"
	elif day > 7:
		status = "won" if health >= 35 else "lost"
	return true

func snapshot() -> Dictionary:
	return {"version": 1, "day": day, "oxygen": oxygen, "pollution": pollution, "hunger": hunger, "health": health, "seed": seed, "status": status, "last_event": last_event, "last_action": last_action}

func restore(data: Dictionary) -> bool:
	if data.get("version") != 1 or not data.has_all(["day", "oxygen", "pollution", "hunger", "health", "seed", "status", "last_event", "last_action"]):
		return false
	if typeof(data.day) != TYPE_INT or data.day < 1 or data.day > 8 or data.seed < 0 or not data.status in ["playing", "won", "lost"]:
		return false
	for key in ["oxygen", "pollution", "hunger", "health"]:
		if typeof(data[key]) != TYPE_INT or data[key] < 0 or data[key] > 100:
			return false
	if typeof(data.last_event) != TYPE_STRING or typeof(data.last_action) != TYPE_INT or data.last_action < -1 or data.last_action > 2:
		return false
	day = data.day
	oxygen = data.oxygen
	pollution = data.pollution
	hunger = data.hunger
	health = data.health
	seed = data.seed
	status = data.status
	last_event = data.last_event
	last_action = data.last_action
	return true
