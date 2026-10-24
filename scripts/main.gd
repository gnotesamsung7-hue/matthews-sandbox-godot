extends Node2D
## Matthew's Sandbox (Godot edition): pixel ragdoll physics sandbox.

const PX = 4.0
const STAGES = [["lab", "Lab", 1.0], ["park", "Park", 1.0], ["beach", "Beach", 1.0], ["candy", "Candy Land", 1.0], ["space", "Space", 0.3]]
const ITEMS = ["crate", "ball", "balloon", "tnt", "duck", "brick", "plank", "steel", "bowling", "tramp"]
const ITEM_NAMES = {"crate": "Crate", "ball": "Ball", "balloon": "Balloon", "tnt": "TNT", "duck": "Duck", "brick": "Brick",
	"plank": "Plank", "steel": "Steel", "bowling": "Bowling", "tramp": "Bounce"}
const ITEM_MASS = {"crate": 1.2, "steel": 5.0, "ball": 0.5, "bowling": 6.0, "tnt": 1.0, "balloon": 0.12, "plank": 1.5, "brick": 2.0, "duck": 0.4}
const TOOLS = [["drag", "Drag"], ["poke", "Poke"], ["boom", "Boom"], ["heal", "Heal"], ["del", "Delete"],
	["magnet", "Magnet"], ["wind", "Wind"], ["grow", "Grow"], ["shrink", "Shrink"], ["copy", "Copy"]]

var W := 1280.0
var H := 720.0
var ground_y := 640.0
var grav := 1.0
var stage := "lab"
var world: Node2D
var bg: Sprite2D
var statics: Array = []
var rags: Array = []
var sfx: Sfx
var mode_kind := "tool"
var mode_id := "drag"
var tab := "people"
var drag_body = null
var drag_off := Vector2.ZERO
var pointer := Vector2.ZERO
var holding := false
var shake := 0.0
var chars: Array = []
var last_random = null
var machine: Sprite2D
var machine_t := -10.0
var machine_tex: Array = []
var floor_body: StaticBody2D

# UI
var ui: CanvasLayer
var theme_: Theme
var slots: HBoxContainer
var tab_buttons := {}
var toast_label: Label
var toast_until := 0.0
var maker: PanelContainer
var maker_spec: Dictionary = {}
var maker_edit_index := -1
var maker_preview: TextureRect
var maker_rows: VBoxContainer
var maker_name: LineEdit
var stage_panel: PanelContainer
var sound_btn: Button


func _ready() -> void:
	randomize()
	sfx = Sfx.new()
	add_child(sfx)
	world = Node2D.new()
	add_child(world)
	bg = Sprite2D.new()
	bg.centered = false
	bg.z_index = -10
	bg.scale = Vector2(PX, PX)
	add_child(bg)
	machine_tex = [Pix.tex(Pix.machine_img(0, 0)), Pix.tex(Pix.machine_img(0, 1)), Pix.tex(Pix.machine_img(1, 0)), Pix.tex(Pix.machine_img(1, 1))]
	machine = Sprite2D.new()
	machine.scale = Vector2(PX, PX)
	machine.texture = machine_tex[0]
	machine.z_index = -5
	add_child(machine)
	load_chars()
	build_ui()
	get_viewport().size_changed.connect(_on_resize)
	_on_resize()
	set_stage(0, true)
	start_scene()
	toast("Pick something below, then tap the screen!")


# ---------------- world size, stage ----------------
func _on_resize() -> void:
	var r = get_viewport_rect().size
	W = r.x
	H = r.y
	ground_y = H - 168.0
	for s in statics:
		s.queue_free()
	statics = []
	floor_body = _static_rect(Vector2(W / 2, ground_y + 200), Vector2(W + 2000, 400))
	statics.append(floor_body)
	statics.append(_static_rect(Vector2(-50, H / 2 - 500), Vector2(100, H + 1400)))
	statics.append(_static_rect(Vector2(W + 50, H / 2 - 500), Vector2(100, H + 1400)))
	statics.append(_static_rect(Vector2(W / 2, -50), Vector2(W + 2000, 100)))
	_apply_stage_look()


func _static_rect(pos: Vector2, size: Vector2) -> StaticBody2D:
	var b = StaticBody2D.new()
	b.position = pos
	var cs = CollisionShape2D.new()
	var sh = RectangleShape2D.new()
	sh.size = size
	cs.shape = sh
	b.add_child(cs)
	var mat = PhysicsMaterial.new()
	mat.friction = 0.9
	b.physics_material_override = mat
	add_child(b)
	return b


func set_stage(i: int, quiet: bool = false) -> void:
	stage = STAGES[i][0]
	grav = STAGES[i][2]
	PhysicsServer2D.area_set_param(get_world_2d().space, PhysicsServer2D.AREA_PARAM_GRAVITY, 980.0 * grav)
	_apply_stage_look()
	if not quiet:
		toast("Welcome to the %s!" % STAGES[i][1])
		sfx.play("magic")


