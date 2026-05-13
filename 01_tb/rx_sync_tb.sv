`timescale 1ns / 1ps

module rx_sync_tb;

  // 1. Khai báo tín hiệu
  logic clk;
  logic rst_n;
  logic rx_in;
  logic rx_sync_out;
  logic start_en_out;

  // 2. Khởi tạo DUT
  rx_sync dut (
    .i_clk(clk),
    .ni_rst(rst_n),
    .i_rx_signal(rx_in),
    .o_rx_sync(rx_sync_out),
    .o_start_en(start_en_out)
  );

  // 3. Khởi tạo file Dump VCD
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, rx_sync_tb);
  end

  // 4. Tạo xung Clock (Chu kỳ 10ns -> 100MHz)
  // Sườn lên (Posedge) sẽ rơi vào các mốc: 5ns, 15ns, 25ns, 35ns...
  initial begin
    clk = 0;
    forever #5 clk = ~clk; 
  end

  initial begin
    // Khởi tạo
    rst_n = 0; rx_in = 1;
    #15; 
    rst_n = 1;
    #10; 

    // NHIỄU CỰC NGẮN (GLITCH) GIỮA 2 NHỊP CLOCK
    $display("[%0t] Kich ban 1: Bơm nhieu Glitch 2ns vao giua chu ky Clock", $time);
    // Thời điểm hiện tại là 25ns. Đợi đến 27ns rồi đánh nhiễu
    #2;  
    rx_in = 0; // Rớt xuống 0 ở 27ns
    #2; 
    rx_in = 1; // Kéo lên lại ở 29ns (Chưa tới sườn clock tiếp theo ở 35ns)
    #30;

    // NHIỄU CHÙM (BOUNCING / RINGING)
    rx_in = 0; #1;
    rx_in = 1; #1;
    rx_in = 0; #1;
    rx_in = 1; #30;

    // NHIỄU TRÚNG NGAY SƯỜN LÊN CLOCK (Nguy hiểm)
    // Sườn clock tiếp theo là 95ns. Ta cho rớt ở 94ns và kéo lên ở 96ns
    #3; // Đang ở 91ns -> lên 94ns
    rx_in = 0; 
    #2; // Kéo dài qua mốc 95ns
    rx_in = 1; 
    #30;

    // START BIT THẬT SỰ (TÍN HIỆU ỔN ĐỊNH)
    rx_in = 0; 
    #80; // Giữ ở mức 0 rất lâu để giả lập 1 bit baudrate

    $display("[%0t] Hoan tat mo phong.", $time);
    $finish;
  end

endmodule