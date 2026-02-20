from PIL import Image, ImageDraw
import math

size = 1024
bg = (10, 17, 40, 255)  # #0A1128
gold = (212, 168, 67, 255)  # #D4A843

img = Image.new('RGBA', (size, size), bg)
draw = ImageDraw.Draw(img)

# Draw "A" letter
a_top_y = 380
a_bottom_y = 780
a_width = 340
a_thickness = 50
center_x = 512

# Left leg
left_outer = [
    (center_x, a_top_y),
    (center_x - a_width//2, a_bottom_y),
    (center_x - a_width//2 + a_thickness, a_bottom_y),
    (center_x, a_top_y + a_thickness + 40),
]

# Right leg
right_outer = [
    (center_x, a_top_y),
    (center_x + a_width//2, a_bottom_y),
    (center_x + a_width//2 - a_thickness, a_bottom_y),
    (center_x, a_top_y + a_thickness + 40),
]

# Crossbar
crossbar_y = 620
crossbar_height = 35
crossbar = [
    (center_x - a_width//4 - 20, crossbar_y),
    (center_x + a_width//4 + 20, crossbar_y),
    (center_x + a_width//4 + 20, crossbar_y + crossbar_height),
    (center_x - a_width//4 - 20, crossbar_y + crossbar_height),
]

draw.polygon(left_outer, fill=gold)
draw.polygon(right_outer, fill=gold)
draw.polygon(crossbar, fill=gold)

# Draw crescent moon in gold — sitting on top of the "A" peak
cx, cy = 512, 300
r1 = 140  # outer circle
r2 = 115  # inner circle (cut out)
offset = 55  # inner circle offset

draw.ellipse([cx - r1, cy - r1, cx + r1, cy + r1], fill=gold)
draw.ellipse([cx - r2 + offset, cy - r2 - 20, cx + r2 + offset, cy + r2 - 20], fill=bg)

img.save('assets/icon/app_icon.png')
print('Icon created: assets/icon/app_icon.png')

# Create foreground only (transparent background) for adaptive icon
img_fg = Image.new('RGBA', (size, size), (0, 0, 0, 0))
draw_fg = ImageDraw.Draw(img_fg)
draw_fg.polygon(left_outer, fill=gold)
draw_fg.polygon(right_outer, fill=gold)
draw_fg.polygon(crossbar, fill=gold)
draw_fg.ellipse([cx - r1, cy - r1, cx + r1, cy + r1], fill=gold)
draw_fg.ellipse([cx - r2 + offset, cy - r2 - 20, cx + r2 + offset, cy + r2 - 20], fill=(0, 0, 0, 0))
img_fg.save('assets/icon/app_icon_foreground.png')
print('Foreground created: assets/icon/app_icon_foreground.png')
