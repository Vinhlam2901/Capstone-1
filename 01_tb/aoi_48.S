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
# GIAI ĐOẠN 1: NHẬN 4608 BYTE (2304 BYTE ẢNH A + 2304 BYTE ẢNH B)
# ========================================================
# ----------------------------------------------------
# NHẬN 2304 BYTE ẢNH A (Lưu từ địa chỉ 0x0000)
# ----------------------------------------------------
    li x6, 0x00000000         # Base RAM lưu Ảnh A
    li x7, 2304               # Đếm 2304 pixel
receive_image_a:
    lbu  x28, 5(x5)           # Đọc thanh ghi trạng thái UART
    andi x28, x28, 1          # Kiểm tra bit RX Valid
    beqz x28, receive_image_a # Nếu chưa có, quay lại chờ
    lbu  x29, 0(x5)           # Đọc data
    sb   x29, 0(x6)           # Ghi vào RAM
    addi x6,  x6, 1           # Tăng địa chỉ RAM
    addi x7,  x7, -1          # Giảm biến đếm
    bnez x7,  receive_image_a # Lặp đến khi đủ 2304 byte
# ----------------------------------------------------
# NHẬN 2304 BYTE ẢNH B (Lưu từ địa chỉ 0x0900)
# ----------------------------------------------------
    li x6, 0x00000900         # Base RAM lưu Ảnh B ở 0x0900
    li x7, 2304               # Đếm 2304 pixel
receive_image_b:
    lbu  x28, 5(x5)           
    andi x28, x28, 1          
    beqz x28, receive_image_b 
    lbu  x29, 0(x5)           
    sb   x29, 0(x6)           # Ghi vào RAM
    addi x6,  x6, 1           
    addi x7,  x7, -1          
    bnez x7,  receive_image_b 

    li x30, 500               # Vòng lặp delay trước khi xử lý Vector
delay1_loop:
    addi x30, x30, -1         
    bnez x30, delay1_loop     
# ========================================================
# GIAI ĐOẠN 2: XỬ LÝ VECTOR (AOI TUYỆT ĐỐI: |IMAGE A - IMAGE B|)
# ========================================================
    li x11, 0x00000000      # Con trỏ Ảnh A ở 0x0000
    li x15, 0x00000900      # Con trỏ Ảnh B ở 0x0900
    li x16, 0x00001200      # Con trỏ Kết quả ở 0x1200
    li x13, 288             # Đếm 288 block (2304 / 8)
    li x10, 8               
    .word 0x0C057657        # (vsetvli x12, x10, e8, m1)    
vector_loop:
    .word 0x02058087        # (vle8.v v1, (x11) - Load Ảnh A)
    .word 0x02078107        # (vle8.v v2, (x15) - Load Ảnh B)
    # Tính toán trị tuyệt đối bằng cơ chế song song OR hai chiều
    .word 0x8A2081D7        # (vssubu.vv v3, v1, v2 -> Chiều xuôi)
    .word 0x8A110257        # (vssubu.vv v4, v2, v1 -> Chiều ngược)
    .word 0x2A3201D7        # (vor.vv v3, v3, v4    -> Hợp nhất)
    .word 0x020801A7        # (vse8.v v3, (x16) - Ghi Kết quả)
    addi x11, x11, 8        
    addi x15, x15, 8        
    addi x16, x16, 8        
    addi x13, x13, -1       
    bnez x13, vector_loop   
# ========================================================
# GIAI ĐOẠN 3: GỬI TRẢ 2304 BYTE KẾT QUẢ AOI QUA TX
# ========================================================
    li x6, 0x00001200       # Trỏ RAM về vị trí Result 0x1200
    li x7, 2304             # Bộ đếm 2304 pixel kết quả
send_loop:
    lbu x28, 5(x5)          
    andi x28, x28, 0x20     
    beqz x28, send_loop     
    lbu x29, 0x00(x6)       # Đọc Result từ RAM
    sb x29, 0(x5)           # Gửi ra TX
    addi x6, x6, 1          
    addi x7, x7, -1         
    bnez x7, send_loop      
done:
    j done