class_name Rag
extends Node2D
## A pixel-art ragdoll: 10 rigid body parts held together with pin joints.

const BUBBLES_HURT = ["Oof!", "Ouch!", "Whoa!", "Eek!"]
const BUBBLES_FLY = ["Wheee!", "Woohoo!", "Yahoo!"]
const BUBBLES_IDLE = ["Hi!", "La la la", "Hello!", ":)"]

var main
var spec: Dictionary
var s := 1.0
var u := 4.0
var parts := {}
var alive := true
var health := 100.0
var hurt_t := -10.0
var drag_t := -10.0
var fly_t := -10.0
var bubble := ""
var bubble_until := -10.0
var head_tex := {}
var seed_t := 0.0
var grounded := false
var mass_total := 0.0
var down_since := -1.0
var hit_t := -10.0
var hit_dmg := 0.0
var getup_t := -10.0


func setup(m, sp: Dictionary, pos: Vector2) -> void:
	main = m
	spec = sp.duplicate(true)
	s = float(spec.get("size", 1.0))
	u = 5.0 * s
	seed_t = randf() * 4.0
	for f in ["n", "b", "o", "k"]:
		head_tex[f] = Pix.tex(Pix.head_img(spec, f))
	var defs = [
		["th_l", Vector2(-2.5, 7), Pix.thigh_img(spec), 1.0, 0],
		["th_r", Vector2(2.5, 7), Pix.thigh_img(spec), 1.0, 0],
		["sh_l", Vector2(-2.5, 12.5), Pix.shin_img(spec), 0.9, 0],
		["sh_r", Vector2(2.5, 12.5), Pix.shin_img(spec), 0.9, 0],
		["torso", Vector2(0, 0), Pix.torso_img(spec), 3.0, 1],
		["ua_l", Vector2(-5, -2), Pix.uarm_img(spec), 0.45, 2],
		["ua_r", Vector2(5, -2), Pix.uarm_img(spec), 0.45, 2],
		["la_l", Vector2(-5, 3), Pix.larm_img(spec), 0.4, 2],
		["la_r", Vector2(5, 3), Pix.larm_img(spec), 0.4, 2],
		["head", Vector2(0, -8.5), null, 1.2, 3],
	]
	for d in defs:
		var b = RigidBody2D.new()
		b.position = pos + d[1] * u
		b.mass = d[3] * s * s
		b.z_index = d[4]
		var spr = Sprite2D.new()
		spr.texture = head_tex["n"] if d[0] == "head" else Pix.tex(d[2])
		spr.scale = Vector2(u, u)
		spr.name = "Spr"
		b.add_child(spr)
		var cs = CollisionShape2D.new()
		if d[0] == "head":
			var sh = CircleShape2D.new()
			sh.radius = 4.0 * u
			cs.shape = sh
		else:
			var sh2 = RectangleShape2D.new()
			var im: Image = d[2]
			sh2.size = Vector2(im.get_width(), im.get_height()) * u * 0.92
			cs.shape = sh2
		b.add_child(cs)
		var mat = PhysicsMaterial.new()
		mat.friction = 0.85
		mat.bounce = 0.05
		b.physics_material_override = mat
		b.angular_damp = 1.0
		b.contact_monitor = true
		b.max_contacts_reported = 4
		b.set_meta("rag", self)
		b.set_meta("part", d[0])
		b.add_to_group("dyn")
		add_child(b)
		parts[d[0]] = b
		mass_total += b.mass
		b.body_entered.connect(_on_hit.bind(b))
	var arr = parts.values()
	for a in arr.size():
		for c in range(a + 1, arr.size()):
			arr[a].add_collision_exception_with(arr[c])
	_joint("torso", "head", pos + Vector2(0, -4.5) * u)
	_joint("torso", "ua_l", pos + Vector2(-5, -4) * u)
	_joint("torso", "ua_r", pos + Vector2(5, -4) * u)
	_joint("ua_l", "la_l", pos + Vector2(-5, 0.5) * u)
	_joint("ua_r", "la_r", pos + Vector2(5, 0.5) * u)
	_joint("torso", "th_l", pos + Vector2(-2.5, 4.5) * u)
	_joint("torso", "th_r", pos + Vector2(2.5, 4.5) * u)
	_joint("th_l", "sh_l", pos + Vector2(-2.5, 9.5) * u)
	_joint("th_r", "sh_r", pos + Vector2(2.5, 9.5) * u)


func _joint(a: String, b: String, at: Vector2) -> void:
	var j = PinJoint2D.new()
	j.position = at
	j.softness = 0.0
	j.disable_collision = true
	add_child(j)
	j.node_a = j.get_path_to(parts[a])
	j.node_b = j.get_path_to(parts[b])


func torso() -> RigidBody2D:
	return parts["torso"]


func center() -> Vector2:
	return parts["torso"].global_position


func now() -> float:
	return Time.get_ticks_msec() / 1000.0


func say(t: String, d: float = 1.4, force: bool = false) -> void:
	if not force and now() < bubble_until - d + 0.6:
		return
	bubble = t
	bubble_until = now() + d


func hurt(dmg: float) -> void:
	if dmg <= 0:
		return
	health = max(0.0, health - dmg)
	hurt_t = now()
	if dmg > 10 and health > 0:
		say(BUBBLES_HURT.pick_random(), 1.0)
		main.sfx.play("ouch", 0.4)
	if health <= 0 and alive:
		alive = false
		say("Zzz", 1.8, true)


func heal() -> void:
	health = 100.0
	alive = true
	say("Yay!", 1.4, true)


func push_all(v: Vector2, add: bool = false) -> void:
	for b in parts.values():
		if add:
			b.linear_velocity += v
		else:
			b.linear_velocity = v


