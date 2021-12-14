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
parameter GUN_X_SIZE = 60; 
parameter GUN_V = 4;
// shot size, velocity
parameter SHOT_SIZE = 6;
parameter SHOT_V = 5;
// obs size, velocity
parameter OBS_SIZE = 30;
parameter OBS_V = 2;
//bomb size, velocity
parameter BOMB_SIZE = 30;
parameter BOMB_V = 10;

wire refr_tick; 
wire [9:0] reach_obs, reach_bomb;
wire reach_top, reach_bottom, wall_left_3, wall_right_3, wall_left_4, wall_right_4;

parameter NEWGAME=3'b00, PLAY=3'b01, NEWGUN=3'b10, OVER=3'b11;
reg [2:0] state_reg, state_next;
reg [1:0] life_reg, life_next;
reg [1:0] stage_reg, stage_next;
parameter STAGE1=3'b00, STAGE2=3'b01, STAGE3=3'b10, STAGE4=3'b11;
parameter FUNC = 0;
reg game_stop, game_over;  

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
wire shot_on[4:0]; 
assign shot_x_l = shot_x_reg;
assign shot_x_r = shot_x_reg + SHOT_SIZE - 1;
assign shot_y_t = shot_y_reg;
assign shot_y_b = shot_y_reg + SHOT_SIZE -1;

//color
assign shot_on[0] = (x>=shot_x_l && x<= (shot_x_r-5) && y>= (2+shot_y_t) && y<= (shot_y_b - 2))? 1 : 0; //shotregionion
assign shot_on[1] = (x>=(1+shot_x_l) && x<= (shot_x_r-4) && y>= (1+shot_y_t) && y<= (shot_y_b - 1))? 1 : 0; //shotregionion
assign shot_on[2] = (x>=(2+shot_x_l) && x<= (shot_x_r-2) && y>= (shot_y_t) && y<= (shot_y_b))? 1 : 0; //shotregionion
assign shot_on[3] = (x>=(4+shot_x_l) && x<= (shot_x_r-1) && y>= (1+shot_y_t) && y<= (shot_y_b - 1))? 1 : 0; //shotregionion
assign shot_on[4] = (x>=(5+shot_x_l) && x<= (shot_x_r) && y>= (2+shot_y_t) && y<= (shot_y_b - 2))? 1 : 0; //shotregionion

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
// random
/*---------------------------------------------------------*/

reg[19:0] s; wire[8:0] rand0, rand1, rand2, rand3, rand4, rand5;
reg[19:0] s1; wire[7:0] rand10, rand11, rand12, rand13, rand14, rand15;
random u0(rst, clk, s, rand0, rand1, rand2, rand3, rand4, rand5); //1stage_x
random1 u1(rst, clk, s1, rand10, rand11, rand12, rand13, rand14, rand15); //1stage_y

reg [19:0] S1; wire [7:0] randB0_x, randB1_x, randB2_x;
reg [19:0] S1_y; wire [7:0] randB0_y, randB1_y, randB2_y;
random_bomb1S(rst, clk, S1, randB0_x, randB1_x,randB2_x);
random_bomb1S_y(rst, clk, S1_y, randB0_y, randB1_y,randB2_y);

/*---------------------------------------------------------*/
// bomb - 1stage
/*---------------------------------------------------------*/

reg [9:0] bomb_x_reg[11:0], bomb_y_reg[11:0];
reg [9:0] bomb1_vy_reg, bomb1_vx_reg, bomb2_vy_reg, bomb2_vx_reg, bomb3_vy_reg, bomb3_vx_reg ;
wire [9:0] bomb_x_l[11:0], bomb_x_r[11:0], bomb_y_t[11:0], bomb_y_b[11:0];
wire bomb_on0[13:0], bomb_on1[13:0], bomb_on2[13:0], bomb_on3[13:0]; 
reg bomb_hit[11:0];
//------------------------------------------------------------------------------------------------------------------------------------------//
assign bomb_x_l[0] = bomb_x_reg[0];
assign bomb_x_r[0] = bomb_x_reg[0] + BOMB_SIZE - 1;
assign bomb_y_t[0] = bomb_y_reg[0];
assign bomb_y_b[0] = bomb_y_reg[0] + BOMB_SIZE -1;