func _apply_stage_look() -> void:
	var bw = int(ceil(W / PX)) + 1
	var bh = int(ceil(H / PX)) + 1
	var gy = int(ground_y / PX)
	bg.texture = Pix.tex(Pix.background(stage, bw, bh, gy))
	if floor_body:
		floor_body.physics_material_override.bounce = 0.85 if stage == "candy" else 0.0
	machine.visible = stage == "lab"
	machine.position = Vector2(26 * PX / 2 + 16, 150 + 30 * PX / 2)


func start_scene() -> void:
	make_item("brick", Vector2(W * 0.2, ground_y - 12))
	make_item("brick", Vector2(W * 0.36, ground_y - 12))
	make_item("plank", Vector2(W * 0.28, ground_y - 32))
	spawn_rag(Pix.dummy_spec(), Vector2(W * 0.28, ground_y - 120))
	make_tramp(Vector2(W * 0.55, ground_y))
	spawn_rag(Pix.random_spec(), Vector2(W * 0.55, ground_y - 330))
	make_item("crate", Vector2(W * 0.78, ground_y - 24))
	make_item("duck", Vector2(W * 0.78, ground_y - 80))
	make_item("tnt", Vector2(W * 0.88, ground_y - 22))
	make_item("balloon", Vector2(W * 0.45, ground_y - 260))


func clear_all() -> void:
	for r in rags:
		if is_instance_valid(r):
			r.queue_free()
	rags = []
	for c in world.get_children():
		c.queue_free()
	drag_body = null


# ---------------- spawning ----------------
func spawn_rag(sp: Dictionary, pos: Vector2) -> Rag:
	var r = Rag.new()
	world.add_child(r)
	var s = float(sp.get("size", 1.0))
	pos.y = min(pos.y, ground_y - 80.0 * s)
	r.setup(self, sp, pos)
	rags.append(r)
	return r


func make_item(kind: String, pos: Vector2, size: float = 1.0) -> Node2D:
	if kind == "tramp":
		return make_tramp(Vector2(pos.x, ground_y), size)
	var b = RigidBody2D.new()
	var hue = randf()
	var im = Pix.item_img(kind, hue)
	var spr = Sprite2D.new()
	spr.texture = Pix.tex(im)
	spr.scale = Vector2(PX * size, PX * size)
	spr.name = "Spr"
	b.add_child(spr)
	var w = im.get_width() * PX * size
	var h = im.get_height() * PX * size
	var cs = CollisionShape2D.new()
	if kind in ["ball", "bowling", "balloon"]:
		var sh = CircleShape2D.new()
		sh.radius = min(w, h) * 0.46
		cs.shape = sh
		if kind == "balloon":
			cs.position = Vector2(0, -4 * size)
	else:
		var sh2 = RectangleShape2D.new()
		sh2.size = Vector2(w, h) * 0.95
		cs.shape = sh2
	b.add_child(cs)
	var mat = PhysicsMaterial.new()
	mat.friction = 0.7
	mat.bounce = 0.8 if kind == "ball" else 0.15
	b.physics_material_override = mat
	b.mass = ITEM_MASS.get(kind, 1.0) * size * size
	if kind == "balloon":
		b.gravity_scale = -0.35
		b.linear_damp = 1.5
	b.position = pos
	b.set_meta("kind", kind)
	b.set_meta("size", size)
	b.contact_monitor = true
	b.max_contacts_reported = 4
	b.body_entered.connect(_on_item_hit.bind(b))
	b.add_to_group("dyn")
	world.add_child(b)
	return b


func make_tramp(pos: Vector2, size: float = 1.0) -> StaticBody2D:
	var s = StaticBody2D.new()
	var im = Pix.item_img("tramp")
	var spr = Sprite2D.new()
	spr.texture = Pix.tex(im)
	spr.scale = Vector2(PX * size, PX * size)
	spr.name = "Spr"
	s.add_child(spr)
	var cs = CollisionShape2D.new()
	var sh = RectangleShape2D.new()
	sh.size = Vector2(im.get_width() * PX * size, 3 * PX * size)
	cs.shape = sh
	cs.position = Vector2(0, -1.5 * PX * size)
	s.add_child(cs)
	s.position = Vector2(pos.x, ground_y - im.get_height() * PX * size / 2)
	s.set_meta("kind", "tramp")
	s.set_meta("size", size)
	var area = Area2D.new()
	var acs = CollisionShape2D.new()
	var ash = RectangleShape2D.new()
	ash.size = Vector2(im.get_width() * PX * size * 0.95, 18)
	acs.shape = ash
	acs.position = Vector2(0, -im.get_height() * PX * size / 2 - 8)
	area.add_child(acs)
	area.body_entered.connect(_on_bounce.bind(s))
	s.add_child(area)
	world.add_child(s)
	return s