func set_vy(vy: float) -> void:
	for b in parts.values():
		b.linear_velocity.y = vy


func _on_hit(other, b) -> void:
	if not alive and health <= 0 and false:
		return
	if other.has_meta("rag") and other.get_meta("rag") == self:
		return
	var pv: Vector2 = b.get_meta("pv", b.linear_velocity)
	var ov = Vector2.ZERO
	var om = 50.0
	if other is RigidBody2D:
		ov = other.get_meta("pv", other.linear_velocity)
		om = other.mass
	if om < 0.3:
		return
	var imp = (pv - ov).length()
	if imp > 330:
		main.sfx.play("thud", 0.07)
	if imp > 600:
		var mult = (2.0 if b.get_meta("part") == "head" else 1.0) * clamp(0.5 + om / 4.0, 0.5, 1.6)
		var dmg = (imp - 600) * 0.05 * mult
		var t = now()
		if t - hit_t < 0.15:
			# one landing = one hit, not one hit per body part
			if dmg > hit_dmg:
				hurt(dmg - hit_dmg)
				hit_dmg = dmg
		else:
			hit_t = t
			hit_dmg = dmg
			hurt(dmg)


func _physics_process(_dt: float) -> void:
	if parts.is_empty():
		return
	var t = now()
	grounded = parts["sh_l"].get_contact_count() > 0 or parts["sh_r"].get_contact_count() > 0
	var dragged = t - drag_t < 0.3
	if alive and grounded and not dragged and main.grav > 0.05:
		var stun = clamp(1.0 - (t - hurt_t) / 0.9, 0.0, 1.0)
		var st = (0.35 + 0.65 * health / 100.0) * (1.0 - stun * 0.8)
		for k in ["torso", "head", "th_l", "th_r", "sh_l", "sh_r"]:
			_upright(parts[k], 0.0, 12.0 * st)
		for k in ["ua_l", "ua_r", "la_l", "la_r"]:
			_upright(parts[k], 0.0, 3.0 * st)
		parts["torso"].apply_central_force(Vector2(0, -mass_total * 980.0 * main.grav * 0.55 * st))
	# fallen over? get back up after a moment
	var touching = false
	for b in parts.values():
		if b.get_contact_count() > 0:
			touching = true
			break
	var lying = abs(wrapf(parts["torso"].rotation, -PI, PI)) > 0.8 or parts["head"].global_position.y > parts["torso"].global_position.y - 10 * u
	if alive and lying and touching and not dragged and main.grav > 0.05:
		if down_since < 0:
			down_since = t
		elif t - down_since > 1.4 and t - getup_t > 1.5:
			getup_t = t
			down_since = -1.0
			for b in parts.values():
				b.linear_velocity = Vector2(b.linear_velocity.x * 0.3, -520.0 * sqrt(main.grav))
				b.angular_velocity = -wrapf(b.rotation, -PI, PI) * 6.0
			say(["Upsy-daisy!", "I'm OK!", "Hup!"].pick_random(), 1.0)
	else:
		down_since = -1.0
	if t - getup_t < 0.5:
		for k in parts:
			_upright(parts[k], 0.0, 10.0)
	var v = parts["torso"].linear_velocity.length()
	if v > 800 and not grounded and t - fly_t > 2.5:
		fly_t = t
		say(BUBBLES_FLY.pick_random(), 1.2, true)
		main.sfx.play("whoosh")
	if alive and grounded and randf() < 0.0008 and t > bubble_until:
		say(BUBBLES_IDLE.pick_random(), 1.5)


func _upright(b: RigidBody2D, target: float, k: float) -> void:
	var d = wrapf(target - b.rotation, -PI, PI)
	b.angular_velocity = lerp(b.angular_velocity, d * k, 0.3)


func _process(_dt: float) -> void:
	if parts.is_empty():
		return
	var t = now()
	var f = "n"
	if not alive:
		f = "k"
	elif t - hurt_t < 0.6:
		f = "o"
	elif fmod(t + seed_t, 3.6) < 0.13:
		f = "b"
	var spr: Sprite2D = parts["head"].get_node("Spr")
	spr.texture = head_tex[f]
	queue_redraw()


func _draw() -> void:
	if parts.is_empty():
		return
	var t = now()
	var h = parts["head"].global_position
	var font = ThemeDB.fallback_font
	if not alive:
		for k in 3:
			var a = t * 2.5 + k * 2.1
			var p = h + Vector2(cos(a) * 20 * s, -22 * s + sin(a) * 4)
			draw_rect(Rect2(p - Vector2(3, 3), Vector2(6, 6)), Color("#ffd23f"))
	if t - hurt_t < 2.0:
		var bx = h + Vector2(-18, -26 * s - 8)
		draw_rect(Rect2(bx, Vector2(36, 6)), Color(0, 0, 0, 0.45))
		var col = Color("#4ade80") if health > 50 else (Color("#facc15") if health > 20 else Color("#f87171"))
		draw_rect(Rect2(bx, Vector2(36 * health / 100.0, 6)), col)
	if t < bubble_until and bubble != "":
		var fs = 20
		var w = font.get_string_size(bubble, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 20
		var p = h + Vector2(-w / 2, -26 * s - 46)
		p.x = clamp(p.x, 4, main.W - w - 4)
		draw_rect(Rect2(p + Vector2(4, 4), Vector2(w, 30)), Color(0, 0, 0, 0.25))
		draw_rect(Rect2(p, Vector2(w, 30)), Color("#ffffff"))
		draw_rect(Rect2(p, Vector2(w, 30)), Color("#2a2233"), false, 3.0)
		draw_rect(Rect2(Vector2(h.x - 4, p.y + 30), Vector2(8, 6)), Color("#ffffff"))
		draw_string(font, p + Vector2(10, 22), bubble, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#2a2233"))
