`timescale 1ns / 1ps
//====================================================================
// Uart_Rx  (rewritten to use 16x oversampling)
//
// The version you originally pasted had NO oversampling logic at all -
// every clken pulse was treated as "one full bit has elapsed", which
// only works if clken is already a 1x baud tick. That is not how a
// real UART receiver should work (no shared clock with the sender, so
// you can't safely rely on a single sample per bit - see the earlier
// discussion on why 16x oversampling exists).
//
// This version borrows the "sample" counter pattern directly from the
// reference uart_reciever module:
//   - clken is now expected to be the 16x baud tick (rx_clk_en)
//   - "sample" counts 0..15 ticks within the current bit
//   - START: waits a full 16-tick bit period after data_in first goes
//            low, to confirm a genuine start bit (same as reference)
//   - DATA/PARITY: the actual bit is sampled at sample==8, the
//            mid-point of the bit - same reasoning as the reference
//            receiver (furthest from either edge, most settled point)
//   - state only advances once a full 16-tick bit period has elapsed
//     (sample==15), keeping every state the same duration
//====================================================================
module Uart_Rx (
    input        clk, reset, rx_start,
    input        clken,          // 16x baud tick (rx_clk_en) from baud_rate_genrator
    input        data_in,
    output reg [7:0] rx_out,
    output       busy
);
    parameter IDLE       = 3'b000,
              START      = 3'b001,
              DATA       = 3'b010,
              Parity_chk = 3'b011,
              STOP       = 3'b100;

    reg [2:0] state;
    reg [3:0] sample;     // 0..15 : position within the current bit (16x oversampling)
    reg [3:0] bit_index;  // 0..8  : which data bit is currently being received
    reg [7:0] shift_rx;
    reg       parity_bit; // received parity bit, sampled mid-bit like the data bits

    always @(posedge clk) begin
        if (reset) begin
            state      <= IDLE;
            sample     <= 4'd0;
            bit_index  <= 4'd0;
            shift_rx   <= 8'd0;
            rx_out     <= 8'd0;
            parity_bit <= 1'b0;
        end
        else begin
            case (state)
                // IDLE is checked every clk edge (not gated by clken) so
                // an rx_start pulse is never missed.
                IDLE: begin
                    if (rx_start) begin
                        state  <= START;
                        sample <= 4'd0;
                    end
                end

                // Wait a full 16-tick bit period after the line first
                // goes low, to confirm a real start bit (filters glitches
                // the same way the reference uart_reciever does).
                START: begin
                    if (clken) begin
                        if (!data_in || sample != 4'd0)
                            sample <= sample + 4'd1;
                        if (sample == 4'd15) begin
                            state     <= DATA;
                            sample    <= 4'd0;
                            bit_index <= 4'd0;
                            shift_rx  <= 8'd0;
                        end
                    end
                end

                // Sample each of the 8 data bits at the mid-point (sample==8),
                // then wait out the rest of the bit period (sample==15)
                // before moving to the next bit / next state.
                DATA: begin
                    if (clken) begin
                        sample <= sample + 4'd1;
                        if (sample == 4'h8) begin
                            shift_rx  <= {data_in, shift_rx[7:1]};
                            bit_index <= bit_index + 4'd1;
                        end
                        if (bit_index == 4'd8 && sample == 4'd15) begin
                            state  <= Parity_chk;
                            sample <= 4'd0;
                            rx_out <= shift_rx;
                        end
                    end
                end

                // Sample the parity bit mid-bit, then compare it once the
                // full bit period has elapsed.
                Parity_chk: begin
                    if (clken) begin
                        sample <= sample + 4'd1;
                        if (sample == 4'h8)
                            parity_bit <= data_in;
                        if (sample == 4'd15) begin
                            state  <= (parity_bit == ^shift_rx) ? STOP : START;
                            sample <= 4'd0;
                        end
                    end
                end

                // Sample the stop bit mid-bit, report, then return to IDLE
                // once the full bit period has elapsed.
                STOP: begin
                    if (clken) begin
                        sample <= sample + 4'd1;
                        if (sample == 4'd15) begin
                            state <= IDLE;
                            if (data_in)
                                $display("Next-data");
                            else
                                $display("retransmit the data");
                        end
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end
    assign busy = (state != IDLE);
endmodulemodule Uart_Rx (
    input  clk, reset, rx_start,
    input  data_in,
    output reg [7:0] rx_out,
    output busy                     // FIX: was "output reg busy" — but busy is driven
                                     // by a continuous "assign" below, and a reg type
                                     // cannot be the target of "assign". Since it's
                                     // combinationally derived from state, it should
                                     // just be a plain wire (default net type), not reg.
);

reg [3:0] count;
reg [7:0] shift_rx;
reg [2:0] state;                // FIX: "state" was used throughout but never declared
reg rx_bit;                     // FIX: declared for use in reset block (was undeclared)

parameter IDLE        = 3'b000,
          START        = 3'b001,
          DATA         = 3'b010,
          Parity_chk   = 3'b011,
          STOP         = 3'b100;

always @(posedge clk) begin
    if (reset) begin
        // FIX: removed "busy <= 1'b0;" — busy is now a wire (driven by the
        // "assign busy = (state != IDLE)" below), so it can't be assigned
        // inside this always block. It resolves to 0 automatically once
        // state <= IDLE takes effect below.
        rx_bit <= 1'b0;
        rx_out <= 8'b0;
        state  <= IDLE;          // FIX: reset block didn't initialize state; FSM
                                  // could start in an unknown/garbage state otherwise
        // FIX: removed "data_in <= 1'b1;" here — data_in is a module INPUT port,
        // it can never be assigned to from inside the module (hard syntax error)
    end
    else begin
        case (state)

            IDLE: begin
                // FIX: removed "data_in <= 1'b1;" here too, same reason as above —
                // data_in is an input, driving it is illegal
                if (rx_start) begin
                    count <= 3'd7;
                    state <= START;
                end
            end

            START: begin
                state <= data_in ? START : DATA;  // wait for line to go low = start bit
            end

            DATA: begin
                shift_rx <= {data_in, shift_rx[7:1]};
                count    <= count - 1;
                if (count == 0) begin
                    // FIX: was "rx_out <= shift_rx;" — this read the STALE pre-shift
                    // value of shift_rx, missing the final bit being shifted in on
                    // this same edge. Must use the same expression as the shift_rx
                    // assignment above so the last bit is actually captured.
                    rx_out <= {data_in, shift_rx[7:1]};
                    count  <= 3'd7;
                    state  <= Parity_chk;
                end
            end

            Parity_chk: begin
                // FIX: was "(^data_in && ^rx_out)" then "(^data_in && ~(^rx_out))" —
                // neither correctly compares the received parity bit against the
                // computed parity of rx_out. AND/NOT combinations can't express
                // "these two bits are equal" for all cases. Use "==" (equivalent
                // to XNOR for single bits) to correctly check even parity match.
                state <= (data_in == ^rx_out) ? STOP : START;
            end

            STOP: begin
                if (data_in) begin
                    state <= IDLE;
                    $display("Next-data");
                end
                else begin
                    state <= IDLE;
                    $display("retransmit the data");
                end
            end

            default: state <= IDLE;

        endcase
    end
end

assign busy = (state != IDLE);

endmodule