//color
assign bomb_on0[0] = (x>= ( 16 + bomb_x_l[0]) && x <= (bomb_x_r[0] -10  )&& y>=bomb_y_t[0] && y  <= (bomb_y_b[0] - 28))? 1 : 0;
assign bomb_on0[1] = (x>= ( 15 + bomb_x_l[0]) && x <= (bomb_x_r[0] -13  )&& y>=(1 +bomb_y_t[0]) && y  <= (bomb_y_b[0] - 27))? 1 : 0;
assign bomb_on0[2] = (x>= ( 14 +bomb_x_l[0]) && x <= (bomb_x_r[0] -14  )&& y>=(2 +bomb_y_t[0]) && y  <= (bomb_y_b[0] - 25))? 1 : 0;
assign bomb_on0[3] = (x>= ( 1 + bomb_x_l[0]) && x <= (bomb_x_r[0] -26 )&& y>=(13 +bomb_y_t[0]) && y  <= (bomb_y_b[0] - 8))? 1 : 0;
assign bomb_on0[4] = (x>= ( 3 + bomb_x_l[0]) && x <= (bomb_x_r[0] -24 )&& y>=( 11 +bomb_y_t[0]) && y  <= (bomb_y_b[0] - 6 ))? 1 : 0;
assign bomb_on0[5] = (x>= ( 5 + bomb_x_l[0]) && x <= (bomb_x_r[0] -22 )&& y>=( 9 +bomb_y_t[0]) && y  <= (bomb_y_b[0] - 4 ))? 1 : 0;
assign bomb_on0[6] = (x>= ( 7 + bomb_x_l[0]) && x <= (bomb_x_r[0] -20 )&& y>=( 7 +bomb_y_t[0]) && y  <= (bomb_y_b[0] -2 ))? 1 : 0;
assign bomb_on0[7] = (x>= ( 9 + bomb_x_l[0]) && x <= (bomb_x_r[0] -17 )&& y>=( 5 +bomb_y_t[0]) && y  <= (bomb_y_b[0]  ))? 1 : 0;
assign bomb_on0[8] = (x>= ( 12 + bomb_x_l[0]) && x <= (bomb_x_r[0] -13 )&& y>=( 5 +bomb_y_t[0]) && y  <= (bomb_y_b[0]  ))? 1 : 0;
assign bomb_on0[9] = (x>= ( 16 + bomb_x_l[0]) && x <= (bomb_x_r[0] -9 )&& y>=( 5 +bomb_y_t[0]) && y  <= (bomb_y_b[0]  ))? 1 : 0;
assign bomb_on0[10] = (x>= ( 20 + bomb_x_l[0]) && x <= (bomb_x_r[0] -7 )&& y>=( 7 +bomb_y_t[0]) && y  <= (bomb_y_b[0] - 2 ))? 1 : 0;
assign bomb_on0[11] = (x>= ( 22 + bomb_x_l[0]) && x <= (bomb_x_r[0] -5 )&& y>=( 9 +bomb_y_t[0]) && y  <= (bomb_y_b[0] - 4 ))? 1 : 0;
assign bomb_on0[12] = (x>= ( 24 + bomb_x_l[0]) && x <= (bomb_x_r[0] -3 )&& y>=( 11 +bomb_y_t[0]) && y  <= (bomb_y_b[0] - 6 ))? 1 : 0;
assign bomb_on0[13] = (x>= ( 26 + bomb_x_l[0]) && x <= (bomb_x_r[0] -1 )&& y>=( 13 +bomb_y_t[0]) && y  <= (bomb_y_b[0] - 8 ))? 1 : 0; //bomb regionion

always @ (posedge clk or posedge rst) begin
    if(rst|game_stop) begin
        bomb_x_reg[0] <= randB0_x + 30;
        bomb_y_reg[0] <= randB0_y + 30;
    end
    else if(refr_tick)begin
        bomb_x_reg[0] <= bomb_x_reg[0] + bomb1_vx_reg;
        bomb_y_reg[0] <= bomb_y_reg[0] + bomb1_vy_reg;
    end
    else if ((shot_x_l >= bomb_x_l[0]) && (shot_x_r <= bomb_x_r[0]) && (shot_y_b <= bomb_y_b[0]) && (shot_y_t >= bomb_y_t[0])) begin
            bomb_x_reg[0] <= 650;
            bomb_y_reg[0] <= 0;
            bomb_hit[0]= 1;
    end 
end
//--------------------------------------------------------------------------------------------------------------------------------//
assign bomb_x_l[1] = bomb_x_reg[1];
assign bomb_x_r[1] = bomb_x_reg[1] + BOMB_SIZE - 1;
assign bomb_y_t[1] = bomb_y_reg[1];
assign bomb_y_b[1] = bomb_y_reg[1] + BOMB_SIZE -1;