func _on_bounce(body, tramp) -> void:
	if not (body is RigidBody2D):
		return
	var vy = body.get_meta("pv", body.linear_velocity).y
	if vy < 120:
		return
	var up = clamp(abs(vy) * 0.95 + 120.0, 650.0, 1500.0)
	if body.has_meta("rag"):
		var r = body.get_meta("rag")
		r.set_vy(-up)
		if r.alive:
			r.say(["Boing!", "Yippee!", "Wheee!"].pick_random(), 1.1)
	else:
		body.linear_velocity.y = -up
	sfx.play("boing", 0.09)
	var spr = tramp.get_node("Spr")
	var tw = create_tween()
	tw.tween_property(spr, "scale:y", PX * 0.6, 0.06)
	tw.tween_property(spr, "scale:y", PX * float(tramp.get_meta("size", 1.0)), 0.18)


func _on_item_hit(other, b) -> void:
	var k = b.get_meta("kind", "")
	var pv: Vector2 = b.get_meta("pv", b.linear_velocity)
	var ov = Vector2.ZERO
	if other is RigidBody2D:
		ov = other.get_meta("pv", other.linear_velocity)
	var imp = (pv - ov).length()
	if imp > 300:
		sfx.play("clank" if k in ["steel", "bowling"] else "thud", 0.07)
	if k == "duck" and imp > 200:
		sfx.play("squeak", 0.15)
	if k == "tnt" and imp > 900 and not b.get_meta("boomed", false):
		b.set_meta("boomed", true)
		get_tree().create_timer(0.03).timeout.connect(_detonate.bind(b))
	if k == "balloon" and imp > 700 and other is RigidBody2D and other.mass > 0.5:
		get_tree().create_timer(0.01).timeout.connect(pop.bind(b))


# ---------------- effects ----------------
func burst(pos: Vector2, n: int, cols: Array, speed: float = 300.0, life: float = 0.6, size: float = 6.0, grav_y: float = 300.0) -> void:
	var p = CPUParticles2D.new()
	p.position = pos
	p.one_shot = true
	p.amount = n
	p.lifetime = life
	p.explosiveness = 1.0
	p.direction = Vector2.UP
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, grav_y)
	p.scale_amount_min = size * 0.6
	p.scale_amount_max = size
	var g = Gradient.new()
	g.colors = PackedColorArray(cols)
	var offs = PackedFloat32Array()
	for k in cols.size():
		offs.append(float(k) / max(1, cols.size() - 1))
	g.offsets = offs
	p.color_initial_ramp = g
	p.z_index = 20
	world.add_child(p)
	p.emitting = true
	get_tree().create_timer(life + 0.2).timeout.connect(p.queue_free)


func explode(c: Vector2, radius: float = 190.0, power: float = 1100.0) -> void:
	shake = 16.0
	sfx.play("boom")
	burst(c, 40, [Color("#fff1a8"), Color("#ffd23f"), Color("#ff8c32"), Color("#ff5a3c")], 520, 0.5, 10, 200)
	burst(c, 16, [Color(0.55, 0.55, 0.6, 0.8), Color(0.75, 0.75, 0.8, 0.6)], 160, 1.2, 14, -80)
	var hit = {}
	for r in rags:
		if not is_instance_valid(r):
			continue
		var dr = r.center() - c
		var dl = dr.length()
		if dl > radius:
			continue
		var fr = 1.0 - dl / radius
		var dirr = dr / dl if dl > 1 else Vector2.UP
		var kick = dirr * power * fr / sqrt(max(r.mass_total / 4.0, 0.5)) + Vector2(0, -200 * fr)
		for b in r.parts.values():
			b.linear_velocity += kick
			b.angular_velocity += randf_range(-4, 4) * fr
		hit[r] = true
		r.hurt(75 * fr)
	for b in get_tree().get_nodes_in_group("dyn"):
		if not is_instance_valid(b) or b.is_queued_for_deletion() or b.has_meta("rag"):
			continue
		var d = b.global_position - c
		var dist = d.length()
		if dist > radius:
			continue
		var f = 1.0 - dist / radius
		var dir = d / dist if dist > 1 else Vector2.UP
		b.linear_velocity += dir * power * f / sqrt(max(b.mass, 0.5)) + Vector2(0, -200 * f)
		b.angular_velocity += randf_range(-6, 6) * f
		if b.has_meta("rag"):
			var r = b.get_meta("rag")
			if not hit.has(r):
				hit[r] = true
				r.hurt(75 * f)
		var k = b.get_meta("kind", "")
		if k == "tnt" and not b.get_meta("boomed", false):
			b.set_meta("boomed", true)
			get_tree().create_timer(0.1 + randf() * 0.08).timeout.connect(_detonate.bind(b))
		elif k == "balloon":
			pop(b)


func _detonate(b) -> void:
	if not is_instance_valid(b):
		return
	var p = b.global_position
	b.queue_free()
	explode(p)


func pop(b) -> void:
	if not is_instance_valid(b) or b.is_queued_for_deletion():
		return
	burst(b.global_position, 14, [Color("#ffffff"), Color("#ff7ab6")], 260, 0.4, 5, 200)
	sfx.play("pop")
	b.queue_free()


