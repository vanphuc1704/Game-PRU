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

SCALE_FACTOR = 1.5

def remove_bg_and_resize(path):
    img = Image.open(path).convert("RGBA")
    datas = img.getdata()
    
    new_data = []
    for item in datas:
        r, g, b, a = item
        # Remove pixels that are mostly gray/white (background artifacts)
        # Background is usually light, so r,g,b > 150.
        # It's also usually colorless, so max(r,g,b) - min(r,g,b) < 40.
        # But we must be careful NOT to remove white from character clothing.
        # Let's look at the top-left pixel to get the base background color.
        
        # A safer way: just use a strict flood-fill or rely on the fact that 
        # the backgrounds in the screenshots are literal solid blocks of green or white.
        # Wait, the user said "nó bị lỗi nhân vật rồi, xuất hiện lại nền trắng".
        # This implies our script literally added white backgrounds or failed to remove them.
        
        # We will use a color distance threshold from the top-left pixel.
        pass

    # Actually, let's just use the top-left pixel and a small tolerance.
    bg_color = datas[0] # Top-left pixel
    if bg_color[3] == 0:
        # Already transparent, maybe find another corner
        bg_color = datas[-1]
        
    bg_r, bg_g, bg_b = bg_color[:3]
    
    for item in datas:
        r, g, b, a = item
        if a == 0:
            new_data.append(item)
            continue
            
        # If the pixel is very close to the background color (tolerance 40)
        if abs(r - bg_r) < 40 and abs(g - bg_g) < 40 and abs(b - bg_b) < 40:
            # Also, backgrounds are usually grayscale or a specific solid color.
            new_data.append((255, 255, 255, 0))
        else:
            new_data.append(item)
            
    img.putdata(new_data)
    
    # Scale up
    new_size = (int(img.width * SCALE_FACTOR), int(img.height * SCALE_FACTOR))
    img = img.resize(new_size, resample=Image.NEAREST)
    
    img.save(path, "PNG")
    print(f"Processed: {os.path.basename(path)}")


for char in characters:
    path = os.path.join(assets_dir, char)
    if os.path.exists(path):
        remove_bg_and_resize(path)
    else:
        print(f"Not found: {char}")
