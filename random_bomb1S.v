module random_bomb1S(
    input rst,
    input clk,
    input[19:0] seed,
    output [7:0] rand_num0,
    output [7:0] rand_num1,
    output [7:0] rand_num2
    );
    
reg[19:0] sreg0, sreg1, sreg2; 
wire [1:0] fd_back0, fd_back1, fd_back2;

    assign seed = -1;
    assign fd_back0[0] = sreg0[19] ^ sreg0[1];
    assign fd_back0[1] = sreg0[4] ^ sreg0[13];
    
    assign fd_back1[0] = sreg1[2] ^ sreg1[12];
    assign fd_back1[1] = sreg1[18] ^ sreg1[0];
    
    assign fd_back2[0] = sreg2[15] ^ sreg2[7];
    assign fd_back2[1] = sreg2[16] ^ sreg2[4];
    

    always @ (posedge clk) begin
        if(rst) begin 
            sreg0 <= seed;
            sreg1 <= seed;
            sreg2 <= seed;
        end
        else begin
            sreg0 <= {fd_back0, sreg0[19:2]};
            sreg1 <= {fd_back1, sreg1[19:2]};
            sreg2 <= {fd_back2, sreg2[19:2]};
        end
    end
    
    assign rand_num0 = sreg0[7:0];
    assign rand_num1 = sreg1[19:10];
    assign rand_num2 = sreg2[13:6];

endmodule