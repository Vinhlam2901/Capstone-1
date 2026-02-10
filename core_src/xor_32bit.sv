//===========================================================================================
// Project         : Single Cycle of RISV - V
// Module          : XOR 32 bit
// File            : xor_32bit.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 9/9/2025
// Updated date    : 6/11/2025 - Finished
//===========================================================================================
module xor_32bit (
  input  wire [31:0] rs1_i,
  input  wire [31:0] rs2_i,
  output wire [31:0] rd_o
);
  xor G0  (rd_o[0 ], rs1_i[0 ], rs2_i[0 ]);
  xor G1  (rd_o[1 ], rs1_i[1 ], rs2_i[1 ]);
  xor G2  (rd_o[2 ], rs1_i[2 ], rs2_i[2 ]);
  xor G3  (rd_o[3 ], rs1_i[3 ], rs2_i[3 ]);
  xor G4  (rd_o[4 ], rs1_i[4 ], rs2_i[4 ]);
  xor G5  (rd_o[5 ], rs1_i[5 ], rs2_i[5 ]);
  xor G6  (rd_o[6 ], rs1_i[6 ], rs2_i[6 ]);
  xor G7  (rd_o[7 ], rs1_i[7 ], rs2_i[7 ]);
  xor G8  (rd_o[8 ], rs1_i[8 ], rs2_i[8 ]);
  xor G9  (rd_o[9 ], rs1_i[9 ], rs2_i[9 ]);
  xor G10 (rd_o[10], rs1_i[10], rs2_i[10]);
  xor G11 (rd_o[11], rs1_i[11], rs2_i[11]);
  xor G12 (rd_o[12], rs1_i[12], rs2_i[12]);
  xor G13 (rd_o[13], rs1_i[13], rs2_i[13]);
  xor G14 (rd_o[14], rs1_i[14], rs2_i[14]);
  xor G15 (rd_o[15], rs1_i[15], rs2_i[15]);
  xor G16 (rd_o[16], rs1_i[16], rs2_i[16]);
  xor G17 (rd_o[17], rs1_i[17], rs2_i[17]);
  xor G18 (rd_o[18], rs1_i[18], rs2_i[18]);
  xor G19 (rd_o[19], rs1_i[19], rs2_i[19]);
  xor G20 (rd_o[20], rs1_i[20], rs2_i[20]);
  xor G21 (rd_o[21], rs1_i[21], rs2_i[21]);
  xor G22 (rd_o[22], rs1_i[22], rs2_i[22]);
  xor G23 (rd_o[23], rs1_i[23], rs2_i[23]);
  xor G24 (rd_o[24], rs1_i[24], rs2_i[24]);
  xor G25 (rd_o[25], rs1_i[25], rs2_i[25]);
  xor G26 (rd_o[26], rs1_i[26], rs2_i[26]);
  xor G27 (rd_o[27], rs1_i[27], rs2_i[27]);
  xor G28 (rd_o[28], rs1_i[28], rs2_i[28]);
  xor G29 (rd_o[29], rs1_i[29], rs2_i[29]);
  xor G30 (rd_o[30], rs1_i[30], rs2_i[30]);
  xor G31 (rd_o[31], rs1_i[31], rs2_i[31]);
endmodule