//color
assign bomb_on1[0] = (x>= ( 16 + bomb_x_l[1]) && x <= (bomb_x_r[1] -10  )&& y>=bomb_y_t[1] && y  <= (bomb_y_b[1] - 28))? 1 : 0;
assign bomb_on1[1] = (x>= ( 15 + bomb_x_l[1]) && x <= (bomb_x_r[1] -13  )&& y>=(1 +bomb_y_t[1]) && y  <= (bomb_y_b[1] - 27))? 1 : 0;
assign bomb_on1[2] = (x>= ( 14 + bomb_x_l[1]) && x <= (bomb_x_r[1] -14  )&& y>=(2 +bomb_y_t[1]) && y  <= (bomb_y_b[1] - 25))? 1 : 0;
assign bomb_on1[3] = (x>= ( 1 + bomb_x_l[1]) && x <= (bomb_x_r[1] -26 )&& y>=(13 +bomb_y_t[1]) && y  <= (bomb_y_b[1] - 8))? 1 : 0;
assign bomb_on1[4] = (x>= ( 3 + bomb_x_l[1]) && x <= (bomb_x_r[1] -24 )&& y>=( 11 +bomb_y_t[1]) && y  <= (bomb_y_b[1] - 6 ))? 1 : 0;
assign bomb_on1[5] = (x>= ( 5 + bomb_x_l[1]) && x <= (bomb_x_r[1] -22 )&& y>=( 9 +bomb_y_t[1]) && y  <= (bomb_y_b[1] - 4 ))? 1 : 0;
assign bomb_on1[6] = (x>= ( 7 + bomb_x_l[1]) && x <= (bomb_x_r[1] -20 )&& y>=( 7 +bomb_y_t[1]) && y  <= (bomb_y_b[1] -2 ))? 1 : 0;
assign bomb_on1[7] = (x>= ( 9 + bomb_x_l[1]) && x <= (bomb_x_r[1] -17 )&& y>=( 5 +bomb_y_t[1]) && y  <= (bomb_y_b[1]  ))? 1 : 0;
assign bomb_on1[8] = (x>= ( 12 + bomb_x_l[1]) && x <= (bomb_x_r[1] -13 )&& y>=( 5 +bomb_y_t[1]) && y  <= (bomb_y_b[1]  ))? 1 : 0;
assign bomb_on1[9] = (x>= ( 16 + bomb_x_l[1]) && x <= (bomb_x_r[1] -9 )&& y>=( 5 +bomb_y_t[1]) && y  <= (bomb_y_b[1]  ))? 1 : 0;
assign bomb_on1[10] = (x>= ( 20 + bomb_x_l[1]) && x <= (bomb_x_r[1] -7 )&& y>=( 7 +bomb_y_t[1]) && y  <= (bomb_y_b[1] - 2 ))? 1 : 0;
assign bomb_on1[11] = (x>= ( 22 + bomb_x_l[1]) && x <= (bomb_x_r[1] -5 )&& y>=( 9 +bomb_y_t[1]) && y  <= (bomb_y_b[1] - 4 ))? 1 : 0;
assign bomb_on1[12] = (x>= ( 24 + bomb_x_l[1]) && x <= (bomb_x_r[1] -3 )&& y>=( 11 +bomb_y_t[1]) && y  <= (bomb_y_b[1] - 6 ))? 1 : 0;
assign bomb_on1[13] = (x>= ( 26 + bomb_x_l[1]) && x <= (bomb_x_r[1] -1 )&& y>=( 13 +bomb_y_t[1]) && y  <= (bomb_y_b[1] - 8 ))? 1 : 0;

always @ (posedge clk or posedge rst) begin
    if(rst|game_stop) begin
        bomb_x_reg[1] <= randB1_x + 30;
        bomb_y_reg[1] <= randB1_y + 30;
    end
    else if(refr_tick)begin
        bomb_x_reg[1] <= bomb_x_reg[1] + bomb1_vx_reg;
        bomb_y_reg[1] <= bomb_y_reg[1] + bomb1_vy_reg;
    end
    else if ((shot_x_l >= bomb_x_l[1]) && (shot_x_r <= bomb_x_r[1]) && (shot_y_b <= bomb_y_b[1]) && (shot_y_t >= bomb_y_t[1])) begin
            bomb_x_reg[1] <= 650;
            bomb_y_reg[1] <= 0;
            bomb_hit[1]= 1;
    end 
end
//--------------------------------------------------------------------------------------------------------------------------------//
assign bomb_x_l[2] = bomb_x_reg[2];
assign bomb_x_r[2] = bomb_x_reg[2] + BOMB_SIZE - 1;
assign bomb_y_t[2] = bomb_y_reg[2];
assign bomb_y_b[2] = bomb_y_reg[2] + BOMB_SIZE -1;

