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
parameter OBS_SIZE = 40;
parameter OBS_V = 10;

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

parameter BOMB_SIZE = 40;
parameter BOMB_V = 10;

wire [1:0]reach_wall;
wire reach_top;
wire reach_bottom;

//refrernce tick 
assign refr_tick = (y==MAX_Y-1 && x==MAX_X-1)? 1 : 0; // frame, 1sec

/*---------------------------------------------------------*/
// gun 
/*---------------------------------------------------------*/

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
reg [9:0] obs3_xl,obs3_xr,obs4_xl,obs4_xr,obs4_y_t,obs4_y_b,obs1_vy_reg, obs1_vx_reg , obs2_vx_reg ,obs2_vy_reg, obs3_vy_reg, obs3_vx_reg, obs4_vy_reg, obs4_vx_reg;
wire [9:0] obs_x_l[39:0], obs_x_r[39:0], obs_y_t[39:0], obs_y_b[39:0];
wire obs_on0[14:0], obs_on1[14:0], obs_on2[14:0], obs_on3[14:0], obs_on4[14:0], obs_on5[14:0]; //1stage
reg obs_hit[5:0]; //1stage clear


assign obs_x_l[0] = obs_x_reg[0]; 
assign obs_x_r[0] = obs_x_l[0] + OBS_SIZE - 1; 
assign obs_y_t[0] = obs_y_reg[0]; 
assign obs_y_b[0] = obs_y_t[0] + OBS_SIZE - 1;

//color
assign obs_on0[0] = (x>= ( 8 + obs_x_l[0]) && x <= (obs_x_r[0] - 19 )&& y>=obs_y_t[0] && y  <= (obs_y_b[0] - 23))? 1 : 0;
assign obs_on0[1] = (x>= ( 19 + obs_x_l[0]) && x <= (obs_x_r[0] - 8 )&& y>=obs_y_t[0] && y  <= (obs_y_b[0] - 23))? 1 : 0;
assign obs_on0[2] = (x>= ( obs_x_l[0]) && x <= (obs_x_r[0] -22)&& y>= ( 6 + obs_y_t[0]) && y  <= (obs_y_b[0] - 16))? 1 : 0;
assign obs_on0[3] = (x>= ( 7 + obs_x_l[0]) && x <= (obs_x_r[0] - 18 )&& y>= ( 6 + obs_y_t[0]) && y  <= (obs_y_b[0] - 20))? 1 : 0;
assign obs_on0[4] = (x>= ( 11 + obs_x_l[0]) && x <= (obs_x_r[0] - 11 )&& y>=( 6 + obs_y_t[0]) && y  <= (obs_y_b[0] - 16))? 1 : 0;
assign obs_on0[5] = (x>= ( 18 + obs_x_l[0]) && x <= (obs_x_r[0] - 7 )&&  y>= ( 6 + obs_y_t[0]) && y  <= (obs_y_b[0] - 20))? 1 : 0;
assign obs_on0[6] = (x>= ( obs_x_l[0] + 22 ) && x <= (obs_x_r[0])&& y>= ( 6 + obs_y_t[0]) && y  <= (obs_y_b[0] - 16))? 1 : 0;
assign obs_on0[7] = (x>= (  obs_x_l[0]) && x <= (obs_x_r[0] - 22 )&& y>= ( 13+ obs_y_t[0]) && y  <= (obs_y_b[0] - 3))? 1 : 0;
assign obs_on0[8] = (x>= ( 7 + obs_x_l[0]) && x <= (obs_x_r[0] - 7 )&& y>= (13 + obs_y_t[0] ) && y  <= (obs_y_b[0] - 11))? 1 : 0;
assign obs_on0[9] = (x>= (22 +  obs_x_l[0]) && x <= (obs_x_r[0])&& y>= ( 13+ obs_y_t[0]) && y  <= (obs_y_b[0] - 3))? 1 : 0;
assign obs_on0[10] = (x>= ( 7+ obs_x_l[0]) && x <= (obs_x_r[0] - 20 )&& y>= ( 18 + obs_y_t[0]) && y  <= (obs_y_b[0] - 8))? 1 : 0;
assign obs_on0[11] = (x>= ( 20 + obs_x_l[0]) && x <= (obs_x_r[0] - 7 )&& y>=( 18 + obs_y_t[0]) && y  <= (obs_y_b[0] - 8))? 1 : 0;
assign obs_on0[12] = (x>= ( 7 + obs_x_l[0]) && x <= (obs_x_r[0] - 7 )&& y>= (21 + obs_y_t[0] ) && y  <= (obs_y_b[0] - 3))? 1 : 0;
assign obs_on0[13] = (x>= ( 6 + obs_x_l[0]) && x <= (obs_x_r[0] - 19 )&& y>= ( 26 + obs_y_t[0] )&& y  <= (obs_y_b[0]))? 1 : 0;
assign obs_on0[14] = (x>= ( 19 + obs_x_l[0]) && x <= (obs_x_r[0] - 6 )&& y>=( 26 + obs_y_t[0] )&& y  <= (obs_y_b[0]))? 1 : 0;

always @ (posedge clk or posedge rst) begin
   if(rst | game_stop) begin
        obs_x_reg[0] <= rand0 + 30; 
        obs_y_reg[0] <= rand10 + 30;
   end 
    else if(refr_tick) begin
         obs_x_reg[0] <= obs_x_reg[0] + obs1_vx_reg; 
         obs_y_reg[0] <= obs_y_reg[0] + obs1_vy_reg;
    end
    else if ((shot_x_l >= obs_x_l[0]) && (shot_x_r <= obs_x_r[0]) && (shot_y_b <= obs_y_b[0])) begin
        obs_x_reg[0] <= 650;
        obs_y_reg[0] <= 0;
        obs_hit[0] = 1;
    end
end
//--------------------------------------------------------------------------------------------------------------------------------//
assign obs_x_l[1] = obs_x_reg[1]; 
assign obs_x_r[1] = obs_x_l[1] + OBS_SIZE - 1; 
assign obs_y_t[1] = obs_y_reg[1]; 
assign obs_y_b[1] = obs_y_t[1] + OBS_SIZE - 1;

//color
assign obs_on1[0] = (x>= ( 8 + obs_x_l[1]) && x <= (obs_x_r[1] - 19 )&& y>=obs_y_t[1] && y  <= (obs_y_b[1] - 23))? 1 : 0;
assign obs_on1[1] = (x>= ( 19 + obs_x_l[1]) && x <= (obs_x_r[1] - 8 )&& y>=obs_y_t[1] && y  <= (obs_y_b[1] - 23))? 1 : 0;
assign obs_on1[2] = (x>= ( obs_x_l[1]) && x <= (obs_x_r[1] -22)&& y>= ( 6 + obs_y_t[1]) && y  <= (obs_y_b[1] - 16))? 1 : 0;
assign obs_on1[3] = (x>= ( 7 + obs_x_l[1]) && x <= (obs_x_r[1] - 18 )&& y>= ( 6 + obs_y_t[1]) && y  <= (obs_y_b[1] - 20))? 1 : 0;
assign obs_on1[4] = (x>= ( 11 + obs_x_l[1]) && x <= (obs_x_r[1] - 11 )&& y>=( 6 + obs_y_t[1]) && y  <= (obs_y_b[1] - 16))? 1 : 0;
assign obs_on1[5] = (x>= ( 18 + obs_x_l[1]) && x <= (obs_x_r[1] - 7 )&&  y>= ( 6 + obs_y_t[1]) && y  <= (obs_y_b[1] - 20))? 1 : 0;
assign obs_on1[6] = (x>= ( obs_x_l[1] + 22 ) && x <= (obs_x_r[1])&& y>= ( 6 + obs_y_t[1]) && y  <= (obs_y_b[1] - 16))? 1 : 0;
assign obs_on1[7] = (x>= (  obs_x_l[1]) && x <= (obs_x_r[1] - 22 )&& y>= ( 13+ obs_y_t[1]) && y  <= (obs_y_b[1] - 3))? 1 : 0;
assign obs_on1[8] = (x>= ( 7 + obs_x_l[1]) && x <= (obs_x_r[1] - 7 )&& y>= (13 + obs_y_t[1] ) && y  <= (obs_y_b[1] - 11))? 1 : 0;
assign obs_on1[9] = (x>= (22 +  obs_x_l[1]) && x <= (obs_x_r[1])&& y>= ( 13+ obs_y_t[1]) && y  <= (obs_y_b[1] - 3))? 1 : 0;
assign obs_on1[10] = (x>= ( 7+ obs_x_l[1]) && x <= (obs_x_r[1] - 20 )&& y>= ( 18 + obs_y_t[1]) && y  <= (obs_y_b[1] - 8))? 1 : 0;
assign obs_on1[11] = (x>= ( 20 + obs_x_l[1]) && x <= (obs_x_r[1] - 7 )&& y>=( 18 + obs_y_t[1]) && y  <= (obs_y_b[1] - 8))? 1 : 0;
assign obs_on1[12] = (x>= ( 7 + obs_x_l[1]) && x <= (obs_x_r[1] - 7 )&& y>= (21 + obs_y_t[1] ) && y  <= (obs_y_b[1] - 3))? 1 : 0;
assign obs_on1[13] = (x>= ( 6 + obs_x_l[1]) && x <= (obs_x_r[1] - 19 )&& y>= ( 26 + obs_y_t[1] )&& y  <= (obs_y_b[1]))? 1 : 0;
assign obs_on1[14] = (x>= ( 19 + obs_x_l[1]) && x <= (obs_x_r[1] - 6 )&& y>=( 26 + obs_y_t[1] )&& y  <= (obs_y_b[1]))? 1 : 0;

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[1] <= rand1+ 30; 
        obs_y_reg[1] <= rand11+ 30; 
    end    
    else if (refr_tick) begin
        obs_x_reg[1] <= obs_x_reg[1] + obs1_vx_reg; 
        obs_y_reg[1] <= obs_y_reg[1] + obs1_vy_reg;
    end
     else if ((shot_x_l >= obs_x_l[1]) && (shot_x_r <= obs_x_r[1]) && (shot_y_b <= obs_y_b[1])) begin
           obs_x_reg[1] <= 650;
           obs_y_reg[1] <= 0;
           obs_hit[1] = 1;
       end
end
//--------------------------------------------------------------------------------------------------------------------------------//
assign obs_x_l[2] = obs_x_reg[2]; 
assign obs_x_r[2] = obs_x_l[2] + OBS_SIZE - 1; 
assign obs_y_t[2] = obs_y_reg[2]; 
assign obs_y_b[2] = obs_y_t[2] + OBS_SIZE - 1;

//color
assign obs_on2[0] = (x>= ( 8 + obs_x_l[2]) && x <= (obs_x_r[2] - 19 )&& y>=obs_y_t[2] && y  <= (obs_y_b[2] - 23))? 1 : 0;
assign obs_on2[1] = (x>= ( 19 + obs_x_l[2]) && x <= (obs_x_r[2] - 8 )&& y>=obs_y_t[2] && y  <= (obs_y_b[2] - 23))? 1 : 0;
assign obs_on2[2] = (x>= ( obs_x_l[2]) && x <= (obs_x_r[2] -22)&& y>= ( 6 + obs_y_t[2]) && y  <= (obs_y_b[2] - 16))? 1 : 0;
assign obs_on2[3] = (x>= ( 7 + obs_x_l[2]) && x <= (obs_x_r[2] - 18 )&& y>= ( 6 + obs_y_t[5]) && y  <= (obs_y_b[2] - 20))? 1 : 0;
assign obs_on2[4] = (x>= ( 11 + obs_x_l[2]) && x <= (obs_x_r[2] - 11 )&& y>=( 6 + obs_y_t[2]) && y  <= (obs_y_b[2] - 16))? 1 : 0;
assign obs_on2[5] = (x>= ( 18 + obs_x_l[2]) && x <= (obs_x_r[2] - 7 )&&  y>= ( 6 + obs_y_t[2]) && y  <= (obs_y_b[2] - 20))? 1 : 0;
assign obs_on2[6] = (x>= ( obs_x_l[2] + 22 ) && x <= (obs_x_r[2])&& y>= ( 6 + obs_y_t[2]) && y  <= (obs_y_b[2] - 16))? 1 : 0;
assign obs_on2[7] = (x>= (  obs_x_l[2]) && x <= (obs_x_r[2] - 22 )&& y>= ( 13+ obs_y_t[2]) && y  <= (obs_y_b[2] - 3))? 1 : 0;
assign obs_on2[8] = (x>= ( 7 + obs_x_l[2]) && x <= (obs_x_r[2] - 7 )&& y>= (13 + obs_y_t[2] ) && y  <= (obs_y_b[2] - 11))? 1 : 0;
assign obs_on2[9] = (x>= (22 +  obs_x_l[2]) && x <= (obs_x_r[2])&& y>= ( 13+ obs_y_t[2]) && y  <= (obs_y_b[2] - 3))? 1 : 0;
assign obs_on2[10] = (x>= ( 7+ obs_x_l[2]) && x <= (obs_x_r[2] - 20 )&& y>= ( 18 + obs_y_t[2]) && y  <= (obs_y_b[2] - 8))? 1 : 0;
assign obs_on2[11] = (x>= ( 20 + obs_x_l[2]) && x <= (obs_x_r[2] - 7 )&& y>=( 18 + obs_y_t[2]) && y  <= (obs_y_b[2] - 8))? 1 : 0;
assign obs_on2[12] = (x>= ( 7 + obs_x_l[2]) && x <= (obs_x_r[2] - 7 )&& y>= (21 + obs_y_t[2] ) && y  <= (obs_y_b[2] - 3))? 1 : 0;
assign obs_on2[13] = (x>= ( 6 + obs_x_l[2]) && x <= (obs_x_r[2] - 19 )&& y>= ( 26 + obs_y_t[2] )&& y  <= (obs_y_b[2]))? 1 : 0;
assign obs_on2[14] = (x>= ( 19 + obs_x_l[2]) && x <= (obs_x_r[2] - 6 )&& y>=( 26 + obs_y_t[2] )&& y  <= (obs_y_b[2]))? 1 : 0;

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[2] <= rand2+ 30; 
        obs_y_reg[2] <= rand12+ 30; 
    end    
    else if (refr_tick) begin
        obs_x_reg[2] <= obs_x_reg[2] + obs1_vx_reg; 
        obs_y_reg[2] <= obs_y_reg[2] + obs1_vy_reg;
    end
     else if ((shot_x_l >= obs_x_l[2]) && (shot_x_r <= obs_x_r[2]) && (shot_y_b <= obs_y_b[2])) begin
           obs_x_reg[2] <= 650;
           obs_y_reg[2] <= 0;
           obs_hit[2] = 1;
       end
