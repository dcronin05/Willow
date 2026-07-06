from PIL import Image, ImageDraw
import os

# Create directory if it doesn't exist
os.makedirs('../source/images/items', exist_ok=True)

# Potion
img = Image.new('1', (16, 16), color=1)
draw = ImageDraw.Draw(img)
# Draw a little bottle
draw.rectangle([6, 2, 9, 5], fill=0) # cork/neck
draw.rectangle([4, 6, 11, 14], fill=0) # body
draw.rectangle([5, 7, 10, 13], fill=1) # inside
draw.line([6, 10, 9, 10], fill=0) # liquid level
img.save('../source/images/items/potion.png')

# Sword
img = Image.new('1', (16, 16), color=1)
draw = ImageDraw.Draw(img)
# Draw a diagonal sword
draw.line([2, 13, 5, 10], fill=0, width=2) # hilt
draw.line([4, 13, 7, 10], fill=0) # crossguard
draw.line([6, 9, 14, 1], fill=0, width=2) # blade
img.save('../source/images/items/sword.png')

print("✅ Generated item images")
