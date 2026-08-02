`timescale 1ns / 1ps
//====================================================================
// baud_rate_genrator
// Produces two free-running enable pulses:
//   enb_tx : ticks once per bit period   (1x baud rate)  -> drives TX
//   enb_rx : ticks 16 times per bit period (16x baud rate) -> drives RX
//====================================================================
module baud_rate_genrator(input clock, reset, output reg enb_tx, enb_rx);
    parameter clk_freq   = 100000000;
    parameter baud_rate  = 9600;
    parameter divisor_tx = clk_freq / baud_rate;
    parameter divisor_rx = clk_freq / (16 * baud_rate);
    reg [13:0] counter_tx;
    reg [9:0]  counter_rx;

    always @(posedge clock) begin
        if (reset) begin
            counter_tx <= 0;
            enb_tx     <= 1'b0;
        end else if (counter_tx == divisor_tx - 1) begin
            counter_tx <= 0;
            enb_tx     <= 1'b1;
        end else begin
            counter_tx <= counter_tx + 1'b1;
            enb_tx     <= 1'b0;
        end
    end

    always @(posedge clock) begin
        if (reset) begin
            counter_rx <= 0;
            enb_rx     <= 1'b0;
        end else if (counter_rx == divisor_rx - 1) begin
            counter_rx <= 0;
            enb_rx     <= 1'b1;
        end else begin
            counter_rx <= counter_rx + 1'b1;
            enb_rx     <= 1'b0;
        end
    end
endmodule
