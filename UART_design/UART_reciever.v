module top_module(
    input clk,
    input in,
    input reset,                    // Synchronous reset
    output reg [7:0] out_byte,
    output done                     // High for one cycle when valid byte is received
);
    // UART parameters
    parameter CLKS_PER_BIT = 87;    // Example: 10MHz clock, 115200 baud, (CLKS_PER_BIT = system frequency / UART baud rate)
    parameter IDLE = 0, START = 1, DATA = 2, PARITY = 3, STOP_CHECK = 4, STOP = 5, WAIT = 6;
    
    reg [2:0] state, next_state;
    reg [3:0] count;
    reg [15:0] clock_count;
    reg [7:0] temp_byte;
    reg parity_bit;
    
    // Metastability protection
    reg in_sync1, in_sync2;
    
    always @(posedge clk) begin
        if (reset) begin
            in_sync1 <= 1'b1;
            in_sync2 <= 1'b1;
        end else begin
            in_sync1 <= in;
            in_sync2 <= in_sync1;
        end
    end
    
    // State transition logic
    always @(posedge clk) begin
        if (reset)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    always @(*) begin
        case (state)
            IDLE:        
                next_state = (in_sync2) ? IDLE : START;  // Wait for falling edge
            START:       
                next_state = (clock_count == (CLKS_PER_BIT-1)/2) ?
                    ((in_sync2 == 1'b0) ? DATA : WAIT) : START;
            DATA:        
                next_state = (count < 7 && clock_count == CLKS_PER_BIT-1) ? DATA :
                             (count == 7 && clock_count == CLKS_PER_BIT-1) ? PARITY : DATA;
            PARITY:      
                next_state = (clock_count == CLKS_PER_BIT-1) ?
                    ((^temp_byte ^ in_sync2) ? WAIT : STOP_CHECK) : PARITY; // Even parity check - fixed syntax
            STOP_CHECK:  
                next_state = (clock_count == CLKS_PER_BIT-1) ?
                    (in_sync2 ? STOP : WAIT) : STOP_CHECK;  // Stop bit must be high
            STOP:  
                next_state = (clock_count == CLKS_PER_BIT-1) ?
                    (in_sync2 ? IDLE : WAIT) : STOP;        // Check stop bit and wait full period
            WAIT:        
                next_state = (in_sync2) ? IDLE : WAIT;
            default:     
                next_state = IDLE;
        endcase
    end
    
    // Data and control path / timing
    always @(posedge clk) begin
        if (reset) begin
            count <= 0;
            out_byte <= 0;
            temp_byte <= 0;
            parity_bit <= 0;
            clock_count <= 0;
        end else if (state == IDLE) begin
            count <= 0;
            temp_byte <= 0;
            parity_bit <= 0;
            clock_count <= 0;
        end else if (state == START) begin
            // Timing for start bit (middle sample)
            if (clock_count < (CLKS_PER_BIT-1)/2)
                clock_count <= clock_count + 1;
            else
                clock_count <= 0; // Reset for data bits (if valid)
        end else if (state == DATA) begin
            // Data bits: LSB first
            if (clock_count < CLKS_PER_BIT-1) begin
                clock_count <= clock_count + 1;
            end else begin
                temp_byte[count] <= in_sync2;  // LSB first - corrected
                count <= count + 1;
                clock_count <= 0;
            end
        end else if (state == PARITY) begin
            // Sample parity bit after all data bits
            if (clock_count < CLKS_PER_BIT-1) begin
                clock_count <= clock_count + 1;
            end else begin
                parity_bit <= in_sync2;
                clock_count <= 0;
            end
        end else if (state == STOP_CHECK) begin
            // Wait for stop bit duration
            if (clock_count < CLKS_PER_BIT-1)
                clock_count <= clock_count + 1;
            else
                clock_count <= 0;
        end else if (state == STOP) begin
            // Check stop bit and wait for full period
            if (clock_count < CLKS_PER_BIT-1) begin
                clock_count <= clock_count + 1;
            end else begin
                // Valid frame received -- output byte
                out_byte <= temp_byte;
                count <= 0;
                temp_byte <= 0;
                parity_bit <= 0;
                clock_count <= 0;
            end
        end else if (state == WAIT) begin
            clock_count <= 0;
            count <= 0;
            temp_byte <= 0;
            parity_bit <= 0;
        end else begin
            clock_count <= 0;
            count <= 0;
        end
    end
    
    assign done = (state == STOP && clock_count == CLKS_PER_BIT-1);

endmodule

