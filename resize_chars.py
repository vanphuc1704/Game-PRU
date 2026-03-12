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

SCALE_FACTOR = 1.5 # Phóng to gấp 1.5 lần, cũng có thể chỉnh thành 2 nếu muốn to hơn nữa

for char in characters:
    path = os.path.join(assets_dir, char)
    if os.path.exists(path):
        try:
            img = Image.open(path).convert("RGBA")
            new_size = (int(img.width * SCALE_FACTOR), int(img.height * SCALE_FACTOR))
            # Dùng NEAREST để giữ nguyên chất lượng pixel art (không bị mờ)
            resized_img = img.resize(new_size, resample=Image.NEAREST)
            resized_img.save(path, "PNG")
            print(f"Resized {char} to {new_size[0]}x{new_size[1]}")
        except Exception as e:
            print(f"Error processing {path}: {e}")
    else:
        print(f"File not found: {path}")

print("Hoàn tất phóng to.")
