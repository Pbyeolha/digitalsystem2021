module graph_mod (clk, rst, x, y, key, key_pulse, rgb);

input clk, rst;
input [9:0] x, y;
input [4:0] key, key_pulse; 
output [2:0] rgb; 

// 화면 크기 설정
parameter MAX_X = 640; 
parameter MAX_Y = 480;  

// gun 위치
parameter GUN_Y_B = 479; 
parameter GUN_Y_T = 429;

// gun size, 속도
parameter GUN_X_SIZE = 50; 
parameter GUN_V = 4;

//장애물 속도, 크기
parameter obs_SIZE = 40;
parameter obs_V = 10;

//장애물 속도, 크기
parameter bomb_SIZE = 40;
parameter bomb_V = 15;

wire refr_tick; 
wire gun_on;
wire [9:0] gun_x_r, gun_x_l; 
reg [9:0] gun_x_reg; 
wire reach_obs, miss_obs;
reg game_stop, game_over;  
reg obs, bomb; //장애물, 폭탄

//refrernce tick 
assign refr_tick = (y==MAX_Y-1 && x==MAX_X-1)? 1 : 0; // 매 프레임마다 한 clk 동안만 1이 됨. 

/*---------------------------------------------------------*/
// gun의 위치 결정
/*---------------------------------------------------------*/
assign gun_x_l = gun_x_reg; //gun의 왼쪽
assign gun_x_r = gun_x_reg + GUN_X_SIZE - 1; //gun의 오른쪽

assign gun_on = (x>=gun_x_l && x<=gun_x_r && y>=GUN_Y_T && GUN_Y_B)? 1 : 0; //gun의 영역