end
//--------------------------------------------------------------------------------------------------------------------------------//
assign obs_x_l[3] = obs_x_reg[3]; 
assign obs_x_r[3] = obs_x_l[3] + OBS_SIZE - 1; 
assign obs_y_t[3] = obs_y_reg[3]; 
assign obs_y_b[3] = obs_y_t[3] + OBS_SIZE - 1;

//color
assign obs_on3[0] = (x>= ( 8 + obs_x_l[3]) && x <= (obs_x_r[3] - 19 )&& y>=obs_y_t[3] && y  <= (obs_y_b[3] - 23))? 1 : 0;
assign obs_on3[1] = (x>= ( 19 + obs_x_l[3]) && x <= (obs_x_r[3] - 8 )&& y>=obs_y_t[3] && y  <= (obs_y_b[3] - 23))? 1 : 0;
assign obs_on3[2] = (x>= ( obs_x_l[3]) && x <= (obs_x_r[3] -22)&& y>= ( 6 + obs_y_t[3]) && y  <= (obs_y_b[3] - 16))? 1 : 0;
assign obs_on3[3] = (x>= ( 7 + obs_x_l[3]) && x <= (obs_x_r[3] - 18 )&& y>= ( 6 + obs_y_t[3]) && y  <= (obs_y_b[3] - 20))? 1 : 0;
assign obs_on3[4] = (x>= ( 11 + obs_x_l[3]) && x <= (obs_x_r[3] - 11 )&& y>=( 6 + obs_y_t[3]) && y  <= (obs_y_b[3] - 16))? 1 : 0;
assign obs_on3[5] = (x>= ( 18 + obs_x_l[3]) && x <= (obs_x_r[3] - 7 )&&  y>= ( 6 + obs_y_t[3]) && y  <= (obs_y_b[3] - 20))? 1 : 0;
assign obs_on3[6] = (x>= ( obs_x_l[3] + 22 ) && x <= (obs_x_r[3])&& y>= ( 6 + obs_y_t[3]) && y  <= (obs_y_b[3] - 16))? 1 : 0;
assign obs_on3[7] = (x>= (  obs_x_l[3]) && x <= (obs_x_r[3] - 22 )&& y>= ( 13+ obs_y_t[3]) && y  <= (obs_y_b[3] - 3))? 1 : 0;
assign obs_on3[8] = (x>= ( 7 + obs_x_l[3]) && x <= (obs_x_r[3] - 7 )&& y>= (13 + obs_y_t[3] ) && y  <= (obs_y_b[3] - 11))? 1 : 0;
assign obs_on3[9] = (x>= (22 +  obs_x_l[3]) && x <= (obs_x_r[3])&& y>= ( 13+ obs_y_t[3]) && y  <= (obs_y_b[3] - 3))? 1 : 0;
assign obs_on3[10] = (x>= ( 7+ obs_x_l[3]) && x <= (obs_x_r[3] - 20 )&& y>= ( 18 + obs_y_t[3]) && y  <= (obs_y_b[3] - 8))? 1 : 0;
assign obs_on3[11] = (x>= ( 20 + obs_x_l[3]) && x <= (obs_x_r[3] - 7 )&& y>=( 18 + obs_y_t[3]) && y  <= (obs_y_b[3] - 8))? 1 : 0;
assign obs_on3[12] = (x>= ( 7 + obs_x_l[3]) && x <= (obs_x_r[3] - 7 )&& y>= (21 + obs_y_t[3] ) && y  <= (obs_y_b[3] - 3))? 1 : 0;
assign obs_on3[13] = (x>= ( 6 + obs_x_l[3]) && x <= (obs_x_r[3] - 19 )&& y>= ( 26 + obs_y_t[3] )&& y  <= (obs_y_b[3]))? 1 : 0;
assign obs_on3[14] = (x>= ( 19 + obs_x_l[3]) && x <= (obs_x_r[3] - 6 )&& y>=( 26 + obs_y_t[3] )&& y  <= (obs_y_b[3]))? 1 : 0;

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[3] <= rand3+ 30; 
        obs_y_reg[3] <= rand13+ 30; 
    end    
    else if (refr_tick) begin
        obs_x_reg[3] <= obs_x_reg[3] + obs1_vx_reg; 
        obs_y_reg[3] <= obs_y_reg[3] + obs1_vy_reg;
    end
     else if ((shot_x_l >= obs_x_l[3]) && (shot_x_r <= obs_x_r[3]) && (shot_y_b <= obs_y_b[3])) begin
           obs_x_reg[3] <= 650;
           obs_y_reg[3] <= 0;
           obs_hit[3] = 1;
       end
end
//--------------------------------------------------------------------------------------------------------------------------------//
assign obs_x_l[4] = obs_x_reg[4]; 
assign obs_x_r[4] = obs_x_l[4] + OBS_SIZE - 1; 
assign obs_y_t[4] = obs_y_reg[4]; 
assign obs_y_b[4] = obs_y_t[4] + OBS_SIZE - 1;

//color
assign obs_on4[0] = (x>= ( 8 + obs_x_l[4]) && x <= (obs_x_r[4] - 19 )&& y>=obs_y_t[4] && y  <= (obs_y_b[4] - 23))? 1 : 0;
assign obs_on4[1] = (x>= ( 19 + obs_x_l[4]) && x <= (obs_x_r[4] - 8 )&& y>=obs_y_t[4] && y  <= (obs_y_b[4] - 23))? 1 : 0;
assign obs_on4[2] = (x>= ( obs_x_l[4]) && x <= (obs_x_r[4] -22)&& y>= ( 6 + obs_y_t[4]) && y  <= (obs_y_b[4] - 16))? 1 : 0;
assign obs_on4[3] = (x>= ( 7 + obs_x_l[4]) && x <= (obs_x_r[4] - 18 )&& y>= ( 6 + obs_y_t[4]) && y  <= (obs_y_b[4] - 20))? 1 : 0;
assign obs_on4[4] = (x>= ( 11 + obs_x_l[4]) && x <= (obs_x_r[4] - 11 )&& y>=( 6 + obs_y_t[4]) && y  <= (obs_y_b[4] - 16))? 1 : 0;
assign obs_on4[5] = (x>= ( 18 + obs_x_l[4]) && x <= (obs_x_r[4] - 7 )&&  y>= ( 6 + obs_y_t[4]) && y  <= (obs_y_b[4] - 20))? 1 : 0;
assign obs_on4[6] = (x>= ( obs_x_l[4] + 22 ) && x <= (obs_x_r[4])&& y>= ( 6 + obs_y_t[4]) && y  <= (obs_y_b[4] - 16))? 1 : 0;
assign obs_on4[7] = (x>= (  obs_x_l[4]) && x <= (obs_x_r[4] - 22 )&& y>= ( 13+ obs_y_t[4]) && y  <= (obs_y_b[4] - 3))? 1 : 0;
assign obs_on4[8] = (x>= ( 7 + obs_x_l[4]) && x <= (obs_x_r[4] - 7 )&& y>= (13 + obs_y_t[4] ) && y  <= (obs_y_b[4] - 11))? 1 : 0;
assign obs_on4[9] = (x>= (22 +  obs_x_l[4]) && x <= (obs_x_r[4])&& y>= ( 13+ obs_y_t[4]) && y  <= (obs_y_b[4] - 3))? 1 : 0;
assign obs_on4[10] = (x>= ( 7+ obs_x_l[4]) && x <= (obs_x_r[4] - 20 )&& y>= ( 18 + obs_y_t[4]) && y  <= (obs_y_b[4] - 8))? 1 : 0;
assign obs_on4[11] = (x>= ( 20 + obs_x_l[4]) && x <= (obs_x_r[4] - 7 )&& y>=( 18 + obs_y_t[4]) && y  <= (obs_y_b[4] - 8))? 1 : 0;
assign obs_on4[12] = (x>= ( 7 + obs_x_l[4]) && x <= (obs_x_r[4] - 7 )&& y>= (21 + obs_y_t[4] ) && y  <= (obs_y_b[4] - 3))? 1 : 0;
assign obs_on4[13] = (x>= ( 6 + obs_x_l[4]) && x <= (obs_x_r[4] - 19 )&& y>= ( 26 + obs_y_t[4] )&& y  <= (obs_y_b[4]))? 1 : 0;
assign obs_on4[14] = (x>= ( 19 + obs_x_l[4]) && x <= (obs_x_r[4] - 6 )&& y>=( 26 + obs_y_t[4] )&& y  <= (obs_y_b[4]))? 1 : 0;

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[4] <= rand4+ 30; 
        obs_y_reg[4] <= rand14+ 30; 
    end    
    else if (refr_tick) begin
        obs_x_reg[4] <= obs_x_reg[4] + obs1_vx_reg; 
        obs_y_reg[4] <= obs_y_reg[4] + obs1_vy_reg;
    end
     else if ((shot_x_l >= obs_x_l[4]) && (shot_x_r <= obs_x_r[4]) && (shot_y_b <= obs_y_b[4])) begin
           obs_x_reg[4] <= 650;
           obs_y_reg[4] <= 0;
           obs_hit[4] = 1;
       end
end
//--------------------------------------------------------------------------------------------------------------------------------//
assign obs_x_l[5] = obs_x_reg[5]; 
assign obs_x_r[5] = obs_x_l[5] + OBS_SIZE - 1; 
assign obs_y_t[5] = obs_y_reg[5]; 
assign obs_y_b[5] = obs_y_t[5] + OBS_SIZE - 1;

//color
assign obs_on5[0] = (x>= ( 8 + obs_x_l[5]) && x <= (obs_x_r[5] - 19 )&& y>=obs_y_t[5] && y  <= (obs_y_b[5] - 23))? 1 : 0;
assign obs_on5[1] = (x>= ( 19 + obs_x_l[5]) && x <= (obs_x_r[5] - 8 )&& y>=obs_y_t[5] && y  <= (obs_y_b[5] - 23))? 1 : 0;
assign obs_on5[2] = (x>= ( obs_x_l[5]) && x <= (obs_x_r[5] -22)&& y>= ( 6 + obs_y_t[5]) && y  <= (obs_y_b[5] - 16))? 1 : 0;
assign obs_on5[3] = (x>= ( 7 + obs_x_l[5]) && x <= (obs_x_r[5] - 18 )&& y>= ( 6 + obs_y_t[5]) && y  <= (obs_y_b[5] - 20))? 1 : 0;
assign obs_on5[4] = (x>= ( 11 + obs_x_l[5]) && x <= (obs_x_r[5] - 11 )&& y>=( 6 + obs_y_t[5]) && y  <= (obs_y_b[5] - 16))? 1 : 0;
assign obs_on5[5] = (x>= ( 18 + obs_x_l[5]) && x <= (obs_x_r[5] - 7 )&&  y>= ( 6 + obs_y_t[5]) && y  <= (obs_y_b[5] - 20))? 1 : 0;
assign obs_on5[6] = (x>= ( obs_x_l[5] + 22 ) && x <= (obs_x_r[5])&& y>= ( 6 + obs_y_t[5]) && y  <= (obs_y_b[5] - 16))? 1 : 0;
assign obs_on5[7] = (x>= (  obs_x_l[5]) && x <= (obs_x_r[5] - 22 )&& y>= ( 13+ obs_y_t[5]) && y  <= (obs_y_b[5] - 3))? 1 : 0;
assign obs_on5[8] = (x>= ( 7 + obs_x_l[5]) && x <= (obs_x_r[5] - 7 )&& y>= (13 + obs_y_t[5] ) && y  <= (obs_y_b[5] - 11))? 1 : 0;
assign obs_on5[9] = (x>= (22 +  obs_x_l[5]) && x <= (obs_x_r[5])&& y>= ( 13+ obs_y_t[5]) && y  <= (obs_y_b[5] - 3))? 1 : 0;
assign obs_on5[10] = (x>= ( 7+ obs_x_l[5]) && x <= (obs_x_r[5] - 20 )&& y>= ( 18 + obs_y_t[5]) && y  <= (obs_y_b[5] - 8))? 1 : 0;
assign obs_on5[11] = (x>= ( 20 + obs_x_l[5]) && x <= (obs_x_r[5] - 7 )&& y>=( 18 + obs_y_t[5]) && y  <= (obs_y_b[5] - 8))? 1 : 0;
assign obs_on5[12] = (x>= ( 7 + obs_x_l[5]) && x <= (obs_x_r[5] - 7 )&& y>= (21 + obs_y_t[5] ) && y  <= (obs_y_b[5] - 3))? 1 : 0;
assign obs_on5[13] = (x>= ( 6 + obs_x_l[5]) && x <= (obs_x_r[5] - 19 )&& y>= ( 26 + obs_y_t[5] )&& y  <= (obs_y_b[5]))? 1 : 0;
assign obs_on5[14] = (x>= ( 19 + obs_x_l[5]) && x <= (obs_x_r[5] - 6 )&& y>=( 26 + obs_y_t[5] )&& y  <= (obs_y_b[5]))? 1 : 0;


always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[5] <= rand5+ 30; 
        obs_y_reg[5] <= rand15+ 30; 
    end    
    else if (refr_tick) begin
        obs_x_reg[5] <= obs_x_reg[5] + obs1_vx_reg; 
        obs_y_reg[5] <= obs_y_reg[5] + obs1_vy_reg;
    end
     else if ((shot_x_l >= obs_x_l[5]) && (shot_x_r <= obs_x_r[5]) && (shot_y_b <= obs_y_b[5])) begin
           obs_x_reg[5] <= 650;
           obs_y_reg[5] <= 0;
           obs_hit[5] = 1;
       end
end

//velocity
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs1_vy_reg <= 0;
        obs1_vx_reg <= 0; //left
    end else if(refr_tick) begin
//          if(reach_bottom) begin 
//                obs1_vy_reg <= 0; 
//                obs1_vx_reg <= 0;
//          end
         
            obs1_vy_reg <= 0;
            obs1_vx_reg <= 0; //left
         
    end
end
/*-----------------------------------------------------------*/
// obs - 2stage
/*---------------------------------------------------------*/

assign obs_x_l[10] = obs_x_reg[10]; 
assign obs_x_r[10] = obs_x_l[10] + OBS_SIZE - 1; 
assign obs_y_t[10] = obs_y_reg[10]; 
assign obs_y_b[10] = obs_y_t[10] + OBS_SIZE - 1;
assign obs_y_b[10] = obs_y_t[10] + OBS_SIZE - 1;

