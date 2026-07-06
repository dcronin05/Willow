from PIL import Image, ImageDraw

# Create a 16x16 1-bit image
img = Image.new('1', (16, 16), color=1)
draw = ImageDraw.Draw(img)

# Draw a sign post
draw.line([8, 6, 8, 15], fill=0) # post
draw.rectangle([2, 2, 14, 8], fill=0) # sign board
draw.rectangle([3, 3, 13, 7], outline=1) # inner border
draw.line([4, 5, 12, 5], fill=0) # text line

img.save('../source/images/sign.png')
print("✅ Generated sign.png")
