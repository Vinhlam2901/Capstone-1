# File: check_hex.py
from PIL import Image
import numpy as np
import os

# Cấu hình phải khớp với Testbench
WIDTH = 8
HEIGHT = 8
INPUT_HEX = "output_dog_plus10.hex"

def verify_image():
    # 1. Kiểm tra file tồn tại
    if not os.path.exists(INPUT_HEX):
        print(f"❌ Lỗi: Không tìm thấy file '{INPUT_HEX}'")
        return

    print(f"Đang đọc file {INPUT_HEX}...")
    
    try:
        # 2. Đọc dữ liệu Hex
        with open(INPUT_HEX, "r") as f:
            lines = f.readlines()
        
        # Lọc dòng trống và convert sang số

        data = []
        for line in lines:
            line = line.strip()
            if line:
                data.append(int(line, 16))
        
        # 3. Kiểm tra số lượng pixel
        expected = WIDTH * HEIGHT
        if len(data) != expected:
            print(f"⚠️ Cảnh báo: Dữ liệu không đủ! Cần {expected}, có {len(data)}")
            # Bù thêm màu đen (0) vào phần thiếu để vẫn hiện ảnh
            data += [0] * (expected - len(data))
        else:
            print(f"✅ Số lượng pixel khớp hoàn hảo ({len(data)})")

        # 4. Dựng lại ảnh
        arr = np.array(data, dtype=np.uint8).reshape((HEIGHT, WIDTH))
        img = Image.fromarray(arr)
        
        # 5. Lưu và Hiển thị
        output_filename = "output_verified.png"
        img.save(output_filename)
        print(f"🖼️ Đã lưu ảnh kết quả: {output_filename}")
        print("👉 Hãy mở file này lên và so sánh với ảnh gốc!")
        
        # Thử mở ảnh tự động (trên Linux)
        try:
            img.show()
        except:
            pass

    except Exception as e:
        print(f"❌ Lỗi xử lý: {e}")

if __name__ == "__main__":
    verify_image()