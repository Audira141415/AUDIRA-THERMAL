import os
import math
from PIL import Image, ImageDraw, ImageFilter, ImageFont
import numpy as np

def create_audira_logo():
    # Render at 2048x2048 for pristine supersampled antialiasing
    SIZE = 2048
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    
    # --- 1. Background Squircle with Gradient ---
    # Create gradient background
    bg = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    
    # Meshgrid for rich radial/linear gradient
    y, x = np.mgrid[0:SIZE, 0:SIZE]
    
    # Normalized coordinates
    nx = x / SIZE
    ny = y / SIZE
    
    # Top-left to bottom-right angle gradient combined with center radial glow
    cx, cy = 0.5, 0.4
    dist = np.sqrt((nx - cx)**2 + (ny - cy)**2)
    
    # Deep royal blue to electric cyan-blue gradient
    # Color 1 (Top / Center): #1E40AF (30, 64, 175) -> #2563EB (37, 99, 235)
    # Color 2 (Bottom): #0F172A (15, 23, 42)
    # Highlight Glow (Upper): #38BDF8 (56, 189, 248)
    
    r = (37 * (1 - ny) + 15 * ny + 40 * np.clip(1.0 - dist * 1.8, 0, 1)).astype(np.uint8)
    g = (99 * (1 - ny) + 23 * ny + 80 * np.clip(1.0 - dist * 1.8, 0, 1)).astype(np.uint8)
    b = (235 * (1 - ny) + 48 * ny + 50 * np.clip(1.0 - dist * 1.8, 0, 1)).astype(np.uint8)
    
    bg_np = np.dstack((r, g, b, np.full((SIZE, SIZE), 255, dtype=np.uint8)))
    bg_img = Image.fromarray(bg_np, "RGBA")
    
    # Squircle Mask
    mask = Image.new("L", (SIZE, SIZE), 0)
    draw_mask = ImageDraw.Draw(mask)
    margin = 80
    corner_radius = 440
    draw_mask.rounded_rectangle(
        [margin, margin, SIZE - margin, SIZE - margin],
        radius=corner_radius,
        fill=255
    )
    
    # Soft drop shadow behind squircle
    shadow_mask = mask.filter(ImageFilter.GaussianBlur(50))
    shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 140))
    img.paste(shadow, (0, 30), shadow_mask)
    
    # Paste masked gradient background
    img.paste(bg_img, (0, 0), mask)
    
    draw = ImageDraw.Draw(img)
    
    # --- 2. Inner Neon / Glass Rim Highlight ---
    rim_mask = Image.new("L", (SIZE, SIZE), 0)
    rim_draw = ImageDraw.Draw(rim_mask)
    rim_draw.rounded_rectangle(
        [margin, margin, SIZE - margin, SIZE - margin],
        radius=corner_radius,
        outline=255,
        width=16
    )
    rim_img = Image.new("RGBA", (SIZE, SIZE), (96, 165, 250, 160)) # #60A5FA glow
    img.paste(rim_img, (0, 0), rim_mask)
    
    # --- 3. Subtle Cyber Grid / Radial Circles ---
    circle_overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    circle_draw = ImageDraw.Draw(circle_overlay)
    center = (SIZE // 2, SIZE // 2)
    for rad in [600, 750, 900]:
        circle_draw.ellipse(
            [center[0] - rad, center[1] - rad, center[0] + rad, center[1] + rad],
            outline=(255, 255, 255, 12),
            width=4
        )
    img.alpha_composite(circle_overlay)

    # --- 4. Thermal Printer Slot at the Top ---
    slot_w = 1100
    slot_h = 70
    slot_x1 = (SIZE - slot_w) // 2
    slot_y1 = 430
    slot_x2 = slot_x1 + slot_w
    slot_y2 = slot_y1 + slot_h
    
    # Slot base (dark slate)
    draw.rounded_rectangle([slot_x1, slot_y1, slot_x2, slot_y2], radius=35, fill=(15, 23, 42, 230))
    # Slot opening (deep dark inside)
    draw.rounded_rectangle([slot_x1 + 30, slot_y1 + 16, slot_x2 - 30, slot_y2 - 16], radius=20, fill=(3, 7, 18, 255))
    # Glowing LED indicator on right of slot
    draw.ellipse([slot_x2 - 70, slot_y1 + 25, slot_x2 - 50, slot_y1 + 45], fill=(52, 211, 153, 255)) # Green LED

    # --- 5. The Thermal Paper Receipt Rolling Out ---
    # Dimensions of the ticket
    rec_w = 900
    rec_left = (SIZE - rec_w) // 2
    rec_right = rec_left + rec_w
    rec_top = slot_y1 + 40
    rec_bottom = 1580
    
    # Draw drop shadow for receipt
    rec_shadow_mask = Image.new("L", (SIZE, SIZE), 0)
    rec_s_draw = ImageDraw.Draw(rec_shadow_mask)
    rec_s_draw.rectangle([rec_left, rec_top, rec_right, rec_bottom], fill=255)
    rec_shadow_mask = rec_shadow_mask.filter(ImageFilter.GaussianBlur(30))
    rec_shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 160))
    img.paste(rec_shadow, (0, 25), rec_shadow_mask)

    # Receipt Body: White to slight warm paper tone
    receipt_img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    rec_draw = ImageDraw.Draw(receipt_img)
    
    # Draw serrated zigzag bottom for receipt
    zigzag_points = []
    # Top edge
    zigzag_points.append((rec_left, rec_top))
    zigzag_points.append((rec_right, rec_top))
    # Right edge
    zigzag_points.append((rec_right, rec_bottom))
    # Serrated bottom: 12 teeth
    teeth = 12
    step = rec_w / teeth
    for i in range(teeth, -1, -1):
        cur_x = rec_left + i * step
        if i % 2 == 1:
            zigzag_points.append((cur_x, rec_bottom + 35))
        else:
            zigzag_points.append((cur_x, rec_bottom))
    zigzag_points.append((rec_left, rec_bottom))
    zigzag_points.append((rec_left, rec_top))
    
    rec_draw.polygon(zigzag_points, fill=(255, 255, 255, 255))
    
    # Subtle inner gradient / paper texture highlight
    rec_draw.line([rec_left, rec_top, rec_right, rec_top], fill=(226, 232, 240, 255), width=6)
    
    # Composite receipt onto main image
    img.alpha_composite(receipt_img)
    
    # --- 6. Content On The Thermal Receipt ---
    # 6.1. Hero Geometric "A" Monogram (for AUDIRA & Agus Dwi R)
    # The A is stylized, modern, bold in deep indigo (#1E3A8A) with a cyan dynamic cut
    a_center_x = SIZE // 2
    a_top_y = rec_top + 160
    a_height = 420
    a_base_w = 460
    
    # Outer triangle for "A"
    p_apex = (a_center_x, a_top_y)
    p_left = (a_center_x - a_base_w // 2, a_top_y + a_height)
    p_right = (a_center_x + a_base_w // 2, a_top_y + a_height)
    
    # Left leg
    leg_w = 95
    left_leg = [
        (a_center_x, a_top_y),
        (a_center_x + 10, a_top_y),
        (p_left[0] + leg_w, p_left[1]),
        (p_left[0], p_left[1])
    ]
    # Right leg
    right_leg = [
        (a_center_x, a_top_y),
        (a_center_x - 10, a_top_y),
        (p_right[0] - leg_w, p_right[1]),
        (p_right[0], p_right[1])
    ]
    
    draw.polygon(left_leg, fill=(30, 58, 138, 255))   # #1E3A8A
    draw.polygon(right_leg, fill=(29, 78, 216, 255))  # #1D4ED8
    
    # Crossbar of "A" - Stylized speed bar with electric cyan gradient
    bar_y = a_top_y + 260
    bar_h = 70
    draw.rounded_rectangle(
        [a_center_x - 220, bar_y, a_center_x + 220, bar_y + bar_h],
        radius=14,
        fill=(14, 165, 233, 255) # Electric Sky Blue #0EA5E9
    )
    
    # Inner cutout triangle of "A"
    inner_top = a_top_y + 110
    inner_base_y = bar_y - 10
    draw.polygon([
        (a_center_x, inner_top),
        (a_center_x - 55, inner_base_y),
        (a_center_x + 55, inner_base_y)
    ], fill=(255, 255, 255, 255))
    
    # 6.2. AUDIRA Text Monogram under "A"
    # Modern simulated typography bars & clean header
    draw.rounded_rectangle([a_center_x - 180, a_top_y + a_height + 45, a_center_x + 180, a_top_y + a_height + 75], radius=10, fill=(30, 58, 138, 255))
    
    # 6.3. Receipt Divider line (Dotted / Dashed)
    div_y = a_top_y + a_height + 115
    for dash_x in range(rec_left + 80, rec_right - 80, 36):
        draw.line([dash_x, div_y, dash_x + 20, div_y], fill=(148, 163, 184, 255), width=6)
        
    # 6.4. Simulated Transaction Rows (Items & Price)
    rows_start_y = div_y + 35
    row_height = 42
    for r_idx in range(3):
        cur_y = rows_start_y + r_idx * row_height
        # Item bar (left)
        w_item = [260, 320, 220][r_idx]
        draw.rounded_rectangle([rec_left + 80, cur_y, rec_left + 80 + w_item, cur_y + 20], radius=8, fill=(203, 213, 225, 255))
        # Price bar (right)
        draw.rounded_rectangle([rec_right - 220, cur_y, rec_right - 80, cur_y + 20], radius=8, fill=(148, 163, 184, 255))
        
    # 6.5. Second Divider (Solid)
    div2_y = rows_start_y + 3 * row_height + 25
    draw.line([rec_left + 80, div2_y, rec_right - 80, div2_y], fill=(148, 163, 184, 255), width=5)

    # 6.6. Total Row (Bold green / blue pill badge)
    total_y = div2_y + 30
    draw.rounded_rectangle([rec_left + 80, total_y, rec_left + 220, total_y + 36], radius=10, fill=(30, 41, 59, 255))
    draw.rounded_rectangle([rec_right - 280, total_y, rec_right - 80, total_y + 36], radius=10, fill=(16, 185, 129, 255)) # Green #10B981

    # 6.7. Crisp 1D Barcode (CODE128 Thermal Bars)
    bc_y = total_y + 70
    bc_h = 100
    bc_left = rec_left + 140
    bc_right = rec_right - 140
    
    # Alternating bar widths
    bar_patterns = [6, 4, 12, 6, 8, 4, 14, 6, 4, 10, 8, 4, 16, 6, 8, 4, 12, 4, 8, 14, 6, 4, 10, 8, 12, 6, 4, 14, 8, 6]
    cur_bx = bc_left
    is_black = True
    for bw in bar_patterns:
        if cur_bx + bw > bc_right:
            break
        if is_black:
            draw.rectangle([cur_bx, bc_y, cur_bx + bw, bc_y + bc_h], fill=(15, 23, 42, 255))
        cur_bx += bw
        is_black = not is_black

    # --- 7. Floating Holographic Bluetooth & Thermal Print Badge ---
    # Bottom-right golden / cyan badge
    badge_cx = SIZE - 460
    badge_cy = SIZE - 460
    badge_r = 130
    
    # Badge shadow
    b_shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    b_s_draw = ImageDraw.Draw(b_shadow)
    b_s_draw.ellipse([badge_cx - badge_r, badge_cy - badge_r + 20, badge_cx + badge_r, badge_cy + badge_r + 20], fill=(0, 0, 0, 160))
    b_shadow = b_shadow.filter(ImageFilter.GaussianBlur(25))
    img.alpha_composite(b_shadow)
    
    # Outer gold/cyan ring
    draw.ellipse([badge_cx - badge_r, badge_cy - badge_r, badge_cx + badge_r, badge_cy + badge_r], fill=(30, 41, 59, 255), outline=(56, 189, 248, 255), width=14)
    # Inner circle
    draw.ellipse([badge_cx - badge_r + 14, badge_cy - badge_r + 14, badge_cx + badge_r - 14, badge_cy + badge_r - 14], fill=(14, 165, 233, 255))
    
    # Bluetooth icon inside badge (white)
    bt_w = 7
    # Vertical line
    draw.line([badge_cx, badge_cy - 70, badge_cx, badge_cy + 70], fill=(255, 255, 255, 255), width=18)
    # Upper chevron
    draw.line([badge_cx, badge_cy - 70, badge_cx + 45, badge_cy - 25], fill=(255, 255, 255, 255), width=16)
    draw.line([badge_cx + 45, badge_cy - 25, badge_cx - 40, badge_cy + 30], fill=(255, 255, 255, 255), width=16)
    # Lower chevron
    draw.line([badge_cx, badge_cy + 70, badge_cx + 45, badge_cy + 25], fill=(255, 255, 255, 255), width=16)
    draw.line([badge_cx + 45, badge_cy + 25, badge_cx - 40, badge_cy - 30], fill=(255, 255, 255, 255), width=16)

    # --- 8. Downscale to 1024x1024 for Master Logo ---
    master_logo = img.resize((1024, 1024), Image.Resampling.LANCZOS)
    
    # Ensure directories exist
    os.makedirs(r"f:\AUDIRA-THERMAL\assets\images", exist_ok=True)
    master_path = r"f:\AUDIRA-THERMAL\assets\images\app_logo.png"
    master_logo.save(master_path, "PNG")
    print(f"Master logo saved to: {master_path}")
    
    # 512x512 Play Store / Web icon
    logo_512 = master_logo.resize((512, 512), Image.Resampling.LANCZOS)
    logo_512.save(r"f:\AUDIRA-THERMAL\assets\images\app_logo_512.png", "PNG")
    
    # --- 9. Export to Android Launcher Mipmaps ---
    mipmap_sizes = {
        r"f:\AUDIRA-THERMAL\android\app\src\main\res\mipmap-mdpi\ic_launcher.png": 48,
        r"f:\AUDIRA-THERMAL\android\app\src\main\res\mipmap-hdpi\ic_launcher.png": 72,
        r"f:\AUDIRA-THERMAL\android\app\src\main\res\mipmap-xhdpi\ic_launcher.png": 96,
        r"f:\AUDIRA-THERMAL\android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png": 144,
        r"f:\AUDIRA-THERMAL\android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png": 192,
    }
    
    for path, size in mipmap_sizes.items():
        os.makedirs(os.path.dirname(path), exist_ok=True)
        res_icon = master_logo.resize((size, size), Image.Resampling.LANCZOS)
        res_icon.save(path, "PNG")
        print(f"Launcher icon ({size}x{size}) saved to: {path}")

if __name__ == "__main__":
    create_audira_logo()
