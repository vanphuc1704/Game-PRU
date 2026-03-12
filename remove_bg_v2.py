import os
from PIL import Image

assets_dir = r"d:\Game Bach Dang\Game-PRU\assets"

characters = [
    "general_anims.png",
    "mongol_anims.png",
    "player_unarmed.png",
    "soldier_anims.png",
    "villager_anims.png"
]

def remove_background(image_path):
    img = Image.open(image_path).convert("RGBA")
    pixels = img.getdata()
    
    newData = []
    
    for item in pixels:
        r, g, b, a = item
        if a == 0:
            newData.append(item)
            continue
            
        # The screenshots show light grey / white bounding boxes around the characters
        # that weren't caught by the single pixel color match.
        # So we delete pixels that are bright (r,g,b > 180) and colorless (max-min < 30)
        # to wipe out all the anti-aliased white artifacts and solid white blocks.
        if r > 180 and g > 180 and b > 180 and max(r,g,b) - min(r,g,b) < 30:
            newData.append((255, 255, 255, 0))
        else:
            newData.append(item)
            
    img.putdata(newData)
    img.save(image_path, "PNG")
    print(f"Processed with tolerance: {image_path}")

for char in characters:
    path = os.path.join(assets_dir, char)
    if os.path.exists(path):
        try:
            remove_background(path)
        except Exception as e:
            print(f"Error processing {path}: {e}")