# ---------------- frame loop ----------------
func _physics_process(_dt: float) -> void:
	var t = Time.get_ticks_msec() / 1000.0
	for b in get_tree().get_nodes_in_group("dyn"):
		b.set_meta("pv", b.linear_velocity)
		if b.position.y > H + 800 or b.position.y < -3000:
			if b.has_meta("rag"):
				remove_rag(b.get_meta("rag"))
			else:
				b.queue_free()
		var f = b.get_meta("fuse", 0.0)
		if f > 0.0 and t > f and not b.get_meta("boomed", false):
			b.set_meta("boomed", true)
			_detonate(b)
	if drag_body != null and is_instance_valid(drag_body):
		if drag_body is RigidBody2D:
			var gp = drag_body.to_global(drag_off)
			var is_rag = drag_body.has_meta("rag")
			var v = (pointer - gp) * (9.0 if is_rag else 14.0)
			var vmax = 1500.0 if is_rag else 2600.0
			if v.length() > vmax:
				v = v.normalized() * vmax
			drag_body.linear_velocity = drag_body.linear_velocity.lerp(v, 0.6)
			drag_body.angular_velocity *= 0.9
			if drag_body.has_meta("rag"):
				drag_body.get_meta("rag").drag_t = t
		else:
			drag_body.position = Vector2(pointer.x, drag_body.position.y)
	if holding and mode_kind == "tool" and mode_id in ["magnet", "wind"]:
		for b in get_tree().get_nodes_in_group("dyn"):
			var d = pointer - b.global_position
			var dist = d.length()
			if dist > 260 or dist < 1:
				continue
			var f2 = 1.0 - dist / 260.0
			var k = 55.0 if mode_id == "magnet" else -70.0
			b.linear_velocity += d / dist * k * f2
			if mode_id == "magnet" and dist < 40:
				b.linear_velocity *= 0.85
			if b.linear_velocity.length() > 1000:
				b.linear_velocity = b.linear_velocity.normalized() * 1000
			if b.has_meta("rag"):
				b.get_meta("rag").drag_t = t


func _process(delta: float) -> void:
	var t = Time.get_ticks_msec() / 1000.0
	shake = max(0.0, shake - delta * 40.0)
	var off = Vector2(randf_range(-shake, shake), randf_range(-shake, shake)) if shake > 0.3 else Vector2.ZERO
	world.position = off
	bg.position = off
	# TNT sparks
	for b in get_tree().get_nodes_in_group("dyn"):
		if b.get_meta("fuse", 0.0) > 0.0 and randf() < 0.4:
			burst(b.global_position + Vector2(0, -24).rotated(b.rotation), 2, [Color("#ffd23f"), Color("#ff8c32")], 80, 0.25, 4, 0)
	# machine
	var mt = t - machine_t
	if mt < 1.2:
		machine.texture = machine_tex[2 + (int(t * 12) % 2)]
		machine.offset = Vector2(randf_range(-0.6, 0.6), randf_range(-0.6, 0.6))
	else:
		machine.texture = machine_tex[int(t * 2) % 2]
		machine.offset = Vector2.ZERO
	if toast_label and t > toast_until:
		toast_label.modulate.a = max(0.0, toast_label.modulate.a - delta * 3)
	queue_redraw()


func _draw() -> void:
	# balloon strings and magnet/wind rings
	for b in get_tree().get_nodes_in_group("dyn"):
		if b.get_meta("kind", "") == "balloon":
			var p = b.global_position + Vector2(0, 22 * b.get_meta("size", 1.0)).rotated(b.rotation)
			var pts = PackedVector2Array([p, p + Vector2(4, 14), p + Vector2(-3, 26), p + Vector2(2, 38)])
			draw_polyline(pts, Color("#555555"), 2.0)
	if holding and mode_kind == "tool" and mode_id in ["magnet", "wind"]:
		var ph = fmod(Time.get_ticks_msec() / 600.0, 1.0)
		for k in 3:
			var f = fmod(ph + k / 3.0, 1.0)
			var r = 260.0 * (1.0 - f) if mode_id == "magnet" else 260.0 * f
			draw_arc(pointer, max(2.0, r), 0, TAU, 40, Color(1, 0.35, 0.35, 0.5) if mode_id == "magnet" else Color(1, 1, 1, 0.6), 4.0)


# ---------------- input ----------------
func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		pointer = e.position
		if e.pressed:
			_down(e.position)
		else:
			_up()
	elif e is InputEventMouseMotion:
		pointer = e.position


func body_at(p: Vector2):
	var space = get_world_2d().direct_space_state
	var q = PhysicsPointQueryParameters2D.new()
	q.position = p - world.position
	q.collide_with_areas = false
	var res = space.intersect_point(q, 16)
	var best = null
	var best_z = -99
	for r in res:
		var c = r.collider
		if c in statics:
			continue
		var z = c.z_index
		if best == null or z > best_z:
			best = c
			best_z = z
	if best == null:
		var sq = PhysicsShapeQueryParameters2D.new()
		var circ = CircleShape2D.new()
		circ.radius = 22
		sq.shape = circ
		sq.transform = Transform2D(0, p - world.position)
		for r in space.intersect_shape(sq, 8):
			if not (r.collider in statics):
				best = r.collider
				break
	return best


