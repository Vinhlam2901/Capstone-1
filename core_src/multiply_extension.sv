module multiply_extension (
  input  wire [31:0] i_op_a,
  input  wire [31:0] i_op_b,
  output wire [31:0] o_mul_low,
  output wire [31:0] o_mul_high
);
// check bit lsb to msb of op_a equal to 1 ?
// is 1 -> hold op_b; is 0 -> clear
// check the next bit n of op_a equal to 1 ?
// is 1 -> accumulate op_b then shift left n bit.
// repeat to msb of op_a
// but just need the 64bit o_mul -> so just mul 16 bit op_a and op_b -> so check from bit 0 to bit 16 of op_a.
  wire        sign_a, sign_b;
  wire [31:0] op_a, op_b;
  wire [31:0] convert_a, convert_b;
  wire [63:0] op_b0 , op_b1 , op_b2 , op_b3 , op_b4 , op_b5 , 
              op_b6 , op_b7 , op_b8 , op_b9 , op_b10, op_b11, 
              op_b12, op_b13, op_b14, op_b15, op_b16, op_b17, 
              op_b18, op_b19, op_b20, op_b21, op_b22, op_b23, 
              op_b24, op_b25, op_b26, op_b27, op_b28, op_b29, 
              op_b30, op_b31;
  wire [63:0] result_64b;
  wire [63:0] o_temp0 , o_temp1 , o_temp2 , o_temp3 , o_temp4 , 
              o_temp5 , o_temp6 , o_temp7 , o_temp8 , o_temp9 , 
              o_temp10, o_temp11, o_temp12, o_temp13, o_temp14, 
              o_temp15, o_temp16, o_temp17, o_temp18, o_temp19, 
              o_temp20, o_temp21, o_temp22, o_temp23, o_temp24, 
              o_temp25, o_temp26, o_temp27, o_temp28, o_temp29, 
              o_temp30;
  wire        cout0 , cout1 , cout2 , cout3 , cout4 , cout5 , cout6 , cout7 , cout8 , 
              cout9 , cout10, cout11, cout12, cout13, cout14, cout15, cout16, cout17, 
              cout18, cout19, cout20, cout21, cout22, cout23, cout24, cout25, cout26, 
              cout27, cout28, cout29, cout30, cout31;
//=============================SIGN=======================================================================================
  assign sign_a    = i_op_a[31];
  assign sign_b    = i_op_b[31];
  assign convert_a = (sign_a) ? (~i_op_a + 1) : i_op_a;
  assign convert_b = (sign_b) ? (~i_op_b + 1) : i_op_b;
