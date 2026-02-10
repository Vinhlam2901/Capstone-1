//===========================================================================================
// Project         : Single Cycle of RISV - V
// Module          : AND 32 bit
// File            : and_32bit.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 9/9/2025
// Updated date    : 6/11/2025 - Finished
//===========================================================================================
module and_32bit (
  input       [31:0] rs1_i,
  input       [31:0] rs2_i,
  output wire [31:0] rd_o
);
  and and0  (rd_o[0 ], rs1_i[0 ], rs2_i[0 ]);
  and and1  (rd_o[1 ], rs1_i[1 ], rs2_i[1 ]);
  and and2  (rd_o[2 ], rs1_i[2 ], rs2_i[2 ]);
  and and3  (rd_o[3 ], rs1_i[3 ], rs2_i[3 ]);
  and and4  (rd_o[4 ], rs1_i[4 ], rs2_i[4 ]);
  and and5  (rd_o[5 ], rs1_i[5 ], rs2_i[5 ]);
  and and6  (rd_o[6 ], rs1_i[6 ], rs2_i[6 ]);
  and and7  (rd_o[7 ], rs1_i[7 ], rs2_i[7 ]);
  and and8  (rd_o[8 ], rs1_i[8 ], rs2_i[8 ]);
  and and9  (rd_o[9 ], rs1_i[9 ], rs2_i[9 ]);
  and and10 (rd_o[10], rs1_i[10], rs2_i[10]);
  and and11 (rd_o[11], rs1_i[11], rs2_i[11]);
  and and12 (rd_o[12], rs1_i[12], rs2_i[12]);
  and and13 (rd_o[13], rs1_i[13], rs2_i[13]);
  and and14 (rd_o[14], rs1_i[14], rs2_i[14]);
  and and15 (rd_o[15], rs1_i[15], rs2_i[15]);
  and and16 (rd_o[16], rs1_i[16], rs2_i[16]);
  and and17 (rd_o[17], rs1_i[17], rs2_i[17]);
  and and18 (rd_o[18], rs1_i[18], rs2_i[18]);
  and and19 (rd_o[19], rs1_i[19], rs2_i[19]);
  and and20 (rd_o[20], rs1_i[20], rs2_i[20]);
  and and21 (rd_o[21], rs1_i[21], rs2_i[21]);
  and and22 (rd_o[22], rs1_i[22], rs2_i[22]);
  and and23 (rd_o[23], rs1_i[23], rs2_i[23]);
  and and24 (rd_o[24], rs1_i[24], rs2_i[24]);
  and and25 (rd_o[25], rs1_i[25], rs2_i[25]);
  and and26 (rd_o[26], rs1_i[26], rs2_i[26]);
  and and27 (rd_o[27], rs1_i[27], rs2_i[27]);
  and and28 (rd_o[28], rs1_i[28], rs2_i[28]);
  and and29 (rd_o[29], rs1_i[29], rs2_i[29]);
  and and30 (rd_o[30], rs1_i[30], rs2_i[30]);
  and and31 (rd_o[31], rs1_i[31], rs2_i[31]);
endmodule
