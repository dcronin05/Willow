from PIL import Image, ImageDraw

# Create a 64x32 1-bit image (Four 16x32 frames side-by-side)
img = Image.new('1', (64, 32), color=1)
draw = ImageDraw.Draw(img)

def draw_head(draw, x_offset):
    # A simple square head
    draw.rectangle([x_offset+4, 2, x_offset+11, 9], fill=0)

def draw_torso(draw, x_offset):
    # A simple rectangle body
    draw.rectangle([x_offset+5, 10, x_offset+10, 20], fill=0)

def draw_arms(draw, x_offset, pose):
    if pose == 'idle':
        draw.line([x_offset+4, 11, x_offset+4, 18], fill=0)
        draw.line([x_offset+11, 11, x_offset+11, 18], fill=0)
    elif pose == 'run1':
        draw.line([x_offset+4, 11, x_offset+2, 16], fill=0) # Arm forward
        draw.line([x_offset+11, 11, x_offset+13, 16], fill=0) # Arm back
    elif pose == 'run2':
        draw.line([x_offset+4, 11, x_offset+6, 16], fill=0) # Arm back
        draw.line([x_offset+11, 11, x_offset+9, 16], fill=0) # Arm forward
    elif pose == 'jump':
        draw.line([x_offset+4, 11, x_offset+2, 4], fill=0) # Arms up
        draw.line([x_offset+11, 11, x_offset+13, 4], fill=0)

def draw_legs(draw, x_offset, pose):
    if pose == 'idle':
        draw.line([x_offset+6, 21, x_offset+6, 30], fill=0)
        draw.line([x_offset+9, 21, x_offset+9, 30], fill=0)
    elif pose == 'run1':
        draw.line([x_offset+6, 21, x_offset+4, 28], fill=0) # Leg forward
        draw.line([x_offset+9, 21, x_offset+11, 30], fill=0) # Leg back
    elif pose == 'run2':
        draw.line([x_offset+6, 21, x_offset+8, 30], fill=0) # Leg back
        draw.line([x_offset+9, 21, x_offset+6, 28], fill=0) # Leg forward
    elif pose == 'jump':
        draw.line([x_offset+6, 21, x_offset+4, 25], fill=0) # Legs bent
        draw.line([x_offset+9, 21, x_offset+11, 25], fill=0)

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
