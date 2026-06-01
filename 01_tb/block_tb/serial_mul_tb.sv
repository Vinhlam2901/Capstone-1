module serial_mul_tb #(parameter WIDTH = 8 )(
    input  wire i_clk,
    input  wire i_run,
    output reg  o_finished,
    output reg  o_pass        // MỚI: Cờ báo hiệu PASS (1) hay FAIL (0)
);

    reg                        i_reset;
    reg                        i_start;
    reg  signed [WIDTH-1:0]    i_op_a;
    reg  signed [WIDTH-1:0]    i_op_b;
    wire signed [2*WIDTH-1:0]  o_result;
    wire                       o_done;
    integer cycle_count;
    
    wire signed [WIDTH-1:0] rand_a = {$random, $random, $random};
    wire signed [WIDTH-1:0] rand_b = {$random, $random, $random};

    serial_multiplier #(WIDTH) DUT (
        .i_clk    (i_clk),
        .i_reset  (i_reset),
        .i_start  (i_start),
        .i_op_a   (i_op_a),
        .i_op_b   (i_op_b),
        .o_result (o_result),
        .o_done   (o_done)
    );

    initial begin
        o_finished = 0;
        o_pass     = 0;
        i_reset = 0;
        i_start = 0;
        i_op_a  = 0;
        i_op_b  = 0;
        cycle_count = 0;

        // Treo chờ Top-level gọi
        wait(i_run == 1);
        
        i_reset = 1;
        repeat(2) @(posedge i_clk);

        i_op_a  = rand_a;
        i_op_b  = rand_b;
        
        i_start = 1'b1;
        @(posedge i_clk);
        i_start = 1'b0;

        // Đếm chu kỳ
        cycle_count = 0;
        while (o_done == 0) begin
            @(posedge i_clk);
            cycle_count = cycle_count + 1;
        end

        // KIỂM TRA ĐÚNG SAI VÀ GÁN CỜ
        if (o_result === (i_op_a * i_op_b)) begin
            $display("[PASS] WIDTH = %2d | Cycles: %2d | Result:!", WIDTH, cycle_count, o_result);
            o_pass = 1'b1;
        end else begin
            $display("[FAIL] WIDTH = %2d | Expected: %h, Got: %h", WIDTH, (i_op_a * i_op_b), o_result);
            o_pass = 1'b0;
        end
        
        o_finished = 1; 
    end
endmodule