//color
assign bomb_on2[0] = (x>= ( 16 + bomb_x_l[2]) && x <= (bomb_x_r[2] -10  )&& y>=bomb_y_t[2] && y  <= (bomb_y_b[2] - 28))? 1 : 0;
assign bomb_on2[1] = (x>= ( 15 + bomb_x_l[2]) && x <= (bomb_x_r[2] -13  )&& y>=(1 +bomb_y_t[2]) && y  <= (bomb_y_b[2] - 27))? 1 : 0;
assign bomb_on2[2] = (x>= ( 14 + bomb_x_l[2]) && x <= (bomb_x_r[2] -14  )&& y>=(2 +bomb_y_t[2]) && y  <= (bomb_y_b[2] - 25))? 1 : 0;
assign bomb_on2[3] = (x>= ( 1 + bomb_x_l[2]) && x <= (bomb_x_r[2] -26 )&& y>=(13 +bomb_y_t[2]) && y  <= (bomb_y_b[2] - 8))? 1 : 0;
assign bomb_on2[4] = (x>= ( 3 + bomb_x_l[2]) && x <= (bomb_x_r[2] -24 )&& y>=( 11 +bomb_y_t[2]) && y  <= (bomb_y_b[2] - 6 ))? 1 : 0;
assign bomb_on2[5] = (x>= ( 5 + bomb_x_l[2]) && x <= (bomb_x_r[2] -22 )&& y>=( 9 +bomb_y_t[2]) && y  <= (bomb_y_b[2] - 4 ))? 1 : 0;
assign bomb_on2[6] = (x>= ( 7 + bomb_x_l[2]) && x <= (bomb_x_r[2] -20 )&& y>=( 7 +bomb_y_t[2]) && y  <= (bomb_y_b[2] -2 ))? 1 : 0;
assign bomb_on2[7] = (x>= ( 9 + bomb_x_l[2]) && x <= (bomb_x_r[2] -17 )&& y>=( 5 +bomb_y_t[2]) && y  <= (bomb_y_b[2]  ))? 1 : 0;
assign bomb_on2[8] = (x>= ( 12 + bomb_x_l[2]) && x <= (bomb_x_r[2] -13 )&& y>=( 5 +bomb_y_t[2]) && y  <= (bomb_y_b[2]  ))? 1 : 0;
assign bomb_on2[9] = (x>= ( 16 + bomb_x_l[2]) && x <= (bomb_x_r[2] -9 )&& y>=( 5 +bomb_y_t[2]) && y  <= (bomb_y_b[2]  ))? 1 : 0;
assign bomb_on2[10] = (x>= ( 20 + bomb_x_l[2]) && x <= (bomb_x_r[2] -7 )&& y>=( 7 +bomb_y_t[2]) && y  <= (bomb_y_b[2] - 2 ))? 1 : 0;
assign bomb_on2[11] = (x>= ( 22 + bomb_x_l[2]) && x <= (bomb_x_r[2] -5 )&& y>=( 9 +bomb_y_t[2]) && y  <= (bomb_y_b[2] - 4 ))? 1 : 0;
assign bomb_on2[12] = (x>= ( 24 + bomb_x_l[2]) && x <= (bomb_x_r[2] -3 )&& y>=( 11 +bomb_y_t[2]) && y  <= (bomb_y_b[2] - 6 ))? 1 : 0;
assign bomb_on2[13] = (x>= ( 26 + bomb_x_l[2]) && x <= (bomb_x_r[2] -1 )&& y>=( 13 +bomb_y_t[2]) && y  <= (bomb_y_b[2] - 8 ))? 1 : 0;

always @ (posedge clk or posedge rst) begin
    if(rst|game_stop) begin
        bomb_x_reg[2] <= randB2_x + 30;
        bomb_y_reg[2] <= randB2_y + 30;
    end
    else if(refr_tick)begin
        bomb_x_reg[2] <= bomb_x_reg[2] + bomb1_vx_reg;
        bomb_y_reg[2] <= bomb_y_reg[2] + bomb1_vy_reg;
    end
    else if ((shot_x_l >= bomb_x_l[2]) && (shot_x_r <= bomb_x_r[2]) && (shot_y_b <= bomb_y_b[2]) && (shot_y_t >= bomb_y_t[2])) begin
            bomb_x_reg[2] <= 650;
            bomb_y_reg[2] <= 0;
            bomb_hit[2]= 1;
    end 
end
always @ (posedge clk or posedge rst) begin
    if(rst|game_stop) begin
        bomb1_vy_reg <= 0; 
        bomb1_vx_reg <= 0;
    end else begin
                bomb1_vy_reg <= 0 ; 
                bomb1_vx_reg <= 0;
            end
    
end

