extends Node

const SAVE_PATH: String = "user://savegame.json"

func _ready() -> void:
	load_game()

# ═══════════════════════════════════════════════════════════════
# MODULE DEFINITIONS
# ═══════════════════════════════════════════════════════════════
var MODULE_DATA: Dictionary = {
	# ── Weapons ─────────────────────────────────────────────────
	"basic_laser": {
		"name": "Základní laser", "category": "weapon",
		"desc": "Standardní laserový kanón. Střílí jednu sérii vpřed.",
		"research_cost": 0, "buy_cost": 0,
		"effect": {"fire_pattern": "single", "damage": 20, "fire_rate": 0.22},
	},
	"double_laser": {
		"name": "Dvojitý laser", "category": "weapon",
		"desc": "Dvě paralelní laserové série.",
		"research_cost": 2, "buy_cost": 80,
		"effect": {"fire_pattern": "double", "damage": 18, "fire_rate": 0.24},
	},
	"plasma_laser": {
		"name": "Plazmový laser", "category": "weapon",
		"desc": "Velká plazmová koule. Vyšší poškození, pomalejší palba.",
		"research_cost": 5, "buy_cost": 200,
		"effect": {"fire_pattern": "plasma", "damage": 50, "fire_rate": 0.70},
	},
	"ion_cannon": {
		"name": "Iontové dělo", "category": "weapon",
		"desc": "Devastující iontový paprsek. Pomalé, ale smrtící.",
		"research_cost": 10, "buy_cost": 450,
		"effect": {"fire_pattern": "ion", "damage": 90, "fire_rate": 1.20},
	},
	"rockets": {
		"name": "Rakety", "category": "weapon",
		"desc": "Samozaměřovací rakety. Menší rozptyl na cíl.",
		"research_cost": 4, "buy_cost": 180,
		"effect": {"fire_pattern": "rocket", "damage": 35, "fire_rate": 2.50},
	},
	"shotgun": {
		"name": "Broková střelba", "category": "weapon",
		"desc": "Tři projektily v rozptyleném vzoru.",
		"research_cost": 3, "buy_cost": 150,
		"effect": {"fire_pattern": "spread", "damage": 14, "fire_rate": 0.55},
	},
	"minigun": {
		"name": "Kulomet", "category": "weapon",
		"desc": "Extrémně rychlá palba s nižším poškozením.",
		"research_cost": 3, "buy_cost": 150,
		"effect": {"fire_pattern": "minigun", "damage": 8, "fire_rate": 0.06},
	},
	# ── Shields ─────────────────────────────────────────────────
	"energy_shield": {
		"name": "Energetický štít", "category": "shield",
		"desc": "+50 HP. Absorpční energetická bariéra.",
		"research_cost": 3, "buy_cost": 150,
		"effect": {"hp_bonus": 50},
	},
	"reflect_shield": {
		"name": "Odrazový štít", "category": "shield",
		"desc": "+30 HP. Odrází projektily zpět na nepřátele.",
		"research_cost": 7, "buy_cost": 350,
		"effect": {"hp_bonus": 30, "reflect": true},
	},
	# ── Engines ─────────────────────────────────────────────────
	"basic_engine": {
		"name": "Základní motor", "category": "engine",
		"desc": "Standardní pohon.",
		"research_cost": 0, "buy_cost": 0,
		"effect": {"speed_mult": 1.0},
	},
	"advanced_engine": {
		"name": "Pokročilý motor", "category": "engine",
		"desc": "+20% rychlost pohybu.",
		"research_cost": 4, "buy_cost": 200,
		"effect": {"speed_mult": 1.20},
	},
	"ion_engine": {
		"name": "Iontový motor", "category": "engine",
		"desc": "+50% rychlost pohybu. Endgame pohon.",
		"research_cost": 12, "buy_cost": 600,
		"effect": {"speed_mult": 1.50},
	},
	# ── Collectors ──────────────────────────────────────────────
	"basic_collector": {
		"name": "Základní sběrač", "category": "collector",
		"desc": "Mechanické klepeto. Sbírá materiál v krátkém dosahu.",
		"research_cost": 0, "buy_cost": 0,
		"effect": {"pickup_range": 90.0},
	},
	"magnet_collector": {
		"name": "Magnetický sběrač", "category": "collector",
		"desc": "2× dosah sběru. Přitáhne vzdálený materiál.",
		"research_cost": 5, "buy_cost": 250,
		"effect": {"pickup_range": 200.0},
	},
	# ── Cargo ───────────────────────────────────────────────────
	"small_cargo": {
		"name": "Malý nákladní prostor", "category": "cargo",
		"desc": "Umožňuje sbírání materiálu.",
		"research_cost": 0, "buy_cost": 0,
		"effect": {"cargo": true, "metal_mult": 1.0},
	},
	"medium_cargo": {
		"name": "Střední nákladní prostor", "category": "cargo",
		"desc": "Umožňuje sběr + bonus +10% šrotu.",
		"research_cost": 2, "buy_cost": 100,
		"effect": {"cargo": true, "metal_mult": 1.10},
	},
	"large_cargo": {
		"name": "Velký nákladní prostor", "category": "cargo",
		"desc": "Umožňuje sběr + bonus +25% šrotu.",
		"research_cost": 4, "buy_cost": 200,
		"effect": {"cargo": true, "metal_mult": 1.25},
	},
	# ── Special abilities ────────────────────────────────────────
	"time_slow": {
		"name": "Časové zpomalení", "category": "special",
		"desc": "Zpomalí všechny nepřátele na 3 sekundy.",
		"research_cost": 6, "buy_cost": 300,
		"effect": {"ability": "time_slow", "cooldown": 12.0},
	},
	"emp": {
		"name": "EMP", "category": "special",
		"desc": "Vyřadí všechny nepřátele z provozu na 2s.",
		"research_cost": 5, "buy_cost": 250,
		"effect": {"ability": "emp", "cooldown": 10.0},
	},
	"repair_unit": {
		"name": "Opravná jednotka", "category": "special",
		"desc": "Okamžitě opraví 30 HP.",
		"research_cost": 4, "buy_cost": 200,
		"effect": {"ability": "repair", "cooldown": 15.0},
	},
	"fighter_drone": {
		"name": "Bojová stíhačka", "category": "special",
		"desc": "Přivolá AI wingmana na 8 sekund.",
		"research_cost": 8, "buy_cost": 400,
		"effect": {"ability": "fighter", "cooldown": 20.0},
	},
}

