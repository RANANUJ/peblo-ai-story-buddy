import os

def check_file(file_path):
    print(f"File: {os.path.basename(file_path)}")
    if not os.path.exists(file_path):
        print("  -> ERROR: File does not exist!")
        return
        
    with open(file_path, 'rb') as f:
        data = f.read(32)
        
    print(f"  -> Size: {os.path.getsize(file_path)} bytes")
    print(f"  -> First 16 bytes: {data[:16].hex(' ').upper()}")
    
    # Check if it starts with ID3
    if data[0:3] == b'ID3':
        print("  -> WARNING: Still starts with ID3 metadata header!")
    elif len(data) >= 2 and data[0] == 0xFF and (data[1] & 0xE0) == 0xE0:
        print("  -> SUCCESS: Starts with valid MPEG sync frame (MP3/audio format)!")
    else:
        print("  -> WARNING: Does not start with MPEG sync or ID3. Might be raw audio, corrupted, or another format.")

if __name__ == "__main__":
    audio_dir = r"d:\Flutter\flutter dev\projects\peblo_ai\assets\audio"
    for file_name in os.listdir(audio_dir):
        if file_name.endswith(".mp3") and not file_name.endswith(".bak"):
            check_file(os.path.join(audio_dir, file_name))
