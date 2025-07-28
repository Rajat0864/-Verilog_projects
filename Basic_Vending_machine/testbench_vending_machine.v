
`timescale 1ns/1ps

module testbench;

  reg clk;
  reg reset;
  reg [1:0] in;
  wire [1:0] Return_change;
  wire product_dispatched;

  // Instantiate the DUT
  top_module dut (
    .clk(clk),
    .in(in),
    .reset(reset),
    .Return_change(Return_change),
    .product_dispatched(product_dispatched)
  );

  // Clock generation
  always #5 clk = ~clk;

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(1, testbench);

    // Initialize
    clk = 0;
    reset = 1;
    in = 2'b00;

    #10;
    reset = 0;

    // Insert 5rs (01)
    in = 2'b01; #10;

    // Insert 10rs (10) -> total 15 -> dispatch product
    in = 2'b10; #10;

    // Idle
    in = 2'b00; #10;

    // Insert 10rs only -> go to S3
    in = 2'b10; #10;

    // Insert 5rs -> should dispatch product
    in = 2'b01; #10;

    // Insert 5rs then 5rs -> should dispatch product
    in = 2'b01; #10;
    in = 2'b01; #10;

    // Insert only 5rs then cancel (00) -> should return change
    in = 2'b01; #10;
    in = 2'b00; #10;

    // Done
    $finish;
  end

endmodule