# ═══════════════════════════════════════════════════════════════
# SHIP DEFINITIONS
# ═══════════════════════════════════════════════════════════════
var SHIP_DATA: Dictionary = {
	"scout": {
		"name": "Scout", "emoji": "🔧",
		"grid": Vector2i(3, 3),
		"base_speed": 280.0, "base_hp": 100,
		"passive": "+20% rychlost pohybu",
		"active": "Krátký dash", "active_key": "dash",
		"active_cooldown": 2.5,
		"unlock_cost": 0,
	},
	"destroyer": {
		"name": "Destroyer", "emoji": "⚔️",
		"grid": Vector2i(4, 3),
		"base_speed": 220.0, "base_hp": 150,
		"passive": "+15% poškození zbraní",
		"active": "Salvová palba", "active_key": "salvo",
		"active_cooldown": 5.0,
		"unlock_cost": 1000,
	},
}

# ═══════════════════════════════════════════════════════════════
# PLANET DEFINITIONS
# ═══════════════════════════════════════════════════════════════
var PLANET_ORDER: Array[String] = [
	"glacius", "infernus", "toxar", "shadowveil", "void_station"
]

var PLANET_DATA: Dictionary = {
	"glacius": {
		"name": "Glacius",     "emoji": "🧊",
		"color": Color(0.20, 0.65, 1.00),
		"desc": "Ledová planeta prvních průzkumníků Void.",
	},
	"infernus": {
		"name": "Infernus",    "emoji": "🌋",
		"color": Color(1.00, 0.35, 0.10),
		"desc": "Sopečná pekla fanatických ohňovců.",
	},
	"toxar": {
		"name": "Toxar",       "emoji": "☢️",
		"color": Color(0.35, 0.90, 0.15),
		"desc": "Toxická mlha. Nepřátelé se regenerují.",
	},
	"shadowveil": {
		"name": "Shadowveil",  "emoji": "🌑",
		"color": Color(0.62, 0.20, 0.90),
		"desc": "Temná zóna. Nepřátelé se teleportují.",
	},
	"void_station": {
		"name": "Void Station","emoji": "💀",
		"color": Color(0.85, 0.85, 0.95),
		"desc": "Nepřátelská základna. Konečný cíl.",
	},
}

