class_name Pix
extends RefCounted
## Pixel-art generator: every character part, item, icon and background is drawn here in code.

const SKINS = ["#ffdbb5", "#f1c27d", "#e0ac69", "#c68642", "#8d5524", "#5c3a21"]
const HAIR_COLS = ["#2b1d14", "#5a3825", "#a0522d", "#e8701e", "#f4c542", "#9e9e9e", "#d95b8a", "#3b6fd6"]
const CLOTH = ["#e84a4a", "#f59e2b", "#f7d43c", "#4cbf56", "#2fb0a8", "#3b82f6", "#6c4ad6", "#e86aa8", "#ffffff", "#3a3f4a", "#8b5a2b", "#9aa4b0"]
const SHOES = ["#3a3f4a", "#e84a4a", "#3b82f6", "#ffffff", "#8b5a2b", "#f59e2b"]
const HAIRS = ["short", "spiky", "bob", "long", "pigtails", "cap", "curly", "bald"]
const TOPS = ["tee", "vest", "overalls", "dress", "checker", "stripes", "hoodie"]
const BOTTOMS = ["pants", "shorts", "skirt"]
const SLEEVES = ["short", "long", "none"]
const SIZES = [0.75, 1.0, 1.35]
const NAMES = ["Max", "Zoe", "Leo", "Mia", "Bolt", "Pip", "Rex", "Luna", "Kiko", "Taro", "Nala", "Ziggy", "Ana", "Jojo", "Bea", "Migs"]


static func c(h) -> Color:
	return Color(h)


static func dark(col: Color, f: float = 0.78) -> Color:
	return Color(col.r * f, col.g * f, col.b * f, col.a)


static func random_spec() -> Dictionary:
	var sz = 1.0
	var r = randf()
	if r < 0.15:
		sz = 0.75
	elif r > 0.85:
		sz = 1.35
	return {
		"name": NAMES.pick_random(), "skin": SKINS.pick_random(), "hair": HAIRS.pick_random(),
		"hair_col": HAIR_COLS.pick_random(), "top": TOPS.pick_random(), "top_col": CLOTH.pick_random(),
		"top_col2": CLOTH.pick_random(), "sleeves": SLEEVES.pick_random(), "bottom": BOTTOMS.pick_random(),
		"bot_col": CLOTH.pick_random(), "shoe_col": SHOES.pick_random(), "size": sz
	}


static func dummy_spec() -> Dictionary:
	return {"name": "Dummy", "skin": "#f7d43c", "hair": "bald", "hair_col": "#2b1d14", "top": "tee", "top_col": "#f7d43c",
		"top_col2": "#3a3f4a", "sleeves": "none", "bottom": "pants", "bot_col": "#f7d43c", "shoe_col": "#3a3f4a", "size": 1.0, "dummy": true}


static func img(w: int, h: int) -> Image:
	var i = Image.create(w, h, false, Image.FORMAT_RGBA8)
	i.fill(Color(0, 0, 0, 0))
	return i