reg [9:0] obs_x_reg [23:0], obs_y_reg [23:0];
reg [9:0] obs1_vy_reg, obs1_vx_reg , obs2_vx_reg ,obs2_vy_reg, obs3_vy_reg, obs3_vx_reg, obs4_vy_reg, obs4_vx_reg; //velocity
wire [9:0] obs_x_l[23:0], obs_x_r[23:0], obs_y_t[23:0], obs_y_b[23:0];
wire obs_on0[14:0], obs_on1[14:0], obs_on2[14:0], obs_on3[14:0], obs_on4[14:0], obs_on5[14:0]; //1stage
reg obs_hit[23:0]; //1stage clear

              
//------------------------------------------------------------------------------------------------------------------------------------------//
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
   if((rst | game_stop) && stage_reg == STAGE1) begin
        obs_x_reg[0] <= rand0 + 30; 
        obs_y_reg[0] <= rand10 + 30;
        obs_hit[0] <= 0;
   end 
    else if(refr_tick) begin
         obs_x_reg[0] <= obs_x_reg[0] + obs1_vx_reg; 
         obs_y_reg[0] <= obs_y_reg[0] + obs1_vy_reg;
         obs_hit[0] <= 0;
    end
    else if ((shot_x_l >= obs_x_l[0]) && (shot_x_r <= obs_x_r[0]) && (shot_y_b <= obs_y_b[0]) && (shot_y_t >= obs_y_t[0]/2)) begin
        obs_x_reg[0] <= 650;
        obs_y_reg[0] <= 0;
        obs_hit[0] <= 1;
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
    if((rst | game_stop) && stage_reg == STAGE1) begin
        obs_x_reg[1] <= rand1+ 30; 
        obs_y_reg[1] <= rand11+ 30; 
        obs_hit[1] <= 0;
    end    
    else if (refr_tick) begin
        obs_x_reg[1] <= obs_x_reg[1] + obs1_vx_reg; 
        obs_y_reg[1] <= obs_y_reg[1] + obs1_vy_reg;
        obs_hit[1] <= 0;
    end
     else if ((shot_x_l >= obs_x_l[1]) && (shot_x_r <= obs_x_r[1]) && (shot_y_b <= obs_y_b[1]) && (shot_y_t >= obs_y_t[1]/2)) begin
           obs_x_reg[1] <= 650;
           obs_y_reg[1] <= 0;
           obs_hit[1] <= 1;
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
assign obs_on2[3] = (x>= ( 7 + obs_x_l[2]) && x <= (obs_x_r[2] - 18 )&& y>= ( 6 + obs_y_t[2]) && y  <= (obs_y_b[2] - 20))? 1 : 0;
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
    if((rst | game_stop) && stage_reg == STAGE1) begin
        obs_x_reg[2] <= rand2+ 30; 
        obs_y_reg[2] <= rand12+ 30; 
        obs_hit[2] <= 0;
    end    
    else if (refr_tick) begin
        obs_x_reg[2] <= obs_x_reg[2] + obs1_vx_reg; 
        obs_y_reg[2] <= obs_y_reg[2] + obs1_vy_reg;
        obs_hit[2] <= 0;
    end
     else if ((shot_x_l >= obs_x_l[2]) && (shot_x_r <= obs_x_r[2]) && (shot_y_b <= obs_y_b[2]) && (shot_y_t >= obs_y_t[2]/2)) begin
           obs_x_reg[2] <= 650;
           obs_y_reg[2] <= 0;
           obs_hit[2] <= 1;
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
    if((rst | game_stop) && stage_reg == STAGE1) begin
        obs_x_reg[3] <= rand3+ 30; 
        obs_y_reg[3] <= rand13+ 30;
        obs_hit[3] <= 0; 
    end    
    else if (refr_tick) begin
        obs_x_reg[3] <= obs_x_reg[3] + obs1_vx_reg; 
        obs_y_reg[3] <= obs_y_reg[3] + obs1_vy_reg;
        obs_hit[3] <= 0;
    end
     else if ((shot_x_l >= obs_x_l[3]) && (shot_x_r <= obs_x_r[3]) && (shot_y_b <= obs_y_b[3]) && (shot_y_t >= obs_y_t[3]/2)) begin
           obs_x_reg[3] <= 650;
           obs_y_reg[3] <= 0;
           obs_hit[3] <= 1;
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
    if((rst | game_stop) && stage_reg == STAGE1) begin
        obs_x_reg[4] <= rand4+ 30; 
        obs_y_reg[4] <= rand14+ 30; 
        obs_hit[4] <= 0;
    end    
    else if (refr_tick) begin
        obs_x_reg[4] <= obs_x_reg[4] + obs1_vx_reg; 
        obs_y_reg[4] <= obs_y_reg[4] + obs1_vy_reg;
        obs_hit[4] <= 0;
    end
     else if ((shot_x_l >= obs_x_l[4]) && (shot_x_r <= obs_x_r[4]) && (shot_y_b <= obs_y_b[4]) && (shot_y_t >= obs_y_t[4]/2)) begin
           obs_x_reg[4] <= 650;
           obs_y_reg[4] <= 0;
           obs_hit[4] <= 1;
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
    if((rst | game_stop) && stage_reg == STAGE1) begin
        obs_x_reg[5] <= rand5+ 30; 
        obs_y_reg[5] <= rand15+ 30; 
        obs_hit[5] <= 0;
    end    
    else if (refr_tick) begin
        obs_x_reg[5] <= obs_x_reg[5] + obs1_vx_reg; 
        obs_y_reg[5] <= obs_y_reg[5] + obs1_vy_reg;
        obs_hit[5] <= 0;      
    end
     else if ((shot_x_l >= obs_x_l[5]) && (shot_x_r <= obs_x_r[5]) && (shot_y_b <= obs_y_b[5]) && (shot_y_t >= obs_y_t[5]/2)) begin
           obs_x_reg[5] <= 650;
           obs_y_reg[5] <= 0;
           obs_hit[5] <= 1;
       end
