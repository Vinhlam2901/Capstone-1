//===========================================================================================
// Project         : Single Cycle of RISV - V
// Module          : Multiplexer 32 to 1
// File            : mux_32to1.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 9/9/2025
// Updated date    : 6/11/2025 - Finished
//===========================================================================================
module mux_32to1 (
    input       [31:0] d0, d1, d2, d3, d4, d5, d6, d7,
                       d8, d9, d10, d11, d12, d13, d14, d15,
                       d16, d17, d18, d19, d20, d21, d22, d23,
                       d24, d25, d26, d27, d28, d29, d30, d31,
    input       [4:0]  s,       // select signal
    output wire [31:0] y_o          // output 32-bit
); // da hal check va da sua loi
 wire [31:0] mux_temp0, mux_temp1, mux_temp2, mux_temp3,
             mux_temp4, mux_temp5, mux_temp6, mux_temp7,
             mux_temp8, mux_temp9, mux_temp10, mux_temp11,
             mux_temp12, mux_temp13, mux_temp14, mux_temp15,
             mux_temp16, mux_temp17, mux_temp18, mux_temp19,
             mux_temp20, mux_temp21, mux_temp22, mux_temp23,
             mux_temp24, mux_temp25, mux_temp26, mux_temp27,
             mux_temp28, mux_temp29;
// Intermediate wires for the 2-to-1 muxes
  assign mux_temp0 =  (s[0]) ? d1 : d0;
  assign mux_temp1 =  (s[0]) ? d3 : d2;
  assign mux_temp2 =  (s[0]) ? d5 : d4;
  assign mux_temp3 =  (s[0]) ? d7 : d6;
  assign mux_temp4 =  (s[0]) ? d9 : d8;
  assign mux_temp5 =  (s[0]) ? d11 : d10;
  assign mux_temp6 =  (s[0]) ? d13 : d12;
  assign mux_temp7 =  (s[0]) ? d15 : d14;
  assign mux_temp8 =  (s[0]) ? d17 : d16;
  assign mux_temp9 =  (s[0]) ? d19 : d18;
  assign mux_temp10 = (s[0]) ? d21 : d20;
  assign mux_temp11 = (s[0]) ? d23 : d22;
  assign mux_temp12 = (s[0]) ? d25 : d24;
  assign mux_temp13 = (s[0]) ? d27 : d26;
  assign mux_temp14 = (s[0]) ? d29 : d28;
  assign mux_temp15 = (s[0]) ? d31 : d30;
//khong nen dung ngo ra cua mot instance thanh ngo vao cua instace khac (sequential)
  assign mux_temp16 = (s[1]) ? mux_temp1 : mux_temp0;
  assign mux_temp17 = (s[1]) ? mux_temp3 : mux_temp2;
  assign mux_temp18 = (s[1]) ? mux_temp5 : mux_temp4;
  assign mux_temp19 = (s[1]) ? mux_temp7 : mux_temp6;
  assign mux_temp20 = (s[1]) ? mux_temp9 : mux_temp8;
  assign mux_temp21 = (s[1]) ? mux_temp11 : mux_temp10;
  assign mux_temp22 = (s[1]) ? mux_temp13 : mux_temp12;
  assign mux_temp23 = (s[1]) ? mux_temp15 : mux_temp14;

  assign mux_temp24 = (s[2]) ? mux_temp17 : mux_temp16;
  assign mux_temp25 = (s[2]) ? mux_temp19 : mux_temp18;
  assign mux_temp26 = (s[2]) ? mux_temp21 : mux_temp20;
  assign mux_temp27 = (s[2]) ? mux_temp23 : mux_temp22;
  assign mux_temp28 = (s[3]) ? mux_temp25 : mux_temp24;
  assign mux_temp29 = (s[3]) ? mux_temp27 : mux_temp26;

  assign y_o = (s[4]) ? mux_temp29 : mux_temp28;
endmodule
