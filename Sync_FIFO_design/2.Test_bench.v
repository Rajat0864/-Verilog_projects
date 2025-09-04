
`timescale 1ns/1ps

module FIFO_tb;

  parameter DSIZE = 8;
  parameter DEPTH = 8;

  reg clk, rst;
  reg w_e, r_e;
  reg [DSIZE-1:0] buf_in;
  wire [DSIZE-1:0] buf_out;
  wire buf_empty, buf_full;
  wire [7:0] fifo_counter;
  wire [7:0] wr_ptr, rd_ptr;

  integer i;
  integer seed = 1;

  top_module dut (
    .clk(clk),
    .rst(rst),
    .w_e(w_e),
    .r_e(r_e),
    .buf_empty(buf_empty),
    .buf_full(buf_full),
    .buf_in(buf_in),
    .buf_out(buf_out),
    .fifo_counter(fifo_counter),
    .wr_ptr(wr_ptr),
    .rd_ptr(rd_ptr)
  );

  always #5 clk = ~clk;

  initial begin
    $dumpfile("fifo_tb.vcd");
    $dumpvars(0, FIFO_tb);
  end

  initial begin
    $display("Time\tclk\trst\tw_e\tr_e\tbuf_in\tbuf_out\tfifo_ctr\twr_ptr\trd_ptr\tempty\tfull");
    $monitor("%0dns\t%b\t%b\t%b\t%b\t%h\t%h\t%0d\t%0d\t%0d\t%b\t%b",
             $time, clk, rst, w_e, r_e, buf_in, buf_out,
             fifo_counter, wr_ptr, rd_ptr, buf_empty, buf_full);
  end

  initial begin
    clk = 0; rst = 1;
    w_e = 0; r_e = 0;
    buf_in = 0;

    #20 rst = 0;

    for (i = 0; i < 5; i = i + 1) begin
      @(negedge clk);
      if (!buf_full) begin
        w_e = 1; buf_in = $random(seed);
      end
      @(negedge clk);
      w_e = 0;
    end

    for (i = 0; i < 5; i = i + 1) begin
      @(negedge clk);
      if (!buf_empty) r_e = 1;
      @(negedge clk);
      r_e = 0;
    end

    for (i = 0; i < DEPTH + 3; i = i + 1) begin
      @(negedge clk);
      if (!buf_full) begin
        w_e = 1; buf_in = $random(seed);
      end else begin
        w_e = 1; buf_in = $random(seed);
        $display("Attempted write when FULL at %0dns", $time);
      end
      @(negedge clk);
      w_e = 0;
    end

    for (i = 0; i < DEPTH + 3; i = i + 1) begin
      @(negedge clk);
      if (!buf_empty) begin
        r_e = 1;
      end else begin
        r_e = 1;
        $display("Attempted read when EMPTY at %0dns", $time);
      end
      @(negedge clk);
      r_e = 0;
    end

    #50;
    $finish;
  end

endmodule