//color
assign obs_on0[0] = (x>= ( 5 + obs_x_l[10]) && x <= (obs_x_r[10] - 6 )&& (2 + y>=obs_y_t[10]) && y  <= (obs_y_b[10] - 21))? 1 : 0;
assign obs_on0[1] = (x>= ( 5 + obs_x_l[10]) && x <= (obs_x_r[10] - 20 )&& (8+y>=obs_y_t[10]) && y  <= (obs_y_b[10] - 18))? 1 : 0;
assign obs_on0[2] = (x>= ( 12+ obs_x_l[10]) && x <= (obs_x_r[10] -13)&& y>= ( 8 + obs_y_t[10]) && y  <= (obs_y_b[10] - 18))? 1 : 0;
assign obs_on0[3] = (x>= ( 19 + obs_x_l[10]) && x <= (obs_x_r[10] - 6 )&& y>= ( 8 + obs_y_t[10]) && y  <= (obs_y_b[10] - 18))? 1 : 0;
assign obs_on0[4] = (x>= ( obs_x_l[10]) && x <= (obs_x_r[10] - 20 )&& y>=( 11 + obs_y_t[10]) && y  <= (obs_y_b[10] - 10))? 1 : 0;
assign obs_on0[5] = (x>= ( 18 + obs_x_l[10]) && x <= (obs_x_r[10] - 7 )&&  y>= ( 11 + obs_y_t[10]) && y  <= (obs_y_b[10] - 15))? 1 : 0;
assign obs_on0[6] = (x>= ( 19+ obs_x_l[10]  ) && x <= (obs_x_r[10])&& y>= ( 11 + obs_y_t[10]) && y  <= (obs_y_b[10] - 10))? 1 : 0;
assign obs_on0[7] = (x>= ( 5 + obs_x_l[10]) && x <= (obs_x_r[10] - 17 )&& y>= ( 19+ obs_y_t[10]) && y  <= (obs_y_b[10] ))? 1 : 0;
assign obs_on0[8] = (x>= ( 12 + obs_x_l[10]) && x <= (obs_x_r[10] - 13 )&& y>= (19 + obs_y_t[10] ) && y  <= (obs_y_b[10] -5))? 1 : 0;
assign obs_on0[9] = (x>= ( 16+  obs_x_l[10]) && x <= (obs_x_r[10]-6 )&& y>= ( 19+ obs_y_t[10]) && y  <= (obs_y_b[10]))? 1 : 0;



always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[10] <= 20; 
        obs_y_reg[10] <=0; 
    end    
    else if(refr_tick) begin
        obs_x_reg[10] <= obs_x_reg[10] + obs1_vx_reg; 
        obs_y_reg[10] <= obs_y_reg[10] + obs1_vy_reg;
        end
        if(reach_obs==1) begin
         obs_x_reg[10] <= 0;
         obs_y_reg[10] <=0 ;
        end
     else if ((shot_x_l >= obs_x_l[10]) && (shot_x_r <= obs_x_r[10]) && (shot_y_b <= obs_y_b[10])) begin
           obs_x_reg[10] <= 650;
           obs_y_reg[10] <= 0;
       end
end

assign obs_x_l[11] = obs_x_reg[11]; 
assign obs_x_r[11] = obs_x_l[11] + OBS_SIZE - 1; 
assign obs_y_t[11] = obs_y_reg[11]; 
assign obs_y_b[11] = obs_y_t[11] + OBS_SIZE - 1;
assign obs_y_b[11] = obs_y_t[11] + OBS_SIZE - 1;

//color
assign obs_on0[0] = (x>= ( 5 + obs_x_l[10]) && x <= (obs_x_r[10] - 6 )&& (2 + y>=obs_y_t[10]) && y  <= (obs_y_b[10] - 21))? 1 : 0;
assign obs_on0[1] = (x>= ( 5 + obs_x_l[10]) && x <= (obs_x_r[10] - 20 )&& (8+y>=obs_y_t[10]) && y  <= (obs_y_b[10] - 18))? 1 : 0;
assign obs_on0[2] = (x>= ( 12+ obs_x_l[10]) && x <= (obs_x_r[10] -13)&& y>= ( 8 + obs_y_t[10]) && y  <= (obs_y_b[10] - 18))? 1 : 0;
assign obs_on0[3] = (x>= ( 19 + obs_x_l[10]) && x <= (obs_x_r[10] - 6 )&& y>= ( 8 + obs_y_t[10]) && y  <= (obs_y_b[10] - 18))? 1 : 0;
assign obs_on0[4] = (x>= ( obs_x_l[10]) && x <= (obs_x_r[10] - 20 )&& y>=( 11 + obs_y_t[10]) && y  <= (obs_y_b[10] - 10))? 1 : 0;
assign obs_on0[5] = (x>= ( 18 + obs_x_l[10]) && x <= (obs_x_r[10] - 7 )&&  y>= ( 11 + obs_y_t[10]) && y  <= (obs_y_b[10] - 15))? 1 : 0;
assign obs_on0[6] = (x>= ( 19+ obs_x_l[10]  ) && x <= (obs_x_r[10])&& y>= ( 11 + obs_y_t[10]) && y  <= (obs_y_b[10] - 10))? 1 : 0;
assign obs_on0[7] = (x>= ( 5 + obs_x_l[10]) && x <= (obs_x_r[10] - 17 )&& y>= ( 19+ obs_y_t[10]) && y  <= (obs_y_b[10] ))? 1 : 0;
assign obs_on0[8] = (x>= ( 12 + obs_x_l[10]) && x <= (obs_x_r[10] - 13 )&& y>= (19 + obs_y_t[10] ) && y  <= (obs_y_b[10] -5))? 1 : 0;
assign obs_on0[9] = (x>= ( 16+  obs_x_l[10]) && x <= (obs_x_r[10]-6 )&& y>= ( 19+ obs_y_t[10]) && y  <= (obs_y_b[10]))? 1 : 0;



always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[11] <= 84; 
        obs_y_reg[11] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[11] <= obs_x_reg[11] + obs1_vx_reg; 
        obs_y_reg[11] <= obs_y_reg[11] + obs1_vy_reg;
        end
        if(reach_obs == 1) begin    //shot reach obs, then obs is eliminated
                    obs_x_reg[11] <= 0;
                    obs_y_reg[11] <= 0;
        end
     else if ((shot_x_l >= obs_x_l[11]) && (shot_x_r <= obs_x_r[11]) && (shot_y_b <= obs_y_b[11])) begin
           obs_x_reg[11] <= 650;
           obs_y_reg[11] <= 0;
       end
end

assign obs_x_l[12] = obs_x_reg[12]; 
assign obs_x_r[12] = obs_x_l[12] + OBS_SIZE - 1; 
assign obs_y_t[12] = obs_y_reg[12]; 
assign obs_y_b[12] = obs_y_t[12] + OBS_SIZE - 1;
assign obs_y_b[12] = obs_y_t[12] + OBS_SIZE - 1;

//color
assign obs_on0[0] = (x>= ( 5 + obs_x_l[10]) && x <= (obs_x_r[10] - 6 )&& (2 + y>=obs_y_t[10]) && y  <= (obs_y_b[10] - 21))? 1 : 0;
assign obs_on0[1] = (x>= ( 5 + obs_x_l[10]) && x <= (obs_x_r[10] - 20 )&& (8+y>=obs_y_t[10]) && y  <= (obs_y_b[10] - 18))? 1 : 0;
assign obs_on0[2] = (x>= ( 12+ obs_x_l[10]) && x <= (obs_x_r[10] -13)&& y>= ( 8 + obs_y_t[10]) && y  <= (obs_y_b[10] - 18))? 1 : 0;
assign obs_on0[3] = (x>= ( 19 + obs_x_l[10]) && x <= (obs_x_r[10] - 6 )&& y>= ( 8 + obs_y_t[10]) && y  <= (obs_y_b[10] - 18))? 1 : 0;
assign obs_on0[4] = (x>= ( obs_x_l[10]) && x <= (obs_x_r[10] - 20 )&& y>=( 11 + obs_y_t[10]) && y  <= (obs_y_b[10] - 10))? 1 : 0;
assign obs_on0[5] = (x>= ( 18 + obs_x_l[10]) && x <= (obs_x_r[10] - 7 )&&  y>= ( 11 + obs_y_t[10]) && y  <= (obs_y_b[10] - 15))? 1 : 0;
assign obs_on0[6] = (x>= ( 19+ obs_x_l[10]  ) && x <= (obs_x_r[10])&& y>= ( 11 + obs_y_t[10]) && y  <= (obs_y_b[10] - 10))? 1 : 0;
assign obs_on0[7] = (x>= ( 5 + obs_x_l[10]) && x <= (obs_x_r[10] - 17 )&& y>= ( 19+ obs_y_t[10]) && y  <= (obs_y_b[10] ))? 1 : 0;
assign obs_on0[8] = (x>= ( 12 + obs_x_l[10]) && x <= (obs_x_r[10] - 13 )&& y>= (19 + obs_y_t[10] ) && y  <= (obs_y_b[10] -5))? 1 : 0;
assign obs_on0[9] = (x>= ( 16+  obs_x_l[10]) && x <= (obs_x_r[10]-6 )&& y>= ( 19+ obs_y_t[10]) && y  <= (obs_y_b[10]))? 1 : 0;



always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[12] <= 148; 
        obs_y_reg[12] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[12] <= obs_x_reg[12] + obs1_vx_reg; 
        obs_y_reg[12] <= obs_y_reg[12] + obs1_vy_reg;
        end
        if(reach_obs == 1) begin    //shot reach obs, then obs is eliminated
                    obs_x_reg[12] <= 0;
                    obs_y_reg[12] <= 0;
    end
     else if ((shot_x_l >= obs_x_l[12]) && (shot_x_r <= obs_x_r[12]) && (shot_y_b <= obs_y_b[12])) begin
           obs_x_reg[12] <= 650;
           obs_y_reg[12] <= 0;
       end
end

assign obs_x_l[13] = obs_x_reg[13]; 
assign obs_x_r[13] = obs_x_l[13] + OBS_SIZE - 1; 
assign obs_y_t[13] = obs_y_reg[3]; 
assign obs_y_b[13] = obs_y_t[13] + OBS_SIZE - 1;
assign obs_y_b[13] = obs_y_t[13] + OBS_SIZE - 1;

//color
assign obs_on0[0] = (x>= ( 5 + obs_x_l[10]) && x <= (obs_x_r[10] - 6 )&& (2 + y>=obs_y_t[10]) && y  <= (obs_y_b[10] - 21))? 1 : 0;
assign obs_on0[1] = (x>= ( 5 + obs_x_l[10]) && x <= (obs_x_r[10] - 20 )&& (8+y>=obs_y_t[10]) && y  <= (obs_y_b[10] - 18))? 1 : 0;
assign obs_on0[2] = (x>= ( 12+ obs_x_l[10]) && x <= (obs_x_r[10] -13)&& y>= ( 8 + obs_y_t[10]) && y  <= (obs_y_b[10] - 18))? 1 : 0;
assign obs_on0[3] = (x>= ( 19 + obs_x_l[10]) && x <= (obs_x_r[10] - 6 )&& y>= ( 8 + obs_y_t[10]) && y  <= (obs_y_b[10] - 18))? 1 : 0;
assign obs_on0[4] = (x>= ( obs_x_l[10]) && x <= (obs_x_r[10] - 20 )&& y>=( 11 + obs_y_t[10]) && y  <= (obs_y_b[10] - 10))? 1 : 0;
assign obs_on0[5] = (x>= ( 18 + obs_x_l[10]) && x <= (obs_x_r[10] - 7 )&&  y>= ( 11 + obs_y_t[10]) && y  <= (obs_y_b[10] - 15))? 1 : 0;
assign obs_on0[6] = (x>= ( 19+ obs_x_l[10]  ) && x <= (obs_x_r[10])&& y>= ( 11 + obs_y_t[10]) && y  <= (obs_y_b[10] - 10))? 1 : 0;
assign obs_on0[7] = (x>= ( 5 + obs_x_l[10]) && x <= (obs_x_r[10] - 17 )&& y>= ( 19+ obs_y_t[10]) && y  <= (obs_y_b[10] ))? 1 : 0;
assign obs_on0[8] = (x>= ( 12 + obs_x_l[10]) && x <= (obs_x_r[10] - 13 )&& y>= (19 + obs_y_t[10] ) && y  <= (obs_y_b[10] -5))? 1 : 0;
assign obs_on0[9] = (x>= ( 16+  obs_x_l[10]) && x <= (obs_x_r[10]-6 )&& y>= ( 19+ obs_y_t[10]) && y  <= (obs_y_b[10]))? 1 : 0;


always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[13] <= 212; 
        obs_y_reg[13] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[13] <= obs_x_reg[13] + obs1_vx_reg; 
        obs_y_reg[13] <= obs_y_reg[13] + obs1_vy_reg;
        end
        if(reach_obs == 1) begin    //shot reach obs, then obs is eliminated
                    obs_x_reg[13] <= 0;
                    obs_y_reg[13] <= 0;
      
    end
     else if ((shot_x_l >= obs_x_l[13]) && (shot_x_r <= obs_x_r[13]) && (shot_y_b <= obs_y_b[13])) begin
           obs_x_reg[13] <= 650;
           obs_y_reg[13] <= 0;
       end
end

assign obs_x_l[14] = obs_x_reg[14]; 
assign obs_x_r[14] = obs_x_l[14] + OBS_SIZE - 1; 
assign obs_y_t[14] = obs_y_reg[14]; 
assign obs_y_b[14] = obs_y_t[14] + OBS_SIZE - 1;
assign obs_y_b[14] = obs_y_t[14] + OBS_SIZE - 1;

//color
assign obs_on0[0] = (x>= ( 5 + obs_x_l[10]) && x <= (obs_x_r[10] - 6 )&& (2 + y>=obs_y_t[10]) && y  <= (obs_y_b[10] - 21))? 1 : 0;
assign obs_on0[1] = (x>= ( 5 + obs_x_l[10]) && x <= (obs_x_r[10] - 20 )&& (8+y>=obs_y_t[10]) && y  <= (obs_y_b[10] - 18))? 1 : 0;
assign obs_on0[2] = (x>= ( 12+ obs_x_l[10]) && x <= (obs_x_r[10] -13)&& y>= ( 8 + obs_y_t[10]) && y  <= (obs_y_b[10] - 18))? 1 : 0;
assign obs_on0[3] = (x>= ( 19 + obs_x_l[10]) && x <= (obs_x_r[10] - 6 )&& y>= ( 8 + obs_y_t[10]) && y  <= (obs_y_b[10] - 18))? 1 : 0;
assign obs_on0[4] = (x>= ( obs_x_l[10]) && x <= (obs_x_r[10] - 20 )&& y>=( 11 + obs_y_t[10]) && y  <= (obs_y_b[10] - 10))? 1 : 0;
assign obs_on0[5] = (x>= ( 18 + obs_x_l[10]) && x <= (obs_x_r[10] - 7 )&&  y>= ( 11 + obs_y_t[10]) && y  <= (obs_y_b[10] - 15))? 1 : 0;
assign obs_on0[6] = (x>= ( 19+ obs_x_l[10]  ) && x <= (obs_x_r[10])&& y>= ( 11 + obs_y_t[10]) && y  <= (obs_y_b[10] - 10))? 1 : 0;
assign obs_on0[7] = (x>= ( 5 + obs_x_l[10]) && x <= (obs_x_r[10] - 17 )&& y>= ( 19+ obs_y_t[10]) && y  <= (obs_y_b[10] ))? 1 : 0;
assign obs_on0[8] = (x>= ( 12 + obs_x_l[10]) && x <= (obs_x_r[10] - 13 )&& y>= (19 + obs_y_t[10] ) && y  <= (obs_y_b[10] -5))? 1 : 0;
assign obs_on0[9] = (x>= ( 16+  obs_x_l[10]) && x <= (obs_x_r[10]-6 )&& y>= ( 19+ obs_y_t[10]) && y  <= (obs_y_b[10]))? 1 : 0;


