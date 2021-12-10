module random_bomb1S_y(
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
    assign fd_back0[0] = sreg0[19] ^ sreg0[9];
    assign fd_back0[1] = sreg0[9] ^ sreg0[1];
    
    assign fd_back1[0] = sreg1[0] ^ sreg1[4];
    assign fd_back1[1] = sreg1[13] ^ sreg1[1];
    
    assign fd_back2[0] = sreg2[17] ^ sreg2[7];
    assign fd_back2[1] = sreg2[18] ^ sreg2[8];
    

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
    
    assign rand_num0 = sreg0[8:1];
    assign rand_num1 = sreg1[11:4];
    assign rand_num2 = sreg2[15:8];

endmodule