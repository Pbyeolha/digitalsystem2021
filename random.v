module random(
    input rst,
    input clk,
    input[19:0] seed,
    output [8:0] rand_num0,
    output [8:0] rand_num1,
    output [8:0] rand_num2,
    output [8:0] rand_num3,
    output [8:0] rand_num4,
    output [8:0] rand_num5

    );
    
reg[19:0] sreg0, sreg1, sreg2, sreg3, sreg4, sreg5; 
wire [1:0] fd_back0, fd_back1, fd_back2, fd_back3, fd_back4, fd_back5;

    assign seed = -1;
    assign fd_back0[0] = sreg0[13] ^ sreg0[2];
    assign fd_back0[1] = sreg0[9] ^ sreg0[3];
    
    assign fd_back1[0] = sreg0[14] ^ sreg0[2];
    assign fd_back1[1] = sreg0[19] ^ sreg0[0];
    
    assign fd_back2[0] = sreg0[17] ^ sreg0[1];
    assign fd_back2[1] = sreg0[18] ^ sreg0[1];
    
    assign fd_back3[0] = sreg0[18] ^ sreg0[8];
    assign fd_back3[1] = sreg0[13] ^ sreg0[3];
    
    assign fd_back4[0] = sreg0[1] ^ sreg0[0];
    assign fd_back4[1] = sreg0[9] ^ sreg0[4];
    
    assign fd_back5[0] = sreg0[18] ^ sreg0[3];
    assign fd_back5[1] = sreg0[11] ^ sreg0[8];

   
    always @ (posedge clk) begin
        if(rst) begin 
            sreg0 <= seed;
            sreg1 <= seed;
            sreg2 <= seed;
            sreg3 <= seed;
            sreg4 <= seed;
            sreg5 <= seed;
        end
        else begin
            sreg0 <= {fd_back0, sreg0[19:2]};
            sreg1 <= {fd_back1, sreg1[19:2]};
            sreg2 <= {fd_back2, sreg2[19:2]};
            sreg3 <= {fd_back3, sreg3[19:2]};
            sreg4 <= {fd_back4, sreg4[19:2]};
            sreg5 <= {fd_back5, sreg5[19:2]};
        end
    end
    
    assign rand_num0 = sreg0[8:0];
    assign rand_num1 = sreg1[10:2];
    assign rand_num2 = sreg2[12:4];
    assign rand_num3 = sreg3[13:5];
    assign rand_num4 = sreg4[17:9];
    assign rand_num5 = sreg5[19:11];

endmodule
