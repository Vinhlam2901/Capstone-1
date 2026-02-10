//===========================================================================================
// Project         : Single Cycle of RISV - V
// Module          : OR 32 bit
// File            : or_32bit.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 9/9/2025
// Updated date    : 6/11/2025 - Finished
//===========================================================================================
module or_32bit (
  input       [31:0] rs1_i,
  input       [31:0] rs2_i,
  output wire [31:0] rd_o
);
  or or0  (rd_o[0 ], rs1_i[0 ], rs2_i[0 ]);
  or or1  (rd_o[1 ], rs1_i[1 ], rs2_i[1 ]);
  or or2  (rd_o[2 ], rs1_i[2 ], rs2_i[2 ]);
  or or3  (rd_o[3 ], rs1_i[3 ], rs2_i[3 ]);
  or or4  (rd_o[4 ], rs1_i[4 ], rs2_i[4 ]);
  or or5  (rd_o[5 ], rs1_i[5 ], rs2_i[5 ]);
  or or6  (rd_o[6 ], rs1_i[6 ], rs2_i[6 ]);
  or or7  (rd_o[7 ], rs1_i[7 ], rs2_i[7 ]);
  or or8  (rd_o[8 ], rs1_i[8 ], rs2_i[8 ]);
  or or9  (rd_o[9 ], rs1_i[9 ], rs2_i[9 ]);
  or or10 (rd_o[10], rs1_i[10], rs2_i[10]);
  or or11 (rd_o[11], rs1_i[11], rs2_i[11]);
  or or12 (rd_o[12], rs1_i[12], rs2_i[12]);
  or or13 (rd_o[13], rs1_i[13], rs2_i[13]);
  or or14 (rd_o[14], rs1_i[14], rs2_i[14]);
  or or15 (rd_o[15], rs1_i[15], rs2_i[15]);
  or or16 (rd_o[16], rs1_i[16], rs2_i[16]);
  or or17 (rd_o[17], rs1_i[17], rs2_i[17]);
  or or18 (rd_o[18], rs1_i[18], rs2_i[18]);
  or or19 (rd_o[19], rs1_i[19], rs2_i[19]);
  or or20 (rd_o[20], rs1_i[20], rs2_i[20]);
  or or21 (rd_o[21], rs1_i[21], rs2_i[21]);
  or or22 (rd_o[22], rs1_i[22], rs2_i[22]);
  or or23 (rd_o[23], rs1_i[23], rs2_i[23]);
  or or24 (rd_o[24], rs1_i[24], rs2_i[24]);
  or or25 (rd_o[25], rs1_i[25], rs2_i[25]);
  or or26 (rd_o[26], rs1_i[26], rs2_i[26]);
  or or27 (rd_o[27], rs1_i[27], rs2_i[27]);
  or or28 (rd_o[28], rs1_i[28], rs2_i[28]);
  or or29 (rd_o[29], rs1_i[29], rs2_i[29]);
  or or30 (rd_o[30], rs1_i[30], rs2_i[30]);
  or or31 (rd_o[31], rs1_i[31], rs2_i[31]);
endmodule
