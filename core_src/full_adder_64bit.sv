module full_adder_64bit (
  input  wire [63:0] A_i,    // Toán hạng A 64-bit
  input  wire [63:0] Y_i,    // Toán hạng B 64-bit
  input  wire        C_i,    // Carry In ban đầu (thường là 0)
  output wire [63:0] Sum_o,  // Tổng 64-bit
  output wire        C_o     // Carry Out cuối cùng (Bit tràn)
);

  // Dây nối bit nhớ từ tầng thấp lên tầng cao
  wire carry_mid;
  full_adder_32bit fa_low (
    .A_i   (A_i[31:0]),
    .Y_i   (Y_i[31:0]),
    .C_i   (C_i),         // Nhận Carry đầu vào
    .Sum_o (Sum_o[31:0]), // Ra kết quả 32 bit thấp
    .c_o   (carry_mid)    // Xuất Carry sang tầng cao
  );
  full_adder_32bit fa_high (
    .A_i   (A_i[63:32]),
    .Y_i   (Y_i[63:32]),
    .C_i   (carry_mid),   // Nhận Carry từ tầng thấp
    .Sum_o (Sum_o[63:32]),// Ra kết quả 32 bit cao
    .c_o   (C_o)          // Xuất Carry cuối cùng ra ngoài
  );

endmodule