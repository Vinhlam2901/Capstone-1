# create_clock -name clk -period 10.0 [get_ports i_clk]
set_max_delay -from [all_inputs] -to [all_outputs] 10.0

# Báo cáo đường trễ đó
report_checks -from [all_inputs] -to [all_outputs] -path_delay max