static func rect(i: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			if xx >= 0 and yy >= 0 and xx < i.get_width() and yy < i.get_height():
				i.set_pixel(xx, yy, col)


static func px(i: Image, x: int, y: int, col: Color) -> void:
	rect(i, x, y, 1, 1, col)


static func disc(i: Image, cx: float, cy: float, r: float, col: Color) -> void:
	for yy in i.get_height():
		for xx in i.get_width():
			if (xx + 0.5 - cx) * (xx + 0.5 - cx) + (yy + 0.5 - cy) * (yy + 0.5 - cy) <= r * r:
				i.set_pixel(xx, yy, col)


static func tex(i: Image) -> ImageTexture:
	return ImageTexture.create_from_image(i)


# ---------------- character parts ----------------
static func head_img(sp: Dictionary, face: String) -> Image:
	var i = img(12, 14)
	var skin = c(sp.skin)
	var hc = c(sp.hair_col)
	var hs = sp.hair
	# hair behind the face
	if hs == "long":
		rect(i, 1, 3, 10, 11, hc)
	elif hs == "bob":
		rect(i, 1, 3, 10, 8, hc)
	elif hs == "pigtails":
		rect(i, 0, 5, 2, 5, hc)
		rect(i, 10, 5, 2, 5, hc)
		px(i, 1, 5, c("#e84a4a"))
		px(i, 10, 5, c("#e84a4a"))
	elif hs == "curly":
		rect(i, 1, 2, 10, 6, hc)
	# face
	rect(i, 2, 3, 8, 8, skin)
	rect(i, 9, 3, 1, 8, dark(skin, 0.9))
	if sp.get("dummy", false):
		# crash-test dummy target mark
		px(i, 2, 4, c("#3a3f4a"))
		px(i, 9, 4, c("#3a3f4a"))
	# hair in front
	match hs:
		"short":
			rect(i, 2, 1, 8, 3, hc)
			px(i, 2, 4, hc)
			px(i, 9, 4, hc)
		"spiky":
			rect(i, 2, 2, 8, 2, hc)
			for xx in [2, 4, 7, 9]:
				px(i, xx, 1, hc)
			px(i, 4, 0, hc)
			px(i, 7, 0, hc)
			px(i, 2, 4, hc)
			px(i, 9, 4, hc)
		"bob":
			rect(i, 2, 1, 8, 3, hc)
			rect(i, 1, 2, 1, 8, hc)
			rect(i, 10, 2, 1, 8, hc)
		"long":
			rect(i, 2, 1, 8, 3, hc)
			rect(i, 1, 2, 1, 9, hc)
			rect(i, 10, 2, 1, 9, hc)
		"pigtails":
			rect(i, 2, 1, 8, 3, hc)
			px(i, 2, 4, hc)
			px(i, 9, 4, hc)
		"cap":
			var cc = c(sp.top_col2)
			rect(i, 2, 0, 8, 3, cc)
			rect(i, 1, 3, 11, 1, dark(cc))
			px(i, 5, 1, c("#ffffff"))
			px(i, 2, 4, hc)
			px(i, 9, 4, hc)
		"curly":
			for xx in range(1, 11, 2):
				px(i, xx, 0, hc)
			rect(i, 1, 1, 10, 3, hc)
			rect(i, 1, 4, 1, 2, hc)
			rect(i, 10, 4, 1, 2, hc)
		"bald":
			px(i, 3, 3, Color(1, 1, 1, 0.35))
	# face features
	var ink = c("#222222")
	var lip = c("#b03a3a")
	if face == "n":
		px(i, 4, 6, ink)
		px(i, 7, 6, ink)
		px(i, 4, 8, lip)
		px(i, 7, 8, lip)
		rect(i, 5, 9, 2, 1, lip)
	elif face == "b":
		rect(i, 3, 6, 2, 1, ink)
		rect(i, 7, 6, 2, 1, ink)
		rect(i, 5, 9, 2, 1, lip)
	elif face == "o":
		rect(i, 3, 6, 2, 1, ink)
		rect(i, 7, 6, 2, 1, ink)
		rect(i, 5, 8, 2, 2, ink)
	else:
		for d in [[3, 5], [5, 5], [4, 6], [3, 7], [5, 7], [6, 5], [8, 5], [7, 6], [6, 7], [8, 7]]:
			px(i, d[0], d[1], ink)
		rect(i, 5, 9, 2, 1, ink)
	if face != "k":
		px(i, 3, 8, Color(1, 0.5, 0.5, 0.55))
		px(i, 8, 8, Color(1, 0.5, 0.5, 0.55))
	return i


static func is_dress(sp: Dictionary) -> bool:
	return sp.top in ["dress", "checker"]


static func torso_img(sp: Dictionary) -> Image:
	var i = img(8, 9)
	var t = c(sp.top_col)
	var t2 = c(sp.top_col2)
	var b = c(sp.bot_col)
	var skin = c(sp.skin)
	match sp.top:
		"vest":
			rect(i, 0, 0, 8, 9, t)
			rect(i, 0, 0, 2, 9, t2)
			rect(i, 6, 0, 2, 9, t2)
		"overalls":
			rect(i, 0, 0, 8, 9, t)
			rect(i, 2, 3, 4, 6, b)
			rect(i, 2, 0, 1, 3, b)
			rect(i, 5, 0, 1, 3, b)
			px(i, 2, 3, c("#ffd23f"))
			px(i, 5, 3, c("#ffd23f"))
		"dress":
			rect(i, 0, 0, 8, 9, t)
			rect(i, 0, 5, 8, 1, t2)
		"checker":
			for y in 9:
				for x in 8:
					px(i, x, y, t if (x + y) % 2 == 0 else dark(t, 0.8))
		"stripes":
			for y in 9:
				rect(i, 0, y, 8, 1, t if y % 2 == 0 else t2)
		"hoodie":
			rect(i, 0, 0, 8, 9, t)
			rect(i, 3, 1, 2, 3, dark(t, 0.7))
			rect(i, 2, 6, 4, 2, dark(t, 0.85))
		_:
			rect(i, 0, 0, 8, 9, t)
	if sp.get("dummy", false):
		rect(i, 3, 2, 2, 2, c("#3a3f4a"))
		px(i, 3, 2, c("#ffffff"))
		px(i, 4, 3, c("#ffffff"))
	rect(i, 3, 0, 2, 1, skin)
	if sp.top in ["tee", "vest", "stripes", "hoodie"]:
		rect(i, 0, 8, 8, 1, b)
	for y in 9:
		px(i, 7, y, dark(i.get_pixel(7, y), 0.88))
	return i


static func uarm_img(sp: Dictionary) -> Image:
	var i = img(2, 5)
	var col = c(sp.top_col)
	if sp.sleeves == "none" or (is_dress(sp) and sp.sleeves != "long"):
		col = c(sp.skin)
	rect(i, 0, 0, 2, 5, col)
	rect(i, 1, 0, 1, 5, dark(col, 0.9))
	return i


static func larm_img(sp: Dictionary) -> Image:
	var i = img(2, 5)
	var col = c(sp.top_col) if sp.sleeves == "long" else c(sp.skin)
	rect(i, 0, 0, 2, 3, col)
	rect(i, 0, 3, 2, 2, c(sp.skin))
	rect(i, 1, 0, 1, 5, Color(0, 0, 0, 0.1))
	return i


static func thigh_img(sp: Dictionary) -> Image:
	var i = img(3, 5)
	var skin = c(sp.skin)
	if is_dress(sp):
		rect(i, 0, 0, 3, 5, skin)
		rect(i, 0, 0, 3, 3, c(sp.top_col))
	elif sp.bottom == "skirt" and sp.top != "overalls":
		rect(i, 0, 0, 3, 5, skin)
		rect(i, 0, 0, 3, 3, c(sp.bot_col))
	else:
		rect(i, 0, 0, 3, 5, c(sp.bot_col))
	rect(i, 2, 0, 1, 5, Color(0, 0, 0, 0.1))
	return i


static func shin_img(sp: Dictionary) -> Image:
	var i = img(3, 6)
	var long = (sp.bottom == "pants" and not is_dress(sp)) or sp.top == "overalls"
	rect(i, 0, 0, 3, 4, c(sp.bot_col) if long else c(sp.skin))
	var sc = c(sp.shoe_col)
	rect(i, 0, 4, 3, 2, sc)
	rect(i, 0, 5, 3, 1, dark(sc, 0.7))
	return i


## Whole character, standing, for previews and buttons (16 x 31 pixels).
static func full_img(sp: Dictionary) -> Image:
	var i = img(16, 31)
	var parts = [[thigh_img(sp), 4, 20], [thigh_img(sp), 9, 20], [shin_img(sp), 4, 25], [shin_img(sp), 9, 25],
		[torso_img(sp), 4, 11], [uarm_img(sp), 2, 11], [uarm_img(sp), 12, 11], [larm_img(sp), 2, 16], [larm_img(sp), 12, 16],
		[head_img(sp, "n"), 2, 0]]
	for p in parts:
		var src: Image = p[0]
		i.blend_rect(src, Rect2i(0, 0, src.get_width(), src.get_height()), Vector2i(p[1], p[2]))
	return i


static func face_icon(sp: Dictionary) -> Image:
	return head_img(sp, "n")


# ---------------- items ----------------
static func item_img(kind: String, hue: float = 0.0) -> Image:
	var i: Image
	match kind:
		"crate":
			i = img(12, 12)
			rect(i, 0, 0, 12, 12, c("#c8894a"))
			rect(i, 0, 0, 12, 1, c("#7a4f24"))
			rect(i, 0, 11, 12, 1, c("#7a4f24"))
			rect(i, 0, 0, 1, 12, c("#7a4f24"))
			rect(i, 11, 0, 1, 12, c("#7a4f24"))
			for k in range(1, 11):
				px(i, k, k, c("#8e5d2c"))
				px(i, k, 11 - k, c("#a8723c"))
		"steel":
			i = img(10, 10)
			rect(i, 0, 0, 10, 10, c("#9aa6b2"))
			rect(i, 0, 9, 10, 1, c("#545f6b"))
			rect(i, 9, 0, 1, 10, c("#545f6b"))
			rect(i, 1, 1, 8, 1, c("#c8d0d8"))
			for d in [[2, 2], [7, 2], [2, 7], [7, 7]]:
				px(i, d[0], d[1], c("#5f6b77"))
		"ball":
			i = img(9, 9)
			disc(i, 4.5, 4.5, 4.5, c("#ef4b4b"))
			for y in range(5, 9):
				for x in 9:
					if i.get_pixel(x, y).a > 0:
						px(i, x, y, c("#f7f7f2"))
			for x in 9:
				if i.get_pixel(x, 4).a > 0:
					px(i, x, 4, c("#2a2233"))
			px(i, 2, 2, c("#ffffff"))
		"bowling":
			i = img(10, 10)
			disc(i, 5, 5, 5, c("#2b3f8c"))
			for d in [[3, 3], [5, 2], [4, 5]]:
				px(i, d[0], d[1], c("#0d1533"))
			px(i, 7, 6, c("#5c74c8"))
		"tnt":
			i = img(8, 11)
			rect(i, 0, 1, 8, 10, c("#d8312a"))
			rect(i, 0, 4, 8, 3, c("#f4e3c3"))
			rect(i, 1, 5, 6, 1, c("#7a1410"))
			rect(i, 7, 1, 1, 10, c("#a32218"))
			px(i, 4, 0, c("#3a2a1a"))
			px(i, 5, 0, c("#3a2a1a"))
		"balloon":
			i = img(8, 11)
			var bc = Color.from_hsv(hue, 0.7, 0.95)
			disc(i, 4, 4.5, 4.2, bc)
			px(i, 2, 2, c("#ffffff"))
			px(i, 2, 3, Color(1, 1, 1, 0.6))
			px(i, 4, 9, dark(bc))
			px(i, 4, 10, c("#888888"))
		"plank":
			i = img(40, 4)
			rect(i, 0, 0, 40, 4, c("#d9a066"))
			rect(i, 0, 3, 40, 1, c("#8a5a2b"))
			rect(i, 3, 1, 14, 1, c("#b07a43"))
			rect(i, 22, 2, 12, 1, c("#b07a43"))
		"brick":
			i = img(12, 6)
			rect(i, 0, 0, 12, 6, c("#c4533a"))
			rect(i, 0, 3, 12, 1, c("#e8b4a4"))
			px(i, 4, 1, c("#e8b4a4"))
			px(i, 4, 2, c("#e8b4a4"))
			px(i, 8, 4, c("#e8b4a4"))
			px(i, 8, 5, c("#e8b4a4"))
		"duck":
			i = img(10, 9)
			rect(i, 1, 4, 8, 4, c("#ffd23f"))
			rect(i, 0, 5, 1, 2, c("#ffd23f"))
			rect(i, 5, 1, 4, 4, c("#ffd23f"))
			px(i, 7, 2, c("#1f2a33"))
			rect(i, 9, 3, 1, 1, c("#ff8c32"))
			rect(i, 2, 5, 3, 2, c("#e6b800"))
			rect(i, 1, 8, 8, 1, c("#c99700"))
		"tramp":
			i = img(28, 7)
			rect(i, 0, 1, 28, 2, c("#ff5a7a"))
			rect(i, 1, 0, 26, 1, c("#3aa0ff"))
			for x in range(3, 26, 5):
				px(i, x, 2, c("#ffd23f"))
			rect(i, 2, 3, 1, 4, c("#5b6573"))
			rect(i, 25, 3, 1, 4, c("#5b6573"))
		_:
			i = img(8, 8)
			rect(i, 0, 0, 8, 8, c("#999999"))
	return i


# ---------------- icons (12 x 12) ----------------
static func icon(name: String) -> Image:
	var i = img(12, 12)
	var ink = c("#2a2233")
	match name:
		"drag":
			rect(i, 3, 4, 7, 6, c("#ffcf9e"))
			for x in [3, 5, 7]:
				rect(i, x, 1, 2, 4, c("#ffcf9e"))
			rect(i, 10, 5, 1, 3, c("#ffcf9e"))
			rect(i, 3, 10, 7, 1, ink)
		"poke":
			rect(i, 5, 1, 2, 6, c("#ffcf9e"))
			rect(i, 3, 6, 7, 5, c("#ffcf9e"))
			rect(i, 3, 11, 7, 1, ink)
		"boom":
			disc(i, 6, 7, 4.5, c("#2a2233"))
			px(i, 8, 2, c("#ffd23f"))
			px(i, 9, 1, c("#ff8c32"))
			px(i, 4, 5, c("#8a8a9a"))
		"heal":
			rect(i, 2, 3, 3, 4, c("#ff4d6d"))
			rect(i, 7, 3, 3, 4, c("#ff4d6d"))
			rect(i, 2, 5, 8, 2, c("#ff4d6d"))
			rect(i, 3, 7, 6, 2, c("#ff4d6d"))
			rect(i, 5, 9, 2, 1, c("#ff4d6d"))
			px(i, 3, 4, c("#ffffff"))
		"del":
			for k in 10:
				px(i, k + 1, k + 1, c("#e84a4a"))
				px(i, k + 2, k + 1, c("#e84a4a"))
				px(i, 10 - k, k + 1, c("#e84a4a"))
				px(i, 11 - k, k + 1, c("#e84a4a"))
		"magnet":
			rect(i, 2, 2, 3, 7, c("#e84a4a"))
			rect(i, 7, 2, 3, 7, c("#e84a4a"))
			rect(i, 2, 8, 8, 2, c("#e84a4a"))
			rect(i, 2, 1, 3, 2, c("#c8d0d8"))
			rect(i, 7, 1, 3, 2, c("#c8d0d8"))
		"wind":
			rect(i, 1, 3, 8, 1, c("#5ab8ff"))
			rect(i, 2, 6, 9, 1, c("#5ab8ff"))
			rect(i, 1, 9, 6, 1, c("#5ab8ff"))
			px(i, 9, 2, c("#5ab8ff"))
			px(i, 11, 5, c("#5ab8ff"))
		"grow":
			rect(i, 5, 3, 2, 8, c("#4cbf56"))
			rect(i, 3, 5, 6, 1, c("#4cbf56"))
			rect(i, 4, 4, 4, 1, c("#4cbf56"))
			px(i, 5, 2, c("#4cbf56"))
			px(i, 6, 2, c("#4cbf56"))
		"shrink":
			rect(i, 5, 1, 2, 8, c("#f59e2b"))
			rect(i, 3, 7, 6, 1, c("#f59e2b"))
			rect(i, 4, 8, 4, 1, c("#f59e2b"))
			px(i, 5, 9, c("#f59e2b"))
			px(i, 6, 9, c("#f59e2b"))
		"copy":
			rect(i, 1, 1, 7, 7, c("#c084fc"))
			rect(i, 4, 4, 7, 7, c("#6c4ad6"))
		"new":
			rect(i, 5, 1, 2, 10, c("#4cbf56"))
			rect(i, 1, 5, 10, 2, c("#4cbf56"))
		"dice":
			rect(i, 1, 1, 10, 10, c("#ffffff"))
			rect(i, 1, 11, 10, 1, ink)
			for d in [[3, 3], [8, 3], [5, 5], [3, 8], [8, 8]]:
				rect(i, d[0], d[1], 1, 1, ink)
		"keep":
			rect(i, 1, 1, 10, 10, c("#3b82f6"))
			rect(i, 3, 1, 6, 4, c("#e9f2ff"))
			rect(i, 3, 7, 6, 4, c("#1f4ea8"))
		"gift":
			rect(i, 1, 4, 10, 7, c("#ff6bb5"))
			rect(i, 1, 3, 10, 2, c("#e84a8a"))
			rect(i, 5, 3, 2, 8, c("#ffd23f"))
			px(i, 4, 2, c("#ffd23f"))
			px(i, 7, 2, c("#ffd23f"))
	return i


# ---------------- random character machine (24 x 30), lever 0 = up, 1 = down ----------------
static func machine_img(lever: int, lights: int) -> Image:
	var i = img(26, 30)
	var body = c("#6c4ad6")
	rect(i, 1, 2, 20, 24, body)
	rect(i, 1, 2, 20, 1, c("#9d7cf0"))
	rect(i, 20, 2, 1, 24, dark(body))
	rect(i, 4, 5, 14, 10, c("#1d1a33"))
	# question mark on screen
	var q = c("#5ff5c8")
	rect(i, 9, 7, 4, 1, q)
	px(i, 13, 8, q)
	px(i, 12, 9, q)
	px(i, 11, 10, q)
	px(i, 11, 12, q)
	# lights
	var cols = [c("#ff4d5e"), c("#ffd23f"), c("#4ade80"), c("#5ab8ff")]
	for k in 4:
		var on = (k + lights) % 2 == 0
		rect(i, 4 + k * 4, 17, 2, 2, cols[k] if on else dark(cols[k], 0.4))
	# chute
	rect(i, 6, 21, 10, 5, c("#2a2233"))
	rect(i, 6, 26, 10, 2, c("#9aa4b0"))
	# lever
	rect(i, 21, 13, 2, 6, c("#5b6573"))
	if lever == 0:
		rect(i, 22, 3, 1, 10, c("#9aa4b0"))
		rect(i, 21, 1, 3, 3, c("#ff4d5e"))
	else:
		rect(i, 22, 14, 1, 10, c("#9aa4b0"))
		rect(i, 21, 23, 3, 3, c("#ff4d5e"))
	# legs
	rect(i, 2, 26, 2, 4, c("#3a3f4a"))
	rect(i, 18, 26, 2, 4, c("#3a3f4a"))
	return i


# ---------------- backgrounds (bw x bh pixels, ground at gy) ----------------
static func background(stage: String, bw: int, bh: int, gy: int) -> Image:
	var i = img(bw, bh)
	var rng = RandomNumberGenerator.new()
	rng.seed = 42
	match stage:
		"lab":
			rect(i, 0, 0, bw, gy, c("#cfe8e4"))
			for x in range(0, bw, 10):
				rect(i, x, 0, 1, gy, c("#bcd9d4"))
			for y in range(0, gy, 10):
				rect(i, 0, y, bw, 1, c("#bcd9d4"))
			rect(i, 0, gy, bw, bh - gy, c("#3b4656"))
			for x in range(0, bw, 6):
				rect(i, x, gy, 3, 2, c("#ffc23d"))
			rect(i, 0, gy + 2, bw, 1, c("#2a3340"))
		"park":
			var sky = [c("#7fcbff"), c("#95d6ff"), c("#acdfff"), c("#c4e9ff")]
			for k in 4:
				rect(i, 0, k * gy / 4, bw, gy / 4 + 1, sky[k])
			disc(i, bw - 30, 22, 9, c("#ffe066"))
			for k in 5:
				var cx = rng.randi_range(10, bw - 30)
				var cy = rng.randi_range(12, 50)
				rect(i, cx, cy, 22, 5, c("#ffffff"))
				rect(i, cx + 4, cy - 3, 12, 3, c("#ffffff"))
			for k in 3:
				disc(i, bw * (0.2 + k * 0.33), gy + 10, 40 + k * 6, c("#8fd07c"))
			rect(i, 0, gy, bw, bh - gy, c("#7a5434"))
			rect(i, 0, gy, bw, 3, c("#5cbf4a"))
			for x in range(0, bw, 3):
				px(i, x, gy - 1, c("#4aa83b"))
			for k in 18:
				var fx = rng.randi_range(0, bw - 1)
				px(i, fx, gy - 2, [c("#ff7ab6"), c("#ffffff"), c("#ffcf3f")][k % 3])
		"candy":
			rect(i, 0, 0, bw, gy, c("#ffc6e5"))
			rect(i, 0, 0, bw, gy / 3, c("#ffb3dc"))
			for k in 5:
				var x = int(bw * (0.1 + k * 0.2))
				var h = rng.randi_range(25, 45)
				rect(i, x, gy - h, 1, h, c("#ffffff"))
				disc(i, x + 0.5, gy - h, 7, [c("#ff5a8a"), c("#7cc8ff"), c("#ffcf3f"), c("#a7e07a"), c("#c084fc")][k])
				disc(i, x + 0.5, gy - h, 3, c("#ffffff"))
			rect(i, 0, gy, bw, bh - gy, c("#ff8fc8"))
			for x in range(0, bw, 6):
				rect(i, x, gy, 3, 3, c("#ffffff"))
				rect(i, x + 3, gy, 3, 3, c("#ff4d6d"))
		"space":
			rect(i, 0, 0, bw, bh, c("#0d1233"))
			for k in 120:
				px(i, rng.randi_range(0, bw - 1), rng.randi_range(0, gy - 1), c("#ffffff") if k % 3 else c("#ffe066"))
			disc(i, bw * 0.78, 34, 14, c("#ff9f6b"))
			disc(i, bw * 0.78 - 4, 30, 4, c("#ffc49c"))
			rect(i, int(bw * 0.78) - 22, 34, 44, 1, c("#ffe0a8"))
			rect(i, 0, gy, bw, bh - gy, c("#8f96a8"))
			rect(i, 0, gy, bw, 2, c("#b3b9c8"))
			for x in range(10, bw, 40):
				rect(i, x, gy + 5, 8, 2, c("#7c8396"))
		"beach":
			rect(i, 0, 0, bw, gy, c("#8fd8ff"))
			disc(i, bw - 34, 24, 9, c("#ffe066"))
			rect(i, 0, gy - 16, bw, 16, c("#2f9be0"))
			for x in range(0, bw, 8):
				px(i, x + 2, gy - 12, c("#ffffff"))
				px(i, x + 6, gy - 6, c("#bfe6ff"))
			rect(i, 20, gy - 40, 2, 40, c("#8a5a2b"))
			for k in 5:
				rect(i, 10 + k * 3, gy - 42 + (k % 2) * 2, 8, 2, c("#2fa84f"))
			rect(i, 0, gy, bw, bh - gy, c("#e7c46e"))
			rect(i, 0, gy, bw, 2, c("#ffe2a1"))
	return i
