//===========================================================================================================
// Project         : UART & RVV
// Module          : Full Adder 1 bit
// File            : full_adder.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 12/12/2025
// Updated date    : 04/03/2026
//============================================================================================================
module full_adder (
    input  X_i,
    input  B_i,
    input  C_i,
    output S_o,
    output C_o
);
  wire w1, w2, w3;
  //Structural code for one bit full adder
  xor G1 (w1, X_i, B_i);
  and G2 (w3, X_i, B_i);

  and G3 (w2, w1, C_i);

  xor G4 (S_o, w1, C_i);
  or G5 (C_o, w2, w3);
endmodule