always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[14] <= 276; 
        obs_y_reg[14] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[14] <= obs_x_reg[14] + obs1_vx_reg; 
        obs_y_reg[14] <= obs_y_reg[14] + obs1_vy_reg;
        end
        if(reach_obs == 1) begin    //shot reach obs, then obs is eliminated
                    obs_x_reg[14] <= 0;
                    obs_y_reg[14] <= 0;
        
    end
    else if ((shot_x_l >= obs_x_l[14]) && (shot_x_r <= obs_x_r[14]) && (shot_y_b <= obs_y_b[14])) begin
               obs_x_reg[14] <= 650;
               obs_y_reg[14] <= 0;
           end
end

assign obs_x_l[15] = obs_x_reg[15]; 
assign obs_x_r[15] = obs_x_l[15] + OBS_SIZE - 1; 
assign obs_y_t[15] = obs_y_reg[15]; 
assign obs_y_b[15] = obs_y_t[15] + OBS_SIZE - 1;
assign obs_y_b[15] = obs_y_t[15] + OBS_SIZE - 1;

//color
assign obs_on0[0] = (x>= ( 5 + obs_x_l[10]) && x <= (obs_x_r[10] - 6 )&& (2 + y>=obs_y_t[10]) && y  <= (obs_y_b[10] - 21))? 1 : 0;
assign obs_on0[1] = (x>= ( 5 + obs_x_l[10]) && x <= (obs_x_r[10] - 20 )&& (8+y>=obs_y_t[10]) && y  <= (obs_y_b[10] - 18))? 1 : 0;
assign obs_on0[2] = (x>= ( 12+ obs_x_l[10]) && x <= (obs_x_r[10] -13)&& y>= ( 8 + obs_y_t[10]) && y  <= (obs_y_b[10] - 18))? 1 : 0;
assign obs_on0[3] = (x>= ( 19 + obs_x_l[10]) && x <= (obs_x_r[10] - 6 )&& y>= ( 8 + obs_y_t[10]) && y  <= (obs_y_b[10] - 18))? 1 : 0;
assign obs_on0[4] = (x>= ( obs_x_l[10]) && x <= (obs_x_r[10] - 20 )&& y>=( 11 + obs_y_t[10]) && y  <= (obs_y_b[10] - 10))? 1 : 0;
assign obs_on0[5] = (x>= ( 18 + obs_x_l[10]) && x <= (obs_x_r[10] - 7 )&&  y>= ( 11 + obs_y_t[10]) && y  <= (obs_y_b[10] - 15))? 1 : 0;
assign obs_on0[6] = (x>= ( 19+ obs_x_l[10]  ) && x <= (obs_x_r[10])&& y>= ( 11 + obs_y_t[10]) && y  <= (obs_y_b[10] - 10))? 1 : 0;
assign obs_on0[7] = (x>= ( 5 + obs_x_l[10]) && x <= (obs_x_r[10] - 17 )&& y>= ( 19+ obs_y_t[10]) && y  <= (obs_y_b[10] ))? 1 : 0;
assign obs_on0[8] = (x>= ( 12 + obs_x_l[10]) && x <= (obs_x_r[10] - 13 )&& y>= (19 + obs_y_t[10] ) && y  <= (obs_y_b[10] -5))? 1 : 0;
assign obs_on0[9] = (x>= ( 16+  obs_x_l[10]) && x <= (obs_x_r[10]-6 )&& y>= ( 19+ obs_y_t[10]) && y  <= (obs_y_b[10]))? 1 : 0;


always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[15] <= 340; 
        obs_y_reg[15] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[15] <= obs_x_reg[15] + obs1_vx_reg; 
        obs_y_reg[15] <= obs_y_reg[15] + obs1_vy_reg;
        end
        if(reach_obs == 1) begin    //shot reach obs, then obs is eliminated
                    obs_x_reg[15] <= 0;
                    obs_y_reg[15] <= 0;
        end
    else if ((shot_x_l >= obs_x_l[15]) && (shot_x_r <= obs_x_r[15]) && (shot_y_b <= obs_y_b[15])) begin
                   obs_x_reg[15] <= 650;
                   obs_y_reg[15] <= 0;
               end
end



always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs2_vy_reg <= OBS_V;
        obs2_vx_reg <= 0; //left
    end else if(refr_tick) begin
          if(reach_bottom) begin 
                obs2_vy_reg <= 0; 
                obs2_vx_reg <= 0;
          end
          else begin
            obs2_vy_reg <= OBS_V;
            obs2_vx_reg <= 0; //left
          end
    end
end
/*---------------------------------------------------------*/
// obs - 3stage
/*---------------------------------------------------------*/

assign obs_x_l[20] = obs_x_reg[20]; 
assign obs_x_r[20] = obs_x_l[20] + OBS_SIZE - 1; 
assign obs_y_t[20] = obs_y_reg[20]; 
assign obs_y_b[20] = obs_y_t[20] + OBS_SIZE - 1;
assign obs_y_b[20] = obs_y_t[20] + OBS_SIZE - 1;

//color
assign obs_on0[0] = (x>= ( 8 + obs_x_l[20]) && x <= (obs_x_r[20] - 19 )&& y>=obs_y_t[20] && y  <= (obs_y_b[20] - 23))? 1 : 0;
assign obs_on0[1] = (x>= ( 19 + obs_x_l[20]) && x <= (obs_x_r[20] - 8 )&& y>=obs_y_t[20] && y  <= (obs_y_b[20] - 23))? 1 : 0;
assign obs_on0[2] = (x>= ( obs_x_l[20]) && x <= (obs_x_r[20] -22)&& y>= ( 6 + obs_y_t[20]) && y  <= (obs_y_b[20] - 16))? 1 : 0;
assign obs_on0[3] = (x>= ( 7 + obs_x_l[20]) && x <= (obs_x_r[20] - 18 )&& y>= ( 6 + obs_y_t[20]) && y  <= (obs_y_b[20] - 20))? 1 : 0;
assign obs_on0[4] = (x>= ( 11 + obs_x_l[20]) && x <= (obs_x_r[20] - 11 )&& y>=( 6 + obs_y_t[20]) && y  <= (obs_y_b[20] - 16))? 1 : 0;
assign obs_on0[5] = (x>= ( 18 + obs_x_l[20]) && x <= (obs_x_r[20] - 7 )&&  y>= ( 6 + obs_y_t[20]) && y  <= (obs_y_b[20] - 20))? 1 : 0;
assign obs_on0[6] = (x>= ( obs_x_l[20] + 22 ) && x <= (obs_x_r[20])&& y>= ( 6 + obs_y_t[20]) && y  <= (obs_y_b[20] - 16))? 1 : 0;
assign obs_on0[7] = (x>= (  obs_x_l[20]) && x <= (obs_x_r[20] - 22 )&& y>= ( 13+ obs_y_t[20]) && y  <= (obs_y_b[20] - 3))? 1 : 0;
assign obs_on0[8] = (x>= ( 7 + obs_x_l[20]) && x <= (obs_x_r[20] - 7 )&& y>= (13 + obs_y_t[20] ) && y  <= (obs_y_b[20] - 11))? 1 : 0;
assign obs_on0[9] = (x>= (22 +  obs_x_l[20]) && x <= (obs_x_r[20])&& y>= ( 13+ obs_y_t[20]) && y  <= (obs_y_b[20] - 3))? 1 : 0;
assign obs_on0[10] = (x>= ( 7+ obs_x_l[20]) && x <= (obs_x_r[20] - 20 )&& y>= ( 18 + obs_y_t[20]) && y  <= (obs_y_b[20] - 8))? 1 : 0;
assign obs_on0[11] = (x>= ( 20 + obs_x_l[20]) && x <= (obs_x_r[20] - 7 )&& y>=( 18 + obs_y_t[20]) && y  <= (obs_y_b[20] - 8))? 1 : 0;
assign obs_on0[12] = (x>= ( 7 + obs_x_l[20]) && x <= (obs_x_r[20] - 7 )&& y>= (21 + obs_y_t[20] ) && y  <= (obs_y_b[20] - 3))? 1 : 0;
assign obs_on0[13] = (x>= ( 6 + obs_x_l[20]) && x <= (obs_x_r[20] - 19 )&& y>= ( 26 + obs_y_t[20] )&& y  <= (obs_y_b[20]))? 1 : 0;
assign obs_on0[14] = (x>= ( 19 + obs_x_l[20]) && x <= (obs_x_r[20] - 6 )&& y>=( 26 + obs_y_t[20] )&& y  <= (obs_y_b[20]))? 1 : 0;


always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[20] <= 20; 
        obs_y_reg[20] <=0; 
    end    
    else if(refr_tick) begin
        obs_x_reg[20] <= obs_x_reg[20] + obs1_vx_reg; 
        obs_y_reg[20] <= obs_y_reg[20] + obs1_vy_reg;
        end
        if(reach_obs==1) begin
         obs_x_reg[20] <= 0;
         obs_y_reg[20] <=0 ;
        end
    else if ((shot_x_l >= obs_x_l[20]) && (shot_x_r <= obs_x_r[20]) && (shot_y_b <= obs_y_b[20])) begin
                           obs_x_reg[20] <= 650;
                           obs_y_reg[20] <= 0;
                       end
end

assign obs_x_l[21] = obs_x_reg[21]; 
assign obs_x_r[21] = obs_x_l[21] + OBS_SIZE - 1; 
assign obs_y_t[21] = obs_y_reg[21]; 
assign obs_y_b[21] = obs_y_t[21] + OBS_SIZE - 1;
assign obs_y_b[21] = obs_y_t[21] + OBS_SIZE - 1;

//color
assign obs_on0[0] = (x>= ( 8 + obs_x_l[21]) && x <= (obs_x_r[21] - 19 )&& y>=obs_y_t[21] && y  <= (obs_y_b[21] - 23))? 1 : 0;
assign obs_on0[1] = (x>= ( 19 + obs_x_l[21]) && x <= (obs_x_r[21] - 8 )&& y>=obs_y_t[21] && y  <= (obs_y_b[21] - 23))? 1 : 0;
assign obs_on0[2] = (x>= ( obs_x_l[21]) && x <= (obs_x_r[21] -22)&& y>= ( 6 + obs_y_t[21]) && y  <= (obs_y_b[21] - 16))? 1 : 0;
assign obs_on0[3] = (x>= ( 7 + obs_x_l[21]) && x <= (obs_x_r[21] - 18 )&& y>= ( 6 + obs_y_t[21]) && y  <= (obs_y_b[21] - 20))? 1 : 0;
assign obs_on0[4] = (x>= ( 11 + obs_x_l[21]) && x <= (obs_x_r[21] - 11 )&& y>=( 6 + obs_y_t[21]) && y  <= (obs_y_b[21] - 16))? 1 : 0;
assign obs_on0[5] = (x>= ( 18 + obs_x_l[21]) && x <= (obs_x_r[21] - 7 )&&  y>= ( 6 + obs_y_t[21]) && y  <= (obs_y_b[21] - 20))? 1 : 0;
assign obs_on0[6] = (x>= ( obs_x_l[21] + 22 ) && x <= (obs_x_r[21])&& y>= ( 6 + obs_y_t[21]) && y  <= (obs_y_b[21] - 16))? 1 : 0;
assign obs_on0[7] = (x>= (  obs_x_l[21]) && x <= (obs_x_r[21] - 22 )&& y>= ( 13+ obs_y_t[21]) && y  <= (obs_y_b[21] - 3))? 1 : 0;
assign obs_on0[8] = (x>= ( 7 + obs_x_l[21]) && x <= (obs_x_r[21] - 7 )&& y>= (13 + obs_y_t[21] ) && y  <= (obs_y_b[21] - 11))? 1 : 0;
assign obs_on0[9] = (x>= (22 +  obs_x_l[21]) && x <= (obs_x_r[21])&& y>= ( 13+ obs_y_t[21]) && y  <= (obs_y_b[21] - 3))? 1 : 0;
assign obs_on0[10] = (x>= ( 7+ obs_x_l[21]) && x <= (obs_x_r[21] - 20 )&& y>= ( 18 + obs_y_t[21]) && y  <= (obs_y_b[21] - 8))? 1 : 0;
assign obs_on0[11] = (x>= ( 20 + obs_x_l[21]) && x <= (obs_x_r[21] - 7 )&& y>=( 18 + obs_y_t[21]) && y  <= (obs_y_b[21] - 8))? 1 : 0;
assign obs_on0[12] = (x>= ( 7 + obs_x_l[21]) && x <= (obs_x_r[21] - 7 )&& y>= (21 + obs_y_t[21] ) && y  <= (obs_y_b[21] - 3))? 1 : 0;
assign obs_on0[13] = (x>= ( 6 + obs_x_l[21]) && x <= (obs_x_r[21] - 19 )&& y>= ( 26 + obs_y_t[21] )&& y  <= (obs_y_b[21]))? 1 : 0;
assign obs_on0[14] = (x>= ( 19 + obs_x_l[21]) && x <= (obs_x_r[21] - 6 )&& y>=( 26 + obs_y_t[21] )&& y  <= (obs_y_b[21]))? 1 : 0;

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[21] <= 84; 
        obs_y_reg[21] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[21] <= obs_x_reg[21] + obs1_vx_reg; 
        obs_y_reg[21] <= obs_y_reg[21] + obs1_vy_reg;
        end
        if(reach_obs == 1) begin    //shot reach obs, then obs is eliminated
                    obs_x_reg[21] <= 0;
                    obs_y_reg[21] <= 0;
        end
   else if ((shot_x_l >= obs_x_l[21]) && (shot_x_r <= obs_x_r[21]) && (shot_y_b <= obs_y_b[21])) begin
                           obs_x_reg[21] <= 650;
                           obs_y_reg[21] <= 0;
                       end
end

assign obs_x_l[22] = obs_x_reg[22]; 
assign obs_x_r[22] = obs_x_l[22] + OBS_SIZE - 1; 
assign obs_y_t[22] = obs_y_reg[22]; 
assign obs_y_b[22] = obs_y_t[22] + OBS_SIZE - 1;
assign obs_y_b[22] = obs_y_t[22] + OBS_SIZE - 1;

