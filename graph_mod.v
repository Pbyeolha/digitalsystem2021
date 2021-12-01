module graph_mod (clk, rst, x, y, key, key_pulse, rgb);

input clk, rst;
input [9:0] x, y;
input [4:0] key, key_pulse; 
output [2:0] rgb; 

// ȭ�� ũ�� ����
parameter MAX_X = 640; 
parameter MAX_Y = 480;  

// gun ��ġ
parameter GUN_Y_B = 470; 
parameter GUN_Y_T = 420;

// gun size, �ӵ�
parameter GUN_X_SIZE = 50; 
parameter GUN_V = 4;

// shot size, �ӵ�
parameter SHOT_SIZE = 6;
parameter SHOT_V = 2;

// obs size, �ӵ�
parameter OBS_X_L = 30;
parameter OBS_X_R = 50;
parameter OBS_SIZE = 20;
parameter OBS_V = 5;

wire refr_tick; 
wire gun_on;
wire [9:0] gun_x_r, gun_x_l; 
reg [9:0] gun_x_reg; 

reg [9:0] shot_x_reg, shot_y_reg;
reg [9:0] shot_vy_reg;
wire [9:0] shot_x_l, shot_x_r, shot_y_t, shot_y_b;
wire shot_on;

wire reach_obs, miss_obs;
reg game_stop, game_over;  

//refrernce tick 
assign refr_tick = (y==MAX_Y-1 && x==MAX_X-1)? 1 : 0; // �� �����Ӹ��� �� clk ���ȸ� 1�� ��. 

/*---------------------------------------------------------*/
// gun�� ��ġ ����
/*---------------------------------------------------------*/
assign gun_x_l = gun_x_reg; //gun�� left
assign gun_x_r = gun_x_l + GUN_X_SIZE - 1; //gun�� right

assign gun_on = (x>=gun_x_l && x<=gun_x_r && y>=GUN_Y_T && y<=GUN_Y_B)? 1 : 0; //gun�� ����

always @ (posedge clk or posedge rst) begin
    if (rst | game_stop) gun_x_reg <= (MAX_X - GUN_X_SIZE)/2; //game�� ���߸� �߰����� ����
    else if (refr_tick) 
        if (key==5'h11 && gun_x_r <= MAX_X -1 - GUN_V) gun_x_reg <= gun_x_reg + GUN_V; //move left
        else if (key==5'h13 && gun_x_l >=GUN_V) gun_x_reg <= gun_x_reg - GUN_V;  //move righ
end

/*---------------------------------------------------------*/
// gun���� �� ������ ��
/*---------------------------------------------------------*/
assign shot_x_l = shot_x_reg;
assign shot_x_r = shot_x_reg + SHOT_SIZE - 1;
assign shot_y_t = shot_y_reg;
assign shot_y_b = shot_y_reg + SHOT_SIZE -1;

assign shot_on = (x>=shot_x_l && x<=shot_x_r && y>=shot_y_t && y<=shot_y_b)? 1 : 0; //shot�� �ִ� ����

always @ (posedge clk or posedge rst) begin
    if(rst|game_stop) begin
        shot_x_reg <= MAX_X/2;
        shot_y_reg <= 420;
    end
    else if(refr_tick) begin
        shot_y_reg <= shot_y_reg + shot_vy_reg;
    end
end

assign reach_obs = (shot_x_r>=OBS_X_L && shot_x_r<=OBS_X_R && shot_y_b>=shot_y_t && shot_y_t<=shot_y_b)? 1 : 0; //shot�� obs�� �ε���
assign miss_obs = (shot_y_t == 0)? 1 : 0; //shot�� ȭ�� ���� ������ shot miss

always @ (posedge clk or posedge rst) begin
    if(rst|game_stop) begin
        shot_vy_reg <= -1*SHOT_V;
    end
    else begin
        if(reach_obs) shot_vy_reg <= -1*SHOT_V;
    end
end

/*---------------------------------------------------------*/
// ���� ��ֹ� ���� ������ score�� 1�� ������Ű�� ���� 
/*---------------------------------------------------------*/
reg d_inc, d_clr;
wire hit, miss;
reg [3:0] dig0, dig1;

assign hit = (reach_obs==1 && refr_tick==1)? 1 : 0; //gun���� ��ֹ� ����, hit�� 1Ŭ�� pulse�� ����� ���� refr_tick�� AND ��Ŵ
assign miss = (miss_obs==1 && refr_tick==1)? 1 : 0; //gun�� ��ֹ� ������, miss�� 1Ŭ�� pulse�� ����� ���� refr_tick�� AND ��Ŵ

always @ (posedge clk or posedge rst) begin
    if(rst | d_clr) begin
        dig1 <= 0;
        dig0 <= 0;
    end else if (hit) begin //��ֹ� ���߸� ������ ����
        if(dig0==9) begin 
            dig0 <= 0;
            if (dig1==9) dig1 <= 0;
            else dig1 <= dig1+1; //���� 10�� �ڸ� 1�� ����
        end else dig0 <= dig0+1; //���� 1�� �ڸ� 1�� ����
    end
end

/*---------------------------------------------------------*/
// finite state machine for game control
/*---------------------------------------------------------*/
parameter NEWGAME=2'b00, PLAY=2'b01, NEWGUN=2'b10, OVER=2'b11; 
reg [1:0] state_reg, state_next;
reg [1:0] life_reg, life_next;
reg [1:0]level_reg, level_next;

always @ (*) begin
    game_stop = 1; 
    d_clr = 0;
    d_inc = 0;
    life_next = life_reg;
    level_next = level_reg;
    game_over = 0;

    case(state_reg) 
        NEWGAME: begin //�� ����
            d_clr = 1; //���ھ� 0���� �ʱ�ȭ
            if(key[4] == 1) begin //��ư�� ������
                state_next = PLAY; //���ӽ���
                life_next = 2'b10; //���� ���� 2����
                level_next = 2'b01; //level 1��
            end else begin
                state_next = NEWGAME; //��ư�� �� ������ ���� ���� ����
                life_next = 2'b11; //���� ���� 3�� ����
                level_next = 2'b00; //level 0���� �ʱ�ȭ
            end
         end
         PLAY: begin
            game_stop = 0; //���� Running
            d_inc = hit;
            if (miss) begin //��ֹ� ��������
                if (life_reg==2'b00) //���� ������ ������
                    state_next = OVER; //��������
                else begin//���� ������ ������ 
                    state_next = NEWGUN; 
                    life_next = life_reg-1'b1; //���� ���� �ϳ� ����
                    level_next = level_reg + 1'b1;
                end
            end else
                state_next = PLAY; //��� ����
        end
        NEWGUN: //�� gun �غ�
            if(key[4] == 1) state_next = PLAY;
            else state_next = NEWGUN; 
        OVER: begin
            if(key[4] == 1) begin //������ ������ �� ��ư�� ������ ������ ����
                state_next = NEWGAME;
            end else begin
                state_next = OVER;
            end
            game_over = 1;
        end 
        default: 
            state_next = NEWGAME;
    endcase
end

always @ (posedge clk or posedge rst) begin
    if(rst) begin
        state_reg <= NEWGAME; 
        life_reg <= 0;
        level_reg <= 0;
    end else begin
        state_reg <= state_next; 
        life_reg <= life_next;
        level_reg <= level_next;
    end
end

/*---------------------------------------------------------*/
// text on screen 
/*---------------------------------------------------------*/

// score region
wire [6:0] char_addr;
reg [6:0] char_addr_s, char_addr_l, char_addr_o, char_addr_lev;
wire [2:0] bit_addr;
reg [2:0] bit_addr_s, bit_addr_l, bit_addr_o, bit_addr_lev;
wire [3:0] row_addr, row_addr_s, row_addr_l, row_addr_o, row_addr_lev; //4bit, �ּ�
wire score_on, life_on, over_on, level_on;

wire font_bit;
wire [7:0] font_word;
wire [10:0] rom_addr;

font_rom_vhd font_rom_inst (clk, rom_addr, font_word);

assign rom_addr = {char_addr, row_addr};
assign font_bit = font_word[~bit_addr]; //ȭ�� x��ǥ�� ������ ������, rom�� bit�� �������� �����Ƿ� reverse

assign char_addr = (score_on)? char_addr_s : (life_on)? char_addr_l : (level_on)? char_addr_lev : (over_on)? char_addr_o : 0;
assign row_addr = (score_on)? row_addr_s : (life_on)? row_addr_l : (level_on)? row_addr_lev : (over_on)? row_addr_o : 0; 
assign bit_addr = (score_on)? bit_addr_s : (life_on)? bit_addr_l : (level_on)? bit_addr_lev : (over_on)? bit_addr_o : 0; 
// score
wire [9:0] score_x_l, score_y_t;
assign score_x_l = 556; 
assign score_y_t = 0; 
assign score_on = (y>=score_y_t && y<score_y_t+16 && x>=score_x_l && x<score_x_l+8*8)? 1 : 0; 
assign row_addr_s = y-score_y_t;
always @ (*) begin
    if (x>=score_x_l+8*0 && x<score_x_l+8*1) begin bit_addr_s = x-score_x_l-8*0; char_addr_s = 7'b1010011; end // S x53    
    else if (x>=score_x_l+8*1 && x<score_x_l+8*2) begin bit_addr_s = x-score_x_l-8*1; char_addr_s = 7'b1000011; end // C x43
    else if (x>=score_x_l+8*2 && x<score_x_l+8*3) begin bit_addr_s = x-score_x_l-8*2; char_addr_s = 7'b1001111; end // O x4f
    else if (x>=score_x_l+8*3 && x<score_x_l+8*4) begin bit_addr_s = x-score_x_l-8*3; char_addr_s = 7'b1010010; end // R x52
    else if (x>=score_x_l+8*4 && x<score_x_l+8*5) begin bit_addr_s = x-score_x_l-8*4; char_addr_s = 7'b1000101; end // E x45
    else if (x>=score_x_l+8*5 && x<score_x_l+8*6) begin bit_addr_s = x-score_x_l-8*5; char_addr_s = 7'b0111010; end // : x3a
    else if (x>=score_x_l+8*6 && x<score_x_l+8*7) begin bit_addr_s = x-score_x_l-8*6; char_addr_s = {3'b011, dig1}; end // digit 10, ASCII �ڵ忡�� ������ address�� 011�� ����
    else if (x>=score_x_l+8*7 && x<score_x_l+8*8) begin bit_addr_s = x-score_x_l-8*7; char_addr_s = {3'b011, dig0}; end
    else begin bit_addr_s = 0; char_addr_s = 0; end                         
end

// life
wire [9:0] life_x_l, life_y_t; 
assign life_x_l = 300; 
assign life_y_t = 0; 
assign life_on = (y>=life_y_t && y<life_y_t+16 && x>=life_x_l && x<life_x_l+8*6)? 1 : 0;
assign row_addr_l = y-life_y_t;
always @(*) begin
    if (x>=life_x_l+8*0 && x<life_x_l+8*1) begin bit_addr_l = (x-life_x_l-8*0); char_addr_l = 7'b1001100; end // L x4c
    else if (x>=life_x_l+8*1 && x<life_x_l+8*2) begin bit_addr_l = (x-life_x_l-8*1); char_addr_l = 7'b1001001; end // I x49
    else if (x>=life_x_l+8*2 && x<life_x_l+8*3) begin bit_addr_l = (x-life_x_l-8*2); char_addr_l = 7'b1000110; end // F x46
    else if (x>=life_x_l+8*3 && x<life_x_l+8*4) begin bit_addr_l = (x-life_x_l-8*3); char_addr_l = 7'b1000101; end // E x45
    else if (x>=life_x_l+8*4 && x<life_x_l+8*5) begin bit_addr_l = (x-life_x_l-8*4); char_addr_l = 7'b0111010; end // : x3a
    else if (x>=life_x_l+8*5 && x<life_x_l+8*6) begin bit_addr_l = (x-life_x_l-8*5); char_addr_l = {5'b01100, life_reg}; end
    else begin bit_addr_l = 0; char_addr_l = 0; end   
end

// level
wire [9:0] level_x_l, level_y_t; 
assign level_x_l = 100; 
assign level_y_t = 0; 
assign level_on = (y>=level_y_t && y<level_y_t+16 && x>=level_x_l && x<level_x_l+8*7)? 1 : 0;
assign row_addr_lev = y-level_y_t;
always @(*) begin
    if (x>=level_x_l+8*0 && x<level_x_l+8*1) begin bit_addr_lev = (x-level_x_l-8*0); char_addr_lev = 7'b1001100; end // L x4c
    else if (x>=level_x_l+8*1 && x<level_x_l+8*2) begin bit_addr_lev = (x-level_x_l-8*1); char_addr_lev = 7'b1000101; end // E x45
    else if (x>=level_x_l+8*2 && x<level_x_l+8*3) begin bit_addr_lev = (x-level_x_l-8*2); char_addr_lev = 7'b1010110; end // V x56
    else if (x>=level_x_l+8*3 && x<level_x_l+8*4) begin bit_addr_lev = (x-level_x_l-8*3); char_addr_lev = 7'b1000101; end // E x45
    else if (x>=level_x_l+8*4 && x<level_x_l+8*5) begin bit_addr_lev = (x-level_x_l-8*4); char_addr_lev = 7'b1001100; end // L x4c
    else if (x>=level_x_l+8*5 && x<level_x_l+8*6) begin bit_addr_lev = (x-level_x_l-8*5); char_addr_lev = 7'b0111010; end // : x3a
    else if (x>=level_x_l+8*6 && x<level_x_l+8*7) begin bit_addr_lev = (x-level_x_l-8*6); char_addr_lev = {5'b01100, level_reg}; end
    else begin bit_addr_lev = 0; char_addr_lev = 0; end   
end

// game over
assign over_on = (game_over==1 && y[9:6]==3 && x[9:5]>=5 && x[9:5]<=13)? 1 : 0; 
assign row_addr_o = y[5:2];
always @(*) begin
    bit_addr_o = x[4:2];
    case (x[9:5]) 
        5: char_addr_o = 7'b1000111; // G x47
        6: char_addr_o = 7'b1100001; // a x61
        7: char_addr_o = 7'b1101101; // m x6d
        8: char_addr_o = 7'b1100101; // e x65
        9: char_addr_o = 7'b0000000; //                      
        10: char_addr_o = 7'b1001111; // O x4f
        11: char_addr_o = 7'b1110110; // v x76
        12: char_addr_o = 7'b1100101; // e x65
        13: char_addr_o = 7'b1110010; // r x72
        default: char_addr_o = 0; 
    endcase
end

/*---------------------------------------------------------*/
// color setting
/*---------------------------------------------------------*/
assign rgb = (font_bit & score_on)? 3'b111 : //black text
             (font_bit & life_on)? 3'b110 : // yellow text  
             (font_bit & level_on)? 3'b110 : // yellow text  
             (font_bit & over_on)? 3'b100 : //red text
             (shot_on) ? 3'b100 : // red shot
             (gun_on)? 3'b111 : //white gun
             3'b000; //black background

endmodule
