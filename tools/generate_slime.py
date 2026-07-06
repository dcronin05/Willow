import os
from PIL import Image

def generate_slime():
    # 16x16 canvas
    img = Image.new('RGBA', (16, 16), (255, 255, 255, 0))
    pixels = img.load()

    # Simple 1-color slime sprite (black and white for Playdate)
    # We'll use black for the outline and body, white for eyes
    
    slime_art = [
        "                ",
        "                ",
        "                ",
        "                ",
        "                ",
        "                ",
        "                ",
        "      XXXX      ",
        "    XXXXXXXX    ",
        "   XXXXXXXXXX   ",
        "  XX XXXXXX XX  ",
        "  XXXXXXXXXXXX  ",
        "  XXXXXXXXXXXX  ",
        " XXXXXXXXXXXXXX ",
        " XXXXXXXXXXXXXX ",
        "XXXXXXXXXXXXXXXX"
    ]
    
    for y, row in enumerate(slime_art):
        for x, char in enumerate(row):
            if char == 'X':
                pixels[x, y] = (0, 0, 0, 255) # Black
            elif char == 'W':
                pixels[x, y] = (255, 255, 255, 255) # White
                
    # Add some white eyes
    pixels[5, 10] = (255, 255, 255, 255)
    pixels[6, 10] = (255, 255, 255, 255)
    
    pixels[9, 10] = (255, 255, 255, 255)
    pixels[10, 10] = (255, 255, 255, 255)

    os.makedirs('../source/images', exist_ok=True)
    img.save('../source/images/slime.png')
    print("Generated source/images/slime.png")

if __name__ == '__main__':
    generate_slime()