//color
assign obs_on0[0] = (x>= ( 8 + obs_x_l[2]) && x <= (obs_x_r[22] - 19 )&& y>=obs_y_t[22] && y  <= (obs_y_b[22] - 23))? 1 : 0;
assign obs_on0[1] = (x>= ( 19 + obs_x_l[22]) && x <= (obs_x_r[22] - 8 )&& y>=obs_y_t[22] && y  <= (obs_y_b[22] - 23))? 1 : 0;
assign obs_on0[2] = (x>= ( obs_x_l[22]) && x <= (obs_x_r[22] -22)&& y>= ( 6 + obs_y_t[22]) && y  <= (obs_y_b[22] - 16))? 1 : 0;
assign obs_on0[3] = (x>= ( 7 + obs_x_l[22]) && x <= (obs_x_r[22] - 18 )&& y>= ( 6 + obs_y_t[22]) && y  <= (obs_y_b[22] - 20))? 1 : 0;
assign obs_on0[4] = (x>= ( 11 + obs_x_l[22]) && x <= (obs_x_r[22] - 11 )&& y>=( 6 + obs_y_t[22]) && y  <= (obs_y_b[22] - 16))? 1 : 0;
assign obs_on0[5] = (x>= ( 18 + obs_x_l[22]) && x <= (obs_x_r[22] - 7 )&&  y>= ( 6 + obs_y_t[22]) && y  <= (obs_y_b[22] - 20))? 1 : 0;
assign obs_on0[6] = (x>= ( obs_x_l[22] + 22 ) && x <= (obs_x_r[22])&& y>= ( 6 + obs_y_t[22]) && y  <= (obs_y_b[22] - 16))? 1 : 0;
assign obs_on0[7] = (x>= (  obs_x_l[22]) && x <= (obs_x_r[22] - 22 )&& y>= ( 13+ obs_y_t[22]) && y  <= (obs_y_b[22] - 3))? 1 : 0;
assign obs_on0[8] = (x>= ( 7 + obs_x_l[22]) && x <= (obs_x_r[22] - 7 )&& y>= (13 + obs_y_t[22] ) && y  <= (obs_y_b[22] - 11))? 1 : 0;
assign obs_on0[9] = (x>= (22 +  obs_x_l[22]) && x <= (obs_x_r[22])&& y>= ( 13+ obs_y_t[22]) && y  <= (obs_y_b[22] - 3))? 1 : 0;
assign obs_on0[10] = (x>= ( 7+ obs_x_l[22]) && x <= (obs_x_r[22] - 20 )&& y>= ( 18 + obs_y_t[22]) && y  <= (obs_y_b[22] - 8))? 1 : 0;
assign obs_on0[11] = (x>= ( 20 + obs_x_l[22]) && x <= (obs_x_r[22] - 7 )&& y>=( 18 + obs_y_t[22]) && y  <= (obs_y_b[22] - 8))? 1 : 0;
assign obs_on0[12] = (x>= ( 7 + obs_x_l[22]) && x <= (obs_x_r[22] - 7 )&& y>= (21 + obs_y_t[22] ) && y  <= (obs_y_b[22] - 3))? 1 : 0;
assign obs_on0[13] = (x>= ( 6 + obs_x_l[22]) && x <= (obs_x_r[22] - 19 )&& y>= ( 26 + obs_y_t[22] )&& y  <= (obs_y_b[22]))? 1 : 0;
assign obs_on0[14] = (x>= ( 19 + obs_x_l[22]) && x <= (obs_x_r[22] - 6 )&& y>=( 26 + obs_y_t[22] )&& y  <= (obs_y_b[22]))? 1 : 0;

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[22] <= 148; 
        obs_y_reg[22] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[22] <= obs_x_reg[22] + obs1_vx_reg; 
        obs_y_reg[22] <= obs_y_reg[22] + obs1_vy_reg;
        end
        if(reach_obs == 1) begin    //shot reach obs, then obs is eliminated
                    obs_x_reg[22] <= 0;
                    obs_y_reg[22] <= 0;
        end
    else if ((shot_x_l >= obs_x_l[22]) && (shot_x_r <= obs_x_r[22]) && (shot_y_b <= obs_y_b[22])) begin
                           obs_x_reg[22] <= 650;
                           obs_y_reg[22] <= 0;
                       end
end

assign obs_x_l[23] = obs_x_reg[23]; 
assign obs_x_r[23] = obs_x_l[23] + OBS_SIZE - 1; 
assign obs_y_t[23] = obs_y_reg[23]; 
assign obs_y_b[23] = obs_y_t[23] + OBS_SIZE - 1;
assign obs_y_b[23] = obs_y_t[23] + OBS_SIZE - 1;

//color
assign obs_on0[0] = (x>= ( 8 + obs_x_l[23]) && x <= (obs_x_r[23] - 19 )&& y>=obs_y_t[23] && y  <= (obs_y_b[23] - 23))? 1 : 0;
assign obs_on0[1] = (x>= ( 19 + obs_x_l[23]) && x <= (obs_x_r[23] - 8 )&& y>=obs_y_t[23] && y  <= (obs_y_b[23] - 23))? 1 : 0;
assign obs_on0[2] = (x>= ( obs_x_l[23]) && x <= (obs_x_r[23] -22)&& y>= ( 6 + obs_y_t[23]) && y  <= (obs_y_b[23] - 16))? 1 : 0;
assign obs_on0[3] = (x>= ( 7 + obs_x_l[23]) && x <= (obs_x_r[23] - 18 )&& y>= ( 6 + obs_y_t[23]) && y  <= (obs_y_b[23] - 20))? 1 : 0;
assign obs_on0[4] = (x>= ( 11 + obs_x_l[23]) && x <= (obs_x_r[23] - 11 )&& y>=( 6 + obs_y_t[23]) && y  <= (obs_y_b[23] - 16))? 1 : 0;
assign obs_on0[5] = (x>= ( 18 + obs_x_l[23]) && x <= (obs_x_r[23] - 7 )&&  y>= ( 6 + obs_y_t[23]) && y  <= (obs_y_b[23] - 20))? 1 : 0;
assign obs_on0[6] = (x>= ( obs_x_l[23] + 22 ) && x <= (obs_x_r[23])&& y>= ( 6 + obs_y_t[23]) && y  <= (obs_y_b[23] - 16))? 1 : 0;
assign obs_on0[7] = (x>= (  obs_x_l[23]) && x <= (obs_x_r[23] - 22 )&& y>= ( 13+ obs_y_t[23]) && y  <= (obs_y_b[23] - 3))? 1 : 0;
assign obs_on0[8] = (x>= ( 7 + obs_x_l[23]) && x <= (obs_x_r[23] - 7 )&& y>= (13 + obs_y_t[23] ) && y  <= (obs_y_b[23] - 11))? 1 : 0;
assign obs_on0[9] = (x>= (22 +  obs_x_l[23]) && x <= (obs_x_r[23])&& y>= ( 13+ obs_y_t[23]) && y  <= (obs_y_b[23] - 3))? 1 : 0;
assign obs_on0[10] = (x>= ( 7+ obs_x_l[23]) && x <= (obs_x_r[23] - 20 )&& y>= ( 18 + obs_y_t[23]) && y  <= (obs_y_b[23] - 8))? 1 : 0;
assign obs_on0[11] = (x>= ( 20 + obs_x_l[23]) && x <= (obs_x_r[23] - 7 )&& y>=( 18 + obs_y_t[23]) && y  <= (obs_y_b[23] - 8))? 1 : 0;
assign obs_on0[12] = (x>= ( 7 + obs_x_l[23]) && x <= (obs_x_r[23] - 7 )&& y>= (21 + obs_y_t[23] ) && y  <= (obs_y_b[23] - 3))? 1 : 0;
assign obs_on0[13] = (x>= ( 6 + obs_x_l[23]) && x <= (obs_x_r[23] - 19 )&& y>= ( 26 + obs_y_t[23] )&& y  <= (obs_y_b[23]))? 1 : 0;
assign obs_on0[14] = (x>= ( 19 + obs_x_l[23]) && x <= (obs_x_r[23] - 6 )&& y>=( 26 + obs_y_t[23] )&& y  <= (obs_y_b[23]))? 1 : 0;

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[23] <= 212; 
        obs_y_reg[23] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[23] <= obs_x_reg[23] + obs1_vx_reg; 
        obs_y_reg[23] <= obs_y_reg[23] + obs1_vy_reg;
        end
        if(reach_obs == 1) begin    //shot reach obs, then obs is eliminated
                    obs_x_reg[23] <= 0;
                    obs_y_reg[23] <= 0;
        end
    else if ((shot_x_l >= obs_x_l[23]) && (shot_x_r <= obs_x_r[23]) && (shot_y_b <= obs_y_b[23])) begin
                           obs_x_reg[23] <= 650;
                           obs_y_reg[23] <= 0;
                       end
end

assign obs_x_l[24] = obs_x_reg[24]; 
assign obs_x_r[24] = obs_x_l[24] + OBS_SIZE - 1; 
assign obs_y_t[24] = obs_y_reg[24]; 
assign obs_y_b[24] = obs_y_t[24] + OBS_SIZE - 1;
assign obs_y_b[24] = obs_y_t[24] + OBS_SIZE - 1;

//color
assign obs_on0[0] = (x>= ( 8 + obs_x_l[24]) && x <= (obs_x_r[24] - 19 )&& y>=obs_y_t[24] && y  <= (obs_y_b[24] - 23))? 1 : 0;
assign obs_on0[1] = (x>= ( 19 + obs_x_l[24]) && x <= (obs_x_r[24] - 8 )&& y>=obs_y_t[24] && y  <= (obs_y_b[24] - 23))? 1 : 0;
assign obs_on0[2] = (x>= ( obs_x_l[24]) && x <= (obs_x_r[24] -22)&& y>= ( 6 + obs_y_t[24]) && y  <= (obs_y_b[24] - 16))? 1 : 0;
assign obs_on0[3] = (x>= ( 7 + obs_x_l[24]) && x <= (obs_x_r[24] - 18 )&& y>= ( 6 + obs_y_t[24]) && y  <= (obs_y_b[24] - 20))? 1 : 0;
assign obs_on0[4] = (x>= ( 11 + obs_x_l[24]) && x <= (obs_x_r[24] - 11 )&& y>=( 6 + obs_y_t[24]) && y  <= (obs_y_b[24] - 16))? 1 : 0;
assign obs_on0[5] = (x>= ( 18 + obs_x_l[24]) && x <= (obs_x_r[24] - 7 )&&  y>= ( 6 + obs_y_t[24]) && y  <= (obs_y_b[24] - 20))? 1 : 0;
assign obs_on0[6] = (x>= ( obs_x_l[24] + 22 ) && x <= (obs_x_r[24])&& y>= ( 6 + obs_y_t[24]) && y  <= (obs_y_b[24] - 16))? 1 : 0;
assign obs_on0[7] = (x>= (  obs_x_l[24]) && x <= (obs_x_r[24] - 22 )&& y>= ( 13+ obs_y_t[24]) && y  <= (obs_y_b[24] - 3))? 1 : 0;
assign obs_on0[8] = (x>= ( 7 + obs_x_l[24]) && x <= (obs_x_r[24] - 7 )&& y>= (13 + obs_y_t[24] ) && y  <= (obs_y_b[24] - 11))? 1 : 0;
assign obs_on0[9] = (x>= (22 +  obs_x_l[24]) && x <= (obs_x_r[24])&& y>= ( 13+ obs_y_t[24]) && y  <= (obs_y_b[24] - 3))? 1 : 0;
assign obs_on0[10] = (x>= ( 7+ obs_x_l[24]) && x <= (obs_x_r[24] - 20 )&& y>= ( 18 + obs_y_t[24]) && y  <= (obs_y_b[24] - 8))? 1 : 0;
assign obs_on0[11] = (x>= ( 20 + obs_x_l[24]) && x <= (obs_x_r[24] - 7 )&& y>=( 18 + obs_y_t[24]) && y  <= (obs_y_b[24] - 8))? 1 : 0;
assign obs_on0[12] = (x>= ( 7 + obs_x_l[24]) && x <= (obs_x_r[24] - 7 )&& y>= (21 + obs_y_t[24] ) && y  <= (obs_y_b[24] - 3))? 1 : 0;
assign obs_on0[13] = (x>= ( 6 + obs_x_l[24]) && x <= (obs_x_r[24] - 19 )&& y>= ( 26 + obs_y_t[24] )&& y  <= (obs_y_b[24]))? 1 : 0;
assign obs_on0[14] = (x>= ( 19 + obs_x_l[24]) && x <= (obs_x_r[24] - 6 )&& y>=( 26 + obs_y_t[24] )&& y  <= (obs_y_b[24]))? 1 : 0;

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[24] <= 276; 
        obs_y_reg[24] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[24] <= obs_x_reg[24] + obs1_vx_reg; 
        obs_y_reg[24] <= obs_y_reg[24] + obs1_vy_reg;
        end
        if(reach_obs == 1) begin    //shot reach obs, then obs is eliminated
                    obs_x_reg[24] <= 0;
                    obs_y_reg[24] <= 0;
        end
    else if ((shot_x_l >= obs_x_l[24]) && (shot_x_r <= obs_x_r[24]) && (shot_y_b <= obs_y_b[24])) begin
                           obs_x_reg[24] <= 650;
                           obs_y_reg[24] <= 0;
                       end
end

assign obs_x_l[25] = obs_x_reg[25]; 
assign obs_x_r[25] = obs_x_l[25] + OBS_SIZE - 1; 
assign obs_y_t[25] = obs_y_reg[25]; 
assign obs_y_b[25] = obs_y_t[25] + OBS_SIZE - 1;
assign obs_y_b[25] = obs_y_t[25] + OBS_SIZE - 1;

