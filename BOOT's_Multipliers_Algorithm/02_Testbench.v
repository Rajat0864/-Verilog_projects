`timescale 1ns / 1ps

module tb_Code();

    parameter N = 4;
    
    reg signed [N-1:0] Multiplier;
    reg signed [N-1:0] Multiplicant;
    wire [2*N-1:0] out;
    
    // Instantiate DUT
    Code #(
        .N(N)
    ) dut (
        .Multiplier(Multiplier),
        .Multiplicant(Multiplicant),
        .out(out)
    );
    
    initial begin
        $dumpfile("Code.vcd");
        $dumpvars(0, tb_Code);
        
        #10 Multiplier =  3; Multiplicant =  3;
        #10 $display(" 3 *  3 = 9 (8'h9): %h", out);

        #10 Multiplier =  7; Multiplicant =  5;
        #10 $display(" 7 *  5 = 35 (8'h23): %h", out);
        
        #10 Multiplier =  4; Multiplicant =  4;
        #10 $display(" 4 *  4 = 16 (8'h10): %h", out);
        
        #10 Multiplier =  0; Multiplicant = 15;
        #10 $display(" 0 * 15 =  0 (8'h00): %h", out);
        
        #10 Multiplier = 15; Multiplicant = 15;
        #10 $display("15 * 15 =225 (8'hE1): %h", out);
        
        #10 Multiplier = -7; Multiplicant =  5;
        #10 $display("-7 *  5 =-35 (8'hDD): %h", out);
        
        #10 Multiplier =  7; Multiplicant = -5;
        #10 $display(" 7 * -5 =-35 (8'hDD): %h", out);
        
        #10 Multiplier = -7; Multiplicant = -5;
        #10 $display("-7 * -5 = 35 (8'h23): %h", out);
        
        #50 $display("Simulation Complete");
        $finish;
    end
    
endmodule