func _down(p: Vector2) -> void:
	holding = true
	if machine.visible and Rect2(machine.position - Vector2(13, 15) * PX, Vector2(26, 30) * PX).has_point(p):
		pull_machine()
		return
	if mode_kind == "item":
		var y = min(p.y, ground_y - 30)
		make_item(mode_id, Vector2(p.x, y))
		sfx.play("spawn")
		return
	if mode_kind == "char":
		var sp = chars[int(mode_id)] if mode_id.is_valid_int() and int(mode_id) < chars.size() else Pix.random_spec()
		var r = spawn_rag(sp, Vector2(p.x, min(p.y, ground_y - 60)))
		r.say("Hi! I'm %s!" % sp.name, 1.6, true)
		sfx.play("hi")
		return
	var b = body_at(p)
	match mode_id:
		"drag":
			if b:
				drag_body = b
				drag_off = b.to_local(p - world.position) if b is RigidBody2D else Vector2.ZERO
		"poke":
			if b:
				poke(b)
		"boom":
			explode(p)
		"heal":
			if b and b.has_meta("rag"):
				b.get_meta("rag").heal()
				sfx.play("magic")
				burst(b.global_position, 12, [Color("#ff6b8a"), Color("#ffb3c6")], 200, 0.6, 6, -100)
		"del":
			if b:
				burst(b.global_position, 10, [Color(1, 1, 1, 0.9)], 200, 0.4, 6, 0)
				sfx.play("pop")
				if b.has_meta("rag"):
					remove_rag(b.get_meta("rag"))
				else:
					b.queue_free()
		"grow":
			if b:
				resize_thing(b, 1.3)
		"shrink":
			if b:
				resize_thing(b, 1.0 / 1.3)
		"copy":
			if b:
				copy_thing(b)


func _up() -> void:
	holding = false
	drag_body = null


func poke(b) -> void:
	if b.has_meta("rag"):
		var r = b.get_meta("rag")
		if r.alive:
			r.set_vy(-560)
			r.say(["Hehe!", "Haha!", "That tickles!"].pick_random(), 1.3, true)
			sfx.play("giggle")
		else:
			r.say("Zzz", 1.0, true)
			toast("Sleeping! Use Heal to wake them up")
		return
	var k = b.get_meta("kind", "")
	match k:
		"tnt":
			if b.get_meta("fuse", 0.0) == 0.0:
				b.set_meta("fuse", Time.get_ticks_msec() / 1000.0 + 1.5)
				sfx.play("fuse")
				toast("Fuse lit! Stand back!")
		"balloon":
			pop(b)
		"duck":
			sfx.play("squeak")
			b.linear_velocity.y = -420
		"tramp":
			sfx.play("boing")
		_:
			if b is RigidBody2D:
				b.linear_velocity.y = -380
				sfx.play("thud")


func remove_rag(r) -> void:
	if not is_instance_valid(r):
		return
	rags.erase(r)
	if drag_body and is_instance_valid(drag_body) and drag_body.has_meta("rag") and drag_body.get_meta("rag") == r:
		drag_body = null
	r.queue_free()


func resize_thing(b, k: float) -> void:
	if b.has_meta("rag"):
		var r = b.get_meta("rag")
		var ns = clamp(snapped(r.s * k, 0.01), 0.6, 2.2)
		if abs(ns - r.s) < 0.01:
			toast("That's as big as it gets!" if k > 1 else "That's as small as it gets!")
			return
		var sp = r.spec.duplicate()
		sp.size = ns
		var pos = r.center()
		remove_rag(r)
		var nr = spawn_rag(sp, pos - Vector2(0, 10))
		nr.say("I'm huge!" if k > 1 else "I'm tiny!", 1.3, true)
	else:
		var kind = b.get_meta("kind", "")
		var ns2 = clamp(float(b.get_meta("size", 1.0)) * k, 0.4, 3.0)
		var pos2 = b.global_position
		b.queue_free()
		make_item(kind, pos2 - Vector2(0, 10), ns2)
	sfx.play("magic")


func copy_thing(b) -> void:
	if b.has_meta("rag"):
		var r = b.get_meta("rag")
		var nr = spawn_rag(r.spec, r.center() + Vector2(50 * r.s, -30))
		nr.say("Twins!", 1.3, true)
	else:
		make_item(b.get_meta("kind", "crate"), b.global_position + Vector2(36, -36), float(b.get_meta("size", 1.0)))
	sfx.play("magic")