//color
assign obs_on0[0] = (x>= ( 8 + obs_x_l[25]) && x <= (obs_x_r[25] - 19 )&& y>=obs_y_t[25] && y  <= (obs_y_b[25] - 23))? 1 : 0;
assign obs_on0[1] = (x>= ( 19 + obs_x_l[25]) && x <= (obs_x_r[25] - 8 )&& y>=obs_y_t[25] && y  <= (obs_y_b[25] - 23))? 1 : 0;
assign obs_on0[2] = (x>= ( obs_x_l[25]) && x <= (obs_x_r[25] -22)&& y>= ( 6 + obs_y_t[25]) && y  <= (obs_y_b[25] - 16))? 1 : 0;
assign obs_on0[3] = (x>= ( 7 + obs_x_l[25]) && x <= (obs_x_r[25] - 18 )&& y>= ( 6 + obs_y_t[25]) && y  <= (obs_y_b[25] - 20))? 1 : 0;
assign obs_on0[4] = (x>= ( 11 + obs_x_l[25]) && x <= (obs_x_r[25] - 11 )&& y>=( 6 + obs_y_t[25]) && y  <= (obs_y_b[25] - 16))? 1 : 0;
assign obs_on0[5] = (x>= ( 18 + obs_x_l[25]) && x <= (obs_x_r[25] - 7 )&&  y>= ( 6 + obs_y_t[25]) && y  <= (obs_y_b[25] - 20))? 1 : 0;
assign obs_on0[6] = (x>= ( obs_x_l[25] + 22 ) && x <= (obs_x_r[25])&& y>= ( 6 + obs_y_t[25]) && y  <= (obs_y_b[25] - 16))? 1 : 0;
assign obs_on0[7] = (x>= (  obs_x_l[25]) && x <= (obs_x_r[25] - 22 )&& y>= ( 13+ obs_y_t[25]) && y  <= (obs_y_b[25] - 3))? 1 : 0;
assign obs_on0[8] = (x>= ( 7 + obs_x_l[25]) && x <= (obs_x_r[25] - 7 )&& y>= (13 + obs_y_t[25] ) && y  <= (obs_y_b[25] - 11))? 1 : 0;
assign obs_on0[9] = (x>= (22 +  obs_x_l[25]) && x <= (obs_x_r[25])&& y>= ( 13+ obs_y_t[25]) && y  <= (obs_y_b[25] - 3))? 1 : 0;
assign obs_on0[10] = (x>= ( 7+ obs_x_l[25]) && x <= (obs_x_r[25] - 20 )&& y>= ( 18 + obs_y_t[25]) && y  <= (obs_y_b[25] - 8))? 1 : 0;
assign obs_on0[11] = (x>= ( 20 + obs_x_l[25]) && x <= (obs_x_r[25] - 7 )&& y>=( 18 + obs_y_t[25]) && y  <= (obs_y_b[25] - 8))? 1 : 0;
assign obs_on0[12] = (x>= ( 7 + obs_x_l[25]) && x <= (obs_x_r[25] - 7 )&& y>= (21 + obs_y_t[25] ) && y  <= (obs_y_b[25] - 3))? 1 : 0;
assign obs_on0[13] = (x>= ( 6 + obs_x_l[25]) && x <= (obs_x_r[25] - 19 )&& y>= ( 26 + obs_y_t[25] )&& y  <= (obs_y_b[25]))? 1 : 0;
assign obs_on0[14] = (x>= ( 19 + obs_x_l[25]) && x <= (obs_x_r[25] - 6 )&& y>=( 26 + obs_y_t[25] )&& y  <= (obs_y_b[25]))? 1 : 0;

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[25] <= 340; 
        obs_y_reg[25] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[25] <= obs_x_reg[25] + obs1_vx_reg; 
        obs_y_reg[25] <= obs_y_reg[25] + obs1_vy_reg;
        end
        if(reach_obs == 1) begin    //shot reach obs, then obs is eliminated
                    obs_x_reg[25] <= 0;
                    obs_y_reg[25] <= 0;
        end
    else if ((shot_x_l >= obs_x_l[25]) && (shot_x_r <= obs_x_r[25]) && (shot_y_b <= obs_y_b[25])) begin
                           obs_x_reg[25] <= 650;
                           obs_y_reg[25] <= 0;
                       end
end



assign reach_wall[0] = (obs3_xr <= MAX_X) ? 1 : 0 ; // right wall
assign reach_wall[1] = (obs3_xl  <= 640-MAX_X) ? 1 : 0 ; //left wall

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs3_vy_reg <= 0;
        obs3_vx_reg <= OBS_V; //left
    end else if(refr_tick) begin
          if(reach_bottom) begin 
                obs3_vy_reg <= 0; 
                obs3_vx_reg <= 0;
                end
          else if(reach_wall[0]) obs3_vx_reg <= -1*OBS_V; // reach wall go left
          else if(reach_wall[1]) obs3_vx_reg <= OBS_V; // reach wall go right
          else  begin
            obs3_vy_reg <= 0;
            obs3_vx_reg <= OBS_V; //left
          end
    end
end

/*---------------------------------------------------------*/
// obs - 4stage
/*---------------------------------------------------------*/

assign obs_x_l[30] = obs_x_reg[30]; 
assign obs_x_r[30] = obs_x_l[30] + OBS_SIZE - 1; 
assign obs_y_t[30] = obs_y_reg[30]; 
assign obs_y_b[30] = obs_y_t[30] + OBS_SIZE - 1;
assign obs_y_b[30] = obs_y_t[30] + OBS_SIZE - 1;

//color
assign obs_on0[0] = (x>= ( 8 + obs_x_l[30]) && x <= (obs_x_r[30] - 19 )&& y>=obs_y_t[30] && y  <= (obs_y_b[30] - 23))? 1 : 0;
assign obs_on0[1] = (x>= ( 19 + obs_x_l[30]) && x <= (obs_x_r[30] - 8 )&& y>=obs_y_t[30] && y  <= (obs_y_b[30] - 23))? 1 : 0;
assign obs_on0[2] = (x>= ( obs_x_l[30]) && x <= (obs_x_r[30] -22)&& y>= ( 6 + obs_y_t[30]) && y  <= (obs_y_b[30] - 16))? 1 : 0;
assign obs_on0[3] = (x>= ( 7 + obs_x_l[30]) && x <= (obs_x_r[30] - 18 )&& y>= ( 6 + obs_y_t[30]) && y  <= (obs_y_b[30] - 20))? 1 : 0;
assign obs_on0[4] = (x>= ( 11 + obs_x_l[30]) && x <= (obs_x_r[30] - 11 )&& y>=( 6 + obs_y_t[30]) && y  <= (obs_y_b[30] - 16))? 1 : 0;
assign obs_on0[5] = (x>= ( 18 + obs_x_l[30]) && x <= (obs_x_r[30] - 7 )&&  y>= ( 6 + obs_y_t[30]) && y  <= (obs_y_b[30] - 20))? 1 : 0;
assign obs_on0[6] = (x>= ( obs_x_l[30] + 22 ) && x <= (obs_x_r[30])&& y>= ( 6 + obs_y_t[30]) && y  <= (obs_y_b[30] - 16))? 1 : 0;
assign obs_on0[7] = (x>= (  obs_x_l[30]) && x <= (obs_x_r[30] - 22 )&& y>= ( 13+ obs_y_t[30]) && y  <= (obs_y_b[30] - 3))? 1 : 0;
assign obs_on0[8] = (x>= ( 7 + obs_x_l[30]) && x <= (obs_x_r[30] - 7 )&& y>= (13 + obs_y_t[30] ) && y  <= (obs_y_b[30] - 11))? 1 : 0;
assign obs_on0[9] = (x>= (22 +  obs_x_l[30]) && x <= (obs_x_r[30])&& y>= ( 13+ obs_y_t[30]) && y  <= (obs_y_b[30] - 3))? 1 : 0;
assign obs_on0[10] = (x>= ( 7+ obs_x_l[30]) && x <= (obs_x_r[30] - 20 )&& y>= ( 18 + obs_y_t[30]) && y  <= (obs_y_b[30] - 8))? 1 : 0;
assign obs_on0[11] = (x>= ( 20 + obs_x_l[30]) && x <= (obs_x_r[30] - 7 )&& y>=( 18 + obs_y_t[30]) && y  <= (obs_y_b[30] - 8))? 1 : 0;
assign obs_on0[12] = (x>= ( 7 + obs_x_l[30]) && x <= (obs_x_r[30] - 7 )&& y>= (21 + obs_y_t[30] ) && y  <= (obs_y_b[30] - 3))? 1 : 0;
assign obs_on0[13] = (x>= ( 6 + obs_x_l[30]) && x <= (obs_x_r[30] - 19 )&& y>= ( 26 + obs_y_t[30] )&& y  <= (obs_y_b[30]))? 1 : 0;
assign obs_on0[14] = (x>= ( 19 + obs_x_l[30]) && x <= (obs_x_r[30] - 6 )&& y>=( 26 + obs_y_t[30] )&& y  <= (obs_y_b[30]))? 1 : 0;


always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[30] <= 20; 
        obs_y_reg[30] <=0; 
    end    
    else if(refr_tick) begin
        obs_x_reg[30] <= obs_x_reg[30] + obs1_vx_reg; 
        obs_y_reg[30] <= obs_y_reg[30] + obs1_vy_reg;
        end
        if(reach_obs==1) begin
         obs_x_reg[30] <= 0;
         obs_y_reg[30] <=0 ;
        end
    else if ((shot_x_l >= obs_x_l[30]) && (shot_x_r <= obs_x_r[30]) && (shot_y_b <= obs_y_b[30])) begin
                           obs_x_reg[30] <= 650;
                           obs_y_reg[30] <= 0;
                       end
end

assign obs_x_l[31] = obs_x_reg[31]; 
assign obs_x_r[31] = obs_x_l[31] + OBS_SIZE - 1; 
assign obs_y_t[31] = obs_y_reg[31]; 
assign obs_y_b[31] = obs_y_t[31] + OBS_SIZE - 1;
assign obs_y_b[31] = obs_y_t[31] + OBS_SIZE - 1;

//color
assign obs_on0[0] = (x>= ( 8 + obs_x_l[31]) && x <= (obs_x_r[31] - 19 )&& y>=obs_y_t[31] && y  <= (obs_y_b[31] - 23))? 1 : 0;
assign obs_on0[1] = (x>= ( 19 + obs_x_l[31]) && x <= (obs_x_r[31] - 8 )&& y>=obs_y_t[31] && y  <= (obs_y_b[31] - 23))? 1 : 0;
assign obs_on0[2] = (x>= ( obs_x_l[31]) && x <= (obs_x_r[31] -22)&& y>= ( 6 + obs_y_t[31]) && y  <= (obs_y_b[31] - 16))? 1 : 0;
assign obs_on0[3] = (x>= ( 7 + obs_x_l[31]) && x <= (obs_x_r[31] - 18 )&& y>= ( 6 + obs_y_t[31]) && y  <= (obs_y_b[31] - 20))? 1 : 0;
assign obs_on0[4] = (x>= ( 11 + obs_x_l[31]) && x <= (obs_x_r[31] - 11 )&& y>=( 6 + obs_y_t[31]) && y  <= (obs_y_b[31] - 16))? 1 : 0;
assign obs_on0[5] = (x>= ( 18 + obs_x_l[31]) && x <= (obs_x_r[31] - 7 )&&  y>= ( 6 + obs_y_t[31]) && y  <= (obs_y_b[31] - 20))? 1 : 0;
assign obs_on0[6] = (x>= ( obs_x_l[31] + 22 ) && x <= (obs_x_r[31])&& y>= ( 6 + obs_y_t[31]) && y  <= (obs_y_b[31] - 16))? 1 : 0;
assign obs_on0[7] = (x>= (  obs_x_l[31]) && x <= (obs_x_r[31] - 22 )&& y>= ( 13+ obs_y_t[31]) && y  <= (obs_y_b[31] - 3))? 1 : 0;
assign obs_on0[8] = (x>= ( 7 + obs_x_l[31]) && x <= (obs_x_r[31] - 7 )&& y>= (13 + obs_y_t[31] ) && y  <= (obs_y_b[31] - 11))? 1 : 0;
assign obs_on0[9] = (x>= (22 +  obs_x_l[31]) && x <= (obs_x_r[31])&& y>= ( 13+ obs_y_t[31]) && y  <= (obs_y_b[31] - 3))? 1 : 0;
assign obs_on0[10] = (x>= ( 7+ obs_x_l[31]) && x <= (obs_x_r[31] - 20 )&& y>= ( 18 + obs_y_t[31]) && y  <= (obs_y_b[31] - 8))? 1 : 0;
assign obs_on0[11] = (x>= ( 20 + obs_x_l[31]) && x <= (obs_x_r[31] - 7 )&& y>=( 18 + obs_y_t[31]) && y  <= (obs_y_b[31] - 8))? 1 : 0;
assign obs_on0[12] = (x>= ( 7 + obs_x_l[31]) && x <= (obs_x_r[31] - 7 )&& y>= (21 + obs_y_t[31] ) && y  <= (obs_y_b[31] - 3))? 1 : 0;
assign obs_on0[13] = (x>= ( 6 + obs_x_l[31]) && x <= (obs_x_r[31] - 19 )&& y>= ( 26 + obs_y_t[31] )&& y  <= (obs_y_b[31]))? 1 : 0;
assign obs_on0[14] = (x>= ( 19 + obs_x_l[31]) && x <= (obs_x_r[31] - 6 )&& y>=( 26 + obs_y_t[31] )&& y  <= (obs_y_b[31]))? 1 : 0;

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[31] <= 84; 
        obs_y_reg[31] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[31] <= obs_x_reg[31] + obs1_vx_reg; 
        obs_y_reg[31] <= obs_y_reg[31] + obs1_vy_reg;
        end
        if(reach_obs == 1) begin    //shot reach obs, then obs is eliminated
                    obs_x_reg[31] <= 0;
                    obs_y_reg[31] <= 0;
        end
    else if ((shot_x_l >= obs_x_l[31]) && (shot_x_r <= obs_x_r[31]) && (shot_y_b <= obs_y_b[31])) begin
                           obs_x_reg[31] <= 650;
                           obs_y_reg[31] <= 0;
                       end
end

assign obs_x_l[32] = obs_x_reg[32]; 
assign obs_x_r[32] = obs_x_l[32] + OBS_SIZE - 1; 
assign obs_y_t[32] = obs_y_reg[32]; 
assign obs_y_b[32] = obs_y_t[32] + OBS_SIZE - 1;
assign obs_y_b[32] = obs_y_t[32] + OBS_SIZE - 1;

