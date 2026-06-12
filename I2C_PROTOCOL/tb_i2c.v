
module tb_i2c;
    reg clk;
    reg rst;
    reg start;
    reg [6:0] test_slave_addr;
    reg [7:0] test_data;
    wire sda;
    wire scl;
    wire busy, done, ack_error;
    pullup(sda);
    iic_controller uut (
        .clk        (clk),
        .rst        (rst),
        .start      (start),
        .slave_addr (test_slave_addr),
        .data       (test_data),
        .sda        (sda),
        .scl        (scl),
        .busy       (busy),
        .done       (done),
        .ack_error  (ack_error)
    );
    iic_slave_model #(.MY_ADDR(7'h42)) slave (
        .sda(sda),
        .scl(scl)
    );
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    initial begin
        #2_000_000;
        $display("[TB] TIMEOUT - simulation did not complete");
        $finish;
    end
    initial begin
        $dumpfile("tb_i2c.vcd");
        $dumpvars(0, tb_i2c);
    end
    initial begin
        rst             = 1;
        start           = 0;
        test_slave_addr = 7'h42;
        test_data       = 8'b1010_1010;
        #50;
        rst = 0;
        #50;
        start = 1;
        #10;
        start = 0;
        wait (done == 1'b1);
        #20;
        if (ack_error)
            $display("[TB] Transaction completed with ACK ERROR at time %0t", $time);
        else
            $display("[TB] Transaction completed successfully at time %0t", $time);
        $display("Test completed.");
        #200;
        $finish;
    end
    initial begin
        $monitor("Time=%0t SCL=%b SDA=%b state=%0d busy=%b done=%b ack_err=%b",
                  $time, scl, sda, uut.state, busy, done, ack_error);
    end
endmodule
