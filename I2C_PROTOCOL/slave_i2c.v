module iic_slave_model #(
    parameter [6:0] MY_ADDR = 7'h42
)(
    inout wire sda,
    input wire scl
);
    reg sda_drive;
    reg sda_out;
    assign sda = sda_drive ? sda_out : 1'bz;
    reg [7:0] shift_reg;
    reg [3:0] bit_cnt;
    reg [7:0] rx_data;
    reg sda_prev, scl_prev;
    initial begin
        sda_drive = 0;
        sda_out   = 0;
        sda_prev  = 1;
        scl_prev  = 1;
    end
    always @(sda or scl) begin
        sda_prev = sda_prev; 
    end
    always @(negedge sda) begin
        if (scl === 1'b1) begin
            handle_transaction;
        end
    end
    task handle_transaction;
        begin
            bit_cnt   = 4'd7;
            shift_reg = 8'd0;
            repeat (8) begin
                @(posedge scl);
                shift_reg = {shift_reg[6:0], sda};
            end
            if (shift_reg[7:1] == MY_ADDR) begin
                $display("[SLAVE] Address match (0x%0h), R/W=%b at time %0t",
                          shift_reg[7:1], shift_reg[0], $time);
                @(negedge scl);
                sda_drive = 1;
                sda_out   = 0;
                @(posedge scl);
                @(negedge scl);
                sda_drive = 0;
                if (shift_reg[0] == 1'b0) begin
                    rx_data = 8'd0;
                    repeat (8) begin
                        @(posedge scl);
                        rx_data = {rx_data[6:0], sda};
                    end
                    $display("[SLAVE] Received data = 0x%0h (%b) at time %0t",
                              rx_data, rx_data, $time);
                    @(negedge scl);
                    sda_drive = 1;
                    sda_out   = 0;
                    @(posedge scl);
                    @(negedge scl);
                    sda_drive = 0;
                end else begin
                    $display("[SLAVE] Read not implemented in this model");
                end
            end else begin
                $display("[SLAVE] Address mismatch (got 0x%0h, expected 0x%0h) - NACK at time %0t",
                          shift_reg[7:1], MY_ADDR, $time);
            end
            wait (scl === 1'b1);
            wait (sda === 1'b1);
        end
    endtask
endmodule
