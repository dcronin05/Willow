import os
from PIL import Image, ImageDraw
import random

# Create a 48x16 RGBA image (three 16x16 tiles side-by-side)
# LDtk requires standard 32-bit PNGs, and Playdate PDC will automatically convert black/white/transparent RGBA to 1-bit on compile!
img = Image.new('RGBA', (48, 16), color=(255, 255, 255, 255))
draw = ImageDraw.Draw(img)

black = (0, 0, 0, 255)
white = (255, 255, 255, 255)
transparent = (0, 0, 0, 0)

# --- TILE 1: Grass (Index 1) ---
# Dark block with a white fuzzy top
draw.rectangle([0, 0, 15, 15], fill=black)
for x in range(16):
    draw.point((x, 0), fill=white)
    # Add random noisy grass blades
    if random.random() > 0.5:
        draw.point((x, 1), fill=white)
    if random.random() > 0.8:
        draw.point((x, 2), fill=white)

# Add some dirt specs below the grass
for _ in range(5):
    draw.point((random.randint(1, 14), random.randint(4, 14)), fill=white)

# --- TILE 2: Solid Dirt (Index 2) ---
draw.rectangle([16, 0, 31, 15], fill=black)
# Add some dirt specs for texture
for _ in range(15):
    draw.point((16 + random.randint(1, 14), random.randint(1, 14)), fill=white)

# --- TILE 3: Background / Air (Index 3) ---
# For the background, we'll draw it transparent so the game engine background color shows through!
draw.rectangle([32, 0, 47, 15], fill=transparent)
# Add a few random black pixels for texture in the air
for _ in range(5):
    draw.point((32 + random.randint(2, 13), random.randint(2, 13)), fill=black)

# Save to source/images
script_dir = os.path.dirname(os.path.abspath(__file__))
images_dir = os.path.join(script_dir, '..', 'source', 'images')
os.makedirs(images_dir, exist_ok=True)

# Save the table for Playdate
img.save(os.path.join(images_dir, 'tileset-table-16-16.png'))
# Save the raw image for LDtk reference
img.save(os.path.join(images_dir, 'tileset.png'))

print("✅ Generated Grass, Dirt, and Air tiles!")