# ---------------- random character machine ----------------
func pull_machine() -> void:
	var t = Time.get_ticks_msec() / 1000.0
	if t - machine_t < 1.3:
		return
	machine_t = t
	sfx.play("machine")
	await get_tree().create_timer(0.9).timeout
	var sp = Pix.random_spec()
	var out = machine.position + Vector2(0, 18 * PX)
	var r = spawn_rag(sp, out + Vector2(40, 10))
	r.push_all(Vector2(260, -160))
	r.say("Hi! I'm %s!" % sp.name, 2.0, true)
	sfx.play("fanfare")
	burst(out, 24, [Color("#ffd23f"), Color("#ff7ab6"), Color("#5ff5c8"), Color("#ffffff")], 320, 0.8, 6, 300)
	last_random = sp
	toast("Meet %s! Tap Keep in People to save them." % sp.name)
	if tab == "people":
		build_slots()


# ---------------- saving ----------------
func load_chars() -> void:
	chars = []
	if FileAccess.file_exists("user://chars.json"):
		var f = FileAccess.open("user://chars.json", FileAccess.READ)
		var data = JSON.parse_string(f.get_as_text())
		if data is Array:
			chars = data


func save_chars() -> void:
	var f = FileAccess.open("user://chars.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(chars))


# ---------------- UI ----------------
func _style(bgc: Color, border: Color, w: int = 4) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bgc
	sb.border_color = border
	sb.set_border_width_all(w)
	sb.set_corner_radius_all(0)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 0
	sb.shadow_offset = Vector2(4, 4)
	return sb


func build_ui() -> void:
	theme_ = Theme.new()
	theme_.default_font_size = 20
	var ink = Color("#2a2233")
	theme_.set_stylebox("normal", "Button", _style(Color("#fff7e6"), ink))
	theme_.set_stylebox("hover", "Button", _style(Color("#ffeccc"), ink))
	theme_.set_stylebox("pressed", "Button", _style(Color("#ffd23f"), ink))
	theme_.set_stylebox("focus", "Button", _style(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
	theme_.set_stylebox("disabled", "Button", _style(Color("#ddd"), ink))
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		theme_.set_color(k, "Button", ink)
	theme_.set_color("font_color", "Label", ink)
	theme_.set_stylebox("panel", "PanelContainer", _style(Color("#fff7e6"), ink))
	theme_.set_stylebox("normal", "LineEdit", _style(Color("#ffffff"), ink))
	theme_.set_color("font_color", "LineEdit", ink)
	ui = CanvasLayer.new()
	add_child(ui)
	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = theme_
	ui.add_child(root)
	# title
	var title = Label.new()
	title.text = "Matthew's Sandbox"
	title.position = Vector2(14, 8)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_outline_color", Color("#ffffff"))
	title.add_theme_constant_override("outline_size", 8)
	root.add_child(title)
	# top-right buttons
	var top = HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top.position = Vector2(-470, 8)
	top.size = Vector2(460, 50)
	top.alignment = BoxContainer.ALIGNMENT_END
	top.add_theme_constant_override("separation", 8)
	root.add_child(top)
	var b_stage = Button.new()
	b_stage.text = "Stage"
	b_stage.pressed.connect(func(): stage_panel.visible = not stage_panel.visible; sfx.play("click"))
	top.add_child(b_stage)
	sound_btn = Button.new()
	sound_btn.text = "Sound: on"
	sound_btn.pressed.connect(func(): sfx.muted = not sfx.muted; sound_btn.text = "Sound: off" if sfx.muted else "Sound: on")
	top.add_child(sound_btn)
	var b_clear = Button.new()
	b_clear.text = "Clear"
	b_clear.pressed.connect(func(): clear_all(); toast("Scene cleared"))
	top.add_child(b_clear)
	# toast
	toast_label = Label.new()
	toast_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_label.position = Vector2(-400, 66)
	toast_label.size = Vector2(800, 40)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size", 24)
	toast_label.add_theme_color_override("font_outline_color", Color("#ffffff"))
	toast_label.add_theme_constant_override("outline_size", 10)
	toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(toast_label)
	# dock
	var dock = PanelContainer.new()
	dock.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dock.offset_top = -150
	root.add_child(dock)
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	dock.add_child(vb)
	var tabs = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	vb.add_child(tabs)
	for t in [["people", "People"], ["things", "Things"], ["tools", "Tools"]]:
		var tb = Button.new()
		tb.text = t[1]
		tb.toggle_mode = true
		tb.custom_minimum_size = Vector2(120, 36)
		tb.pressed.connect(_set_tab.bind(t[0]))
		tabs.add_child(tb)
		tab_buttons[t[0]] = tb
	var sc = ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 96)
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(sc)
	slots = HBoxContainer.new()
	slots.add_theme_constant_override("separation", 6)
	sc.add_child(slots)
	build_stage_panel(root)
	build_maker(root)
	_set_tab("people")


func _set_tab(t: String) -> void:
	tab = t
	for k in tab_buttons:
		tab_buttons[k].button_pressed = k == t
	build_slots()
	sfx.play("click")


func _slot(icon_img: Image, label: String, on: bool, cb: Callable) -> Button:
	var b = Button.new()
	b.icon = Pix.tex(icon_img)
	b.text = label
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.custom_minimum_size = Vector2(96, 92)
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_constant_override("icon_max_width", 48)
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if on:
		b.add_theme_stylebox_override("normal", _style(Color("#ff6b4a"), Color("#2a2233")))
	b.pressed.connect(cb)
	slots.add_child(b)
	return b


func build_slots() -> void:
	for c in slots.get_children():
		c.queue_free()
	if tab == "people":
		_slot(Pix.icon("dice"), "Random", mode_kind == "char" and mode_id == "random", func(): _pick("char", "random"))
		_slot(Pix.face_icon(Pix.dummy_spec()), "Dummy", mode_kind == "char" and mode_id == "dummy", func(): _pick("char", "dummy"))
		for k in chars.size():
			var sp = chars[k]
			var sel = mode_kind == "char" and mode_id == str(k)
			_slot(Pix.face_icon(sp), String(sp.name).substr(0, 9), sel, _pick_char.bind(k))
		if last_random != null:
			_slot(Pix.icon("keep"), "Keep", false, func(): keep_random())
		_slot(Pix.icon("new"), "New", false, func(): open_maker(-1))
	elif tab == "things":
		for k in ITEMS:
			_slot(Pix.item_img(k, 0.95), ITEM_NAMES[k], mode_kind == "item" and mode_id == k, _pick.bind("item", k))
	else:
		for t in TOOLS:
			_slot(Pix.icon(t[0]), t[1], mode_kind == "tool" and mode_id == t[0], _pick.bind("tool", t[0]))


func _pick(kind: String, id: String) -> void:
	mode_kind = kind
	mode_id = id
	sfx.play("click")
	var hints = {"drag": "Drag and fling things", "poke": "Tickle people, light TNT, pop balloons", "boom": "Tap anywhere to blast",
		"heal": "Tap a sleeping friend to wake them", "del": "Tap something to remove it", "magnet": "Hold your finger down to pull things in",
		"wind": "Hold your finger down to blow things away", "grow": "Tap something to make it bigger", "shrink": "Tap something to make it smaller",
		"copy": "Tap something to make a twin"}
	if kind == "tool":
		toast(hints.get(id, ""))
	elif kind == "item":
		toast("Tap the screen to drop a %s" % ITEM_NAMES[id].to_lower())
	elif id == "random":
		toast("Tap the screen: a new friend every time!")
	else:
		toast("Tap the screen to drop them")
	build_slots()


func _pick_char(k: int) -> void:
	if mode_kind == "char" and mode_id == str(k):
		open_maker(k)
		return
	_pick("char", str(k))
	toast("Tap to drop %s. Tap the button again to change them." % chars[k].name)


func keep_random() -> void:
	if last_random == null:
		return
	chars.append(last_random.duplicate())
	save_chars()
	toast("%s is saved in People!" % last_random.name)
	last_random = null
	sfx.play("fanfare")
	build_slots()


func toast(t: String) -> void:
	if toast_label == null:
		return
	toast_label.text = t
	toast_label.modulate.a = 1.0
	toast_until = Time.get_ticks_msec() / 1000.0 + 1.8


# ---------------- stage picker ----------------
func build_stage_panel(root: Control) -> void:
	stage_panel = PanelContainer.new()
	stage_panel.set_anchors_preset(Control.PRESET_CENTER)
	stage_panel.position = Vector2(-330, -120)
	stage_panel.size = Vector2(660, 200)
	stage_panel.visible = false
	root.add_child(stage_panel)
	var vb = VBoxContainer.new()
	stage_panel.add_child(vb)
	var l = Label.new()
	l.text = "Pick a stage"
	l.add_theme_font_size_override("font_size", 26)
	vb.add_child(l)
	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	vb.add_child(hb)
	for k in STAGES.size():
		var b = Button.new()
		b.text = STAGES[k][1]
		b.custom_minimum_size = Vector2(118, 90)
		b.icon = Pix.tex(Pix.background(STAGES[k][0], 30, 20, 15))
		b.expand_icon = true
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.add_theme_constant_override("icon_max_width", 90)
		b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		b.pressed.connect(func(): set_stage(k); stage_panel.visible = false)
		hb.add_child(b)


# ---------------- character maker ----------------
const MAKER_ROWS = [["Skin", "skin", "SKINS"], ["Hair", "hair", "HAIRS"], ["Hair colour", "hair_col", "HAIR_COLS"],
	["Top", "top", "TOPS"], ["Top colour", "top_col", "CLOTH"], ["Second colour", "top_col2", "CLOTH"],
	["Sleeves", "sleeves", "SLEEVES"], ["Bottom", "bottom", "BOTTOMS"], ["Bottom colour", "bot_col", "CLOTH"],
	["Shoes", "shoe_col", "SHOES"], ["Size", "size", "SIZES"]]


func _list(name: String) -> Array:
	match name:
		"SKINS":
			return Pix.SKINS
		"HAIRS":
			return Pix.HAIRS
		"HAIR_COLS":
			return Pix.HAIR_COLS
		"TOPS":
			return Pix.TOPS
		"CLOTH":
			return Pix.CLOTH
		"SLEEVES":
			return Pix.SLEEVES
		"BOTTOMS":
			return Pix.BOTTOMS
		"SHOES":
			return Pix.SHOES
		"SIZES":
			return Pix.SIZES
	return []


func build_maker(root: Control) -> void:
	maker = PanelContainer.new()
	maker.set_anchors_preset(Control.PRESET_FULL_RECT)
	maker.offset_left = 40
	maker.offset_right = -40
	maker.offset_top = 20
	maker.offset_bottom = -20
	maker.visible = false
	root.add_child(maker)
	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 24)
	maker.add_child(hb)
	var left = VBoxContainer.new()
	hb.add_child(left)
	var l = Label.new()
	l.text = "Make a character"
	l.add_theme_font_size_override("font_size", 28)
	left.add_child(l)
	maker_preview = TextureRect.new()
	maker_preview.custom_minimum_size = Vector2(240, 465)
	maker_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	maker_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	maker_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	left.add_child(maker_preview)
	var right = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 4)
	hb.add_child(right)
	var nrow = HBoxContainer.new()
	right.add_child(nrow)
	var nl = Label.new()
	nl.text = "Name"
	nl.custom_minimum_size = Vector2(170, 0)
	nrow.add_child(nl)
	maker_name = LineEdit.new()
	maker_name.max_length = 12
	maker_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	maker_name.text_changed.connect(func(t): maker_spec.name = t)
	nrow.add_child(maker_name)
	var sc = ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(sc)
	maker_rows = VBoxContainer.new()
	maker_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(maker_rows)
	var foot = HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_END
	foot.add_theme_constant_override("separation", 8)
	right.add_child(foot)
	for bdef in [["Random", "rand"], ["Delete", "del"], ["Cancel", "cancel"], ["Save", "save"]]:
		var b = Button.new()
		b.text = bdef[0]
		b.custom_minimum_size = Vector2(120, 48)
		b.name = "B_" + bdef[1]
		b.pressed.connect(_maker_btn.bind(bdef[1]))
		foot.add_child(b)


