from PIL import Image
import numpy as np
import os
WIDTH = 8
HEIGHT = 8
INPUT_HEX = "result_aoi.hex"
def verify_image():
    if not os.path.exists(INPUT_HEX):
        print(f"❌ Lỗi: Không tìm thấy file '{INPUT_HEX}'")
        return
    print(f"Đang đọc file {INPUT_HEX}...")
    try:
        with open(INPUT_HEX, "r") as f:
            lines = f.readlines()     
        data = []
        for line in lines:
            line = line.strip()
            if line:
                line = line.zfill(16)
                pixel_chunks = [line[i:i+2] for i in range(0, len(line), 2)]
                pixel_chunks.reverse()      
                for pixel in pixel_chunks:
                    val = int(pixel, 16)
                    # 💡 ĐOẠN ĐỔI NỀN THẦN THÁNH: Lấy 255 trừ đi giá trị gốc
                    # Biến 0 (Giống nhau) thành 255 (Trắng)
                    # Biến >0 (Lỗi) thành màu tối / đen (0)
                    inverted_val = 255 - val
                    data.append(inverted_val)      
        expected = WIDTH * HEIGHT
        if len(data) != expected:
            print(f"⚠️ Cảnh báo: Dữ liệu không đủ! Cần {expected}, có {len(data)}")
            if len(data) < expected:
                data += [255] * (expected - len(data)) # Thiếu thì bù nền trắng (255)
            else:
                data = data[:expected]
        else:
            print(f"✅ Số lượng pixel khớp hoàn hảo ({len(data)} pixels)")
        # Dựng ảnh nền trắng chấm đen
        arr = np.array(data, dtype=np.uint8).reshape((HEIGHT, WIDTH))
        img = Image.fromarray(arr)
        output_filename = "output_verified.png"
        img.save(output_filename)
        print(f"🖼️ Đã lưu ảnh kết quả: {output_filename}")
        print("👉 Nền ảnh mặc định là TRẮNG, các điểm lỗi sẽ hiển thị dạng chấm ĐEN!") 
        try:
            img.show()
        except:
            pass

    except Exception as e:
        print(f"❌ Lỗi xử lý: {e}")

if __name__ == "__main__":
    verify_image()