always @ (posedge clk or posedge rst) begin
    if (rst | game_stop) gun_x_reg <= (MAX_X - GUN_X_SIZE)/2; //game이 멈추면 중간에서 시작
    else if (refr_tick) 
        if (key==5'h11 && gun_x_r <= MAX_X -1 - GUN_V) gun_x_reg <= gun_x_reg + GUN_V; //move right
        else if (key==5'h13 && gun_x_l >=GUN_V) gun_x_reg <= gun_x_reg - GUN_V;  //move left
end

/*---------------------------------------------------------*/
// gun에서 총 나가는 거
/*---------------------------------------------------------*/

/*---------------------------------------------------------*/
// 총이 장애물 맞힐 때마다 score를 1씩 증가시키는 로직 
/*---------------------------------------------------------*/
reg d_inc, d_clr;
wire hit, miss;
reg [3:0] dig0, dig1;

assign hit = (reach_obs==1 && refr_tick==1)? 1 : 0; //gun으로 장애물 맞힘, hit를 1클럭 pulse로 만들기 위해 refr_tick과 AND 시킴
assign miss = (miss_obs==1 && refr_tick==1)? 1 : 0; //gun이 장애물에 맞음, miss를 1클럭 pulse로 만들기 위해 refr_tick과 AND 시킴

always @ (posedge clk or posedge rst) begin
    if(rst | d_clr) begin
        dig1 <= 0;
        dig0 <= 0;
    end else if (hit) begin //장애물 맞추면 점수가 증가
        if(dig0==9) begin 
            dig0 <= 0;
            if (dig1==9) dig1 <= 0;
            else dig1 <= dig1+1; //점수 10의 자리 1씩 증가
        end else dig0 <= dig0+1; //점수 1의 자리 1씩 증가
    end
end

/*---------------------------------------------------------*/
// random
/*---------------------------------------------------------*/
reg [19:0] sreg0;
reg [2:0] rand;
wire [1:0] fd_back0;
wire [19:0] seed;
    
assign fd_back0[0] = sreg0[17] ^ sreg0[0] ^ sreg0[9];
assign fd_back0[1] = sreg0[18] ^ sreg0[1] ^ sreg0[10];
    
always @ (posedge clk) begin
    if(rst) sreg0 <= seed;
    else begin 
    sreg0 <= {fd_back0, sreg0[19:2]};
    rand <= sreg0[2:0];
    end
end

/*---------------------------------------------------------*/
// down
/*---------------------------------------------------------*/

/*
reg fall_down;

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop)
        fall_down <= 0;
    else if(fall_down == 1 && obs == 1) begin
        
    end
    else if(fall_down ==1 && bomb ==1  ) begin
    
    end   
end 
*/

/*---------------------------------------------------------*/
// 장애물
/*---------------------------------------------------------*/
wire [9:0] obs_left, obs_right, obs_y_t, obs_y_b; 
reg obs_x_reg, obs_y_reg;

assign obs_left = obs_x_reg; //장애물의 왼쪽
assign obs_right = obs_left + obs_SIZE - 1; //장애물의 오른쪽
assign obs_y_t = obs_y_reg;
assign obs_y_b = obs_y_t + obs_SIZE - 1;

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg <= MAX_X/rand;
        obs <= 0;
    end    
    else if(refr_tick) begin
        obs <= 1;
        //fall_down <= 1;
        obs_y_reg <= obs_y_reg + obs_V;
    end
end

assign reach_obs = (gun_x_l >= obs_left && gun_x_r <= obs_right)? 1:0;
assign miss_obs = (gun_x_l <= obs_left && gun_x_r >= obs_right)? 1:0;

/*---------------------------------------------------------*/
// bomb
/*---------------------------------------------------------*/
wire [9:0] bomb_left, bomb_right, bomb_y_t, bomb_y_b; 
reg bomb_x_reg, bomb_y_reg;

assign bomb_left = bomb_x_reg; //장애물의 왼쪽
assign bomb_right = bomb_left + bomb_SIZE - 1; //장애물의 오른쪽
assign bomb_y_t = bomb_y_reg;
assign bomb_y_b = bomb_y_t + bomb_SIZE - 1;

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        bomb_x_reg <= MAX_X/rand;
        bomb <= 0;
    end    
    else if(refr_tick) begin
        bomb <= 1;
        //fall_down <= 1;
        bomb_y_reg <= bomb_y_reg + bomb_V;
    end
end

/*---------------------------------------------------------*/
// finite state machine for game control
/*---------------------------------------------------------*/
parameter NEWGAME=2'b00, PLAY=2'b01, NEWGUN=2'b10, OVER=2'b11; 
reg [1:0] state_reg, state_next;
reg [1:0] life_reg, life_next;
reg [1:0] level_reg, level_next;

always @ (key, hit, miss, state_reg, life_reg, level_reg) begin
    game_stop = 1; 
    d_clr = 0;
    d_inc = 0;
    life_next = life_reg;
    level_next = level_reg;
    game_over = 0;

    case(state_reg) 
        NEWGAME: begin //새 게임
            d_clr = 1; //스코어 0으로 초기화
            if(key[4] == 1) begin //버튼이 눌리면
                state_next = PLAY; //게임시작
                life_next = 2'b10; //남은 생명 2개로
            end else begin
                state_next = NEWGAME; //버튼이 안 눌리면 현재 상태 유지
                life_next = 2'b11; //남은 생명 3개 유지
            end
         end
         PLAY: begin
            game_stop = 0; //게임 Running
            d_inc = hit;
            if (miss) begin //장애물에 맞으면
                if (life_reg==2'b00) //남은 생명이 없으면
                    state_next = OVER; //게임종료
                else begin//남은 생명이 있으면 
                    state_next = NEWGUN; 
                    life_next = life_reg-1'b1; //남은 생명 하나 줄임
                end
            end else
                state_next = PLAY; //ball 놓치지 않으면 계속 진행
        end
        NEWGUN: //새 gun 준비
            if(key[4] == 1) state_next = PLAY;
            else state_next = NEWGUN; 
        OVER: begin
            if(key[4] == 1) begin //게임이 끝났을 때 버튼을 누르면 새게임 시작
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
wire [3:0] row_addr, row_addr_s, row_addr_l, row_addr_o, row_addr_lev; //4bit, 주소
wire score_on, life_on, over_on, level_on;

wire font_bit;
wire [7:0] font_word;
wire [10:0] rom_addr;

font_rom_vhd font_rom_inst (clk, rom_addr, font_word);

assign rom_addr = {char_addr, row_addr};
assign font_bit = font_word[~bit_addr]; //화면 x좌표는 왼쪽이 작은데, rom의 bit는 오른쪽이 작으므로 reverse

assign char_addr = (score_on)? char_addr_s : (life_on)? char_addr_l : (over_on)? char_addr_o : (level_on)? char_addr_lev : 0;
assign row_addr = (score_on)? row_addr_s : (life_on)? row_addr_l : (over_on)? char_addr_o : (level_on)? char_addr_lev : 0; 
assign bit_addr = (score_on)? bit_addr_s : (life_on)? bit_addr_l : (over_on)? char_addr_o : (level_on)? char_addr_lev : 0; 

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
    else if (x>=score_x_l+8*6 && x<score_x_l+8*7) begin bit_addr_s = x-score_x_l-8*6; char_addr_s = {3'b011, dig1}; end // digit 10, ASCII 코드에서 숫자의 address는 011로 시작
    else if (x>=score_x_l+8*7 && x<score_x_l+8*8) begin bit_addr_s = x-score_x_l-8*7; char_addr_s = {3'b011, dig0}; end
    else begin bit_addr_s = 0; char_addr_s = 0; end                         
end

// life
wire [9:0] life_x_l, life_y_t; 
assign life_x_l = 200; 
assign life_y_t = 0; 
assign life_on = (y>=life_y_t && y<life_y_t+16 && x>=life_x_l && x<life_x_l+8*6)? 1 : 0;
assign row_addr_l = y-life_y_t;
always @(*) begin
    if (x>=life_x_l+8*0 && x<life_x_l+8*1) begin bit_addr_l = (x-life_x_l-8*0); char_addr_l = 7'b1001100; end // L x4c
    else if (x>=life_x_l+8*1 && x<life_x_l+8*2) begin bit_addr_l = (x-life_x_l-8*1); char_addr_l = 7'b1001001; end // I x49
    else if (x>=life_x_l+8*2 && x<life_x_l+8*3) begin bit_addr_l = (x-life_x_l-8*1); char_addr_l = 7'b1000110; end // F x46
    else if (x>=life_x_l+8*3 && x<life_x_l+8*4) begin bit_addr_l = (x-life_x_l-8*1); char_addr_l = 7'b1000101; end // E x45
    else if (x>=life_x_l+8*4 && x<life_x_l+8*5) begin bit_addr_l = (x-life_x_l-8*1); char_addr_l = 7'b0111010; end // : x3a
    else if (x>=life_x_l+8*5 && x<life_x_l+8*6) begin bit_addr_l = (x-life_x_l-8*2); char_addr_l = {5'b01100, life_reg}; end
    else begin bit_addr_l = 0; char_addr_l = 0; end   
end

// level
wire [9:0] level_x_l, level_y_t; 
assign level_x_l = 10; 
assign level_y_t = 0; 
assign level_on = (y>=life_y_t && y<life_y_t+16 && x>=life_x_l && x<life_x_l+8*7)? 1 : 0;
assign row_addr_l = y-level_y_t;
always @(*) begin
    if (x>=life_x_l+8*0 && x<life_x_l+8*1) begin bit_addr_l = (x-life_x_l-8*0); char_addr_l = 7'b1001100; end // L x4c
    else if (x>=life_x_l+8*1 && x<life_x_l+8*2) begin bit_addr_l = (x-life_x_l-8*1); char_addr_l = 7'b1000101; end // E x45
    else if (x>=life_x_l+8*2 && x<life_x_l+8*3) begin bit_addr_l = (x-life_x_l-8*1); char_addr_l = 7'b1010110; end // V x56
    else if (x>=life_x_l+8*3 && x<life_x_l+8*4) begin bit_addr_l = (x-life_x_l-8*1); char_addr_l = 7'b1000101; end // E x45
    else if (x>=life_x_l+8*4 && x<life_x_l+8*5) begin bit_addr_l = (x-life_x_l-8*1); char_addr_l = 7'b1001100; end // L x4c
    else if (x>=life_x_l+8*5 && x<life_x_l+8*6) begin bit_addr_l = (x-life_x_l-8*1); char_addr_l = 7'b0111010; end // : x3a
    else if (x>=life_x_l+8*6 && x<life_x_l+8*7) begin bit_addr_l = (x-life_x_l-8*2); char_addr_l = {5'b01100, level_reg}; end
    else begin bit_addr_l = 0; char_addr_l = 0; end   
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
assign rgb = (font_bit & score_on)? 3'b001 : //blue text
             (font_bit & level_on)? 3'b111 : // black text 
             (font_bit & life_on)? 3'b111 : // black text   
             (font_bit & over_on)? 3'b100 : //red text
             (gun_on)? 3'b111 : //black gun
             3'b110; //yello background

endmodule