end

//velocity
always @ (posedge clk or posedge rst) begin
    if((rst | game_stop) && stage_reg == STAGE1) begin
        obs1_vy_reg <= 0;
        obs1_vx_reg <= 0; //left
    end else if(refr_tick) begin
        obs1_vy_reg <= 0;
        obs1_vx_reg <= 0; //left
         
    end
end

/*---------------------------------------------------------*/
// if hit_obs, score ++
/*---------------------------------------------------------*/

reg d_inc, d_clr;
wire hit_obs, hit_bomb;
wire hit_score;
reg [3:0] dig0, dig1;

assign reach_obs = ((obs_hit[0] == 1) || (obs_hit[1] ==1) || (obs_hit[2] ==1) || (obs_hit[3] ==1) || (obs_hit[4] == 1 ) || (obs_hit[5] == 1))? 1 : 0; //hit obs
assign reach_bomb = ((bomb_hit[0] == 1) || (bomb_hit[1] ==1) || (bomb_hit[2] ==1))? 1 : 0; //hit bomb

assign hit_obs = (reach_obs==1 && refr_tick == 1)? 1 : 0; //hit obs
assign hit_bomb = (reach_bomb ==1 && refr_tick == 1)? 1 : 0; //hit bomb
assign hit_score = ((hit_obs == 1 && refr_tick ==1))? 1 : 0; //hit socre

always @ (posedge clk or posedge rst) begin
    if(rst | d_clr) begin
        dig1 <= 0;
        dig0 <= 0;
    end 
    else if (hit_score) begin //hit, score ++
        if(dig0==9) begin 
            dig0 <= 0;
            if (dig1==9) dig1 <= 0;
            else dig1 <= dig1+1; //10
        end 
        else dig0 <= dig0+1; //1
    end
end