//color
assign obs_on0[0] = (x>= ( 8 + obs_x_l[32]) && x <= (obs_x_r[32] - 19 )&& y>=obs_y_t[32] && y  <= (obs_y_b[32] - 23))? 1 : 0;
assign obs_on0[1] = (x>= ( 19 + obs_x_l[32]) && x <= (obs_x_r[32] - 8 )&& y>=obs_y_t[32] && y  <= (obs_y_b[32] - 23))? 1 : 0;
assign obs_on0[2] = (x>= ( obs_x_l[32]) && x <= (obs_x_r[32] -22)&& y>= ( 6 + obs_y_t[32]) && y  <= (obs_y_b[32] - 16))? 1 : 0;
assign obs_on0[3] = (x>= ( 7 + obs_x_l[32]) && x <= (obs_x_r[32] - 18 )&& y>= ( 6 + obs_y_t[32]) && y  <= (obs_y_b[32] - 20))? 1 : 0;
assign obs_on0[4] = (x>= ( 11 + obs_x_l[32]) && x <= (obs_x_r[32] - 11 )&& y>=( 6 + obs_y_t[32]) && y  <= (obs_y_b[32] - 16))? 1 : 0;
assign obs_on0[5] = (x>= ( 18 + obs_x_l[32]) && x <= (obs_x_r[32] - 7 )&&  y>= ( 6 + obs_y_t[32]) && y  <= (obs_y_b[32] - 20))? 1 : 0;
assign obs_on0[6] = (x>= ( obs_x_l[32] + 22 ) && x <= (obs_x_r[32])&& y>= ( 6 + obs_y_t[32]) && y  <= (obs_y_b[32] - 16))? 1 : 0;
assign obs_on0[7] = (x>= (  obs_x_l[32]) && x <= (obs_x_r[32] - 22 )&& y>= ( 13+ obs_y_t[32]) && y  <= (obs_y_b[32] - 3))? 1 : 0;
assign obs_on0[8] = (x>= ( 7 + obs_x_l[32]) && x <= (obs_x_r[32] - 7 )&& y>= (13 + obs_y_t[32] ) && y  <= (obs_y_b[32] - 11))? 1 : 0;
assign obs_on0[9] = (x>= (22 +  obs_x_l[32]) && x <= (obs_x_r[32])&& y>= ( 13+ obs_y_t[32]) && y  <= (obs_y_b[32] - 3))? 1 : 0;
assign obs_on0[10] = (x>= ( 7+ obs_x_l[32]) && x <= (obs_x_r[32] - 20 )&& y>= ( 18 + obs_y_t[32]) && y  <= (obs_y_b[32] - 8))? 1 : 0;
assign obs_on0[11] = (x>= ( 20 + obs_x_l[32]) && x <= (obs_x_r[32] - 7 )&& y>=( 18 + obs_y_t[32]) && y  <= (obs_y_b[32] - 8))? 1 : 0;
assign obs_on0[12] = (x>= ( 7 + obs_x_l[32]) && x <= (obs_x_r[32] - 7 )&& y>= (21 + obs_y_t[32] ) && y  <= (obs_y_b[32] - 3))? 1 : 0;
assign obs_on0[13] = (x>= ( 6 + obs_x_l[32]) && x <= (obs_x_r[32] - 19 )&& y>= ( 26 + obs_y_t[32] )&& y  <= (obs_y_b[32]))? 1 : 0;
assign obs_on0[14] = (x>= ( 19 + obs_x_l[32]) && x <= (obs_x_r[32] - 6 )&& y>=( 26 + obs_y_t[32] )&& y  <= (obs_y_b[32]))? 1 : 0;

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[32] <= 148; 
        obs_y_reg[32] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[32] <= obs_x_reg[32] + obs1_vx_reg; 
        obs_y_reg[32] <= obs_y_reg[32] + obs1_vy_reg;
        end
        if(reach_obs == 1) begin    //shot reach obs, then obs is eliminated
                    obs_x_reg[32] <= 0;
                    obs_y_reg[32] <= 0;
        end
    else if ((shot_x_l >= obs_x_l[32]) && (shot_x_r <= obs_x_r[32]) && (shot_y_b <= obs_y_b[32])) begin
                           obs_x_reg[32] <= 650;
                           obs_y_reg[32] <= 0;
                       end
end

assign obs_x_l[33] = obs_x_reg[33]; 
assign obs_x_r[33] = obs_x_l[33] + OBS_SIZE - 1; 
assign obs_y_t[33] = obs_y_reg[33]; 
assign obs_y_b[33] = obs_y_t[33] + OBS_SIZE - 1;
assign obs_y_b[33] = obs_y_t[33] + OBS_SIZE - 1;

//color
assign obs_on0[0] = (x>= ( 8 + obs_x_l[33]) && x <= (obs_x_r[33] - 19 )&& y>=obs_y_t[33] && y  <= (obs_y_b[33] - 23))? 1 : 0;
assign obs_on0[1] = (x>= ( 19 + obs_x_l[33]) && x <= (obs_x_r[33] - 8 )&& y>=obs_y_t[33] && y  <= (obs_y_b[33] - 23))? 1 : 0;
assign obs_on0[2] = (x>= ( obs_x_l[33]) && x <= (obs_x_r[33] -22)&& y>= ( 6 + obs_y_t[33]) && y  <= (obs_y_b[33] - 16))? 1 : 0;
assign obs_on0[3] = (x>= ( 7 + obs_x_l[33]) && x <= (obs_x_r[33] - 18 )&& y>= ( 6 + obs_y_t[33]) && y  <= (obs_y_b[33] - 20))? 1 : 0;
assign obs_on0[4] = (x>= ( 11 + obs_x_l[33]) && x <= (obs_x_r[33] - 11 )&& y>=( 6 + obs_y_t[33]) && y  <= (obs_y_b[33] - 16))? 1 : 0;
assign obs_on0[5] = (x>= ( 18 + obs_x_l[33]) && x <= (obs_x_r[33] - 7 )&&  y>= ( 6 + obs_y_t[33]) && y  <= (obs_y_b[33] - 20))? 1 : 0;
assign obs_on0[6] = (x>= ( obs_x_l[33] + 22 ) && x <= (obs_x_r[33])&& y>= ( 6 + obs_y_t[33]) && y  <= (obs_y_b[33] - 16))? 1 : 0;
assign obs_on0[7] = (x>= (  obs_x_l[33]) && x <= (obs_x_r[33] - 22 )&& y>= ( 13+ obs_y_t[33]) && y  <= (obs_y_b[33] - 3))? 1 : 0;
assign obs_on0[8] = (x>= ( 7 + obs_x_l[33]) && x <= (obs_x_r[33] - 7 )&& y>= (13 + obs_y_t[33] ) && y  <= (obs_y_b[33] - 11))? 1 : 0;
assign obs_on0[9] = (x>= (22 +  obs_x_l[33]) && x <= (obs_x_r[33])&& y>= ( 13+ obs_y_t[33]) && y  <= (obs_y_b[33] - 3))? 1 : 0;
assign obs_on0[10] = (x>= ( 7+ obs_x_l[33]) && x <= (obs_x_r[33] - 20 )&& y>= ( 18 + obs_y_t[33]) && y  <= (obs_y_b[33] - 8))? 1 : 0;
assign obs_on0[11] = (x>= ( 20 + obs_x_l[33]) && x <= (obs_x_r[33] - 7 )&& y>=( 18 + obs_y_t[33]) && y  <= (obs_y_b[33] - 8))? 1 : 0;
assign obs_on0[12] = (x>= ( 7 + obs_x_l[33]) && x <= (obs_x_r[33] - 7 )&& y>= (21 + obs_y_t[33] ) && y  <= (obs_y_b[33] - 3))? 1 : 0;
assign obs_on0[13] = (x>= ( 6 + obs_x_l[33]) && x <= (obs_x_r[33] - 19 )&& y>= ( 26 + obs_y_t[33] )&& y  <= (obs_y_b[33]))? 1 : 0;
assign obs_on0[14] = (x>= ( 19 + obs_x_l[33]) && x <= (obs_x_r[33] - 6 )&& y>=( 26 + obs_y_t[33] )&& y  <= (obs_y_b[33]))? 1 : 0;

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[33] <= 212; 
        obs_y_reg[33] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[33] <= obs_x_reg[33] + obs1_vx_reg; 
        obs_y_reg[33] <= obs_y_reg[33] + obs1_vy_reg;
        end
        if(reach_obs == 1) begin    //shot reach obs, then obs is eliminated
                    obs_x_reg[33] <= 0;
                    obs_y_reg[33] <= 0;
        end
    else if ((shot_x_l >= obs_x_l[33]) && (shot_x_r <= obs_x_r[33]) && (shot_y_b <= obs_y_b[33])) begin
                           obs_x_reg[33] <= 650;
                           obs_y_reg[33] <= 0;
                       end
end

assign obs_x_l[34] = obs_x_reg[34]; 
assign obs_x_r[34] = obs_x_l[34] + OBS_SIZE - 1; 
assign obs_y_t[34] = obs_y_reg[34]; 
assign obs_y_b[34] = obs_y_t[34] + OBS_SIZE - 1;
assign obs_y_b[34] = obs_y_t[34] + OBS_SIZE - 1;

//color
assign obs_on0[0] = (x>= ( 8 + obs_x_l[34]) && x <= (obs_x_r[34] - 19 )&& y>=obs_y_t[34] && y  <= (obs_y_b[34] - 23))? 1 : 0;
assign obs_on0[1] = (x>= ( 19 + obs_x_l[34]) && x <= (obs_x_r[34] - 8 )&& y>=obs_y_t[34] && y  <= (obs_y_b[34] - 23))? 1 : 0;
assign obs_on0[2] = (x>= ( obs_x_l[34]) && x <= (obs_x_r[34] -22)&& y>= ( 6 + obs_y_t[34]) && y  <= (obs_y_b[34] - 16))? 1 : 0;
assign obs_on0[3] = (x>= ( 7 + obs_x_l[34]) && x <= (obs_x_r[34] - 18 )&& y>= ( 6 + obs_y_t[34]) && y  <= (obs_y_b[34] - 20))? 1 : 0;
assign obs_on0[4] = (x>= ( 11 + obs_x_l[34]) && x <= (obs_x_r[34] - 11 )&& y>=( 6 + obs_y_t[34]) && y  <= (obs_y_b[34] - 16))? 1 : 0;
assign obs_on0[5] = (x>= ( 18 + obs_x_l[34]) && x <= (obs_x_r[34] - 7 )&&  y>= ( 6 + obs_y_t[34]) && y  <= (obs_y_b[34] - 20))? 1 : 0;
assign obs_on0[6] = (x>= ( obs_x_l[34] + 22 ) && x <= (obs_x_r[34])&& y>= ( 6 + obs_y_t[34]) && y  <= (obs_y_b[34] - 16))? 1 : 0;
assign obs_on0[7] = (x>= (  obs_x_l[34]) && x <= (obs_x_r[34] - 22 )&& y>= ( 13+ obs_y_t[34]) && y  <= (obs_y_b[34] - 3))? 1 : 0;
assign obs_on0[8] = (x>= ( 7 + obs_x_l[34]) && x <= (obs_x_r[34] - 7 )&& y>= (13 + obs_y_t[34] ) && y  <= (obs_y_b[34] - 11))? 1 : 0;
assign obs_on0[9] = (x>= (22 +  obs_x_l[34]) && x <= (obs_x_r[34])&& y>= ( 13+ obs_y_t[34]) && y  <= (obs_y_b[34] - 3))? 1 : 0;
assign obs_on0[10] = (x>= ( 7+ obs_x_l[34]) && x <= (obs_x_r[34] - 20 )&& y>= ( 18 + obs_y_t[34]) && y  <= (obs_y_b[34] - 8))? 1 : 0;
assign obs_on0[11] = (x>= ( 20 + obs_x_l[34]) && x <= (obs_x_r[34] - 7 )&& y>=( 18 + obs_y_t[34]) && y  <= (obs_y_b[34] - 8))? 1 : 0;
assign obs_on0[12] = (x>= ( 7 + obs_x_l[34]) && x <= (obs_x_r[34] - 7 )&& y>= (21 + obs_y_t[34] ) && y  <= (obs_y_b[34] - 3))? 1 : 0;
assign obs_on0[13] = (x>= ( 6 + obs_x_l[34]) && x <= (obs_x_r[34] - 19 )&& y>= ( 26 + obs_y_t[34] )&& y  <= (obs_y_b[34]))? 1 : 0;
assign obs_on0[14] = (x>= ( 19 + obs_x_l[34]) && x <= (obs_x_r[34] - 6 )&& y>=( 26 + obs_y_t[34] )&& y  <= (obs_y_b[34]))? 1 : 0;

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[34] <= 276; 
        obs_y_reg[34] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[34] <= obs_x_reg[34] + obs1_vx_reg; 
        obs_y_reg[34] <= obs_y_reg[34] + obs1_vy_reg;
        end
        if(reach_obs == 1) begin    //shot reach obs, then obs is eliminated
                    obs_x_reg[34] <= 0;
                    obs_y_reg[34] <= 0;
        end
    else if ((shot_x_l >= obs_x_l[34]) && (shot_x_r <= obs_x_r[34]) && (shot_y_b <= obs_y_b[34])) begin
                           obs_x_reg[34] <= 650;
                           obs_y_reg[34] <= 0;
                       end
end

assign obs_x_l[35] = obs_x_reg[35]; 
assign obs_x_r[35] = obs_x_l[35] + OBS_SIZE - 1; 
assign obs_y_t[35] = obs_y_reg[35]; 
assign obs_y_b[35] = obs_y_t[35] + OBS_SIZE - 1;
assign obs_y_b[35] = obs_y_t[35] + OBS_SIZE - 1;

//color
assign obs_on0[0] = (x>= ( 8 + obs_x_l[35]) && x <= (obs_x_r[35] - 19 )&& y>=obs_y_t[35] && y  <= (obs_y_b[35] - 23))? 1 : 0;
assign obs_on0[1] = (x>= ( 19 + obs_x_l[35]) && x <= (obs_x_r[35] - 8 )&& y>=obs_y_t[35] && y  <= (obs_y_b[35] - 23))? 1 : 0;
assign obs_on0[2] = (x>= ( obs_x_l[35]) && x <= (obs_x_r[35] -22)&& y>= ( 6 + obs_y_t[35]) && y  <= (obs_y_b[35] - 16))? 1 : 0;
assign obs_on0[3] = (x>= ( 7 + obs_x_l[35]) && x <= (obs_x_r[35] - 18 )&& y>= ( 6 + obs_y_t[35]) && y  <= (obs_y_b[35] - 20))? 1 : 0;
assign obs_on0[4] = (x>= ( 11 + obs_x_l[35]) && x <= (obs_x_r[35] - 11 )&& y>=( 6 + obs_y_t[35]) && y  <= (obs_y_b[35] - 16))? 1 : 0;
assign obs_on0[5] = (x>= ( 18 + obs_x_l[35]) && x <= (obs_x_r[35] - 7 )&&  y>= ( 6 + obs_y_t[35]) && y  <= (obs_y_b[35] - 20))? 1 : 0;
assign obs_on0[6] = (x>= ( obs_x_l[35] + 22 ) && x <= (obs_x_r[35])&& y>= ( 6 + obs_y_t[35]) && y  <= (obs_y_b[35] - 16))? 1 : 0;
assign obs_on0[7] = (x>= (  obs_x_l[35]) && x <= (obs_x_r[35] - 22 )&& y>= ( 13+ obs_y_t[35]) && y  <= (obs_y_b[35] - 3))? 1 : 0;
assign obs_on0[8] = (x>= ( 7 + obs_x_l[35]) && x <= (obs_x_r[35] - 7 )&& y>= (13 + obs_y_t[35] ) && y  <= (obs_y_b[35] - 11))? 1 : 0;
assign obs_on0[9] = (x>= (22 +  obs_x_l[35]) && x <= (obs_x_r[35])&& y>= ( 13+ obs_y_t[35]) && y  <= (obs_y_b[35] - 3))? 1 : 0;
assign obs_on0[10] = (x>= ( 7+ obs_x_l[35]) && x <= (obs_x_r[35] - 20 )&& y>= ( 18 + obs_y_t[35]) && y  <= (obs_y_b[35] - 8))? 1 : 0;
assign obs_on0[11] = (x>= ( 20 + obs_x_l[35]) && x <= (obs_x_r[35] - 7 )&& y>=( 18 + obs_y_t[35]) && y  <= (obs_y_b[35] - 8))? 1 : 0;
assign obs_on0[12] = (x>= ( 7 + obs_x_l[35]) && x <= (obs_x_r[35] - 7 )&& y>= (21 + obs_y_t[35] ) && y  <= (obs_y_b[35] - 3))? 1 : 0;
assign obs_on0[13] = (x>= ( 6 + obs_x_l[35]) && x <= (obs_x_r[35] - 19 )&& y>= ( 26 + obs_y_t[35] )&& y  <= (obs_y_b[35]))? 1 : 0;
assign obs_on0[14] = (x>= ( 19 + obs_x_l[35]) && x <= (obs_x_r[35] - 6 )&& y>=( 26 + obs_y_t[35] )&& y  <= (obs_y_b[35]))? 1 : 0;

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[35] <= 340; 
        obs_y_reg[35] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[35] <= obs_x_reg[35] + obs1_vx_reg; 
        obs_y_reg[35] <= obs_y_reg[35] + obs1_vy_reg;
        end
        if(reach_obs == 1) begin    //shot reach obs, then obs is eliminated
                    obs_x_reg[35] <= 0;
                    obs_y_reg[35] <= 0;
        end
    else if ((shot_x_l >= obs_x_l[35]) && (shot_x_r <= obs_x_r[35]) && (shot_y_b <= obs_y_b[35])) begin
                           obs_x_reg[35] <= 650;
                           obs_y_reg[35] <= 0;
                       end
