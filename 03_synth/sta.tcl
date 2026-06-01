# 1. Nạp thư viện vật lý và file Netlist vừa tổng hợp
read_liberty nangate45.lib
read_verilog hazard_detect_netlist.v

# 2. Khai báo module cao nhất
link_design hazard_detect

# 3. Nạp file ràng buộc xung nhịp
read_sdc timing.sdc

# 4. Xuất báo cáo đường găng (Critical Path)
report_checks -path_delay max -format full