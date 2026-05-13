# File: gen_hex.py
from PIL import Image
import os

# --- CẤU HÌNH ---
WIDTH = 8
HEIGHT = 8
INPUT_IMAGE = "dog.png" 
OUTPUT_HEX = "dog_gen.hex"

def create_hex():
    if not os.path.exists(INPUT_IMAGE):
        print(f"❌ Lỗi: Không tìm thấy file '{INPUT_IMAGE}'. Hãy copy ảnh vào thư mục này!")
        return

    try:
        # 1. Mở ảnh
        img = Image.open(INPUT_IMAGE)
        # 2. Convert sang ảnh xám (L) và Resize về 64x64
        img = img.convert('L').resize((WIDTH, HEIGHT))
        width, height = img.size 

        print(f"Kích thước gốc của ảnh là: {width} x {height} pixels")
        # 3. Lấy dữ liệu pixel
        pixels = list(img.getdata())
        
        # 4. Ghi ra file Hex
        with open(OUTPUT_HEX, "w") as f:
            for p in pixels:
                # Ghi số Hex 2 chữ số (vd: 0a, ff, 10)
                f.write(f"{p:02x}\n")
                
        print(f"✅ THÀNH CÔNG! Đã tạo file '{OUTPUT_HEX}'")
        print(f"   Kích thước: {WIDTH}x{HEIGHT} = {len(pixels)} dòng.")
        
    except Exception as e:
        print(f"❌ Có lỗi: {e}")

if __name__ == "__main__":
    create_hex()