import os
from PIL import Image

# Directory containing the images
assets_dir = r"d:\Game Bach Dang\Game-PRU\assets"

# List of characters to process
characters = [
    "general_anims.png",
    "mongol_anims.png",
    "player_unarmed.png",
    "soldier_anims.png",
    "villager_anims.png"
]

for char in characters:
    path = os.path.join(assets_dir, char)
    if not os.path.exists(path):
        print(f"File not found: {path}")
        continue
        
    try:
        img = Image.open(path).convert("RGBA")
        datas = img.getdata()

        # Get color of the top left pixel (assuming it's the background color)
        bg_color = img.getpixel((0, 0))
        # If the image is already mostly transparent, the top-left might be transparent.
        # Let's check its alpha. If it's already transparent, skip or look for another bg color.
        if len(bg_color) == 4 and bg_color[3] == 0:
            print(f"Skipping {path}: Top-left pixel is already transparent. It might already have no background.")
            continue
            
        bg_rgb = bg_color[:3]
        
        newData = []
        for item in datas:
            # if the RGB matches the background color RGB
            if item[:3] == bg_rgb:
                newData.append((255, 255, 255, 0)) # Fully transparent
            else:
                newData.append(item)
                
        img.putdata(newData)
        img.save(path, "PNG")
        print(f"Processed: {path} (Removed background color: {bg_rgb})")
    except Exception as e:
        print(f"Error processing {path}: {e}")

print("Done processing images.")