func open_maker(index: int) -> void:
	maker_edit_index = index
	maker_spec = chars[index].duplicate() if index >= 0 else Pix.random_spec()
	maker.find_child("B_del", true, false).visible = index >= 0
	maker.visible = true
	_refresh_maker()
	sfx.play("click")


func _refresh_maker() -> void:
	maker_name.text = maker_spec.name
	maker_preview.texture = Pix.tex(Pix.full_img(maker_spec))
	for c in maker_rows.get_children():
		c.queue_free()
	for row in MAKER_ROWS:
		var hb = HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)
		maker_rows.add_child(hb)
		var l = Label.new()
		l.text = row[0]
		l.custom_minimum_size = Vector2(170, 0)
		hb.add_child(l)
		var prev = Button.new()
		prev.text = " < "
		prev.pressed.connect(_maker_cycle.bind(row[1], row[2], -1))
		hb.add_child(prev)
		var val = maker_spec.get(row[1])
		if row[2] in ["SKINS", "HAIR_COLS", "CLOTH", "SHOES"]:
			var cr = ColorRect.new()
			cr.color = Color(val)
			cr.custom_minimum_size = Vector2(120, 34)
			hb.add_child(cr)
		else:
			var vl = Label.new()
			vl.custom_minimum_size = Vector2(120, 0)
			vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vl.text = {0.75: "Small", 1.0: "Normal", 1.35: "Big"}.get(val, str(val)) if row[2] == "SIZES" else str(val).capitalize()
			hb.add_child(vl)
		var nxt = Button.new()
		nxt.text = " > "
		nxt.pressed.connect(_maker_cycle.bind(row[1], row[2], 1))
		hb.add_child(nxt)


