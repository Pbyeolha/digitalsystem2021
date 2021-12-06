module graph_mod (clk, rst, x, y, key, key_pulse, rgb);
input clk, rst;
input [9:0] x, y;
input [4:0] key, key_pulse; 
output [2:0] rgb;

// screen size
parameter MAX_X = 640; 
parameter MAX_Y = 480;  
// gun position
parameter GUN_Y_B = 470; 
parameter GUN_Y_T = 420;
// gun size, velocity
parameter GUN_X_SIZE = 50; 
parameter GUN_V = 4;
// shot size, velocity
parameter SHOT_SIZE = 6;
parameter SHOT_V = 7;
// obs size, velocity
parameter OBS_SIZE = 30;
parameter OBS_V = 2;
//bomb size, velocity
parameter BOMB_SIZE = 40;
parameter BOMB_V = 10;
wire refr_tick; 
wire [9:0] reach_obs, miss_obs;
reg game_stop, game_over;  
reg obs;
//refrernce tick 
assign refr_tick = (y==MAX_Y-1 && x==MAX_X-1)? 1 : 0; // frame, 1sec

/*---------------------------------------------------------*/
// gun 
/*---------------------------------------------------------*/
wire gun_on;
wire [9:0] gun_x_r, gun_x_l; 
reg [9:0] gun_x_reg; 
assign gun_x_l = gun_x_reg; //left
assign gun_x_r = gun_x_l + GUN_X_SIZE - 1; //right
assign gun_on = (x>=gun_x_l && x<=gun_x_r && y>=GUN_Y_T && y<=GUN_Y_B)? 1 : 0; //gun position
always @ (posedge clk or posedge rst) begin
    if (rst | game_stop) gun_x_reg <= (MAX_X - GUN_X_SIZE)/2; //if game stop, game begin middle
    else if (refr_tick) 
        if (key==5'h11 && gun_x_r <= MAX_X -1 - GUN_V) gun_x_reg <= gun_x_reg + GUN_V; //move left
        else if (key==5'h13 && gun_x_l >=GUN_V) gun_x_reg <= gun_x_reg - GUN_V;  //move right
end
/*---------------------------------------------------------*/
// shot
/*---------------------------------------------------------*/
reg [9:0] shot_x_reg, shot_y_reg;
reg [9:0] shot_vy_reg, shot_vx_reg;
wire [9:0] shot_x_l, shot_x_r, shot_y_t, shot_y_b;
wire shot_on; 
assign shot_x_l = shot_x_reg;
assign shot_x_r = shot_x_reg + SHOT_SIZE - 1;
assign shot_y_t = shot_y_reg;
assign shot_y_b = shot_y_reg + SHOT_SIZE -1;
assign shot_on = (x>=shot_x_l && x<=shot_x_r && y>=shot_y_t && y<=shot_y_b)? 1 : 0; //obs regionion

always @ (posedge clk or posedge rst) begin
    if(rst|game_stop) begin
        shot_x_reg <= (gun_x_l + gun_x_r) / 2;
        shot_y_reg <= (GUN_Y_B + GUN_Y_T) / 2;
    end
    else if(refr_tick)begin
        shot_x_reg <= (gun_x_l + gun_x_r) / 2;
        shot_y_reg <= (GUN_Y_B + GUN_Y_T) / 2;
        if(key == 5'h15) begin
           shot_y_reg <= shot_y_reg + shot_vy_reg;
           shot_x_reg <= shot_x_reg + shot_vx_reg;
        end
    end 
end

always @ (posedge clk or posedge rst) begin
    if(rst|game_stop) begin
        shot_vy_reg <= -1*SHOT_V; //up
        shot_vx_reg <= 0;
    end else begin
            if(reach_obs) begin 
                shot_vy_reg <= -1*SHOT_V; //up //fix
                shot_vx_reg <= 0;
            end
            else begin
                shot_vy_reg <= -1*SHOT_V; //up
                shot_vx_reg <= 0;
            end
    end
end
/*---------------------------------------------------------*/
// obs - 1stage
/*---------------------------------------------------------*/
reg [9:0] obs_x_reg [39:0], obs_y_reg [39:0];
reg [9:0] obs1_vy_reg, obs1_vx_reg;
wire [9:0] obs_x_l[39:0], obs_x_r[39:0], obs_y_t[39:0], obs_y_b[39:0];
wire obs_on[39:0];

assign obs_x_l[0] = obs_x_reg[0]; 
assign obs_x_r[0] = obs_x_l[0] + OBS_SIZE - 1; 
assign obs_y_t[0] = obs_y_reg[0]; 
assign obs_y_b[0] = obs_y_t[0] + OBS_SIZE - 1;
assign obs_on[0] = (x>=obs_x_l[0] && x<=obs_x_r[0] && y>=obs_y_t[0] && y<=obs_y_b[0])? 1 : 0; //obs regionion

always @ (posedge clk or posedge rst) begin
   if(rst | game_stop) begin
        obs_x_reg[0] <= 20; 
        obs_y_reg[0] <= 150;
   end 
    else if(refr_tick) begin
         obs_x_reg[0] <= obs_x_reg[0] + obs1_vx_reg; 
         obs_y_reg[0] <= obs_y_reg[0] + obs1_vy_reg;
    end
    else if ((shot_x_l >= obs_x_l[0]) && (shot_x_r <= obs_x_r[0]) && (shot_y_b <= obs_y_b[0])) begin
        obs_x_reg[0] <= 650;
        obs_y_reg[0] <= 0;
    end
end

assign obs_x_l[1] = obs_x_reg[1]; 
assign obs_x_r[1] = obs_x_l[1] + OBS_SIZE - 1; 
assign obs_y_t[1] = obs_y_reg[1]; 
assign obs_y_b[1] = obs_y_t[1] + OBS_SIZE - 1;
assign obs_on[1] = (x>=obs_x_l[1] && x<=obs_x_r[1] && y>=obs_y_t[1] && y<=obs_y_b[1])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[1] <= 84; 
        obs_y_reg[1] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[1] <= obs_x_reg[1] + obs1_vx_reg; 
        obs_y_reg[1] <= obs_y_reg[1] + obs1_vy_reg;
    end
end

assign obs_x_l[2] = obs_x_reg[2]; 
assign obs_x_r[2] = obs_x_l[2] + OBS_SIZE - 1; 
assign obs_y_t[2] = obs_y_reg[2]; 
assign obs_y_b[2] = obs_y_t[2] + OBS_SIZE - 1;
assign obs_on[2] = (x>=obs_x_l[2] && x<=obs_x_r[2] && y>=obs_y_t[2] && y<=obs_y_b[2])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[2] <= 148; 
        obs_y_reg[2] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[2] <= obs_x_reg[2] + obs1_vx_reg; 
        obs_y_reg[2] <= obs_y_reg[2] + obs1_vy_reg;
    end
end

assign obs_x_l[3] = obs_x_reg[3]; 
assign obs_x_r[3] = obs_x_l[3] + OBS_SIZE - 1; 
assign obs_y_t[3] = obs_y_reg[3]; 
assign obs_y_b[3] = obs_y_t[3] + OBS_SIZE - 1;
assign obs_on[3] = (x>=obs_x_l[3] && x<=obs_x_r[3] && y>=obs_y_t[3] && y<=obs_y_b[3])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[3] <= 212; 
        obs_y_reg[3] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[3] <= obs_x_reg[3] + obs1_vx_reg; 
        obs_y_reg[3] <= obs_y_reg[3] + obs1_vy_reg;
    end
end

assign obs_x_l[4] = obs_x_reg[4]; 
assign obs_x_r[4] = obs_x_l[4] + OBS_SIZE - 1; 
assign obs_y_t[4] = obs_y_reg[4]; 
assign obs_y_b[4] = obs_y_t[4] + OBS_SIZE - 1;
assign obs_on[4] = (x>=obs_x_l[4] && x<=obs_x_r[4] && y>=obs_y_t[4] && y<=obs_y_b[4])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[4] <= 276; 
        obs_y_reg[4] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[4] <= obs_x_reg[4] + obs1_vx_reg; 
        obs_y_reg[4] <= obs_y_reg[4] + obs1_vy_reg;
    end
end

assign obs_x_l[5] = obs_x_reg[5]; 
assign obs_x_r[5] = obs_x_l[5] + OBS_SIZE - 1; 
assign obs_y_t[5] = obs_y_reg[5]; 
assign obs_y_b[5] = obs_y_t[5] + OBS_SIZE - 1;
assign obs_on[5] = (x>=obs_x_l[5] && x<=obs_x_r[5] && y>=obs_y_t[5] && y<=obs_y_b[5])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[5] <= 340; 
        obs_y_reg[5] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[5] <= obs_x_reg[5] + obs1_vx_reg; 
        obs_y_reg[5] <= obs_y_reg[5] + obs1_vy_reg;
    end
end

assign obs_x_l[6] = obs_x_reg[6]; 
assign obs_x_r[6] = obs_x_l[6] + OBS_SIZE - 1; 
assign obs_y_t[6] = obs_y_reg[6]; 
assign obs_y_b[6] = obs_y_t[6] + OBS_SIZE - 1;
assign obs_on[6] = (x>=obs_x_l[6] && x<=obs_x_r[6] && y>=obs_y_t[6] && y<=obs_y_b[6])? 1 : 0; //obs regionion
                   
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[6] <= 404; 
        obs_y_reg[6] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[6] <= obs_x_reg[6] + obs1_vx_reg; 
        obs_y_reg[6] <= obs_y_reg[6] + obs1_vy_reg;
    end
end

assign obs_x_l[7] = obs_x_reg[7]; 
assign obs_x_r[7] = obs_x_l[7] + OBS_SIZE - 1; 
assign obs_y_t[7] = obs_y_reg[7]; 
assign obs_y_b[7] = obs_y_t[7] + OBS_SIZE - 1;
assign obs_on[7] = (x>=obs_x_l[7] && x<=obs_x_r[7] && y>=obs_y_t[7] && y<=obs_y_b[7])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[7] <= 468; 
        obs_y_reg[7] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[7] <= obs_x_reg[7] + obs1_vx_reg; 
        obs_y_reg[7] <= obs_y_reg[7] + obs1_vy_reg;
    end
end

assign obs_x_l[8] = obs_x_reg[8]; 
assign obs_x_r[8] = obs_x_l[8] + OBS_SIZE - 1; 
assign obs_y_t[8] = obs_y_reg[8]; 
assign obs_y_b[8] = obs_y_t[8] + OBS_SIZE - 1;
assign obs_on[8] = (x>=obs_x_l[8] && x<=obs_x_r[8] && y>=obs_y_t[8] && y<=obs_y_b[8])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[8] <= 532; 
        obs_y_reg[8] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[8] <= obs_x_reg[8] + obs1_vx_reg; 
        obs_y_reg[8] <= obs_y_reg[8] + obs1_vy_reg;
    end
end

assign obs_x_l[9] = obs_x_reg[9]; 
assign obs_x_r[9] = obs_x_l[9] + OBS_SIZE - 1; 
assign obs_y_t[9] = obs_y_reg[9]; 
assign obs_y_b[9] = obs_y_t[9] + OBS_SIZE - 1;
assign obs_on[9] = (x>=obs_x_l[9] && x<=obs_x_r[9] && y>=obs_y_t[9] && y<=obs_y_b[9])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[9] <= 590; 
        obs_y_reg[9] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[9] <= obs_x_reg[9] + obs1_vx_reg; 
        obs_y_reg[9] <= obs_y_reg[9] + obs1_vy_reg;
    end
end
wire reach_bottom;
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs1_vy_reg <= 0;
        obs1_vx_reg <= 0; //left
    end else if(refr_tick) begin
          if(reach_bottom) begin 
                obs1_vy_reg <= 0; 
                obs1_vx_reg <= 0;
          end
          else begin
            obs1_vy_reg <= 0;
            obs1_vx_reg <= 0; //left
          end
    end
end
/*---------------------------------------------------------*/
// bomb
/*---------------------------------------------------------*/
wire [9:0] bomb_x_l, bomb_x_r, bomb_y_t, bomb_y_b; 
reg bomb_x_reg, bomb_y_reg;
wire bomb_on;
//assign bomb_x_l = bomb_x_reg; // left
//assign bomb_x_r = bomb_x_l + bomb_SIZE - 1; //right
//assign bomb_y_t = bomb_y_reg;
//assign bomb_y_b = bomb_y_t + bomb_SIZE - 1;
//assign bomb_on = (x>=bomb_x_l && x<=bomb_x_r && y>=bomb_y_t && y<=bomb_y_b)? 1 : 0; //bomb region
//always @ (posedge clk or posedge rst) begin
//    if(rst | game_stop) begin
//        bomb_x_reg <= MAX_X - rand;
//        bomb_y_reg <= MAX_Y;
//    end    
//    else if(refr_tick) begin
//        bomb_y_reg <= bomb_y_reg + bomb_V;
//    end
//end

/*---------------------------------------------------------*/
// if hit, score ++
/*---------------------------------------------------------*/
reg d_inc, d_clr;
wire hit, miss;
reg [3:0] dig0, dig1;
assign reach_obs = (shot_y_t <= obs_y_b[0])? 1 : 0; //hit obs
assign miss_obs = (obs_y_b[0] == 479)? 1 : 0; //shot reach screen, miss
assign hit = (reach_obs==1 && refr_tick == 1)? 1 : 0; //hit
assign miss = (miss_obs==1 && refr_tick==1)? 1 : 0; // miss

always @ (posedge clk or posedge rst) begin
    if(rst | d_clr) begin
        dig1 <= 0;
        dig0 <= 0;
    end else if (hit) begin //hit, score ++
        if(dig0==9) begin 
            dig0 <= 0;
            if (dig1==9) dig1 <= 0;
            else dig1 <= dig1+1; //10
        end else dig0 <= dig0+1; //1
    end
end
/*---------------------------------------------------------*/
// finite state machine for game control
/*---------------------------------------------------------*/
parameter NEWGAME=3'b00, PLAY=3'b01, NEWGUN=3'b10, OVER=3'b11;
reg [2:0] state_reg, state_next;
reg [1:0] life_reg, life_next;
reg [1:0] stage_reg, stage_next;
always @ (*) begin
    game_stop = 1; 
    d_clr = 0;
    d_inc = 0;
    life_next = life_reg;
    stage_next = stage_reg;
    game_over = 0;
    case(state_reg) 
        NEWGAME: begin //new game
            d_clr = 1; //score init
            if(key[4] == 1) begin //if key push,
                state_next = PLAY; //game start
                life_next = 2'b10; //left life 2
                stage_next = 2'b01; //level up
            end else begin
                state_next = NEWGAME; //no key push,
                life_next = 2'b11; //left life 3
                stage_next = 2'b00; //level init
            end
         end
         PLAY: begin
            game_stop = 0; //game running
            d_inc = hit;
            if (miss) begin //miss obs
                if (life_reg==2'b00) //no left life
                    state_next = OVER; //gameover
                else begin//yes left life
                    state_next = NEWGUN; //new gun
                    life_next = life_reg-1'b1; //- life
                    stage_next = stage_reg + 1'b1;
                end
            end else if(hit)
                state_next = PLAY; 
        end
        NEWGUN: //new gun
            if(key[4] == 1) state_next = PLAY;
            else state_next = NEWGUN; 
        OVER: begin
            if(key[4] == 1) begin //key push, ne game
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
        stage_reg <= 0;
    end else begin
        state_reg <= state_next; 
        life_reg <= life_next;
        stage_reg <= stage_next;
    end
end
/*---------------------------------------------------------*/
// text on screen 
/*---------------------------------------------------------*/
// score region
wire [6:0] char_addr;
reg [6:0] char_addr_s, char_addr_l, char_addr_o, char_addr_stage;
wire [2:0] bit_addr;
reg [2:0] bit_addr_s, bit_addr_l, bit_addr_o, bit_addr_stage;
wire [3:0] row_addr, row_addr_s, row_addr_l, row_addr_o, row_addr_stage; //4bit, ???
wire score_on, life_on, over_on, stage_on;
wire font_bit;
wire [7:0] font_word;
wire [10:0] rom_addr;
font_rom_vhd font_rom_inst (clk, rom_addr, font_word);
assign rom_addr = {char_addr, row_addr};
assign font_bit = font_word[~bit_addr]; 
assign char_addr = (score_on)? char_addr_s : (life_on)? char_addr_l : (stage_on)? char_addr_stage : (over_on)? char_addr_o : 0;
assign row_addr = (score_on)? row_addr_s : (life_on)? row_addr_l : (stage_on)? row_addr_stage : (over_on)? row_addr_o : 0; 
assign bit_addr = (score_on)? bit_addr_s : (life_on)? bit_addr_l : (stage_on)? bit_addr_stage : (over_on)? bit_addr_o : 0; 
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
    else if (x>=score_x_l+8*6 && x<score_x_l+8*7) begin bit_addr_s = x-score_x_l-8*6; char_addr_s = {3'b011, dig1}; end // digit 10, ASCII ????? ?????? address?? 011?? ????
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
// stage
wire [9:0] stage_x_l, stage_y_t; 
assign stage_x_l = 100; 
assign stage_y_t = 0; 
assign stage_on = (y>=stage_y_t && y<stage_y_t+16 && x>=stage_x_l && x<stage_x_l+8*7)? 1 : 0;
assign row_addr_stage = y-stage_y_t;
always @(*) begin
    if (x>=stage_x_l+8*0 && x<stage_x_l+8*1) begin bit_addr_stage = (x-stage_x_l-8*0); char_addr_stage = 7'b1010011; end // S x53
    else if (x>=stage_x_l+8*1 && x<stage_x_l+8*2) begin bit_addr_stage = (x-stage_x_l-8*1); char_addr_stage = 7'b1010100; end // T x54
    else if (x>=stage_x_l+8*2 && x<stage_x_l+8*3) begin bit_addr_stage = (x-stage_x_l-8*2); char_addr_stage = 7'b1000001; end // A x41
    else if (x>=stage_x_l+8*3 && x<stage_x_l+8*4) begin bit_addr_stage = (x-stage_x_l-8*3); char_addr_stage = 7'b1000111; end // G x47
    else if (x>=stage_x_l+8*4 && x<stage_x_l+8*5) begin bit_addr_stage = (x-stage_x_l-8*4); char_addr_stage = 7'b1000101; end // E x45
    else if (x>=stage_x_l+8*5 && x<stage_x_l+8*6) begin bit_addr_stage = (x-stage_x_l-8*5); char_addr_stage = 7'b0111010; end // : x3a
    else if (x>=stage_x_l+8*6 && x<stage_x_l+8*7) begin bit_addr_stage = (x-stage_x_l-8*6); char_addr_stage = {5'b01100, stage_reg}; end
    else begin bit_addr_stage = 0; char_addr_stage = 0; end   
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
             (font_bit & stage_on)? 3'b110 : // yellow text  
             (font_bit & over_on)? 3'b100 : //red text
             (shot_on) ? 3'b100 : // red shot
             (gun_on)? 3'b111 : //white gun
             (bomb_on)? 3'b100 : // red bomb
             (obs_on[0]) ? 3'b001 : //blue obs
             (obs_on[1]) ? 3'b001 :
             (obs_on[2]) ? 3'b001 :
             (obs_on[3]) ? 3'b001 :
             (obs_on[4]) ? 3'b001 :
             (obs_on[5]) ? 3'b001 :
             (obs_on[6]) ? 3'b001 :
             (obs_on[7]) ? 3'b001 :
             (obs_on[8]) ? 3'b001 :
             (obs_on[9]) ? 3'b001 :
             3'b000; //black background
endmodule