/*---------------------------------------------------------*/
// finite state machine for game control
/*---------------------------------------------------------*/

 always @ * begin
        game_stop = 1; 
        d_clr = 0;
        d_inc = 0;
        life_next = life_reg;
        stage_next = stage_reg;
        game_over = 0;    
        case(FUNC)
          STAGE1:
             case(state_reg)
               NEWGAME: begin
                d_clr = 1;
                if(key[4] == 1) begin
                  state_next = PLAY;
                  life_next = 2'b11;
                end
                end
               PLAY: begin
                game_stop = 0;
                d_inc = hit_obs;
                if(hit_bomb) begin
                   if(life_reg==2'b00)
                    state_next = OVER;
                   else begin
                    state_next = NEWGUN;
                    life_next = life_reg - 1'b1;
                   end
                end else if(hit_obs)
                   state_next = PLAY;
                   if((obs_hit[0] == 1) && (obs_hit[1] ==1) && (obs_hit[2] ==1) && (obs_hit[3] ==1) && (obs_hit[4] == 1 ) && (obs_hit[5] == 1))
                    stage_next = STAGE2;
              end
              NEWGUN: 
                if(key[4] == 1) state_next = PLAY;
                else state_next = NEWGUN;
              OVER: begin
                 if(key[4] == 1) begin
                   state_next = NEWGAME;
                 end else begin
                   state_next = OVER;
                 end
                 game_over = 1;
              end
              default:
                 state_next = NEWGAME;
             endcase
            STAGE2: 
                case(state_reg)
                    NEWGAME: begin
                        d_clr = 1;
                        if(key[4] == 1) begin
                            state_next = PLAY;
                            life_next = 2'b11;
                        end
                    end
                    PLAY: begin
                        game_stop = 0;
                        d_inc = hit_obs;
                        if(hit_bomb) begin
                            if(life_reg==2'b00)
                                state_next = OVER;
                            else begin
                                state_next = NEWGUN;
                                life_next = life_reg - 1'b1;
                            end
                        end else if(hit_obs)
                         state_next = PLAY;
                         if((obs_hit[6] == 1) && (obs_hit[7] ==1) && (obs_hit[8] ==1) && (obs_hit[8] ==1) && (obs_hit[9] == 1 ) && (obs_hit[10] == 1) && (obs_hit[11] == 1))
                            stage_next = STAGE3;
                  end
                  NEWGUN: 
                    if(key[4] == 1) state_next = PLAY;
                    else state_next = NEWGUN;
                  OVER: begin
                    if(key[4] == 1) begin
                        state_next = NEWGAME;
                    end else begin
                        state_next = OVER;
                    end
                        game_over = 1;
                  end
                  default:
                    state_next = NEWGAME;
                endcase 
            STAGE3: 
            case(state_reg)
                NEWGAME: begin
                    d_clr = 1;
                    if(key[4] == 1) begin
                        state_next = PLAY;
                        life_next = 2'b11;
                    end
                end
                PLAY: begin
                    game_stop = 0;
                    d_inc = hit_obs;
                    if(hit_bomb) begin
                        if(life_reg==2'b00)
                            state_next = OVER;
                        else begin
                            state_next = NEWGUN;
                            life_next = life_reg - 1'b1;
                        end
                    end else if(hit_obs)
                     state_next = PLAY;
                    //else if((obs_hit3[0] == 1) && (obs_hit3[1] ==1) && (obs_hit3[2] ==1) && (obs_hit3[3] ==1) && (obs_hit3[4] == 1 ) && (obs_hit3[5] == 1))
                        stage_next = STAGE4;
              end
              NEWGUN: 
                if(key[4] == 1) state_next = PLAY;
                else state_next = NEWGUN;
              OVER: begin
                if(key[4] == 1) begin
                    state_next = NEWGAME;
                end else begin
                    state_next = OVER;
                end
                    game_over = 1;
              end
              default:
                state_next = NEWGAME;
            endcase 
            STAGE4:
        case(state_reg)
            NEWGAME: begin
                d_clr = 1;
                if(key[4] == 1) begin
                    state_next = PLAY;
                    life_next = 2'b11;
                end
            end
            PLAY: begin
                game_stop = 0;
                d_inc = hit_obs;
                if(hit_bomb) begin
                    if(life_reg==2'b00)
                        state_next = OVER;
                    else begin
                        state_next = NEWGUN;
                        life_next = life_reg - 1'b1;
                    end
                end else if(hit_obs)
                 state_next = PLAY;
                //else if((obs_hit4[0] == 1) && (obs_hit4[1] ==1) && (obs_hit4[2] ==1) && (obs_hit4[3] ==1) && (obs_hit4[4] == 1 ) && (obs_hit4[5] == 1))
                    state_next = OVER;
          end
          NEWGUN: 
            if(key[4] == 1) state_next = PLAY;
            else state_next = NEWGUN;
          OVER: begin
            if(key[4] == 1) begin
                state_next = NEWGAME;
            end else begin
                state_next = OVER;
            end
                game_over = 1;
          end
          default:
            state_next = NEWGAME;
        endcase 
        default:
            stage_next = STAGE1;
        endcase
    end
    
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            stage_reg <= STAGE1;
            state_reg <= NEWGAME; 
            life_reg <= 0;
        end
        else begin
        stage_reg <= stage_next;
        state_reg <= state_next; 
        life_reg <= life_next;
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
assign score_y_t = 5; 
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
assign life_y_t = 5; 
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
assign stage_y_t = 5; 
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
             (shot_on[0]) ? 3'b100 : // red shot
             (shot_on[1]) ? 3'b100 : // red shot
             (shot_on[2]) ? 3'b100 : // red shot
             (shot_on[3]) ? 3'b100 : // red shot
             (shot_on[4]) ? 3'b100 : // red shot
             (gun_on)? 3'b111 : //white gun
             
             (bomb_on0[0])? 3'b100 : // red bomb
             (bomb_on0[1])? 3'b100 :
             (bomb_on0[2])? 3'b100 :
             (bomb_on0[3])? 3'b100 :
             (bomb_on0[4])? 3'b100 :
             (bomb_on0[5])? 3'b100 :
             (bomb_on0[6])? 3'b100 :
             (bomb_on0[7])? 3'b100 :
             (bomb_on0[8])? 3'b100 :
             (bomb_on0[9])? 3'b100 :
             (bomb_on0[10])? 3'b100 :
             (bomb_on0[11])? 3'b100 :
             (bomb_on0[12])? 3'b100 :
             (bomb_on0[13])? 3'b100 :
             
             (bomb_on1[0])? 3'b100 : // red bomb
             (bomb_on1[1])? 3'b100 :
             (bomb_on1[2])? 3'b100 :
             (bomb_on1[3])? 3'b100 :
             (bomb_on1[4])? 3'b100 :
             (bomb_on1[5])? 3'b100 :
             (bomb_on1[6])? 3'b100 :
             (bomb_on1[7])? 3'b100 :
             (bomb_on1[8])? 3'b100 :
             (bomb_on1[9])? 3'b100 :
             (bomb_on1[10])? 3'b100 :
             (bomb_on1[11])? 3'b100 :
             (bomb_on1[12])? 3'b100 :
             (bomb_on1[13])? 3'b100 :
             
             (bomb_on2[0])? 3'b100 : // red bomb
             (bomb_on2[1])? 3'b100 :
             (bomb_on2[2])? 3'b100 :
             (bomb_on2[3])? 3'b100 :
             (bomb_on2[4])? 3'b100 :
             (bomb_on2[5])? 3'b100 :
             (bomb_on2[6])? 3'b100 :
             (bomb_on2[7])? 3'b100 :
             (bomb_on2[8])? 3'b100 :
             (bomb_on2[9])? 3'b100 :
             (bomb_on2[10])? 3'b100 :
             (bomb_on2[11])? 3'b100 :
             (bomb_on2[12])? 3'b100 :
             (bomb_on2[13])? 3'b100 :                          
             
            
             (obs_on0[0]) ? 3'b100 : //1stage
             (obs_on0[1]) ? 3'b100 :
             (obs_on0[2]) ? 3'b100 :
             (obs_on0[3]) ? 3'b100 :
             (obs_on0[4]) ? 3'b100 :
             (obs_on0[5]) ? 3'b100 :
             (obs_on0[6]) ? 3'b100 :
             (obs_on0[7]) ? 3'b100 :
             (obs_on0[8]) ? 3'b100 :
             (obs_on0[9]) ? 3'b100 :
             (obs_on0[10]) ? 3'b100 :
             (obs_on0[11]) ? 3'b100 :
             (obs_on0[12]) ? 3'b100 :
             (obs_on0[13]) ? 3'b100 :
             (obs_on0[14]) ? 3'b100 :
             (obs_on1[0]) ? 3'b100 :
             (obs_on1[1]) ? 3'b100 :
             (obs_on1[2]) ? 3'b100 :
             (obs_on1[3]) ? 3'b100 :
             (obs_on1[4]) ? 3'b100 :
             (obs_on1[5]) ? 3'b100 :
             (obs_on1[6]) ? 3'b100 :
             (obs_on1[7]) ? 3'b100 :
             (obs_on1[8]) ? 3'b100 :
             (obs_on1[9]) ? 3'b100 :
             (obs_on1[10]) ? 3'b100 :
             (obs_on1[11]) ? 3'b100 :
             (obs_on1[12]) ? 3'b100 :
             (obs_on1[13]) ? 3'b100 :
             (obs_on1[14]) ? 3'b100 :
             (obs_on2[0]) ? 3'b100 :
             (obs_on2[1]) ? 3'b100 :
             (obs_on2[2]) ? 3'b100 :
             (obs_on2[3]) ? 3'b100 :
             (obs_on2[4]) ? 3'b100 :
             (obs_on2[5]) ? 3'b100 :
             (obs_on2[6]) ? 3'b100 :
             (obs_on2[7]) ? 3'b100 :
             (obs_on2[8]) ? 3'b100 :
             (obs_on2[9]) ? 3'b100 :
             (obs_on2[10]) ? 3'b100 :
             (obs_on2[11]) ? 3'b100 :
             (obs_on2[12]) ? 3'b100 :
             (obs_on2[13]) ? 3'b100 :
             (obs_on2[14]) ? 3'b100 :
             (obs_on3[0]) ? 3'b100 :
             (obs_on3[1]) ? 3'b100 :
             (obs_on3[2]) ? 3'b100 :
             (obs_on3[3]) ? 3'b100 :
             (obs_on3[4]) ? 3'b100 :
             (obs_on3[5]) ? 3'b100 :
             (obs_on3[6]) ? 3'b100 :
             (obs_on3[7]) ? 3'b100 :
             (obs_on3[8]) ? 3'b100 :
             (obs_on3[9]) ? 3'b100 :
             (obs_on3[10]) ? 3'b100 :
             (obs_on3[11]) ? 3'b100 :
             (obs_on3[12]) ? 3'b100 :
             (obs_on3[13]) ? 3'b100 :
             (obs_on3[14]) ? 3'b100 :
             (obs_on4[0]) ? 3'b100 :
             (obs_on4[1]) ? 3'b100 :
             (obs_on4[2]) ? 3'b100 :
             (obs_on4[3]) ? 3'b100 :
             (obs_on4[4]) ? 3'b100 :
             (obs_on4[5]) ? 3'b100 :
             (obs_on4[6]) ? 3'b100 :
             (obs_on4[7]) ? 3'b100 :
             (obs_on4[8]) ? 3'b100 :
             (obs_on4[9]) ? 3'b100 :
             (obs_on4[10]) ? 3'b100 :
             (obs_on4[11]) ? 3'b100 :
             (obs_on4[12]) ? 3'b100 :
             (obs_on4[13]) ? 3'b100 :
             (obs_on4[14]) ? 3'b100 :
             (obs_on5[0]) ? 3'b100 :     
             (obs_on5[1]) ? 3'b100 :
             (obs_on5[2]) ? 3'b100 :
             (obs_on5[3]) ? 3'b100 :
             (obs_on5[4]) ? 3'b100 :
             (obs_on5[5]) ? 3'b100 :
             (obs_on5[6]) ? 3'b100 :
             (obs_on5[7]) ? 3'b100 :
             (obs_on5[8]) ? 3'b100 :
             (obs_on5[9]) ? 3'b100 :
             (obs_on5[10]) ? 3'b100 :
             (obs_on5[11]) ? 3'b100 :
             (obs_on5[12]) ? 3'b100 :
             (obs_on5[13]) ? 3'b100 :
             (obs_on5[14]) ? 3'b100 :
           
                                  
             3'b000; //black background
             
endmodule