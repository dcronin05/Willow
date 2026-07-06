from PIL import Image, ImageDraw

# Create a 64x32 RGBA image (Four 16x32 frames side-by-side)
# We use RGBA so we can have a transparent background. Playdate PDC will automatically convert it.
img = Image.new('RGBA', (64, 32), color=(0, 0, 0, 0)) # Transparent background
draw = ImageDraw.Draw(img)

black = (0, 0, 0, 255)
white = (255, 255, 255, 255)

def draw_head(draw, x_offset):
    # A simple square head
    draw.rectangle([x_offset+4, 2, x_offset+11, 9], fill=black)
    # Draw a white eye looking right
    draw.point((x_offset+9, 4), fill=white)
    draw.point((x_offset+10, 4), fill=white)
    # Draw a little nose sticking out to the right
    draw.point((x_offset+12, 5), fill=black)

def draw_torso(draw, x_offset):
    # A simple rectangle body
    draw.rectangle([x_offset+5, 10, x_offset+10, 20], fill=black)

def draw_arms(draw, x_offset, pose):
    if pose == 'idle':
        draw.line([x_offset+4, 11, x_offset+4, 18], fill=black)
        draw.line([x_offset+11, 11, x_offset+11, 18], fill=black)
    elif pose == 'run1':
        draw.line([x_offset+4, 11, x_offset+2, 16], fill=black) # Arm forward
        draw.line([x_offset+11, 11, x_offset+13, 16], fill=black) # Arm back
    elif pose == 'run2':
        draw.line([x_offset+4, 11, x_offset+6, 16], fill=black) # Arm back
        draw.line([x_offset+11, 11, x_offset+9, 16], fill=black) # Arm forward
    elif pose == 'jump':
        draw.line([x_offset+4, 11, x_offset+2, 4], fill=black) # Arms up
        draw.line([x_offset+11, 11, x_offset+13, 4], fill=black)

def draw_legs(draw, x_offset, pose):
    if pose == 'idle':
        draw.line([x_offset+6, 21, x_offset+6, 30], fill=black)
        draw.line([x_offset+9, 21, x_offset+9, 30], fill=black)
    elif pose == 'run1':
        draw.line([x_offset+6, 21, x_offset+4, 28], fill=black) # Leg forward
        draw.line([x_offset+9, 21, x_offset+11, 30], fill=black) # Leg back
    elif pose == 'run2':
        draw.line([x_offset+6, 21, x_offset+8, 30], fill=black) # Leg back
        draw.line([x_offset+9, 21, x_offset+6, 28], fill=black) # Leg forward
    elif pose == 'jump':
        draw.line([x_offset+6, 21, x_offset+4, 25], fill=black) # Legs bent
        draw.line([x_offset+9, 21, x_offset+11, 25], fill=black)

# Frame 1: Idle (x_offset = 0)
draw_head(draw, 0)
draw_torso(draw, 0)
draw_arms(draw, 0, 'idle')
draw_legs(draw, 0, 'idle')

# Frame 2: Run 1 (x_offset = 16)
draw_head(draw, 16)
draw_torso(draw, 16)
draw_arms(draw, 16, 'run1')
draw_legs(draw, 16, 'run1')

# Frame 3: Run 2 (x_offset = 32)
draw_head(draw, 32)
draw_torso(draw, 32)
draw_arms(draw, 32, 'run2')
draw_legs(draw, 32, 'run2')

# Frame 4: Jump (x_offset = 48)
draw_head(draw, 48)
draw_torso(draw, 48)
draw_arms(draw, 48, 'jump')
draw_legs(draw, 48, 'jump')

img.save('../source/images/player-table-16-32.png')
print("✅ Generated player-table-16-32.png")