var current_planet: String = "glacius"
var current_mission: int   = 0   # 0–2 = normální, 3 = boss

var missions_done: Dictionary = {
	"glacius": 0, "infernus": 0, "toxar": 0, "shadowveil": 0, "void_station": 0
}

func is_planet_unlocked(planet_id: String) -> bool:
	var idx: int = PLANET_ORDER.find(planet_id)
	if idx < 0:
		return false
	if idx == 0:
		return true
	return missions_done.get(PLANET_ORDER[idx - 1], 0) >= 4

# Visual colors per category (used in hangar + hub)
var CAT_COLORS: Dictionary = {
	"weapon":    Color(0.85, 0.20, 0.20),
	"engine":    Color(0.95, 0.50, 0.10),
	"cargo":     Color(0.50, 0.55, 0.55),
	"collector": Color(0.80, 0.70, 0.10),
	"shield":    Color(0.20, 0.50, 0.95),
	"special":   Color(0.70, 0.20, 0.90),
}

var CAT_SHORT: Dictionary = {
	"weapon": "Z", "engine": "M", "cargo": "N",
	"collector": "S", "shield": "Š", "special": "A",
}

# ═══════════════════════════════════════════════════════════════
# PERSISTENT STATE
# ═══════════════════════════════════════════════════════════════
var metal_scrap: int = 200
var void_crystals: int = 10
var total_runs: int = 0
var planet_runs: Dictionary = {
	"glacius": 0, "infernus": 0, "toxar": 0, "shadowveil": 0, "void_station": 0
}

var current_ship: String = "scout"

# owned_modules: module_id → count (total copies bought)
var owned_modules: Dictionary = {
	"basic_laser": 1, "basic_engine": 1,
	"small_cargo": 1, "basic_collector": 1,
}

# installed_modules: fixed-size array matching grid slot count.
# "" means the slot is empty.  Size = ship grid cols × rows.
var installed_modules: Array[String] = [
	"basic_laser", "basic_engine", "small_cargo", "basic_collector",
	"", "", "", "", "",
]

# researched: set of module IDs that have been researched
var researched_modules: Array[String] = [
	"basic_laser", "basic_engine", "small_cargo", "basic_collector",
]

var meta_bonuses: Dictionary = {
	"metal_pickup_mult": 1.0,
	"start_metal_bonus": 0,
}

var tutorial_done: bool = false

# ── Tester mode ──────────────────────────────────────────────────
var tester_mode: bool = false

func toggle_tester_mode() -> void:
	tester_mode = not tester_mode
	if tester_mode:
		metal_scrap   = 99999
		void_crystals = 99999

# ═══════════════════════════════════════════════════════════════
# GRID HELPERS
# ═══════════════════════════════════════════════════════════════
func get_slot_count() -> int:
	var g: Vector2i = SHIP_DATA[current_ship]["grid"]
	return g.x * g.y

func available_count(module_id: String) -> int:
	return owned_modules.get(module_id, 0) - installed_modules.count(module_id)

func equip_module(module_id: String) -> bool:
	if available_count(module_id) <= 0:
		return false
	for i: int in installed_modules.size():
		if installed_modules[i].is_empty():
			installed_modules[i] = module_id
			return true
	return false

