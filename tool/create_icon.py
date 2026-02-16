from PIL import Image, ImageDraw
import math

size = 1024
bg = (10, 17, 40, 255)  # #0A1128
gold = (212, 168, 67, 255)  # #D4A843

img = Image.new('RGBA', (size, size), bg)
draw = ImageDraw.Draw(img)

# Draw crescent moon in gold
cx, cy = 512, 340
r1 = 180  # outer circle
r2 = 150  # inner circle (cut out)
offset = 60  # inner circle offset

draw.ellipse([cx - r1, cy - r1, cx + r1, cy + r1], fill=gold)
draw.ellipse([cx - r2 + offset, cy - r2 - 20, cx + r2 + offset, cy + r2 - 20], fill=bg)

# Draw "V" letter as polygon
v_top_y = 500
v_bottom_y = 820
v_width = 320
v_thickness = 50
center_x = 512

points = [
    (center_x - v_width // 2, v_top_y),
    (center_x - v_width // 2 + v_thickness, v_top_y),
    (center_x, v_bottom_y - 40),
    (center_x + v_width // 2 - v_thickness, v_top_y),
    (center_x + v_width // 2, v_top_y),
    (center_x, v_bottom_y),
]
draw.polygon(points, fill=gold)

img.save('assets/icon/app_icon.png')
print('Icon created: assets/icon/app_icon.png')

# Create foreground only (transparent background) for adaptive icon
img_fg = Image.new('RGBA', (size, size), (0, 0, 0, 0))
draw_fg = ImageDraw.Draw(img_fg)
draw_fg.ellipse([cx - r1, cy - r1, cx + r1, cy + r1], fill=gold)
draw_fg.ellipse([cx - r2 + offset, cy - r2 - 20, cx + r2 + offset, cy + r2 - 20], fill=(0, 0, 0, 0))
draw_fg.polygon(points, fill=gold)
img_fg.save('assets/icon/app_icon_foreground.png')
print('Foreground created: assets/icon/app_icon_foreground.png')
