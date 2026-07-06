from PIL import Image, ImageDraw

# Create a 32x16 1-bit image (two 16x16 tiles side-by-side)
# Mode '1' means 1-bit pixels (black and white). Color=1 means white background.
img = Image.new('1', (32, 16), color=1)
draw = ImageDraw.Draw(img)

# --- TILE 1: Solid Ground (Index 1) ---
# Draw a black 16x16 square
draw.rectangle([0, 0, 15, 15], fill=0)
# Draw a white outline inside to make it look like a block instead of a flat void
draw.rectangle([2, 2, 13, 13], outline=1)
draw.rectangle([4, 4, 11, 11], outline=1)

# --- TILE 2: Background / Air (Index 2) ---
# We leave it mostly white, but let's add a few random black pixels 
# to give the air some texture so we can see the camera moving!
draw.point((18, 4), fill=0)
draw.point((25, 12), fill=0)
draw.point((28, 7), fill=0)

# The "-table-16-16" suffix is magic. It tells the Playdate compiler 
# to automatically slice this image into 16x16 chunks!
img.save('tileset-table-16-16.png')
print("✅ Generated tileset-table-16-16.png")