end



assign reach_wall[0] = (obs4_xr <= MAX_X) ? 1 : 0 ; // right wall
assign reach_wall[1] = (obs4_xl <= 640-MAX_X) ? 1 : 0 ; //left wall
assign reach_bottom = (obs4_y_b > MAX_Y-1)? 1 :0; // bottom 
assign reach_top = (obs4_y_t == 0)? 1:0; // top 

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs4_vy_reg <= OBS_V;
        obs4_vx_reg <= 0; //left
     end 
     else if(refr_tick) begin 
                  if(reach_bottom) obs4_vy_reg <= -1*OBS_V;
                 else if(reach_top) obs4_vy_reg <= OBS_V; 
                 else if(reach_wall[0]) obs4_vx_reg <= -1*OBS_V; // reach wall go left
                 else if(reach_wall[1]) obs4_vx_reg <= OBS_V; // reach wall go right
                 end
          
end
/*---------------------------------------------------------*/
/*---------------------------------------------------------*/
// bomb
/*---------------------------------------------------------*/
wire [11:0] bomb_left, bomb_right, bomb_y_t, bomb_y_b; 
reg [11:0] bomb_x_reg, bomb_y_reg;
wire bomb_on0[13:0], bomb_on1[13:0], bomb_on2[13:0], bomb_on3[13:0];

assign bomb_left[0] = bomb_x_reg[0]; //장애물의 왼쪽
assign bomb_right[0] = bomb_left[0] + bomb_SIZE - 1; //장애물의 오른쪽
assign bomb_y_t[0] = bomb_y_reg[0];
assign bomb_y_b[0] = bomb_y_t[0] + bomb_SIZE - 1;

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        bomb_x_reg[0] <= MAX_X/rand;
        bomb <= 0;
    end    
    else if(refr_tick) begin
        bomb <= 1;
        //fall_down <= 1;
        bomb_y_reg[0] <= bomb_y_reg[0] + bomb_V;
    end
end
//color
assign bomb_on0[0] = (x>= ( 16 + bomb_left[0]) && x <= (bomb_right[0] -10  )&& y>=bomb_y_t[0] && y  <= (bomb_y_b[0] - 28))? 1 : 0;
assign bomb_on0[1] = (x>= ( 15 + bomb_left[0]) && x <= (bomb_right[0] -13  )&& y>=(1 +bomb_y_t[0]) && y  <= (bomb_y_b[0] - 27))? 1 : 0;
assign bomb_on0[2] = (x>= ( 14 + bomb_left[0]) && x <= (bomb_right[0] -14  )&& y>=(2 +bomb_y_t[0]) && y  <= (bomb_y_b[0] - 25))? 1 : 0;
assign bomb_on0[3] = (x>= ( 1 + bomb_left[0]) && x <= (bomb_right[0] -26 )&& y>=(13 +bomb_y_t[0]) && y  <= (bomb_y_b[0] - 8))? 1 : 0;
assign bomb_on0[4] = (x>= ( 3 + bomb_left[0]) && x <= (bomb_right[0] -24 )&& y>=( 11 +bomb_y_t[0]) && y  <= (bomb_y_b[0] - 6 ))? 1 : 0;
assign bomb_on0[5] = (x>= ( 5 + bomb_left[0]) && x <= (bomb_right[0] -24 )&& y>=( 9 +bomb_y_t[0]) && y  <= (bomb_y_b[0] - 4 ))? 1 : 0;
assign bomb_on0[6] = (x>= ( 7 + bomb_left[0]) && x <= (bomb_right[0] -22 )&& y>=( 7 +bomb_y_t[0]) && y  <= (bomb_y_b[0] -2 ))? 1 : 0;
assign bomb_on0[7] = (x>= ( 9 + bomb_left[0]) && x <= (bomb_right[0] -20 )&& y>=( 5 +bomb_y_t[0]) && y  <= (bomb_y_b[0]  ))? 1 : 0;
assign bomb_on0[8] = (x>= ( 12 + bomb_left[0]) && x <= (bomb_right[0] -17 )&& y>=( 5 +bomb_y_t[0]) && y  <= (bomb_y_b[0]  ))? 1 : 0;
assign bomb_on0[9] = (x>= ( 16 + bomb_left[0]) && x <= (bomb_right[0] -13 )&& y>=( 5 +bomb_y_t[0]) && y  <= (bomb_y_b[0]  ))? 1 : 0;
assign bomb_on0[10] = (x>= ( 20 + bomb_left[0]) && x <= (bomb_right[0] -9 )&& y>=( 7 +bomb_y_t[0]) && y  <= (bomb_y_b[0] - 2 ))? 1 : 0;
assign bomb_on0[11] = (x>= ( 22 + bomb_left[0]) && x <= (bomb_right[0] -7 )&& y>=( 9 +bomb_y_t[0]) && y  <= (bomb_y_b[0] - 4 ))? 1 : 0;
assign bomb_on0[12] = (x>= ( 24 + bomb_left[0]) && x <= (bomb_right[0] -5 )&& y>=( 11 +bomb_y_t[0]) && y  <= (bomb_y_b[0] - 6 ))? 1 : 0;
assign bomb_on0[13] = (x>= ( 26 + bomb_left[0]) && x <= (bomb_right[0] -3 )&& y>=( 13 +bomb_y_t[0]) && y  <= (bomb_y_b[0] - 8 ))? 1 : 0;






assign bomb_left[1] = bomb_x_reg[1]; //장애물의 왼쪽
assign bomb_right[1] = bomb_left[1] + bomb_SIZE - 1; //장애물의 오른쪽
assign bomb_y_t[1] = bomb_y_reg[1];
assign bomb_y_b[1] = bomb_y_t[1] + bomb_SIZE - 1;

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        bomb_x_reg[1] <= MAX_X/rand;
        bomb <= 0;
    end    
    else if(refr_tick) begin
        bomb <= 1;
        //fall_down <= 1;
        bomb_y_reg[1] <= bomb_y_reg[1] + bomb_V;
    end
end

//color
assign bomb_on1[0] = (x>= ( 16 + bomb_left[1]) && x <= (bomb_right[1] -10  )&& y>=bomb_y_t[1] && y  <= (bomb_y_b[1] - 28))? 1 : 0;
assign bomb_on1[1] = (x>= ( 15 + bomb_left[1]) && x <= (bomb_right[1] -13  )&& y>=(1 +bomb_y_t[1]) && y  <= (bomb_y_b[1] - 27))? 1 : 0;
assign bomb_on1[2] = (x>= ( 14 + bomb_left[1]) && x <= (bomb_right[1] -14  )&& y>=(2 +bomb_y_t[1]) && y  <= (bomb_y_b[1] - 25))? 1 : 0;
assign bomb_on1[3] = (x>= ( 1 + bomb_left[1]) && x <= (bomb_right[1] -26 )&& y>=(13 +bomb_y_t[1]) && y  <= (bomb_y_b[1] - 8))? 1 : 0;
assign bomb_on1[4] = (x>= ( 3 + bomb_left[1]) && x <= (bomb_right[1] -24 )&& y>=( 11 +bomb_y_t[1]) && y  <= (bomb_y_b[1] - 6 ))? 1 : 0;
assign bomb_on1[5] = (x>= ( 5 + bomb_left[1]) && x <= (bomb_right[1] -24 )&& y>=( 9 +bomb_y_t[1]) && y  <= (bomb_y_b[1] - 4 ))? 1 : 0;
assign bomb_on1[6] = (x>= ( 7 + bomb_left[1]) && x <= (bomb_right[1] -22 )&& y>=( 7 +bomb_y_t[1]) && y  <= (bomb_y_b[1] -2 ))? 1 : 0;
assign bomb_on1[7] = (x>= ( 9 + bomb_left[1]) && x <= (bomb_right[1] -20 )&& y>=( 5 +bomb_y_t[1]) && y  <= (bomb_y_b[1]  ))? 1 : 0;
assign bomb_on1[8] = (x>= ( 12 + bomb_left[1]) && x <= (bomb_right[1] -17 )&& y>=( 5 +bomb_y_t[1]) && y  <= (bomb_y_b[1]  ))? 1 : 0;
assign bomb_on1[9] = (x>= ( 16 + bomb_left[1]) && x <= (bomb_right[1] -13 )&& y>=( 5 +bomb_y_t[1]) && y  <= (bomb_y_b[1]  ))? 1 : 0;
assign bomb_on1[10] = (x>= ( 20 + bomb_left[1]) && x <= (bomb_right[1] -9 )&& y>=( 7 +bomb_y_t[1]) && y  <= (bomb_y_b[1] - 2 ))? 1 : 0;
assign bomb_on1[11] = (x>= ( 22 + bomb_left[1]) && x <= (bomb_right[1] -7 )&& y>=( 9 +bomb_y_t[1]) && y  <= (bomb_y_b[1] - 4 ))? 1 : 0;
assign bomb_on1[12] = (x>= ( 24 + bomb_left[1]) && x <= (bomb_right[1] -5 )&& y>=( 11 +bomb_y_t[1]) && y  <= (bomb_y_b[1] - 6 ))? 1 : 0;
assign bomb_on1[13] = (x>= ( 26 + bomb_left[1]) && x <= (bomb_right[1] -3 )&& y>=( 13 +bomb_y_t[1]) && y  <= (bomb_y_b[1] - 8 ))? 1 : 0;






assign bomb_left[2] = bomb_x_reg[2]; //장애물의 왼쪽
assign bomb_right[2] = bomb_left[2] + bomb_SIZE - 1; //장애물의 오른쪽
assign bomb_y_t[2] = bomb_y_reg[2];
assign bomb_y_b[2] = bomb_y_t[2] + bomb_SIZE - 1;

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        bomb_x_reg[2] <= MAX_X/rand;
        bomb <= 0;
    end    
    else if(refr_tick) begin
        bomb <= 1;
        //fall_down <= 1;
        bomb_y_reg[2] <= bomb_y_reg[2] + bomb_V;
    end
end
//color
assign bomb_on2[0] = (x>= ( 16 + bomb_left[2]) && x <= (bomb_right[2] -10  )&& y>=bomb_y_t[2] && y  <= (bomb_y_b[2] - 28))? 1 : 0;
assign bomb_on2[1] = (x>= ( 15 + bomb_left[2]) && x <= (bomb_right[2] -13  )&& y>=(1 +bomb_y_t[2]) && y  <= (bomb_y_b[2] - 27))? 1 : 0;
assign bomb_on2[2] = (x>= ( 14 + bomb_left[2]) && x <= (bomb_right[2] -14  )&& y>=(2 +bomb_y_t[2]) && y  <= (bomb_y_b[2] - 25))? 1 : 0;
assign bomb_on2[3] = (x>= ( 1 + bomb_left[2]) && x <= (bomb_right[2] -26 )&& y>=(13 +bomb_y_t[2]) && y  <= (bomb_y_b[2] - 8))? 1 : 0;
assign bomb_on2[4] = (x>= ( 3 + bomb_left[2]) && x <= (bomb_right[2] -24 )&& y>=( 11 +bomb_y_t[2]) && y  <= (bomb_y_b[2] - 6 ))? 1 : 0;
assign bomb_on2[5] = (x>= ( 5 + bomb_left[2]) && x <= (bomb_right[2] -24 )&& y>=( 9 +bomb_y_t[2]) && y  <= (bomb_y_b[2] - 4 ))? 1 : 0;
assign bomb_on2[6] = (x>= ( 7 + bomb_left[2]) && x <= (bomb_right[2] -22 )&& y>=( 7 +bomb_y_t[2]) && y  <= (bomb_y_b[2] -2 ))? 1 : 0;
assign bomb_on2[7] = (x>= ( 9 + bomb_left[2]) && x <= (bomb_right[2] -20 )&& y>=( 5 +bomb_y_t[2]) && y  <= (bomb_y_b[2]  ))? 1 : 0;
assign bomb_on2[8] = (x>= ( 12 + bomb_left[2]) && x <= (bomb_right[2] -17 )&& y>=( 5 +bomb_y_t[2]) && y  <= (bomb_y_b[2]  ))? 1 : 0;
assign bomb_on2[9] = (x>= ( 16 + bomb_left[2]) && x <= (bomb_right[2] -13 )&& y>=( 5 +bomb_y_t[2]) && y  <= (bomb_y_b[2]  ))? 1 : 0;
assign bomb_on2[10] = (x>= ( 20 + bomb_left[2]) && x <= (bomb_right[2] -9 )&& y>=( 7 +bomb_y_t[2]) && y  <= (bomb_y_b[2] - 2 ))? 1 : 0;
assign bomb_on2[11] = (x>= ( 22 + bomb_left[2]) && x <= (bomb_right[2] -7 )&& y>=( 9 +bomb_y_t[2]) && y  <= (bomb_y_b[2] - 4 ))? 1 : 0;
assign bomb_on2[12] = (x>= ( 24 + bomb_left[2]) && x <= (bomb_right[2] -5 )&& y>=( 11 +bomb_y_t[2]) && y  <= (bomb_y_b[2] - 6 ))? 1 : 0;
assign bomb_on2[13] = (x>= ( 26 + bomb_left[2]) && x <= (bomb_right[2] -3 )&& y>=( 13 +bomb_y_t[2]) && y  <= (bomb_y_b[2] - 8 ))? 1 : 0;


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