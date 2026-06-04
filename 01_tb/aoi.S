.global _start
.option norvc

_start:
# ========================================================
# KHỞI TẠO UART
# ========================================================
    li x5,  0x10020000      # 0x100202B7
    li x28, 0x83            # 0x08300E13
    sb x28, 3(x5)           # 0x01C281A3
    li x28, 1               # 0x00100E13
    sb x28, 0(x5)           # 0x01C28023
    li x28, 0               # 0x00000E13
    sb x28, 1(x5)           # 0x01C280A3
    li x28, 0x03            # 0x00300E13
    sb x28, 3(x5)           # 0x01C281A3
# ========================================================
# GIAI ĐOẠN 1: NHẬN 128 BYTE (64 BYTE ẢNH A + 64 BYTE ẢNH B)
# ========================================================
# ----------------------------------------------------
# NHẬN 64 BYTE ẢNH A (Lưu từ địa chỉ 0x00)
# ----------------------------------------------------
    li x6, 0x00000000         # 0x00000313    (Base RAM lưu Ảnh A)
    li x7, 64                 # 0x04000393    (Đếm 64 pixel)
receive_image_a:
    lbu  x28, 5(x5)           # 0x0052CE03    (Đọc thanh ghi trạng thái UART)
    andi x28, x28, 1          # 0x001E7E13    (Kiểm tra bit RX Valid)
    beqz x28, receive_image_a # 0xFE0E0CE3    (Nếu chưa có, quay lại chờ)
    lbu  x29, 0(x5)           # 0x0002CE83    (Đọc data)
    sb   x29, 0(x6)           # 0x01D30023    (Ghi vào RAM)
    addi x6,  x6, 1           # 0x00130313    (Tăng địa chỉ RAM)
    addi x7,  x7, -1          # 0xFFF38393    (Giảm biến đếm)
    bnez x7,  receive_image_a # 0xFE0392E3    (Lặp đến khi đủ 64 byte)
# ----------------------------------------------------
# NHẬN 64 BYTE ẢNH B (Lưu từ địa chỉ 0x40)
# ----------------------------------------------------
    li x6, 0x00000040         # 0x04000313    (Base RAM lưu Ảnh B ở 0x40)
    li x7, 64                 # 0x04000393    (Đếm 64 pixel)
receive_image_b:
    lbu  x28, 5(x5)           # 0x0052CE03
    andi x28, x28, 1          # 0x001E7E13
    beqz x28, receive_image_b # 0xFE0E0CE3
    lbu  x29, 0(x5)           # 0x0002CE83
    sb   x29, 0(x6)           # 0x01D30023    (Ghi vào RAM)
    addi x6,  x6, 1           # 0x00130313
    addi x7,  x7, -1          # 0xFFF38393
    bnez x7,  receive_image_b # 0xFE0392E3
    li x30, 500               # 0x1F400F13    
delay1_loop:
    addi x30, x30, -1         # 0xFFF08F13    
    bnez x30, delay1_loop     # 0xFE0F1EE3    
# ========================================================
# GIAI ĐOẠN 2: XỬ LÝ VECTOR (AOI TUYỆT ĐỐI: |IMAGE A - IMAGE B|)
# ========================================================
    li x11, 0x00000000      # 0x00000593    (Con trỏ Ảnh A ở 0x00)
    li x15, 0x00000040      # 0x04000793    (Con trỏ Ảnh B ở 0x40)
    li x16, 0x00000080      # 0x08000813    (Con trỏ Kết quả ở 0x80)
    li x13, 8               # 0x00800693    (Đếm 8 block x 8 pixel)
    li x10, 8               # 0x00800513    
    .word 0x0C057657        # 0x0C057657    (vsetvli x12, x10, e8, m1)    
vector_loop:
    .word 0x02058087        # 0x02058087    (vle8.v v1, (x11) - Load Ảnh A)
    .word 0x02078107        # 0x02078107    (vle8.v v2, (x15) - Load Ảnh B)
    # Tính toán trị tuyệt đối bằng cơ chế song song OR hai chiều
    .word 0x8A2081D7        # 0x8A2081D7    (vssubu.vv v3, v1, v2 -> Chiều xuôi)
    .word 0x8A110257        # 0x8A110257    (vssubu.vv v4, v2, v1 -> Chiều ngược)
    .word 0x2A3201D7        # 0x2A3201D7    (vor.vv v3, v3, v4    -> Hợp nhất)
    .word 0x020801A7        # 0x020801A7    (vse8.v v3, (x16) - Ghi Kết quả)
    addi x11, x11, 8        # 0x00858593    
    addi x15, x15, 8        # 0x00878793    
    addi x16, x16, 8        # 0x00880813    
    addi x13, x13, -1       # 0xFFF68693    
    bnez x13, vector_loop   # 0xFE0690E3
    
# ========================================================
# GIAI ĐOẠN 3: GỬI TRẢ 64 BYTE KẾT QUẢ AOI QUA TX
# ========================================================
    li x6, 0x00000080       # 0x08000313    (Trỏ RAM về vị trí Result 0x80)
    li x7, 64               # 0x04000393    (Bộ đếm 64 pixel kết quả)
send_loop:
    lbu x28, 5(x5)          # 0x0052CE03
    andi x28, x28, 0x20     # 0x020E7E13
    beqz x28, send_loop     # 0xFE0E0CE3
    lbu x29, 0x00(x6)       # 0x00034E83    (Đọc Result từ RAM)
    sb x29, 0(x5)           # 0x01D28023    (Gửi ra TX)
    addi x6, x6, 1          # 0x00130313
    addi x7, x7, -1         # 0xFFF38393
    bnez x7, send_loop      # 0xFE0392E3
done:
    j done                  # 0x0000006F