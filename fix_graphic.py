from PIL import Image
import os

def fix_feature_graphic():
    input_path = r"D:\Programming\copilotcli\gastrotator\play_store_submission\assets_v1\graphics\feature_graphic_final.png"
    output_path = r"D:\Programming\copilotcli\gastrotator\play_store_submission\assets_v1\graphics\feature_graphic_fixed_1024x500.png"
    
    # Target dimensions
    target_width = 1024
    target_height = 500
    
    # Culinary Curator Surface Color (Off-white)
    bg_color = (252, 249, 248) # #FCF9F8
    
    if not os.path.exists(input_path):
        print(f"Error: {input_path} not found.")
        return

    # 1. Open source image
    with Image.open(input_path) as source:
        source = source.convert("RGB")
        
        # 2. Create new canvas
        canvas = Image.new("RGB", (target_width, target_height), bg_color)
        
        # 3. Calculate scaling to fit height
        # Source is 512x512, we need 500 height.
        scale_factor = target_height / source.height
        new_source_width = int(source.width * scale_factor)
        new_source_height = target_height
        
        source_resized = source.resize((new_source_width, new_source_height), Image.Resampling.LANCZOS)
        
        # 4. Paste in the center
        paste_x = (target_width - new_source_width) // 2
        canvas.paste(source_resized, (paste_x, 0))
        
        # 5. Save final
        canvas.save(output_path, "PNG")
        print(f"Successfully saved fixed graphic to: {output_path}")

if __name__ == "__main__":
    fix_feature_graphic()
