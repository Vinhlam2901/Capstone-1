// module full_adder (
//     input  X_i,
//     input  B_i,
//     input  C_i,
//     output S_o,
//     output C_o
// );
//   wire w1, w2, w3;
//   //Structural code for one bit full adder
//   xor G1 (w1, X_i, B_i);
//   and G2 (w3, X_i, B_i);

//   and G3 (w2, w1, C_i);

//   xor G4 (S_o, w1, C_i);
//   or G5 (C_o, w2, w3);
// endmodule
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