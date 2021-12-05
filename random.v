module random(
    input rst,
    input clk,
    output [9:0] rnd
    );
    reg [9:0] r_reg;
    wire [9:0] r_next;
    wire fdback;
    
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            r_reg[0] <= 1;
            r_reg[9:1] <= 0;
        end
        else r_reg <= r_next;
    end
    assign fdback = r_reg[9] ^ r_reg[5] ^ r_reg[0];
    assign r_next = {fdback, r_reg[9:1]};
    assign rnd = r_reg;
        
endmodule
