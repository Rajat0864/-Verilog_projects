`timescale 1ns / 1ps

module uart_top2_tb;
    reg         clk, reset;
    reg         tx_start, rx_start;
    reg  [7:0]  data_in;
    wire        tx_busy, rx_busy;
    wire [7:0]  rx_out;

    integer pass_count = 0;
    integer fail_count = 0;
    reg [7:0] expected;

    initial clk = 0;
    always #5 clk = ~clk;

    uart_top2 dut (
        .clk(clk), .reset(reset),
        .tx_start(tx_start), .data_in(data_in),
        .rx_start(rx_start),
        .tx_busy(tx_busy), .rx_busy(rx_busy),
        .rx_out(rx_out)
    );

    task send_and_check(input [7:0] byte_val);
    begin
        expected = byte_val;
        data_in  = byte_val;

        @(negedge clk); rx_start = 1'b1;
        @(negedge clk); rx_start = 1'b0;

        @(negedge clk); tx_start = 1'b1;
        @(negedge clk); tx_start = 1'b0;

        wait (tx_busy == 1'b0);
        wait (rx_busy == 1'b0);
        #100;

        if (rx_out === expected) begin
            $display(" [PASS] Sent 0x%02H -> Received 0x%02H", expected, rx_out);
            pass_count = pass_count + 1;
        end else begin
            $display(" [FAIL] Sent 0x%02H -> Received 0x%02H  MISMATCH!", expected, rx_out);
            fail_count = fail_count + 1;
        end
    end
    endtask

    initial begin
        $dumpfile("uart_top2.vcd");
        $dumpvars(0, uart_top2_tb);

        reset    = 1'b1;
        tx_start = 1'b0;
        rx_start = 1'b0;
        data_in  = 8'h00;
        #100;
        reset = 1'b0;
        #100;

        send_and_check(8'h41);
        send_and_check(8'h55);
        send_and_check(8'hA5);
        send_and_check(8'hFF);
        send_and_check(8'h00);

        $display(" Total PASS: %0d   Total FAIL: %0d", pass_count, fail_count);
        #100;
        $finish;
    end
endmodule
