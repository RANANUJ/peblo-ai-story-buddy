import os
import shutil

# Directories
source_dir = r"C:\Users\anujr\.gemini\antigravity-ide\brain\24de1e2e-46e7-430e-a4aa-3e4b2a8e088e"
dest_dir = r"d:\Flutter\flutter dev\projects\peblo_ai\assets\images"

# Image mappings
mappings = {
    "raga_idle_1782148371262.png": "raga_idle.png",
    "raga_speaking_1782148389076.png": "raga_speaking.png",
    "raga_thinking_1782148407488.png": "raga_thinking.png",
    "raga_shy_1782148428663.png": "raga_shy.png",
    "raga_wave_bye_1782148445964.png": "raga_wave_bye.png",
    "vidya_idle_1782148464846.png": "vidya_idle.png",
    "vidya_pointing_1782148485871.png": "vidya_pointing.png",
    "vidya_sympathetic_1782148505638.png": "vidya_sympathetic.png",
    "vidya_celebrating_1782148526450.png": "vidya_celebrating.png",
}

print("Starting to copy generated mascot images...")

# Copy files
for src_name, dest_name in mappings.items():
    src_path = os.path.join(source_dir, src_name)
    dest_path = os.path.join(dest_dir, dest_name)
    
    if os.path.exists(src_path):
        shutil.copy2(src_path, dest_path)
        print(f"Success: Copied {src_name} -> {dest_name}")
    else:
        print(f"Error: Source file does not exist: {src_path}")

print("Mascot asset copy operation finished.")
