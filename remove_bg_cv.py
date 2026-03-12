import cv2
import numpy as np
import os

assets_dir = r"d:\Game Bach Dang\Game-PRU\assets"
files = [
    "general_anims.png",
    "house_large.png",
    "mongol_anims.png",
    "player_unarmed.png",
    "soldier_anims.png",
    "villager_anims.png"
]

for f in files:
    path = os.path.join(assets_dir, f)
    if not os.path.exists(path):
        continue
    
    # Read with alpha channel if present
    img = cv2.imread(path, cv2.IMREAD_UNCHANGED)
    if img is None:
        continue
        
    # Ensure it's 4 channels
    if img.shape[2] == 3:
        img = cv2.cvtColor(img, cv2.COLOR_BGR2BGRA)
        
    # Get the top-left pixel color for the mask
    # We will flood fill from all 4 corners
    h, w = img.shape[:2]
    mask = np.zeros((h + 2, w + 2), np.uint8)
    
    # Use a tolerance for floodfill (how much pixel value can vary from origin)
    # BGR format
    tolerance = (25, 25, 25, 255) 
    
    corners = [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]
    
    # The image might have an alpha channel already with alpha 0 as bg,
    # or it might have a solid color bg.
    # Convert image to a flat color format for flood filling the mask.
    bgr_img = img[:, :, :3].copy()
    
    for pt in corners:
        # Check if point is already masked
        if mask[pt[1] + 1, pt[0] + 1] == 0:
            # floodFill on BGR to build mask of contiguous background colors
            cv2.floodFill(bgr_img, mask, pt, (0,255,0), (20,20,20), (30,30,30), flags=cv2.FLOODFILL_MASK_ONLY | (255 << 8))

    # Mask now has 255 for the background
    # But for pixel art, sometimes jpeg artifacts make it leave a halo.
    # We can dilate the mask slightly IF the background is very noisy, but it might eat character lines.
    # Since it's pixel art with black lines, let's also remove any contiguous bright pixels around the mask.
    # Wait, simple flood fill with decent tolerance is usually enough. Let's dilate mask by 1 iteration? No, that erases the 1px black outline.
    
    # After floodfill, any pixel where mask == 255 becomes transparent
    # mask is size (h+2, w+2), so slice it
    bg_mask = mask[1:h+1, 1:w+1] == 255
    img[bg_mask] = [0, 0, 0, 0]
    
    # Scale up characters to 1.5x using nearest neighbor (except house)
    if f != "house_large.png":
        new_w, new_h = int(w * 1.5), int(h * 1.5)
        img = cv2.resize(img, (new_w, new_h), interpolation=cv2.INTER_NEAREST)
        
    cv2.imwrite(path, img)
    print(f"Processed: {f}")