## Place module_id at a specific slot.  If occupied, old module is unequipped first.
func equip_module_at(module_id: String, slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= installed_modules.size():
		return false
	installed_modules[slot_index] = ""        # free slot so available_count is correct
	if available_count(module_id) <= 0:
		return false
	installed_modules[slot_index] = module_id
	return true

## Swap (or move) two slots.  Works even if one or both are empty.
func move_module(from_slot: int, to_slot: int) -> void:
	if from_slot == to_slot:
		return
	if from_slot < 0 or from_slot >= installed_modules.size():
		return
	if to_slot < 0 or to_slot >= installed_modules.size():
		return
	var tmp: String = installed_modules[to_slot]
	installed_modules[to_slot]   = installed_modules[from_slot]
	installed_modules[from_slot] = tmp

func unequip_module(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= installed_modules.size():
		return false
	installed_modules[slot_index] = ""
	return true

# ═══════════════════════════════════════════════════════════════
# SHOP ACTIONS
# ═══════════════════════════════════════════════════════════════
func can_research(module_id: String) -> bool:
	if module_id in researched_modules:
		return false
	if tester_mode:
		return true
	var cost: int = MODULE_DATA[module_id].get("research_cost", 999)
	return void_crystals >= cost

func research_module(module_id: String) -> bool:
	if not can_research(module_id):
		return false
	if not tester_mode:
		void_crystals -= MODULE_DATA[module_id].get("research_cost", 0)
	researched_modules.append(module_id)
	return true

func can_buy(module_id: String) -> bool:
	if module_id not in researched_modules:
		return false
	if tester_mode:
		return true
	return metal_scrap >= MODULE_DATA[module_id].get("buy_cost", 999)

func buy_module(module_id: String) -> bool:
	if not can_buy(module_id):
		return false
	if not tester_mode:
		metal_scrap -= MODULE_DATA[module_id].get("buy_cost", 0)
	owned_modules[module_id] = owned_modules.get(module_id, 0) + 1
	return true

# ═══════════════════════════════════════════════════════════════
# PLAYER STATS (computed from installed modules + ship)
# ═══════════════════════════════════════════════════════════════
func get_player_stats() -> Dictionary:
	var ship: Dictionary = SHIP_DATA[current_ship]
	var stats: Dictionary = {
		"speed":          ship["base_speed"],
		"has_engine":     false,
		"max_hp":         ship["base_hp"],
		"pickup_range":   0.0,
		"has_cargo":      false,
		"metal_mult":     meta_bonuses.get("metal_pickup_mult", 1.0),
		"reflect_shield": false,
		"weapons":        [],
		"specials":       [],
	}

	for i: int in installed_modules.size():
		var module_id: String = installed_modules[i]
		if module_id.is_empty():
			continue
		var data: Dictionary = MODULE_DATA.get(module_id, {})
		var eff: Dictionary  = data.get("effect", {})
		match data.get("category", ""):
			"weapon":
				stats["weapons"].append({
					"id":      module_id,
					"pattern": eff.get("fire_pattern", "single"),
					"damage":  eff.get("damage", 20),
					"rate":    eff.get("fire_rate", 0.22),
					"slot":    i,
				})
			"engine":
				stats["has_engine"] = true
				stats["speed"] *= eff.get("speed_mult", 1.0)
			"shield":
				stats["max_hp"] += eff.get("hp_bonus", 0)
				if eff.get("reflect", false):
					stats["reflect_shield"] = true
			"collector":
				stats["pickup_range"] = max(stats["pickup_range"], eff.get("pickup_range", 0.0))
			"cargo":
				stats["has_cargo"] = true
				stats["metal_mult"] *= eff.get("metal_mult", 1.0)
			"special":
				stats["specials"].append({
					"id":       module_id,
					"ability":  eff.get("ability", ""),
					"cooldown": eff.get("cooldown", 10.0),
				})

	# Ship passive bonuses
	match current_ship:
		"scout":
			stats["speed"] *= 1.20
		"destroyer":
			for w: Dictionary in stats["weapons"]:
				w["damage"] = int(w["damage"] * 1.15)

	# Fallback: always have a weapon
	if stats["weapons"].is_empty():
		stats["weapons"] = [{"id": "basic_laser", "pattern": "single", "damage": 20, "rate": 0.22}]

	return stats

# ═══════════════════════════════════════════════════════════════
# RUN MANAGEMENT
# ═══════════════════════════════════════════════════════════════
func start_run() -> void:
	pass

func end_run(victory: bool, metal_earned: int, crystals_earned: int) -> void:
	total_runs += 1
	planet_runs[current_planet] = planet_runs.get(current_planet, 0) + 1

	var metal_keep: int = int(metal_earned * meta_bonuses.get("metal_pickup_mult", 1.0))
	if not victory:
		metal_keep = int(metal_keep * 0.5)

	metal_scrap    += metal_keep
	void_crystals  += crystals_earned
	_check_meta_progression(current_planet)

func _check_meta_progression(planet: String) -> void:
	var runs: int = planet_runs.get(planet, 0)
	match runs:
		2: meta_bonuses["start_metal_bonus"] = max(meta_bonuses.get("start_metal_bonus", 0), 50)
		5: meta_bonuses["metal_pickup_mult"]  = max(meta_bonuses.get("metal_pickup_mult", 1.0), 1.25)
		7: meta_bonuses["start_metal_bonus"]  = max(meta_bonuses.get("start_metal_bonus", 0), 150)

# Marks the current mission as completed and saves.
func complete_mission() -> void:
	var done: int = missions_done.get(current_planet, 0)
	if current_mission == done:
		missions_done[current_planet] = done + 1
	save_game()

# ═══════════════════════════════════════════════════════════════
# SAVE / LOAD
# ═══════════════════════════════════════════════════════════════
func save_game() -> void:
	var data: Dictionary = {
		"metal_scrap":       metal_scrap,
		"void_crystals":     void_crystals,
		"total_runs":        total_runs,
		"current_ship":      current_ship,
		"planet_runs":       planet_runs,
		"missions_done":     missions_done,
		"owned_modules":     owned_modules,
		"installed_modules": Array(installed_modules),
		"researched_modules":Array(researched_modules),
		"meta_bonuses":      meta_bonuses,
		"tutorial_done":     tutorial_done,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return
	var d: Dictionary = parsed

	# Scalars
	metal_scrap   = int(d.get("metal_scrap",   metal_scrap))
	void_crystals = int(d.get("void_crystals", void_crystals))
	total_runs    = int(d.get("total_runs",    total_runs))
	current_ship  = str(d.get("current_ship",  current_ship))

	# Dictionaries with int values
	for key: String in ["planet_runs", "missions_done"]:
		if d.has(key):
			for k: String in d[key]:
				get(key)[k] = int(d[key][k])

	# owned_modules (int values)
	if d.has("owned_modules"):
		owned_modules.clear()
		for k: String in d["owned_modules"]:
			owned_modules[k] = int(d["owned_modules"][k])

	# meta_bonuses (float values)
	if d.has("meta_bonuses"):
		for k: String in d["meta_bonuses"]:
			meta_bonuses[k] = float(d["meta_bonuses"][k])

	# installed_modules — typed Array[String], resized to current ship grid
	if d.has("installed_modules"):
		var slot_count: int = get_slot_count()
		var arr: Array = d["installed_modules"]
		installed_modules.resize(slot_count)
		for i: int in slot_count:
			installed_modules[i] = str(arr[i]) if i < arr.size() else ""

	tutorial_done = bool(d.get("tutorial_done", false))

	# researched_modules
	if d.has("researched_modules"):
		researched_modules.clear()
		for item: Variant in d["researched_modules"]:
			researched_modules.append(str(item))

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
