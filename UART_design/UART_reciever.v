module Uart_Rx (
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