//=============================LSB=======================================================================================
  assign op_b0  = (convert_a[ 0]) ? {{32{1'b0}}, convert_b            } : 64'b0;
  assign op_b1  = (convert_a[ 1]) ? {{31{1'b0}}, convert_b, { 1{1'b0}}} : 64'b0;
  assign op_b2  = (convert_a[ 2]) ? {{30{1'b0}}, convert_b, { 2{1'b0}}} : 64'b0;
  assign op_b3  = (convert_a[ 3]) ? {{29{1'b0}}, convert_b, { 3{1'b0}}} : 64'b0;
  assign op_b4  = (convert_a[ 4]) ? {{28{1'b0}}, convert_b, { 4{1'b0}}} : 64'b0;
  assign op_b5  = (convert_a[ 5]) ? {{27{1'b0}}, convert_b, { 5{1'b0}}} : 64'b0;
  assign op_b6  = (convert_a[ 6]) ? {{26{1'b0}}, convert_b, { 6{1'b0}}} : 64'b0;
  assign op_b7  = (convert_a[ 7]) ? {{25{1'b0}}, convert_b, { 7{1'b0}}} : 64'b0;
  assign op_b8  = (convert_a[ 8]) ? {{24{1'b0}}, convert_b, { 8{1'b0}}} : 64'b0;
  assign op_b9  = (convert_a[ 9]) ? {{23{1'b0}}, convert_b, { 9{1'b0}}} : 64'b0;
  assign op_b10 = (convert_a[10]) ? {{22{1'b0}}, convert_b, {10{1'b0}}} : 64'b0;
  assign op_b11 = (convert_a[11]) ? {{21{1'b0}}, convert_b, {11{1'b0}}} : 64'b0;
  assign op_b12 = (convert_a[12]) ? {{20{1'b0}}, convert_b, {12{1'b0}}} : 64'b0;
  assign op_b13 = (convert_a[13]) ? {{19{1'b0}}, convert_b, {13{1'b0}}} : 64'b0;
  assign op_b14 = (convert_a[14]) ? {{18{1'b0}}, convert_b, {14{1'b0}}} : 64'b0;
  assign op_b15 = (convert_a[15]) ? {{17{1'b0}}, convert_b, {15{1'b0}}} : 64'b0;
  assign op_b16 = (convert_a[16]) ? {{16{1'b0}}, convert_b, {16{1'b0}}} : 64'b0;
  assign op_b17 = (convert_a[17]) ? {{15{1'b0}}, convert_b, {17{1'b0}}} : 64'b0;
  assign op_b18 = (convert_a[18]) ? {{14{1'b0}}, convert_b, {18{1'b0}}} : 64'b0;
  assign op_b19 = (convert_a[19]) ? {{13{1'b0}}, convert_b, {19{1'b0}}} : 64'b0;
  assign op_b20 = (convert_a[20]) ? {{12{1'b0}}, convert_b, {20{1'b0}}} : 64'b0;
  assign op_b21 = (convert_a[21]) ? {{11{1'b0}}, convert_b, {21{1'b0}}} : 64'b0;
  assign op_b22 = (convert_a[22]) ? {{10{1'b0}}, convert_b, {22{1'b0}}} : 64'b0;
  assign op_b23 = (convert_a[23]) ? {{ 9{1'b0}}, convert_b, {23{1'b0}}} : 64'b0;
  assign op_b24 = (convert_a[24]) ? {{ 8{1'b0}}, convert_b, {24{1'b0}}} : 64'b0;
  assign op_b25 = (convert_a[25]) ? {{ 7{1'b0}}, convert_b, {25{1'b0}}} : 64'b0;
  assign op_b26 = (convert_a[26]) ? {{ 6{1'b0}}, convert_b, {26{1'b0}}} : 64'b0;
  assign op_b27 = (convert_a[27]) ? {{ 5{1'b0}}, convert_b, {27{1'b0}}} : 64'b0;
  assign op_b28 = (convert_a[28]) ? {{ 4{1'b0}}, convert_b, {28{1'b0}}} : 64'b0;
  assign op_b29 = (convert_a[29]) ? {{ 3{1'b0}}, convert_b, {29{1'b0}}} : 64'b0;
  assign op_b30 = (convert_a[30]) ? {{ 2{1'b0}}, convert_b, {30{1'b0}}} : 64'b0;
  assign op_b31 = (convert_a[31]) ? {{ 1{1'b0}}, convert_b, {31{1'b0}}} : 64'b0;
//=============================LSB=======================================================================================
  // adder
  full_adder_64bit full_adder0  (.A_i(op_b0   ),.Y_i(op_b1 ),.C_i(1'b0),.Sum_o(o_temp0 ),.C_o());
  full_adder_64bit full_adder1  (.A_i(o_temp0 ),.Y_i(op_b2 ),.C_i(1'b0),.Sum_o(o_temp1 ),.C_o());
  full_adder_64bit full_adder2  (.A_i(o_temp1 ),.Y_i(op_b3 ),.C_i(1'b0),.Sum_o(o_temp2 ),.C_o());
  full_adder_64bit full_adder3  (.A_i(o_temp2 ),.Y_i(op_b4 ),.C_i(1'b0),.Sum_o(o_temp3 ),.C_o());
  full_adder_64bit full_adder4  (.A_i(o_temp3 ),.Y_i(op_b5 ),.C_i(1'b0),.Sum_o(o_temp4 ),.C_o());
  full_adder_64bit full_adder5  (.A_i(o_temp4 ),.Y_i(op_b6 ),.C_i(1'b0),.Sum_o(o_temp5 ),.C_o());
  full_adder_64bit full_adder6  (.A_i(o_temp5 ),.Y_i(op_b7 ),.C_i(1'b0),.Sum_o(o_temp6 ),.C_o());
  full_adder_64bit full_adder7  (.A_i(o_temp6 ),.Y_i(op_b8 ),.C_i(1'b0),.Sum_o(o_temp7 ),.C_o());
  full_adder_64bit full_adder8  (.A_i(o_temp7 ),.Y_i(op_b9 ),.C_i(1'b0),.Sum_o(o_temp8 ),.C_o());
  full_adder_64bit full_adder9  (.A_i(o_temp8 ),.Y_i(op_b10),.C_i(1'b0),.Sum_o(o_temp9 ),.C_o());
  full_adder_64bit full_adder10 (.A_i(o_temp9 ),.Y_i(op_b11),.C_i(1'b0),.Sum_o(o_temp10),.C_o());
  full_adder_64bit full_adder11 (.A_i(o_temp10),.Y_i(op_b12),.C_i(1'b0),.Sum_o(o_temp11),.C_o());
  full_adder_64bit full_adder12 (.A_i(o_temp11),.Y_i(op_b13),.C_i(1'b0),.Sum_o(o_temp12),.C_o());
  full_adder_64bit full_adder13 (.A_i(o_temp12),.Y_i(op_b14),.C_i(1'b0),.Sum_o(o_temp13),.C_o());
  full_adder_64bit full_adder14 (.A_i(o_temp13),.Y_i(op_b15),.C_i(1'b0),.Sum_o(o_temp14),.C_o());
  full_adder_64bit full_adder15 (.A_i(o_temp14),.Y_i(op_b16),.C_i(1'b0),.Sum_o(o_temp15),.C_o());
  full_adder_64bit full_adder16 (.A_i(o_temp15),.Y_i(op_b17),.C_i(1'b0),.Sum_o(o_temp16),.C_o());
  full_adder_64bit full_adder17 (.A_i(o_temp16),.Y_i(op_b18),.C_i(1'b0),.Sum_o(o_temp17),.C_o());
  full_adder_64bit full_adder18 (.A_i(o_temp17),.Y_i(op_b19),.C_i(1'b0),.Sum_o(o_temp18),.C_o());
  full_adder_64bit full_adder19 (.A_i(o_temp18),.Y_i(op_b20),.C_i(1'b0),.Sum_o(o_temp19),.C_o());
  full_adder_64bit full_adder20 (.A_i(o_temp19),.Y_i(op_b21),.C_i(1'b0),.Sum_o(o_temp20),.C_o());
  full_adder_64bit full_adder21 (.A_i(o_temp20),.Y_i(op_b22),.C_i(1'b0),.Sum_o(o_temp21),.C_o());
  full_adder_64bit full_adder22 (.A_i(o_temp21),.Y_i(op_b23),.C_i(1'b0),.Sum_o(o_temp22),.C_o());
  full_adder_64bit full_adder23 (.A_i(o_temp22),.Y_i(op_b24),.C_i(1'b0),.Sum_o(o_temp23),.C_o());
  full_adder_64bit full_adder24 (.A_i(o_temp23),.Y_i(op_b25),.C_i(1'b0),.Sum_o(o_temp24),.C_o());
  full_adder_64bit full_adder25 (.A_i(o_temp24),.Y_i(op_b26),.C_i(1'b0),.Sum_o(o_temp25),.C_o());
  full_adder_64bit full_adder26 (.A_i(o_temp25),.Y_i(op_b27),.C_i(1'b0),.Sum_o(o_temp26),.C_o());
  full_adder_64bit full_adder27 (.A_i(o_temp26),.Y_i(op_b28),.C_i(1'b0),.Sum_o(o_temp27),.C_o());
  full_adder_64bit full_adder28 (.A_i(o_temp27),.Y_i(op_b29),.C_i(1'b0),.Sum_o(o_temp28),.C_o());
  full_adder_64bit full_adder29 (.A_i(o_temp28),.Y_i(op_b30),.C_i(1'b0),.Sum_o(o_temp29),.C_o());
  full_adder_64bit full_adder30 (.A_i(o_temp29),.Y_i(op_b31),.C_i(1'b0),.Sum_o(o_temp30),.C_o());

  assign result_64b = (sign_a != sign_b) ? (~o_temp30 + 1) : o_temp30;
  assign o_mul_high = result_64b[63:32];
  assign o_mul_low  = result_64b[31:0];

endmodule
