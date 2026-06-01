# Khai báo để gọi lệnh Yosys
yosys -import

# 1. Đọc file
set fp [open "../02_sim/flist" r]
set file_data [read $fp]
close $fp

# Tạo một biến chuỗi rỗng để gom tất cả các file lại
set all_rtl_files ""

# Quét flist và gom file
foreach line [split $file_data "\n"] {
    set line [string trim $line]
    
    if {![string match "#*" $line] && ![string match "//*" $line]} {
        if {[string match "*.v" $line] || [string match "*.sv" $line]} {
            # Ghép nối tên file vào chuỗi, cách nhau bởi khoảng trắng
            append all_rtl_files " $line"
        }
    }
}

# Lệnh quyền lực: Bơm toàn bộ danh sách file vào Yosys trong CÙNG MỘT LÚC!
puts "--> Dang nap toan bo RTL vao chung mot moi truong: $all_rtl_files"
eval "read_verilog -sv $all_rtl_files"
# 3. Kịch bản tổng hợp chính
# 3. Kịch bản tổng hợp ASIC
hierarchy -top hazard_detect -check
yosys proc; opt; fsm; opt; memory; opt

# Tổng hợp chuẩn ASIC
synth -top hazard_detect

# Ánh xạ vào thư viện Nangate 45nm
dfflibmap -liberty nangate45.lib
abc -liberty nangate45.lib

# --- BỘ LỌC ÉP CHUẨN OPENSTA ---
# 1. Đập phẳng mọi module con thành một lưới logic duy nhất
flatten
# 2. Xé lẻ tất cả các mảng bus (ví dụ: [7:0]) thành các dây 1 bit để OpenSTA không bị ngộp
splitnets -ports
# 3. Dọn dẹp rác (các dây không dùng đến)
opt_clean -purge
# -------------------------------

# Xuất Netlist chuẩn ASIC
write_verilog -noattr hazard_detect_netlist.v