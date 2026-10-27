extends RefCounted

# The look of the interface, drawn in pixels like the world: windows of parchment in a wooden
# frame with nails, buttons cut in planks of wood with a thick bottom edge, and fields of light
# parchment. Each one is a small image enlarged SCALE times and stretched as a 9-slice box.

const SCALE := 3
const OUTLINE := Color("2a1a0c")
const INK := Color("3a2410")  # dark brown ink on parchment
const CREAM := Color("fff0d0")  # letters carved in wood
const GOLD := Color("f0c040")
const PAPER := Color("f2e2bc")
const WOOD := {
	"normal": Color("a86e3a"),
	"hover": Color("c08448"),
	"pressed": Color("7a4a24"),
	"disabled": Color("8a8070"),
}


static func _big(image: Image) -> Image:
	image.resize(image.get_width() * SCALE, image.get_height() * SCALE, Image.INTERPOLATE_NEAREST)
	return image


static func _style(image: Image, margins: Array, content: Array) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = ImageTexture.create_from_image(_big(image))
	for i in 4:
		box.set_texture_margin(i, margins[i] * SCALE)
		box.set_content_margin(i, content[i])
	box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	return box


# A window: a frame of wood around a sheet of parchment, a nail in each corner.
static func panel() -> StyleBoxTexture:
	var n := 20
	var image := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var wood: Color = WOOD.normal
	for y in n:
		for x in n:
			var edge := mini(mini(x, y), mini(n - 1 - x, n - 1 - y))
			var c := Color.TRANSPARENT
			if edge == 0:
				# Round corners: the very corner pixels stay empty.
				if (x == 0 or x == n - 1) and (y == 0 or y == n - 1):
					continue
				c = OUTLINE
			elif edge <= 2:
				c = wood
				if y == 1 or x == 1:
					c = wood.lightened(0.2)
				elif y == n - 2 or x == n - 2:
					c = wood.darkened(0.25)
				elif (x * 3 + y * 5) % 7 == 0:
					c = wood.darkened(0.15)
			elif edge == 3:
				c = INK
			else:
				c = PAPER
				if y == 4 or x == 4:
					c = PAPER.darkened(0.1)  # the shade of the frame on the sheet
				elif (x * 7 + y * 11) % 23 == 0:
					c = PAPER.darkened(0.05)
			image.set_pixel(x, y, c)
	for corner in [Vector2i(2, 2), Vector2i(n - 3, 2), Vector2i(2, n - 3), Vector2i(n - 3, n - 3)]:
		image.set_pixel(corner.x, corner.y, Color("e8d8b0"))
	return _style(image, [5, 5, 5, 5], [16, 14, 16, 14])


# A plank button. state: normal, hover, pressed (also a chosen tab or tool), disabled.
static func button(state: String) -> StyleBoxTexture:
	var w := 12
	var h := 12
	var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var wood: Color = WOOD[state]
	var sunk := state == "pressed"
	var top := 1 if sunk else 0  # a pressed plank goes down into its edge
	for y in range(top, h):
		for x in w:
			var c := wood
			var first := y == top
			var last := y == h - 1
			if (x == 0 or x == w - 1) and (first or last):
				continue
			if first or last or x == 0 or x == w - 1:
				c = OUTLINE
			elif sunk and (y == top + 1 or x == 1 or x == w - 2 or y == h - 2):
				c = GOLD  # the chosen one gets a golden rim
			elif not sunk and y >= h - 3:
				c = wood.darkened(0.35)  # the thick edge of the plank
			elif y == top + 1:
				c = wood.lightened(0.25)
			elif x == w - 2:
				c = wood.darkened(0.15)
			elif y == 6 and x % 5 != 2:
				c = wood.darkened(0.12)  # wood grain
			image.set_pixel(x, y, c)
	return _style(image, [3, 3 + top, 3, 4], [10, 5 + top * SCALE, 10, 9 - top * SCALE])


# A field to type in: light parchment sunk in a brown border, gold when typing.
static func field(focused: bool) -> StyleBoxTexture:
	var n := 10
	var image := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var edge := mini(mini(x, y), mini(n - 1 - x, n - 1 - y))
			var c := PAPER.lightened(0.5)
			if edge == 0:
				if (x == 0 or x == n - 1) and (y == 0 or y == n - 1):
					continue
				c = GOLD.darkened(0.3) if focused else OUTLINE
			elif y == 1 or x == 1:
				c = PAPER.darkened(0.12)
			image.set_pixel(x, y, c)
	return _style(image, [2, 2, 2, 2], [10, 6, 10, 6])


# A thin bar of wood for scroll bars.
static func bar(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = OUTLINE
	box.set_border_width_all(2)
	box.set_corner_radius_all(3)
	return box