func _maker_cycle(key: String, list_name: String, d: int) -> void:
	var lst = _list(list_name)
	var idx = lst.find(maker_spec.get(key))
	idx = (idx + d + lst.size()) % lst.size()
	maker_spec[key] = lst[idx]
	sfx.play("click")
	_refresh_maker()


func _maker_btn(which: String) -> void:
	match which:
		"rand":
			var nm = maker_spec.name
			maker_spec = Pix.random_spec()
			if maker_edit_index >= 0:
				maker_spec.name = nm
			sfx.play("magic")
			_refresh_maker()
		"cancel":
			maker.visible = false
		"del":
			if maker_edit_index >= 0:
				chars.remove_at(maker_edit_index)
				save_chars()
				mode_kind = "char"
				mode_id = "random"
			maker.visible = false
			build_slots()
		"save":
			if String(maker_spec.name).strip_edges() == "":
				maker_spec.name = Pix.NAMES.pick_random()
			if maker_edit_index >= 0:
				chars[maker_edit_index] = maker_spec.duplicate()
				mode_id = str(maker_edit_index)
			else:
				chars.append(maker_spec.duplicate())
				mode_id = str(chars.size() - 1)
			mode_kind = "char"
			save_chars()
			maker.visible = false
			tab = "people"
			build_slots()
			sfx.play("fanfare")
			toast("Tap the screen to drop %s!" % maker_spec.name)
