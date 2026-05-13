.global _start
.option norvc

_start:
    # ========================================================
    # KHỞI TẠO UART
    # ========================================================
    li x5, 0x10020000       # 0x100202B7
    li x28, 0x83            # 0x08300E13
    sb x28, 3(x5)           # 0x01C281A3
    li x28, 1               # 0x00100E13
    sb x28, 0(x5)           # 0x01C28023
    li x28, 0               # 0x00000E13
    sb x28, 1(x5)           # 0x01C280A3
    li x28, 0x03            # 0x00300E13
    sb x28, 3(x5)           # 0x01C281A3
    # ========================================================
    # GIAI ĐOẠN 1: NHẬN 64 BYTE TỪ UART VÀO RAM
    # ========================================================
    li x6, 0x00000000       # 0x00000313    (Base RAM)
    li x7, 64               # 0x04000393    (Đếm 64 pixel)
receive_loop:
    lbu x28, 5(x5)          # 0x0052CE03
    andi x28, x28, 1        # 0x001E7E13
    beqz x28, receive_loop  # 0xFE0E0CE3
    lbu x29, 0(x5)          # 0x0002CE83
    sb x29, 0(x6)           # 0x01D30023    (Ghi vào RAM)
    addi x6, x6, 1          # 0x00130313
    addi x7, x7, -1         # 0xFFF38393
    bnez x7, receive_loop   # 0xFE0392E3
    li x30, 500             # 0x1F400F13    (Nạp số 500 vào thanh ghi x30)
delay_loop:
    addi x30, x30, -1       # 0xFFF08F13    (Giảm x30 đi 1)
    bnez x30, delay_loop    # 0xFE0F1EE3    (Nếu x30 chưa bằng 0, lặp lại)
    # ========================================================
    # GIAI ĐOẠN 2: XỬ LÝ VECTOR (ÉP FULL 255 QUA THANH GHI SCALAR)
    # ========================================================
    li x11, 0x00000000      # 0x00000593    (Con trỏ RAM)
    li x13, 8               # 0x00800693    (Đếm 8 block)
    # Nạp số 255 vào thanh ghi vô hướng x14
    li x14, 255             # 0x0FF00713    (addi x14, x0, 255)
    .word 0x0C057657        # 0x0C057657    (vsetvli x12, x10, e8, m1
vector_loop:
    .word 0x02058087        # 0x02058087    (vle8.v v1, (x11))
    # Dùng vsaddu.vx (Cộng Vector với thanh ghi Scalar x14)
    # v1 = v1 + x14 (kẹp bão hòa 255)
    .word 0x821740D7        # 0x821740D7    (vsaddu.vx v1, v1, x14)
    
    .word 0x020580A7        # 0x020580A7    (vse8.v v1, (x11))
    addi x11, x11, 8        # 0x00858593
    addi x13, x13, -1       # 0xFFF68693
    bnez x13, vector_loop   # 0xFE0696E3
    # ========================================================
    # GIAI ĐOẠN 2.5: VẼ VIỀN ĐEN TRÊN/DƯỚI BẰNG SCALAR
    # ========================================================
    li x11, 0x00000000      # Trỏ vào mem[0] (Viền trên)
    sd x0, 0(x11)           # Ghi 8 byte 0 (Màu đen) vào mem[0]
    
    li x11, 56              # Trỏ vào mem[7] (Offset = 56, Viền dưới)
    sd x0, 0(x11)           # Ghi 8 byte 0 (Màu đen) vào mem[7]
    # ========================================================
    # GIAI ĐOẠN 3: GỬI TRẢ 64 BYTE TỪ RAM QUA TX
    # ========================================================
    li x6, 0x00000000       # 0x00000313    (Reset con trỏ RAM về 0)
    li x7, 64               # 0x04000393    (Reset bộ đếm về 64)
send_loop:
    lbu x28, 5(x5)          # 0x0052CE03
    andi x28, x28, 0x20     # 0x020E7E13
    beqz x28, send_loop     # 0xFE0E0CE3
    lbu x29, 0(x6)          # 0x00034E83    (Đọc data từ RAM)
    sb x29, 0(x5)           # 0x01D28023    (Gửi ra TX)
    addi x6, x6, 1          # 0x00130313
    addi x7, x7, -1         # 0xFFF38393
    bnez x7, send_loop      # 0xFE0392E3
done:
    j done                  # 0x0000006F