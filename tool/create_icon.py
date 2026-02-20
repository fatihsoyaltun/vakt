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

# Splash icon (512x512) — scaled at 0.5x + vertical shift for better centering
splash_size = 512
img_splash = Image.new('RGBA', (splash_size, splash_size), bg)
draw_splash = ImageDraw.Draw(img_splash)

scx = 256
dy = 40  # shift down so crescent doesn't get cut off at top

# A shape at 0.5 scale
sa_top_y = 190 + dy
sa_bottom_y = 390 + dy
sa_width = 170
sa_thickness = 25

sleft_outer = [
    (scx, sa_top_y),
    (scx - sa_width//2, sa_bottom_y),
    (scx - sa_width//2 + sa_thickness, sa_bottom_y),
    (scx, sa_top_y + sa_thickness + 20),
]
sright_outer = [
    (scx, sa_top_y),
    (scx + sa_width//2, sa_bottom_y),
    (scx + sa_width//2 - sa_thickness, sa_bottom_y),
    (scx, sa_top_y + sa_thickness + 20),
]
scrossbar_y = 310 + dy
scrossbar_height = 18
scrossbar = [
    (scx - sa_width//4 - 10, scrossbar_y),
    (scx + sa_width//4 + 10, scrossbar_y),
    (scx + sa_width//4 + 10, scrossbar_y + scrossbar_height),
    (scx - sa_width//4 - 10, scrossbar_y + scrossbar_height),
]

draw_splash.polygon(sleft_outer, fill=gold)
draw_splash.polygon(sright_outer, fill=gold)
draw_splash.polygon(scrossbar, fill=gold)

# Crescent at 0.5 scale + shift
scx_m, scy_m = 256, 150 + dy
sr1, sr2, soff = 70, 58, 28
draw_splash.ellipse([scx_m - sr1, scy_m - sr1, scx_m + sr1, scy_m + sr1], fill=gold)
draw_splash.ellipse([scx_m - sr2 + soff, scy_m - sr2 - 10, scx_m + sr2 + soff, scy_m + sr2 - 10], fill=bg)

img_splash.save('assets/icon/splash_icon.png')
print('Splash icon created: assets/icon/splash_icon.png')
