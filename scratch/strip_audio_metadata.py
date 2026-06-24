import os
import shutil

def strip_id3v2(file_path):
    print(f"Processing: {file_path}")
    with open(file_path, 'rb') as f:
        data = f.read()
    
    if len(data) > 10 and data[0:3] == b'ID3':
        # The ID3v2 header format has the size in bytes 6, 7, 8, 9 as synchsafe integers (7 bits per byte).
        size_bytes = data[6:10]
        size = (size_bytes[0] & 0x7F) << 21 | \
               (size_bytes[1] & 0x7F) << 14 | \
               (size_bytes[2] & 0x7F) << 7 | \
               (size_bytes[3] & 0x7F)
        
        # Header is 10 bytes long. The size field does not include these 10 bytes.
        total_header_size = size + 10
        print(f"  -> Found ID3v2 tag. Size: {size} bytes. Total header to strip: {total_header_size} bytes.")
        
        if len(data) > total_header_size:
            # Create a backup just in case
            backup_path = file_path + ".bak"
            shutil.copy2(file_path, backup_path)
            
            clean_data = data[total_header_size:]
            with open(file_path, 'wb') as f:
                f.write(clean_data)
            
            print(f"  -> Successfully stripped metadata and saved. Backup created at {backup_path}")
        else:
            print("  -> Error: Header size is larger than the file itself!")
    else:
        print("  -> No ID3v2 tag found at the start of this file.")

if __name__ == "__main__":
    audio_dir = r"d:\Flutter\flutter dev\projects\peblo_ai\assets\audio"
    if not os.path.exists(audio_dir):
        print(f"Audio directory does not exist: {audio_dir}")
    else:
        for file_name in os.listdir(audio_dir):
            if file_name.endswith(".mp3"):
                file_path = os.path.join(audio_dir, file_name)
                strip_id3v2(file_path)
        print("\nAll done! Please clean/rebuild your Flutter app and try playing the voice again.")
