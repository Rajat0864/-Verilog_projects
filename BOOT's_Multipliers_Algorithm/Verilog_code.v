`timescale 1ns / 1ps

module Code #(
    parameter N = 4
)(
    input  [N-1:0] Multiplier,
    input  [N-1:0] Multiplicant,
    output reg [2*N-1:0] out
);

reg [N-1:0] Ml;     // Multiplicant
reg [N-1:0] A;      // Accumulator
reg [N:0]   Mr;     // Multiplier + Q-1 (N+1 bits)
integer i;

always @(*) begin
    A  = 0;
    Ml = Multiplicant;
    Mr = {Multiplier, 1'b0};

    for(i = 0; i < N; i = i + 1) begin
        if(Mr[1:0] == 2'b01) begin
            A = A + Ml;
            {A, Mr} = {A[N-1], A, Mr[N:1]};
        end
        else if(Mr[1:0] == 2'b10) begin
            A = A +(~ Ml +1'b1);
            {A, Mr} = {A[N-1], A, Mr[N:1]};
        end
        else begin
        {A, Mr} = {A[N-1], A, Mr[N:1]};
        end
    end

    out = {A, Mr[N:1]};
end

endmodule
