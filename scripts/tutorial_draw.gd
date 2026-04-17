extends Control

## Set by tutorial.gd each step
var arm_target: Vector2 = Vector2(700, 750)
var expression: int = 0   # 0 = smile, 1 = O-mouth, 2 = big grin

const FP    := Vector2(155.0, 928.0)   # feet anchor
const SUIT  := Color(0.22, 0.42, 0.82)
const SKIN  := Color(0.95, 0.82, 0.68)
const INK   := Color(0.08, 0.10, 0.18)
const SUIT2 := Color(0.32, 0.58, 1.00)

# Bubble tail colour — must match the PanelContainer bg in tutorial.gd
const TAIL_COL := Color(0.11, 0.13, 0.21, 0.97)

func _draw() -> void:
	_draw_tail()
	_draw_char()

func _draw_char() -> void:
	var fp: Vector2 = FP

	# ── Legs ─────────────────────────────────────────────────────
	var lleg: Vector2 = fp + Vector2(-18, -46)
	var rleg: Vector2 = fp + Vector2( 18, -46)
	draw_line(fp, lleg, SUIT, 7.0, true)
	draw_line(fp, rleg, SUIT, 7.0, true)
	# Feet
	draw_line(lleg, lleg + Vector2(-16, 0), SUIT, 6.0, true)
	draw_line(rleg, rleg + Vector2( 16, 0), SUIT, 6.0, true)

	# ── Body ─────────────────────────────────────────────────────
	var waist:    Vector2 = fp + Vector2(0, -46)
	var shoulder: Vector2 = fp + Vector2(0, -106)
	draw_line(waist, shoulder, SUIT, 8.0, true)
	# Belt stripe
	draw_line(waist + Vector2(-12, -6), waist + Vector2(12, -6), SUIT2, 4.0, true)

	# ── Arms ─────────────────────────────────────────────────────
	var arm_root: Vector2 = fp + Vector2(0, -90)
	# Pointing arm
	var adir: Vector2 = (arm_target - arm_root).normalized()
	var arm_end: Vector2 = arm_root + adir * 65.0
	draw_line(arm_root, arm_end, SUIT, 6.5, true)
	draw_circle(arm_end, 6.0, SKIN)
	# Index finger hint
	draw_circle(arm_end + adir * 5.0, 3.5, SKIN)
	# Other arm (relaxed)
	var side: Vector2 = Vector2(-sign(adir.x) * 0.7 - adir.y * 0.3, 0.55).normalized()
	draw_line(arm_root, arm_root + side * 48.0, SUIT, 6.0, true)

	# ── Neck ─────────────────────────────────────────────────────
	var neck_bot: Vector2 = shoulder
	var neck_top: Vector2 = shoulder + Vector2(0, -14)
	draw_line(neck_bot, neck_top, SKIN, 6.0, true)

	# ── Helmet ───────────────────────────────────────────────────
	var head: Vector2 = neck_top + Vector2(0, -30)
	# Outer shell
	draw_circle(head, 32.0, SUIT)
	# Visor glass
	draw_circle(head, 24.0, Color(0.06, 0.09, 0.20, 0.94))
	draw_arc(head, 24.0, 0.0, TAU, 40, Color(0.28, 0.52, 0.90, 0.70), 3.0)
	# Visor shine
	draw_arc(head + Vector2(-6, -10), 13.0, -TAU * 0.23, -TAU * 0.04,
		8, Color(1.0, 1.0, 1.0, 0.16), 3.5)

	# Eyes
	for ex: float in [-8.0, 8.0]:
		draw_circle(head + Vector2(ex, -1), 3.8, SKIN)
		draw_circle(head + Vector2(ex, -1), 1.8, INK)
		draw_circle(head + Vector2(ex + 1.2, -2), 1.0, Color.WHITE)

	# Mouth
	match expression:
		0:   # smile
			draw_arc(head + Vector2(0, 7), 6.0, 0.15, PI - 0.15, 8, SKIN, 2.2)
		1:   # surprised O
			draw_circle(head + Vector2(0, 8), 4.0, SKIN)
		2:   # big grin
			draw_arc(head + Vector2(0, 7), 8.0, 0.05, PI - 0.05, 10, SKIN, 2.8)

	# Side bolts
	for bx: float in [-30.0, 30.0]:
		draw_circle(head + Vector2(bx, 2), 4.0, SUIT2)

	# Antenna
	draw_line(head + Vector2(16, -28), head + Vector2(21, -48), SUIT, 3.0, true)
	draw_circle(head + Vector2(21, -50), 5.5, Color(1.0, 0.32, 0.14))
	draw_circle(head + Vector2(21, -50), 2.5, Color(1.0, 0.90, 0.20))

func _draw_tail() -> void:
	# Triangle from bubble left edge toward character's head
	var head_pos: Vector2 = FP + Vector2(0, -174)  # approx head center
	var bx: float = 308.0  # left edge of bubble panel
	var mid_y: float = 760.0
	var pts := PackedVector2Array([
		Vector2(bx, mid_y - 28.0),
		Vector2(bx, mid_y + 28.0),
		head_pos + Vector2(32.0, 0.0),
	])
	draw_polygon(pts, PackedColorArray([TAIL_COL]))
	var outline := PackedVector2Array(pts)
	outline.append(pts[0])
	draw_polyline(outline, Color(0.22, 0.28, 0.44, 0.70), 1.5)
