local colors = {}

colors.white = Vector.hex("ededed")
colors.red = Vector.hex("e64e4b")
colors.dark_red = Vector.hex("5d375a")
colors.yellow = Vector.hex("f7e5b2")
colors.light_green = Vector.hex("b3daa3")
colors.black = Vector.hex("000000")
colors.blue_high = Vector.hex("3f5d92")

Ldump.mark(colors, {}, ...)
return colors
