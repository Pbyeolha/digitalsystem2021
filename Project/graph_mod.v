module graph_mod (clk, rst, x, y, key, key_pulse, rgb);
input clk, rst;
input [9:0] x, y;
input [4:0] key, key_pulse; 
output [2:0] rgb;

// screen size
parameter MAX_X = 640; 
parameter MAX_Y = 480;  
// gun position
parameter GUN_Y_B = 480; 
parameter GUN_Y_T = 420;
// gun size, velocity
parameter GUN_X_SIZE = 60; 
parameter GUN_V = 4;
// shot size, velocity
parameter SHOT_SIZE = 9;
parameter SHOT_V = 5;
// obs size, velocity
parameter OBS_SIZE = 30;
parameter OBS_V = 1;

//bomb size, velocity
parameter BOMB_SIZE = 30;
parameter BOMB_V = 5;
//FSM
parameter NEWGAME=2'b00, PLAY=2'b01, NEWGUN=2'b10, OVER=2'b11;
parameter STAGE0 = 3'b000, STAGE1 = 3'b001, STAGE2 = 3'b010, STAGE3 = 3'b011, STAGE4 = 3'b100;

wire refr_tick; 
wire [9:0] reach_obs, reach_bomb;
wire reach_top, reach_bottom, wall_left_3_1, wall_left_3_2, wall_left_3_3, wall_left_3_4, wall_left_3_5, wall_left_3_6, 
     wall_right_3_1, wall_right_3_2, wall_right_3_3, wall_right_3_4, wall_right_3_5, wall_right_3_6;
wire reach_top_1, reach_top_2, reach_top_3, reach_top_4, reach_top_5, reach_top_6;
wire reach_bottom_1, reach_bottom_2, reach_bottom_3, reach_bottom_4, reach_bottom_5, reach_bottom_6;
wire wall_left_4_1, wall_left_4_2, wall_left_4_3, wall_left_4_4, wall_left_4_5, wall_left_4_6;
wire wall_right_4_1, wall_right_4_2, wall_right_4_3, wall_right_4_4, wall_right_4_5, wall_right_4_6;

reg game_stop, game_over, game_clear;  
reg stage1, stage2, stage3, stage4;

//refrernce tick 
assign refr_tick = (y==MAX_Y-1 && x==MAX_X-1)? 1 : 0; // frame, 1sec

/*---------------------------------------------------------*/
// gun 
/*---------------------------------------------------------*/
wire [9:0] gun_x_r, gun_x_l; 
reg [9:0] gun_x_reg; 
wire gun_on[2:0];
assign gun_x_l = gun_x_reg; //left
assign gun_x_r = gun_x_l + GUN_X_SIZE - 1; //right

//color
assign gun_on[0] = (x>= (22 + gun_x_l) && x <= (gun_x_r - 23)&& y>=( 6+GUN_Y_T) && y  <= (GUN_Y_B - 38))? 1 : 0;
assign gun_on[1] = (x>= (14 + gun_x_l) && x <= (gun_x_r - 15 )&& y>=(22+GUN_Y_T) && y  <= (GUN_Y_B - 23))? 1 : 0;
assign gun_on[2] = (x>= ( gun_x_l) && x <= (gun_x_r )&& y>=( 37+ GUN_Y_T) && y  <= GUN_Y_B )? 1 : 0;

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
wire shot_on[6:0]; 
assign shot_x_l = shot_x_reg;
assign shot_x_r = shot_x_reg + SHOT_SIZE - 1;
assign shot_y_t = shot_y_reg;
assign shot_y_b = shot_y_reg + SHOT_SIZE -1;

//color
assign shot_on[0] = (x>= (3 + shot_x_l) && x <= (shot_x_r - 3)&& y>=( shot_y_t) && y  <= (shot_y_b - 7))? 1 : 0;
assign shot_on[1] = (x>= (2 + shot_x_l) && x <= (shot_x_r - 2 )&& y>=(1+shot_y_t) && y  <= (shot_y_b - 6))? 1 : 0;
assign shot_on[2] = (x>= (1 + shot_x_l) && x <= (shot_x_r -1)&& y>=(2+ shot_y_t) && y  <= shot_y_b -5)? 1 : 0;
assign shot_on[3] = (x>= ( shot_x_l) && x <= (shot_x_r  )&& y>=(3+shot_y_t) && y  <= (shot_y_b - 3))? 1 : 0;
assign shot_on[4] = (x>= (1 + shot_x_l) && x <= (shot_x_r - 1 )&& y>=(5+shot_y_t) && y  <= (shot_y_b - 2))? 1 : 0;
assign shot_on[5] = (x>= (2 + shot_x_l) && x <= (shot_x_r - 2 )&& y>=(6+shot_y_t) && y  <= (shot_y_b -1))? 1 : 0;
assign shot_on[6] = (x>= (3 + shot_x_l) && x <= (shot_x_r - 3 )&& y>=(7+shot_y_t) && y  <= (shot_y_b ))? 1 : 0;


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
//////////////////////////////////2stage_obs random///////////////////////////////////////////
reg[19:0] s2; wire[8:0] rand16, rand17, rand18, rand19, rand20, rand21;
random2 u2(rst, clk, s2, rand16, rand17, rand18, rand19, rand20, rand21); //2stage_x
//////////////////////////////////3stage_obs random///////////////////////////////////////////

//////////////////////////////////4stage_obs random///////////////////////////////////////////

//////////////////////////////////1stage_bomb random///////////////////////////////////////////
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
reg bomb_hit[11:0], bomb_score[11:0];
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
        bomb_score[0] = 0;
    end
    else if(refr_tick)begin
        bomb_x_reg[0] <= bomb_x_reg[0] + bomb1_vx_reg;
        bomb_y_reg[0] <= bomb_y_reg[0] + bomb1_vy_reg;
        bomb_score[0] = 0;
    end
    else if ((shot_x_l >= bomb_x_l[0]) && (shot_x_r <= bomb_x_r[0]) && (shot_y_b <= bomb_y_b[0]) && (shot_y_t >= bomb_y_t[0])) begin
            bomb_x_reg[0] <= 650;
            bomb_y_reg[0] <= 0;
            bomb_hit[0] = 1;
            bomb_score[0] = 1;
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
        bomb_score[1] = 0;
    end
    else if(refr_tick)begin
        bomb_x_reg[1] <= bomb_x_reg[1] + bomb2_vx_reg;
        bomb_y_reg[1] <= bomb_y_reg[1] + bomb2_vy_reg;
        bomb_score[1] = 0;
    end
    else if ((shot_x_l >= bomb_x_l[1]) && (shot_x_r <= bomb_x_r[1]) && (shot_y_b <= bomb_y_b[1]) && (shot_y_t >= bomb_y_t[1])) begin
            bomb_x_reg[1] <= 650;
            bomb_y_reg[1] <= 0;
            bomb_hit[1] = 1;
            bomb_score[1] = 1;
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
        bomb_score[2] = 0;
    end
    else if(refr_tick)begin
        bomb_x_reg[2] <= bomb_x_reg[2] + bomb3_vx_reg;
        bomb_y_reg[2] <= bomb_y_reg[2] + bomb3_vy_reg;
        bomb_score[2] = 0;
    end
    else if ((shot_x_l >= bomb_x_l[2]) && (shot_x_r <= bomb_x_r[2]) && (shot_y_b <= bomb_y_b[2]) && (shot_y_t >= bomb_y_t[2])) begin
            bomb_x_reg[2] <= 650;
            bomb_y_reg[2] <= 0;
            bomb_hit[2] = 1;
            bomb_score[2] = 1;
    end 
    
end
always @ (posedge clk or posedge rst) begin
    if(rst|game_stop) begin
        bomb1_vy_reg <= 0; 
        bomb1_vx_reg <= BOMB_V;
    end else if(bomb_hit[0] == 1) begin
        bomb1_vy_reg <= 0;
        bomb1_vx_reg <= 0;
    end 
    else begin
        bomb1_vy_reg <= 0 ; 
        bomb1_vx_reg <= BOMB_V;
   end
end

always @ (posedge clk or posedge rst) begin
    if(rst|game_stop) begin
        bomb2_vy_reg <= 0; 
        bomb2_vx_reg <= BOMB_V;
    end else if(bomb_hit[1] == 1) begin
        bomb2_vy_reg <= 0;
        bomb2_vx_reg <= 0;
    end else begin
        bomb2_vy_reg <= 0 ; 
        bomb2_vx_reg <= BOMB_V;
   end
end

always @ (posedge clk or posedge rst) begin
    if(rst|game_stop) begin
        bomb3_vy_reg <= 0; 
        bomb3_vx_reg <= BOMB_V;
    end else if(bomb_hit[2] == 1) begin
        bomb3_vy_reg <= 0;
        bomb3_vx_reg <= 0;
    end else begin
        bomb3_vy_reg <= 0 ; 
        bomb3_vx_reg <= BOMB_V;
   end
end
/*---------------------------------------------------------*/
// obs - 1stage / 0~5
/*---------------------------------------------------------*/
reg [9:0] obs_x_reg [23:0], obs_y_reg [23:0];
reg [9:0] obs1_vy_reg, obs1_vx_reg , obs2_vx_reg ,obs2_vy_reg; //velocity
reg[9:0] obs3_vx_reg[5:0], obs3_vy_reg;
reg[9:0] obs4_vx_reg[5:0], obs4_vy_reg[5:0];
wire [9:0] obs_x_l[23:0], obs_x_r[23:0], obs_y_t[23:0], obs_y_b[23:0];
wire obs_on0[14:0], obs_on1[14:0], obs_on2[14:0], obs_on3[14:0], obs_on4[14:0], obs_on5[14:0], //1stage
        obs_on6[14:0], obs_on7[14:0], obs_on8[14:0], obs_on9[14:0], obs_on10[14:0], obs_on11[14:0], //2stage
        obs_on12[21:0], obs_on13[21:0], obs_on14[21:0], obs_on15[21:0], obs_on16[21:0], obs_on17[21:0], //3stage
        obs_on18[20:0], obs_on19[20:0], obs_on20[20:0], obs_on21[20:0], obs_on22[20:0], obs_on23[20:0]; //4stage
reg obs_hit[23:0]; //1stage clear
reg obs_score[23:0];
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
 if(stage1 == 1) begin
   if(rst | game_stop) begin
        obs_x_reg[0] <= rand0 + 30; 
        obs_y_reg[0] <= rand10 + 30;
        obs_score[0] <= 0;
   end 
    else if(refr_tick == 1) begin
         obs_x_reg[0] <= obs_x_reg[0] + obs1_vx_reg; 
         obs_y_reg[0] <= obs_y_reg[0] + obs1_vy_reg;
         obs_score[0] <= 0;
    end
    else if (((shot_x_l >= obs_x_l[0]) && (shot_x_r <= obs_x_r[0]) && (shot_y_b <= obs_y_b[0]) && (shot_y_t >= obs_y_t[0]))) begin
        obs_x_reg[0] <= 650;
        obs_y_reg[0] <= 0;
        obs_score[0] <= 1;
        obs_hit[0] = 1;
    end
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
 if(stage1 == 1) begin
    if(rst | game_stop) begin
        obs_x_reg[1] <= rand1+ 30; 
        obs_y_reg[1] <= rand11+ 30; 
        obs_score[1] <= 0;
    end    
    else if (refr_tick) begin
        obs_x_reg[1] <= obs_x_reg[1] + obs1_vx_reg; 
        obs_y_reg[1] <= obs_y_reg[1] + obs1_vy_reg;
        obs_score[1] <= 0;
    end
     else if ((shot_x_l >= obs_x_l[1]) && (shot_x_r <= obs_x_r[1]) && (shot_y_b <= obs_y_b[1])) begin
           obs_x_reg[1] <= 650;
           obs_y_reg[1] <= 0;
           obs_score[1] <= 1;
           obs_hit[1] = 1;
       end
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
 if(stage1 == 1) begin
    if(rst | game_stop) begin
        obs_x_reg[2] <= rand2+ 30; 
        obs_y_reg[2] <= rand12+ 30; 
        obs_score[2] <= 0;
    end    
    else if (refr_tick) begin
        obs_x_reg[2] <= obs_x_reg[2] + obs1_vx_reg; 
        obs_y_reg[2] <= obs_y_reg[2] + obs1_vy_reg;
        obs_score[2] <= 0;
    end
     else if ((shot_x_l >= obs_x_l[2]) && (shot_x_r <= obs_x_r[2]) && (shot_y_b <= obs_y_b[2])) begin
           obs_x_reg[2] <= 650;
           obs_y_reg[2] <= 0;
           obs_score[2] <= 1;
           obs_hit[2] = 1;
       end
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
  if(stage1 == 1) begin
    if(rst | game_stop) begin
        obs_x_reg[3] <= rand3+ 30; 
        obs_y_reg[3] <= rand13+ 30; 
        obs_score[3] <= 0; 
    end    
    else if (refr_tick) begin
        obs_x_reg[3] <= obs_x_reg[3] + obs1_vx_reg; 
        obs_y_reg[3] <= obs_y_reg[3] + obs1_vy_reg;
        obs_score[3] <= 0; 
    end
     else if ((shot_x_l >= obs_x_l[3]) && (shot_x_r <= obs_x_r[3]) && (shot_y_b <= obs_y_b[3])) begin
           obs_x_reg[3] <= 650;
           obs_y_reg[3] <= 0;
           obs_score[3] <= 1;
           obs_hit[3] = 1;
       end
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
  if(stage1 == 1) begin
    if(rst | game_stop) begin
        obs_x_reg[4] <= rand4+ 30; 
        obs_y_reg[4] <= rand14+ 30; 
        obs_score[4] <= 0;
    end    
    else if (refr_tick) begin
        obs_x_reg[4] <= obs_x_reg[4] + obs1_vx_reg; 
        obs_y_reg[4] <= obs_y_reg[4] + obs1_vy_reg;
        obs_score[4] <= 0;
    end
     else if ((shot_x_l >= obs_x_l[4]) && (shot_x_r <= obs_x_r[4]) && (shot_y_b <= obs_y_b[4])) begin
           obs_x_reg[4] <= 650;
           obs_y_reg[4] <= 0;
           obs_score[4] <= 1;
           obs_hit[4] = 1;
       end
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
 if(stage1 == 1) begin
    if(rst | game_stop) begin
        obs_x_reg[5] <= rand5+ 30; 
        obs_y_reg[5] <= rand15+ 30; 
        obs_score[5] <= 0;
    end    
    else if (refr_tick) begin
        obs_x_reg[5] <= obs_x_reg[5] + obs1_vx_reg; 
        obs_y_reg[5] <= obs_y_reg[5] + obs1_vy_reg;
        obs_score[5] <= 0;
    end
     else if ((shot_x_l >= obs_x_l[5]) && (shot_x_r <= obs_x_r[5]) && (shot_y_b <= obs_y_b[5])) begin
           obs_x_reg[5] <= 650;
           obs_y_reg[5] <= 0;
           obs_score[5] <= 1;
           obs_hit[5] = 1;
       end
   end
end

//velocity
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs1_vy_reg <= 0;
        obs1_vx_reg <= 0; //left
    end else begin
            obs1_vy_reg <= 0;
            obs1_vx_reg <= 0; //left
         
    end
end
/*---------------------------------------------------------*/
// obs - 2stage / 6~11
/*---------------------------------------------------------*/
assign obs_x_l[6] = obs_x_reg[6]; 
assign obs_x_r[6] = obs_x_l[6] + OBS_SIZE - 1; 
assign obs_y_t[6] = obs_y_reg[6]; 
assign obs_y_b[6] = obs_y_t[6] + OBS_SIZE - 1;

//color
assign obs_on6[0] = (x>= ( 5 + obs_x_l[6]) && x <= (obs_x_r[6] - 6 )&& y >=(2 +obs_y_t[6]) && y  <= (obs_y_b[6] - 21))? 1 : 0;
assign obs_on6[1] = (x>= ( 5 + obs_x_l[6]) && x <= (obs_x_r[6] - 20 )&& y >= (8+obs_y_t[6]) && y  <= (obs_y_b[6] - 18))? 1 : 0;
assign obs_on6[2] = (x>= ( 12+ obs_x_l[6]) && x <= (obs_x_r[6] -13)&& y>= ( 8 + obs_y_t[6]) && y  <= (obs_y_b[6] - 18))? 1 : 0;
assign obs_on6[3] = (x>= ( 19 + obs_x_l[6]) && x <= (obs_x_r[6] - 6 )&& y>= ( 8 + obs_y_t[6]) && y  <= (obs_y_b[6] - 18))? 1 : 0;
assign obs_on6[4] = (x>= ( obs_x_l[6]) && x <= (obs_x_r[6] - 20 )&& y>=( 11 + obs_y_t[6]) && y  <= (obs_y_b[6] - 10))? 1 : 0;
assign obs_on6[5] = (x>= ( 9 + obs_x_l[6]) && x <= (obs_x_r[6] - 10 )&&  y>= ( 11 + obs_y_t[6]) && y  <= (obs_y_b[6] - 15))? 1 : 0;
assign obs_on6[6] = (x>= ( 19+ obs_x_l[6]  ) && x <= (obs_x_r[6])&& y>= ( 11 + obs_y_t[6]) && y  <= (obs_y_b[6] - 10))? 1 : 0;
assign obs_on6[7] = (x>= ( 5 + obs_x_l[6]) && x <= (obs_x_r[6] - 17 )&& y>= ( 19+ obs_y_t[6]) && y  <= (obs_y_b[6] ))? 1 : 0;
assign obs_on6[8] = (x>= ( 12 + obs_x_l[6]) && x <= (obs_x_r[6] - 13 )&& y>= (19 + obs_y_t[6] ) && y  <= (obs_y_b[6] -5))? 1 : 0;
assign obs_on6[9] = (x>= ( 16+  obs_x_l[6]) && x <= (obs_x_r[6]-6 )&& y>= ( 19+ obs_y_t[6]) && y  <= (obs_y_b[6]))? 1 : 0;
reg [9:0] obs_x_rand;
always @ (posedge clk or posedge rst) begin
 if(stage2 == 1) begin
    if(rst | game_stop) begin
        obs_x_reg[6] <= 70; 
        obs_y_reg[6] <= 0; 
        obs_score[6] <= 0;
    end    
    else if(refr_tick) begin
        obs_x_reg[6] <= obs_x_reg[6] + obs2_vx_reg; 
        obs_y_reg[6] <= obs_y_reg[6] + obs2_vy_reg;
        obs_score[6] <= 0;
        end
     else if ((shot_x_l >= obs_x_l[6]) && (shot_x_r <= obs_x_r[6]) && (shot_y_b <= obs_y_b[6])) begin
           obs_x_reg[6] <= 650;
           obs_y_reg[6] <= 0;
           obs_score[6] <= 1;
           obs_hit[6] = 1;
       end
   end
end
//--------------------------------------------------------------------------------------------------------------------------------//
assign obs_x_l[7] = obs_x_reg[7]; 
assign obs_x_r[7] = obs_x_l[7] + OBS_SIZE - 1; 
assign obs_y_t[7] = obs_y_reg[7]; 
assign obs_y_b[7] = obs_y_t[7] + OBS_SIZE - 1;

//color
assign obs_on7[0] = (x>= ( 5 + obs_x_l[7]) && x <= (obs_x_r[7] - 6 )&& y >=(2 + obs_y_t[7]) && y  <= (obs_y_b[7] - 21))? 1 : 0;
assign obs_on7[1] = (x>= ( 5 + obs_x_l[7]) && x <= (obs_x_r[7] - 20 )&& y >=(8+obs_y_t[7]) && y  <= (obs_y_b[7] - 18))? 1 : 0;
assign obs_on7[2] = (x>= ( 12+ obs_x_l[7]) && x <= (obs_x_r[7] -13)&& y>= ( 8 + obs_y_t[7]) && y  <= (obs_y_b[7] - 18))? 1 : 0;
assign obs_on7[3] = (x>= ( 19 + obs_x_l[7]) && x <= (obs_x_r[7] - 6 )&& y>= ( 8 + obs_y_t[7]) && y  <= (obs_y_b[7] - 18))? 1 : 0;
assign obs_on7[4] = (x>= ( obs_x_l[7]) && x <= (obs_x_r[7] - 20 )&& y>=( 11 + obs_y_t[7]) && y  <= (obs_y_b[7] - 10))? 1 : 0;
assign obs_on7[5] = (x>= ( 9 + obs_x_l[7]) && x <= (obs_x_r[7] - 10 )&&  y>= ( 11 + obs_y_t[7]) && y  <= (obs_y_b[7] - 15))? 1 : 0;
assign obs_on7[6] = (x>= ( 19+ obs_x_l[7]  ) && x <= (obs_x_r[7])&& y>= ( 11 + obs_y_t[7]) && y  <= (obs_y_b[7] - 10))? 1 : 0;
assign obs_on7[7] = (x>= ( 5 + obs_x_l[7]) && x <= (obs_x_r[7] - 17 )&& y>= ( 19+ obs_y_t[7]) && y  <= (obs_y_b[7] ))? 1 : 0;
assign obs_on7[8] = (x>= ( 12 + obs_x_l[7]) && x <= (obs_x_r[7] - 13 )&& y>= (19 + obs_y_t[7] ) && y  <= (obs_y_b[7] -5))? 1 : 0;
assign obs_on7[9] = (x>= ( 16+  obs_x_l[7]) && x <= (obs_x_r[7]-6 )&& y>= ( 19+ obs_y_t[7]) && y  <= (obs_y_b[7]))? 1 : 0;

always @ (posedge clk or posedge rst) begin
 if(stage2 == 1) begin
    if(rst | game_stop) begin
        obs_x_reg[7] <= 140; 
        obs_y_reg[7] <= 40; 
        obs_score[7] <= 0;
    end    
    else if (refr_tick) begin
        obs_x_reg[7] <= obs_x_reg[7] + obs2_vx_reg; 
        obs_y_reg[7] <= obs_y_reg[7] + obs2_vy_reg;
        obs_score[7] <= 0;
        end
     else if ((shot_x_l >= obs_x_l[7]) && (shot_x_r <= obs_x_r[7]) && (shot_y_b <= obs_y_b[7])) begin
           obs_x_reg[7] <= 650;
           obs_y_reg[7] <= 0;
           obs_score[7] <= 1;
           obs_hit[7] <= 1;
       end
  end
end
//--------------------------------------------------------------------------------------------------------------------------------//
assign obs_x_l[8] = obs_x_reg[8]; 
assign obs_x_r[8] = obs_x_l[8] + OBS_SIZE - 1; 
assign obs_y_t[8] = obs_y_reg[8]; 
assign obs_y_b[8] = obs_y_t[8] + OBS_SIZE - 1;

//color
assign obs_on8[0] = (x>= ( 5 + obs_x_l[8]) && x <= (obs_x_r[8] - 6 )&& y >=(2 +obs_y_t[8]) && y  <= (obs_y_b[8] - 21))? 1 : 0;
assign obs_on8[1] = (x>= ( 5 + obs_x_l[8]) && x <= (obs_x_r[8] - 20 )&& y >=(8+obs_y_t[8]) && y  <= (obs_y_b[8] - 18))? 1 : 0;
assign obs_on8[2] = (x>= ( 12+ obs_x_l[8]) && x <= (obs_x_r[8] -13)&& y>= ( 8 + obs_y_t[8]) && y  <= (obs_y_b[8] - 18))? 1 : 0;
assign obs_on8[3] = (x>= ( 19 + obs_x_l[8]) && x <= (obs_x_r[8] - 6 )&& y>= ( 8 + obs_y_t[8]) && y  <= (obs_y_b[8] - 18))? 1 : 0;
assign obs_on8[4] = (x>= ( obs_x_l[8]) && x <= (obs_x_r[8] - 20 )&& y>=( 11 + obs_y_t[8]) && y  <= (obs_y_b[8] - 10))? 1 : 0;
assign obs_on8[5] = (x>= ( 9 + obs_x_l[8]) && x <= (obs_x_r[8] - 10 )&&  y>= ( 11 + obs_y_t[8]) && y  <= (obs_y_b[8] - 15))? 1 : 0;
assign obs_on8[6] = (x>= ( 19+ obs_x_l[8]  ) && x <= (obs_x_r[8])&& y>= ( 11 + obs_y_t[8]) && y  <= (obs_y_b[8] - 10))? 1 : 0;
assign obs_on8[7] = (x>= ( 5 + obs_x_l[8]) && x <= (obs_x_r[8] - 17 )&& y>= ( 19+ obs_y_t[8]) && y  <= (obs_y_b[8] ))? 1 : 0;
assign obs_on8[8] = (x>= ( 12 + obs_x_l[8]) && x <= (obs_x_r[8] - 13 )&& y>= (19 + obs_y_t[8] ) && y  <= (obs_y_b[8] -5))? 1 : 0;
assign obs_on8[9] = (x>= ( 16+  obs_x_l[8]) && x <= (obs_x_r[8]-6 )&& y>= ( 19+ obs_y_t[8]) && y  <= (obs_y_b[8]))? 1 : 0;

always @ (posedge clk or posedge rst) begin
 if(stage2 == 1) begin
    if(rst | game_stop) begin
        obs_x_reg[8] <= 210; 
        obs_y_reg[8] <= 20; 
        obs_score[8] <= 0;
    end    
    else if (refr_tick) begin
        obs_x_reg[8] <= obs_x_reg[8] + obs2_vx_reg; 
        obs_y_reg[8] <= obs_y_reg[8] + obs2_vy_reg;
        obs_score[8] <= 0;
        end
     else if ((shot_x_l >= obs_x_l[8]) && (shot_x_r <= obs_x_r[8]) && (shot_y_b <= obs_y_b[8])) begin
           obs_x_reg[8] <= 650;
           obs_y_reg[8] <= 0;
           obs_score[8] <= 1;
           obs_hit[8] = 1;
       end
   end
end
//--------------------------------------------------------------------------------------------------------------------------------//
assign obs_x_l[9] = obs_x_reg[9]; 
assign obs_x_r[9] = obs_x_l[9] + OBS_SIZE - 1; 
assign obs_y_t[9] = obs_y_reg[9]; 
assign obs_y_b[9] = obs_y_t[9] + OBS_SIZE - 1;

//color
assign obs_on9[0] = (x>= ( 5 + obs_x_l[9]) && x <= (obs_x_r[9] - 6 )&& y >=(2 +obs_y_t[9]) && y  <= (obs_y_b[9] - 21))? 1 : 0;
assign obs_on9[1] = (x>= ( 5 + obs_x_l[9]) && x <= (obs_x_r[9] - 20 )&& y >=(8+obs_y_t[9]) && y  <= (obs_y_b[9] - 18))? 1 : 0;
assign obs_on9[2] = (x>= ( 12+ obs_x_l[9]) && x <= (obs_x_r[9] -13)&& y>= ( 8 + obs_y_t[9]) && y  <= (obs_y_b[9] - 18))? 1 : 0;
assign obs_on9[3] = (x>= ( 19 + obs_x_l[9]) && x <= (obs_x_r[9] - 6 )&& y>= ( 8 + obs_y_t[9]) && y  <= (obs_y_b[9] - 18))? 1 : 0;
assign obs_on9[4] = (x>= ( obs_x_l[9]) && x <= (obs_x_r[9] - 20 )&& y>=( 11 + obs_y_t[9]) && y  <= (obs_y_b[9] - 10))? 1 : 0;
assign obs_on9[5] = (x>= ( 9 + obs_x_l[9]) && x <= (obs_x_r[9] - 10 )&&  y>= ( 11 + obs_y_t[9]) && y  <= (obs_y_b[9] - 15))? 1 : 0;
assign obs_on9[6] = (x>= ( 19+ obs_x_l[9]  ) && x <= (obs_x_r[9])&& y>= ( 11 + obs_y_t[9]) && y  <= (obs_y_b[9] - 10))? 1 : 0;
assign obs_on9[7] = (x>= ( 5 + obs_x_l[9]) && x <= (obs_x_r[9] - 17 )&& y>= ( 19+ obs_y_t[9]) && y  <= (obs_y_b[9] ))? 1 : 0;
assign obs_on9[8] = (x>= ( 12 + obs_x_l[9]) && x <= (obs_x_r[9] - 13 )&& y>= (19 + obs_y_t[9] ) && y  <= (obs_y_b[9] -5))? 1 : 0;
assign obs_on9[9] = (x>= ( 16+  obs_x_l[9]) && x <= (obs_x_r[9]-6 )&& y>= ( 19+ obs_y_t[9]) && y  <= (obs_y_b[9]))? 1 : 0;

always @ (posedge clk or posedge rst) begin
 if(stage2 == 1) begin
    if(rst | game_stop) begin
        obs_x_reg[9] <= 330; 
        obs_y_reg[9] <= 110; 
        obs_score[9] <= 0;
    end    
    else if (refr_tick) begin
        obs_x_reg[9] <= obs_x_reg[9] + obs2_vx_reg; 
        obs_y_reg[9] <= obs_y_reg[9] + obs2_vy_reg;
        obs_score[9] <= 0;
        end
     else if ((shot_x_l >= obs_x_l[9]) && (shot_x_r <= obs_x_r[9]) && (shot_y_b <= obs_y_b[9])) begin
           obs_x_reg[9] <= 650;
           obs_y_reg[9] <= 0;
           obs_score[9] <= 1;
           obs_hit[9] = 1;
       end
   end
end
//--------------------------------------------------------------------------------------------------------------------------------//
assign obs_x_l[10] = obs_x_reg[10]; 
assign obs_x_r[10] = obs_x_l[10] + OBS_SIZE - 1; 
assign obs_y_t[10] = obs_y_reg[10]; 
assign obs_y_b[10] = obs_y_t[10] + OBS_SIZE - 1;

//color
assign obs_on10[0] = (x>= ( 5 + obs_x_l[10]) && x <= (obs_x_r[10] - 6 )&& y >=(2 + obs_y_t[10]) && y  <= (obs_y_b[10] - 21))? 1 : 0;
assign obs_on10[1] = (x>= ( 5 + obs_x_l[10]) && x <= (obs_x_r[10] - 20 )&& y >=(8+obs_y_t[10]) && y  <= (obs_y_b[10] - 18))? 1 : 0;
assign obs_on10[2] = (x>= ( 12+ obs_x_l[10]) && x <= (obs_x_r[10] -13)&& y>= ( 8 + obs_y_t[10]) && y  <= (obs_y_b[10] - 18))? 1 : 0;
assign obs_on10[3] = (x>= ( 19 + obs_x_l[10]) && x <= (obs_x_r[10] - 6 )&& y>= ( 8 + obs_y_t[10]) && y  <= (obs_y_b[10] - 18))? 1 : 0;
assign obs_on10[4] = (x>= ( obs_x_l[10]) && x <= (obs_x_r[10] - 20 )&& y>=( 11 + obs_y_t[10]) && y  <= (obs_y_b[10] - 10))? 1 : 0;
assign obs_on10[5] = (x>= ( 9 + obs_x_l[10]) && x <= (obs_x_r[10] - 10 )&&  y>= ( 11 + obs_y_t[10]) && y  <= (obs_y_b[10] - 15))? 1 : 0;
assign obs_on10[6] = (x>= ( 19+ obs_x_l[10]  ) && x <= (obs_x_r[10])&& y>= ( 11 + obs_y_t[10]) && y  <= (obs_y_b[10] - 10))? 1 : 0;
assign obs_on10[7] = (x>= ( 5 + obs_x_l[10]) && x <= (obs_x_r[10] - 17 )&& y>= ( 19+ obs_y_t[10]) && y  <= (obs_y_b[10] ))? 1 : 0;
assign obs_on10[8] = (x>= ( 12 + obs_x_l[10]) && x <= (obs_x_r[10] - 13 )&& y>= (19 + obs_y_t[10] ) && y  <= (obs_y_b[10] -5))? 1 : 0;
assign obs_on10[9] = (x>= ( 16+  obs_x_l[10]) && x <= (obs_x_r[10]-6 )&& y>= ( 19+ obs_y_t[10]) && y  <= (obs_y_b[10]))? 1 : 0;

always @ (posedge clk or posedge rst) begin
 if(stage2 == 1) begin
    if(rst | game_stop) begin
        obs_x_reg[10] <= 400; 
        obs_y_reg[10] <= 230; 
        obs_score[10] <= 0;
    end    
    else if (refr_tick) begin
        obs_x_reg[10] <= obs_x_reg[10] + obs2_vx_reg; 
        obs_y_reg[10] <= obs_y_reg[10] + obs2_vy_reg;
        obs_score[10] <= 0;
        end
    else if ((shot_x_l >= obs_x_l[10]) && (shot_x_r <= obs_x_r[10]) && (shot_y_b <= obs_y_b[10])) begin
               obs_x_reg[10] <= 650;
               obs_y_reg[10] <= 0;
               obs_score[10] <= 1;
               obs_hit[10] = 1;
           end
    end
end
//--------------------------------------------------------------------------------------------------------------------------------//
assign obs_x_l[11] = obs_x_reg[11]; 
assign obs_x_r[11] = obs_x_l[11] + OBS_SIZE - 1; 
assign obs_y_t[11] = obs_y_reg[11]; 
assign obs_y_b[11] = obs_y_t[11] + OBS_SIZE - 1;

//color
assign obs_on11[0] = (x>= ( 5 + obs_x_l[11]) && x <= (obs_x_r[11] - 6 )&& y >= (2 +obs_y_t[11]) && y  <= (obs_y_b[11] - 21))? 1 : 0;
assign obs_on11[1] = (x>= ( 5 + obs_x_l[11]) && x <= (obs_x_r[11] - 20 )&& y >= (8+obs_y_t[11]) && y  <= (obs_y_b[11] - 18))? 1 : 0;
assign obs_on11[2] = (x>= ( 12+ obs_x_l[11]) && x <= (obs_x_r[11] -13)&& y>= ( 8 + obs_y_t[11]) && y  <= (obs_y_b[11] - 18))? 1 : 0;
assign obs_on11[3] = (x>= ( 19 + obs_x_l[11]) && x <= (obs_x_r[11] - 6 )&& y>= ( 8 + obs_y_t[11]) && y  <= (obs_y_b[11] - 18))? 1 : 0;
assign obs_on11[4] = (x>= ( obs_x_l[11]) && x <= (obs_x_r[11] - 20 )&& y>=( 11 + obs_y_t[11]) && y  <= (obs_y_b[11] - 10))? 1 : 0;
assign obs_on11[5] = (x>= ( 9 + obs_x_l[11]) && x <= (obs_x_r[11] - 10)&&  y>= ( 11 + obs_y_t[11]) && y  <= (obs_y_b[11] - 15))? 1 : 0;
assign obs_on11[6] = (x>= ( 19+ obs_x_l[11]  ) && x <= (obs_x_r[11])&& y>= ( 11 + obs_y_t[11]) && y  <= (obs_y_b[11] - 10))? 1 : 0;
assign obs_on11[7] = (x>= ( 5 + obs_x_l[11]) && x <= (obs_x_r[11] - 17 )&& y>= ( 19+ obs_y_t[11]) && y  <= (obs_y_b[11] ))? 1 : 0;
assign obs_on11[8] = (x>= ( 12 + obs_x_l[11]) && x <= (obs_x_r[11] - 13 )&& y>= (19 + obs_y_t[11] ) && y  <= (obs_y_b[11] -5))? 1 : 0;
assign obs_on11[9] = (x>= ( 16+  obs_x_l[11]) && x <= (obs_x_r[11]-6 )&& y>= ( 19+ obs_y_t[11]) && y  <= (obs_y_b[11]))? 1 : 0;

always @ (posedge clk or posedge rst) begin
 if(stage2 == 1) begin
    if(rst | game_stop) begin
        obs_x_reg[11] <= 500; 
        obs_y_reg[11] <= 19; 
        obs_score[11] <= 0;
    end    
    else if (refr_tick) begin
        obs_x_reg[11] <= obs_x_reg[11] + obs2_vx_reg; 
        obs_y_reg[11] <= obs_y_reg[11] + obs2_vy_reg;
        obs_score[11] <= 0;
        end
    else if ((shot_x_l >= obs_x_l[11]) && (shot_x_r <= obs_x_r[11]) && (shot_y_b <= obs_y_b[11])) begin
                   obs_x_reg[11] <= 650;
                   obs_y_reg[11] <= 0;
                   obs_score[11] <= 1;
                   obs_hit[11] = 1;
    end
  end
end

//velocity
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs2_vy_reg <= OBS_V;
        obs2_vx_reg <= 0; //left
    end else begin
            obs2_vy_reg <= OBS_V;
            obs2_vx_reg <= 0; //left
    end
end
/*---------------------------------------------------------*/
// obs - 3stage / 12~17
/*---------------------------------------------------------*/
assign obs_x_l[12] = obs_x_reg[12]; 
assign obs_x_r[12] = obs_x_l[12] + OBS_SIZE - 1; 
assign obs_y_t[12] = obs_y_reg[12]; 
assign obs_y_b[12] = obs_y_t[12] + OBS_SIZE - 1;

//color
assign obs_on12[0] = (x>= ( obs_x_l[12]) && x <= (obs_x_r[12] - 27)&& y>=obs_y_t[12] && y  <= (obs_y_b[12] - 25))? 1 : 0;
assign obs_on12[1] = (x>= ( 8 + obs_x_l[12]) && x <= (obs_x_r[12] - 18 )&& y>=obs_y_t[12] && y  <= (obs_y_b[12] - 25))? 1 : 0;
assign obs_on12[2] = (x>= (17+ obs_x_l[12]) && x <= (obs_x_r[12] -9)&& y>=  obs_y_t[12] && y  <= (obs_y_b[12] - 25))? 1 : 0;
assign obs_on12[3] = (x>= ( 26 + obs_x_l[12]) && x <= (obs_x_r[12])&& y>=  obs_y_t[12] && y  <= (obs_y_b[12] - 25))? 1 : 0;
assign obs_on12[4] = (x>= (  obs_x_l[12]) && x <= (obs_x_r[12]  )&& y>=( 4 + obs_y_t[12]) && y  <= (obs_y_b[12] -20))? 1 : 0;
assign obs_on12[5] = (x>= (  obs_x_l[12]) && x <= (obs_x_r[12] - 28 )&&  y>= (9 + obs_y_t[12]) && y  <= (obs_y_b[12] - 15))? 1 : 0;
assign obs_on12[6] = (x>= ( 2+obs_x_l[12]  ) && x <= (obs_x_r[12]-25)&& y>= ( 11+ obs_y_t[12]) && y  <= (obs_y_b[12] - 15))? 1 : 0;
assign obs_on12[7] = (x>= (9+ obs_x_l[12]) && x <= (obs_x_r[12] - 18 )&& y>= ( 11+ obs_y_t[12]) && y  <= (obs_y_b[12] -15))? 1 : 0;
assign obs_on12[8] = (x>= ( 11 + obs_x_l[12]) && x <= (obs_x_r[12] - 12 )&& y>= (9 + obs_y_t[12] ) && y  <= (obs_y_b[12] - 15))? 1 : 0;
assign obs_on12[9] = (x>= (17+  obs_x_l[12]) && x <= (obs_x_r[12]-10)&& y>= ( 11+ obs_y_t[12]) && y  <= (obs_y_b[12] - 15))? 1 : 0;
assign obs_on12[10] = (x>= ( 24+ obs_x_l[12]) && x <= (obs_x_r[12] - 3 )&& y>= ( 11 + obs_y_t[12]) && y  <= (obs_y_b[12] - 15))? 1 : 0;
assign obs_on12[11] = (x>= ( 26 + obs_x_l[12]) && x <= (obs_x_r[12]  )&& y>=( 9+ obs_y_t[12]) && y  <= (obs_y_b[12] - 15))? 1 : 0;
assign obs_on12[12] = (x>= (  obs_x_l[12]) && x <= (obs_x_r[12]  )&& y>= (14 + obs_y_t[12] ) && y  <= (obs_y_b[12] - 10))? 1 : 0;
assign obs_on12[13] = (x>= (  obs_x_l[12]) && x <= (obs_x_r[12] - 28)&& y>= ( 19 + obs_y_t[12] )&& y  <= (obs_y_b[12]))? 1 : 0;
assign obs_on12[14] = (x>= ( 1 + obs_x_l[12]) && x <= (obs_x_r[12] - 23 )&& y>=( 24 + obs_y_t[12] )&& y  <= (obs_y_b[12]))? 1 : 0;
assign obs_on12[15] = (x>= ( 6 + obs_x_l[12]) && x <= (obs_x_r[12] - 21 )&& y>=( 19+ obs_y_t[12] )&& y  <= (obs_y_b[12]))? 1 : 0;
assign obs_on12[16] = (x>= ( 8 + obs_x_l[12]) && x <= (obs_x_r[12] - 16 )&& y>=( 24 + obs_y_t[12] )&& y  <= (obs_y_b[12]))? 1 : 0;
assign obs_on12[17] = (x>= ( 13 + obs_x_l[12]) && x <= (obs_x_r[12] - 14 )&& y>=( 19 + obs_y_t[12] )&& y  <= (obs_y_b[12]))? 1 : 0;
assign obs_on12[18] = (x>= ( 15 + obs_x_l[12]) && x <= (obs_x_r[12] - 9 )&& y>=( 24 + obs_y_t[12] )&& y  <= (obs_y_b[12]))? 1 : 0;
assign obs_on12[19] = (x>= ( 20 + obs_x_l[12]) && x <= (obs_x_r[12] - 7 )&& y>=( 19 + obs_y_t[12] )&& y  <= (obs_y_b[12]))? 1 : 0;
assign obs_on12[20] = (x>= ( 22 + obs_x_l[12]) && x <= (obs_x_r[12] - 2 )&& y>=( 24 + obs_y_t[12] )&& y  <= (obs_y_b[12]))? 1 : 0;
assign obs_on12[21] = (x>= ( 27 + obs_x_l[12]) && x <= (obs_x_r[12]  )&& y>=( 19 + obs_y_t[12] )&& y  <= (obs_y_b[12]))? 1 : 0;

always @ (posedge clk or posedge rst) begin
 if(stage3) begin
    if(rst | game_stop) begin
        obs_x_reg[12] <= 3; 
        obs_y_reg[12] <= 30; 
        obs_score[12] <= 0;
    end    
    else if(refr_tick) begin
        obs_x_reg[12] <= obs_x_reg[12] + obs3_vx_reg[0]; 
        obs_y_reg[12] <= obs_y_reg[12] + obs3_vy_reg;
        obs_score[12] <= 0;
        end
    else if ((shot_x_l >= obs_x_l[12]) && (shot_x_r <= obs_x_r[12]) && (shot_y_b <= obs_y_b[12]) && (shot_y_t >= obs_y_t[12])) begin
                           obs_x_reg[12] <= 650;
                           obs_y_reg[12] <= 490;
                           obs_score[12] <= 1;
                           obs_hit[12] = 1;
    end
  end
end
//--------------------------------------------------------------------------------------------------------------------------------//
assign obs_x_l[13] = obs_x_reg[13]; 
assign obs_x_r[13] = obs_x_l[13] + OBS_SIZE - 1; 
assign obs_y_t[13] = obs_y_reg[13]; 
assign obs_y_b[13] = obs_y_t[13] + OBS_SIZE - 1;

//color
assign obs_on13[0] = (x>= ( obs_x_l[13]) && x <= (obs_x_r[13] - 27)&& y>=obs_y_t[13] && y  <= (obs_y_b[13] - 25))? 1 : 0;
assign obs_on13[1] = (x>= ( 8 + obs_x_l[13]) && x <= (obs_x_r[13] - 18 )&& y>=obs_y_t[13] && y  <= (obs_y_b[13] - 25))? 1 : 0;
assign obs_on13[2] = (x>= (17+ obs_x_l[13]) && x <= (obs_x_r[13] -9)&& y>=  obs_y_t[13] && y  <= (obs_y_b[13] - 25))? 1 : 0;
assign obs_on13[3] = (x>= ( 26 + obs_x_l[13]) && x <= (obs_x_r[13])&& y>=  obs_y_t[13] && y  <= (obs_y_b[13] - 25))? 1 : 0;
assign obs_on13[4] = (x>= (  obs_x_l[13]) && x <= (obs_x_r[13]  )&& y>=( 4 + obs_y_t[13]) && y  <= (obs_y_b[13] -20))? 1 : 0;
assign obs_on13[5] = (x>= (  obs_x_l[13]) && x <= (obs_x_r[13] - 28 )&&  y>= (9 + obs_y_t[13]) && y  <= (obs_y_b[13] - 15))? 1 : 0;
assign obs_on13[6] = (x>= ( 2+obs_x_l[13]  ) && x <= (obs_x_r[13]-25)&& y>= ( 11+ obs_y_t[13]) && y  <= (obs_y_b[13] - 15))? 1 : 0;
assign obs_on13[7] = (x>= (9+ obs_x_l[13]) && x <= (obs_x_r[13] - 18 )&& y>= ( 11+ obs_y_t[13]) && y  <= (obs_y_b[13] -15))? 1 : 0;
assign obs_on13[8] = (x>= ( 11 + obs_x_l[13]) && x <= (obs_x_r[13] - 12 )&& y>= (9 + obs_y_t[13] ) && y  <= (obs_y_b[13] - 15))? 1 : 0;
assign obs_on13[9] = (x>= (17+  obs_x_l[13]) && x <= (obs_x_r[13]-10)&& y>= ( 11+ obs_y_t[13]) && y  <= (obs_y_b[13] - 15))? 1 : 0;
assign obs_on13[10] = (x>= ( 24+ obs_x_l[13]) && x <= (obs_x_r[13] - 3 )&& y>= ( 11 + obs_y_t[13]) && y  <= (obs_y_b[13] - 15))? 1 : 0;
assign obs_on13[11] = (x>= ( 26 + obs_x_l[13]) && x <= (obs_x_r[13]  )&& y>=( 9+ obs_y_t[13]) && y  <= (obs_y_b[13] - 15))? 1 : 0;
assign obs_on13[12] = (x>= (  obs_x_l[13]) && x <= (obs_x_r[13]  )&& y>= (14 + obs_y_t[13] ) && y  <= (obs_y_b[13] - 10))? 1 : 0;
assign obs_on13[13] = (x>= (  obs_x_l[13]) && x <= (obs_x_r[13] - 28)&& y>= ( 19 + obs_y_t[13] )&& y  <= (obs_y_b[13]))? 1 : 0;
assign obs_on13[14] = (x>= ( 1 + obs_x_l[13]) && x <= (obs_x_r[13] - 23 )&& y>=( 24 + obs_y_t[13] )&& y  <= (obs_y_b[13]))? 1 : 0;
assign obs_on13[15] = (x>= ( 6 + obs_x_l[13]) && x <= (obs_x_r[13] - 21 )&& y>=( 19+ obs_y_t[13] )&& y  <= (obs_y_b[13]))? 1 : 0;
assign obs_on13[16] = (x>= ( 8 + obs_x_l[13]) && x <= (obs_x_r[13] - 16 )&& y>=( 24 + obs_y_t[13] )&& y  <= (obs_y_b[13]))? 1 : 0;
assign obs_on13[17] = (x>= ( 13 + obs_x_l[13]) && x <= (obs_x_r[13] - 14 )&& y>=( 19 + obs_y_t[13] )&& y  <= (obs_y_b[13]))? 1 : 0;
assign obs_on13[18] = (x>= ( 15 + obs_x_l[13]) && x <= (obs_x_r[13] - 9 )&& y>=( 24 + obs_y_t[13] )&& y  <= (obs_y_b[13]))? 1 : 0;
assign obs_on13[19] = (x>= ( 20 + obs_x_l[13]) && x <= (obs_x_r[13] - 7 )&& y>=( 19 + obs_y_t[13] )&& y  <= (obs_y_b[13]))? 1 : 0;
assign obs_on13[20] = (x>= ( 22 + obs_x_l[13]) && x <= (obs_x_r[13] - 2 )&& y>=( 24 + obs_y_t[13] )&& y  <= (obs_y_b[13]))? 1 : 0;
assign obs_on13[21] = (x>= ( 27 + obs_x_l[13]) && x <= (obs_x_r[13]  )&& y>=( 19 + obs_y_t[13] )&& y  <= (obs_y_b[13]))? 1 : 0;

always @ (posedge clk or posedge rst) begin
  if(stage3) begin
    if(rst | game_stop) begin
        obs_x_reg[13] <= 23; 
        obs_y_reg[13] <= 120; 
        obs_score[13] <= 0;
    end    
    else if (refr_tick) begin
        obs_x_reg[13] <= obs_x_reg[13] + obs3_vx_reg[1]; 
        obs_y_reg[13] <= obs_y_reg[13] + obs3_vy_reg;
        obs_score[13] <= 0;
        end
   else if ((shot_x_l >= obs_x_l[13]) && (shot_x_r <= obs_x_r[13]) && (shot_y_b <= obs_y_b[13]) && (shot_y_t >= obs_y_t[13])) begin
                           obs_x_reg[13] <= 650;
                           obs_y_reg[13] <= 490;
                           obs_hit[13] = 1;
                           obs_score[13] <= 1;
                       end
  end
end
//--------------------------------------------------------------------------------------------------------------------------------//
assign obs_x_l[14] = obs_x_reg[14]; 
assign obs_x_r[14] = obs_x_l[14] + OBS_SIZE - 1; 
assign obs_y_t[14] = obs_y_reg[14]; 
assign obs_y_b[14] = obs_y_t[14] + OBS_SIZE - 1;

//color
assign obs_on14[0] = (x>= ( obs_x_l[14]) && x <= (obs_x_r[14] - 27)&& y>=obs_y_t[14] && y  <= (obs_y_b[14] - 25))? 1 : 0;
assign obs_on14[1] = (x>= ( 8 + obs_x_l[14]) && x <= (obs_x_r[14] - 18 )&& y>=obs_y_t[14] && y  <= (obs_y_b[14] - 25))? 1 : 0;
assign obs_on14[2] = (x>= (17+ obs_x_l[14]) && x <= (obs_x_r[14] -9)&& y>=  obs_y_t[14] && y  <= (obs_y_b[14] - 25))? 1 : 0;
assign obs_on14[3] = (x>= ( 26 + obs_x_l[14]) && x <= (obs_x_r[14])&& y>=  obs_y_t[14] && y  <= (obs_y_b[14] - 25))? 1 : 0;
assign obs_on14[4] = (x>= (  obs_x_l[14]) && x <= (obs_x_r[14]  )&& y>=( 4 + obs_y_t[14]) && y  <= (obs_y_b[14] -20))? 1 : 0;
assign obs_on14[5] = (x>= (  obs_x_l[14]) && x <= (obs_x_r[14] - 28 )&&  y>= (9 + obs_y_t[14]) && y  <= (obs_y_b[14] - 15))? 1 : 0;
assign obs_on14[6] = (x>= ( 2+obs_x_l[14]  ) && x <= (obs_x_r[14]-25)&& y>= ( 11+ obs_y_t[14]) && y  <= (obs_y_b[14] - 15))? 1 : 0;
assign obs_on14[7] = (x>= (9+ obs_x_l[14]) && x <= (obs_x_r[14] - 18 )&& y>= ( 11+ obs_y_t[14]) && y  <= (obs_y_b[14] -15))? 1 : 0;
assign obs_on14[8] = (x>= ( 11 + obs_x_l[14]) && x <= (obs_x_r[14] - 12 )&& y>= (9 + obs_y_t[14] ) && y  <= (obs_y_b[14] - 15))? 1 : 0;
assign obs_on14[9] = (x>= (17+  obs_x_l[14]) && x <= (obs_x_r[14]-10)&& y>= ( 11+ obs_y_t[14]) && y  <= (obs_y_b[14] - 15))? 1 : 0;
assign obs_on14[10] = (x>= ( 24+ obs_x_l[14]) && x <= (obs_x_r[14] - 3 )&& y>= ( 11 + obs_y_t[14]) && y  <= (obs_y_b[14] - 15))? 1 : 0;
assign obs_on14[11] = (x>= ( 26 + obs_x_l[14]) && x <= (obs_x_r[14]  )&& y>=( 9+ obs_y_t[14]) && y  <= (obs_y_b[14] - 15))? 1 : 0;
assign obs_on14[12] = (x>= (  obs_x_l[14]) && x <= (obs_x_r[14]  )&& y>= (14 + obs_y_t[14] ) && y  <= (obs_y_b[14] - 10))? 1 : 0;
assign obs_on14[13] = (x>= (  obs_x_l[14]) && x <= (obs_x_r[14] - 28)&& y>= ( 19 + obs_y_t[14] )&& y  <= (obs_y_b[14]))? 1 : 0;
assign obs_on14[14] = (x>= ( 1 + obs_x_l[14]) && x <= (obs_x_r[14] - 23 )&& y>=( 24 + obs_y_t[14] )&& y  <= (obs_y_b[14]))? 1 : 0;
assign obs_on14[15] = (x>= ( 6 + obs_x_l[14]) && x <= (obs_x_r[14] - 21 )&& y>=( 19+ obs_y_t[14] )&& y  <= (obs_y_b[14]))? 1 : 0;
assign obs_on14[16] = (x>= ( 8 + obs_x_l[14]) && x <= (obs_x_r[14] - 16)&& y>=( 24 + obs_y_t[14] )&& y  <= (obs_y_b[14]))? 1 : 0;
assign obs_on14[17] = (x>= ( 13 + obs_x_l[14]) && x <= (obs_x_r[14] - 14 )&& y>=( 19 + obs_y_t[14] )&& y  <= (obs_y_b[14]))? 1 : 0;
assign obs_on14[18] = (x>= ( 15 + obs_x_l[14]) && x <= (obs_x_r[14] - 9 )&& y>=( 24 + obs_y_t[14] )&& y  <= (obs_y_b[14]))? 1 : 0;
assign obs_on14[19] = (x>= ( 20 + obs_x_l[14]) && x <= (obs_x_r[14] - 7 )&& y>=( 19 + obs_y_t[14] )&& y  <= (obs_y_b[14]))? 1 : 0;
assign obs_on14[20] = (x>= ( 22 + obs_x_l[14]) && x <= (obs_x_r[14] - 2 )&& y>=( 24 + obs_y_t[14] )&& y  <= (obs_y_b[14]))? 1 : 0;
assign obs_on14[21] = (x>= ( 27 + obs_x_l[14]) && x <= (obs_x_r[14]  )&& y>=( 19 + obs_y_t[14] )&& y  <= (obs_y_b[14]))? 1 : 0;

always @ (posedge clk or posedge rst) begin
  if(stage3 == 1) begin
    if(rst | game_stop) begin
        obs_x_reg[14] <= 68; 
        obs_y_reg[14] <= 180; 
        obs_score[14] <= 0;
    end    
    else if (refr_tick) begin
        obs_x_reg[14] <= obs_x_reg[14] + obs3_vx_reg[2]; 
        obs_y_reg[14] <= obs_y_reg[14] + obs3_vy_reg;
         obs_score[14] <= 0;
        end
    else if ((shot_x_l >= obs_x_l[14]) && (shot_x_r <= obs_x_r[14]) && (shot_y_b <= obs_y_b[14]) && (shot_y_t >= obs_y_t[14])) begin
                           obs_x_reg[14] <= 650;
                           obs_y_reg[14] <= 490;
                           obs_hit[14] = 1;
                            obs_score[14] <= 1;
                       end
 end
end
//--------------------------------------------------------------------------------------------------------------------------------//
assign obs_x_l[15] = obs_x_reg[15]; 
assign obs_x_r[15] = obs_x_l[15] + OBS_SIZE - 1; 
assign obs_y_t[15] = obs_y_reg[15]; 
assign obs_y_b[15] = obs_y_t[15] + OBS_SIZE - 1;

//color
assign obs_on15[0] = (x>= ( obs_x_l[15]) && x <= (obs_x_r[15] - 27)&& y>=obs_y_t[15] && y  <= (obs_y_b[15] - 25))? 1 : 0;
assign obs_on15[1] = (x>= ( 8 + obs_x_l[15]) && x <= (obs_x_r[15] - 18 )&& y>=obs_y_t[15] && y  <= (obs_y_b[15] - 25))? 1 : 0;
assign obs_on15[2] = (x>= (17+ obs_x_l[15]) && x <= (obs_x_r[15] -9)&& y>=  obs_y_t[15] && y  <= (obs_y_b[15] - 25))? 1 : 0;
assign obs_on15[3] = (x>= ( 26 + obs_x_l[15]) && x <= (obs_x_r[15])&& y>=  obs_y_t[15] && y  <= (obs_y_b[15] - 25))? 1 : 0;
assign obs_on15[4] = (x>= (  obs_x_l[15]) && x <= (obs_x_r[15]  )&& y>=( 4 + obs_y_t[15]) && y  <= (obs_y_b[15] -20))? 1 : 0;
assign obs_on15[5] = (x>= (  obs_x_l[15]) && x <= (obs_x_r[15] - 28 )&&  y>= (9 + obs_y_t[15]) && y  <= (obs_y_b[15] - 15))? 1 : 0;
assign obs_on15[6] = (x>= ( 2+obs_x_l[15]  ) && x <= (obs_x_r[15]-25)&& y>= ( 11+ obs_y_t[15]) && y  <= (obs_y_b[15] - 15))? 1 : 0;
assign obs_on15[7] = (x>= (9+ obs_x_l[15]) && x <= (obs_x_r[15] - 18 )&& y>= ( 11+ obs_y_t[15]) && y  <= (obs_y_b[15] -15))? 1 : 0;
assign obs_on15[8] = (x>= ( 11 + obs_x_l[15]) && x <= (obs_x_r[15] - 12 )&& y>= (9 + obs_y_t[15] ) && y  <= (obs_y_b[15] - 15))? 1 : 0;
assign obs_on15[9] = (x>= (17+  obs_x_l[15]) && x <= (obs_x_r[15]-10)&& y>= ( 11+ obs_y_t[15]) && y  <= (obs_y_b[15] - 15))? 1 : 0;
assign obs_on15[10] = (x>= ( 24+ obs_x_l[15]) && x <= (obs_x_r[15] - 3 )&& y>= ( 11 + obs_y_t[15]) && y  <= (obs_y_b[15] - 15))? 1 : 0;
assign obs_on15[11] = (x>= ( 26 + obs_x_l[15]) && x <= (obs_x_r[15]  )&& y>=( 9+ obs_y_t[15]) && y  <= (obs_y_b[15] - 15))? 1 : 0;
assign obs_on15[12] = (x>= (  obs_x_l[15]) && x <= (obs_x_r[15]  )&& y>= (14 + obs_y_t[15] ) && y  <= (obs_y_b[15] - 10))? 1 : 0;
assign obs_on15[13] = (x>= (  obs_x_l[15]) && x <= (obs_x_r[15] - 28)&& y>= ( 19 + obs_y_t[15] )&& y  <= (obs_y_b[15]))? 1 : 0;
assign obs_on15[14] = (x>= ( 1 + obs_x_l[15]) && x <= (obs_x_r[15] - 23 )&& y>=( 24 + obs_y_t[15] )&& y  <= (obs_y_b[15]))? 1 : 0;
assign obs_on15[15] = (x>= ( 6 + obs_x_l[15]) && x <= (obs_x_r[15] - 21 )&& y>=( 19+ obs_y_t[15] )&& y  <= (obs_y_b[15]))? 1 : 0;
assign obs_on15[16] = (x>= ( 8 + obs_x_l[15]) && x <= (obs_x_r[15] - 16 )&& y>=( 24 + obs_y_t[15] )&& y  <= (obs_y_b[15]))? 1 : 0;
assign obs_on15[17] = (x>= ( 13 + obs_x_l[15]) && x <= (obs_x_r[15] - 14 )&& y>=( 19 + obs_y_t[15] )&& y  <= (obs_y_b[15]))? 1 : 0;
assign obs_on15[18] = (x>= ( 15 + obs_x_l[15]) && x <= (obs_x_r[15] - 9 )&& y>=( 24 + obs_y_t[15] )&& y  <= (obs_y_b[15]))? 1 : 0;
assign obs_on15[19] = (x>= ( 20 + obs_x_l[15]) && x <= (obs_x_r[15] - 7 )&& y>=( 19 + obs_y_t[15] )&& y  <= (obs_y_b[15]))? 1 : 0;
assign obs_on15[20] = (x>= ( 22 + obs_x_l[15]) && x <= (obs_x_r[15] - 2 )&& y>=( 24 + obs_y_t[15] )&& y  <= (obs_y_b[15]))? 1 : 0;
assign obs_on15[21] = (x>= ( 27 + obs_x_l[15]) && x <= (obs_x_r[15]  )&& y>=( 19 + obs_y_t[15] )&& y  <= (obs_y_b[15]))? 1 : 0;

always @ (posedge clk or posedge rst) begin
 if(stage3 == 1) begin
    if(rst | game_stop) begin
        obs_x_reg[15] <= 581; 
        obs_y_reg[15] <= 210; 
        obs_score[15] <= 0;
    end    
    else if (refr_tick) begin
        obs_x_reg[15] <= obs_x_reg[15] + obs3_vx_reg[3]; 
        obs_y_reg[15] <= obs_y_reg[15] + obs3_vy_reg;
        obs_score[15] <= 0;
        end
    else if ((shot_x_l >= obs_x_l[15]) && (shot_x_r <= obs_x_r[15]) && (shot_y_b <= obs_y_b[15]) && (shot_y_t >= obs_y_t[15])) begin
                           obs_x_reg[15] <= 650;
                           obs_y_reg[15] <= 490;
                           obs_hit[15] = 1;
                           obs_score[15] <= 1;
                       end
  end
end
//--------------------------------------------------------------------------------------------------------------------------------//
assign obs_x_l[16] = obs_x_reg[16]; 
assign obs_x_r[16] = obs_x_l[16] + OBS_SIZE - 1; 
assign obs_y_t[16] = obs_y_reg[16]; 
assign obs_y_b[16] = obs_y_t[16] + OBS_SIZE - 1;

//color
assign obs_on16[0] = (x>= ( obs_x_l[16]) && x <= (obs_x_r[16] - 27)&& y>=obs_y_t[16] && y  <= (obs_y_b[16] - 25))? 1 : 0;
assign obs_on16[1] = (x>= ( 8 + obs_x_l[16]) && x <= (obs_x_r[16] - 18 )&& y>=obs_y_t[16] && y  <= (obs_y_b[16] - 25))? 1 : 0;
assign obs_on16[2] = (x>= (17+ obs_x_l[16]) && x <= (obs_x_r[16] -9)&& y>=  obs_y_t[16] && y  <= (obs_y_b[16] - 25))? 1 : 0;
assign obs_on16[3] = (x>= ( 26 + obs_x_l[16]) && x <= (obs_x_r[16])&& y>=  obs_y_t[16] && y  <= (obs_y_b[16] - 25))? 1 : 0;
assign obs_on16[4] = (x>= (  obs_x_l[16]) && x <= (obs_x_r[16]  )&& y>=( 4 + obs_y_t[16]) && y  <= (obs_y_b[16] -20))? 1 : 0;
assign obs_on16[5] = (x>= (  obs_x_l[16]) && x <= (obs_x_r[16] - 28 )&&  y>= (9 + obs_y_t[16]) && y  <= (obs_y_b[16] - 15))? 1 : 0;
assign obs_on16[6] = (x>= ( 2+obs_x_l[16]  ) && x <= (obs_x_r[16]-25)&& y>= ( 11+ obs_y_t[16]) && y  <= (obs_y_b[16] - 15))? 1 : 0;
assign obs_on16[7] = (x>= (9+ obs_x_l[16]) && x <= (obs_x_r[16] - 18 )&& y>= ( 11+ obs_y_t[16]) && y  <= (obs_y_b[16] -15))? 1 : 0;
assign obs_on16[8] = (x>= ( 11 + obs_x_l[16]) && x <= (obs_x_r[16] - 12 )&& y>= (9 + obs_y_t[16] ) && y  <= (obs_y_b[16] - 15))? 1 : 0;
assign obs_on16[9] = (x>= (17+  obs_x_l[16]) && x <= (obs_x_r[16]-10)&& y>= ( 11+ obs_y_t[16]) && y  <= (obs_y_b[16] - 15))? 1 : 0;
assign obs_on16[10] = (x>= ( 24+ obs_x_l[16]) && x <= (obs_x_r[16] - 3 )&& y>= ( 11 + obs_y_t[16]) && y  <= (obs_y_b[16] - 15))? 1 : 0;
assign obs_on16[11] = (x>= ( 26 + obs_x_l[16]) && x <= (obs_x_r[16]  )&& y>=( 9+ obs_y_t[16]) && y  <= (obs_y_b[16] - 15))? 1 : 0;
assign obs_on16[12] = (x>= (  obs_x_l[16]) && x <= (obs_x_r[16]  )&& y>= (14 + obs_y_t[16] ) && y  <= (obs_y_b[16] - 10))? 1 : 0;
assign obs_on16[13] = (x>= (  obs_x_l[16]) && x <= (obs_x_r[16] - 28)&& y>= ( 19 + obs_y_t[16] )&& y  <= (obs_y_b[16]))? 1 : 0;
assign obs_on16[14] = (x>= ( 1 + obs_x_l[16]) && x <= (obs_x_r[16] - 23 )&& y>=( 24 + obs_y_t[16] )&& y  <= (obs_y_b[16]))? 1 : 0;
assign obs_on16[15] = (x>= ( 6 + obs_x_l[16]) && x <= (obs_x_r[16] - 21 )&& y>=( 19+ obs_y_t[16] )&& y  <= (obs_y_b[16]))? 1 : 0;
assign obs_on16[16] = (x>= ( 8 + obs_x_l[16]) && x <= (obs_x_r[16] - 16 )&& y>=( 24 + obs_y_t[16] )&& y  <= (obs_y_b[16]))? 1 : 0;
assign obs_on16[17] = (x>= ( 13 + obs_x_l[16]) && x <= (obs_x_r[16] - 14 )&& y>=( 19 + obs_y_t[16] )&& y  <= (obs_y_b[16]))? 1 : 0;
assign obs_on16[18] = (x>= ( 15 + obs_x_l[16]) && x <= (obs_x_r[16] - 9 )&& y>=( 24 + obs_y_t[16] )&& y  <= (obs_y_b[16]))? 1 : 0;
assign obs_on16[19] = (x>= ( 20 + obs_x_l[16]) && x <= (obs_x_r[16] - 7 )&& y>=( 19 + obs_y_t[16] )&& y  <= (obs_y_b[16]))? 1 : 0;
assign obs_on16[20] = (x>= ( 22 + obs_x_l[16]) && x <= (obs_x_r[16] - 2 )&& y>=( 24 + obs_y_t[16] )&& y  <= (obs_y_b[16]))? 1 : 0;
assign obs_on16[21] = (x>= ( 27 + obs_x_l[16]) && x <= (obs_x_r[16]  )&& y>=( 19 + obs_y_t[16] )&& y  <= (obs_y_b[16]))? 1 : 0;

always @ (posedge clk or posedge rst) begin
 if(stage3 == 1) begin
    if(rst | game_stop) begin
        obs_x_reg[16] <= 312; 
        obs_y_reg[16] <= 300; 
        obs_score[16] <= 0;
    end    
    else if (refr_tick) begin
        obs_x_reg[16] <= obs_x_reg[16] + obs3_vx_reg[4]; 
        obs_y_reg[16] <= obs_y_reg[16] + obs3_vy_reg;
        obs_score[16] <= 0;
        end
    else if ((shot_x_l >= obs_x_l[16]) && (shot_x_r <= obs_x_r[16]) && (shot_y_b <= obs_y_b[16]) && (shot_y_t >= obs_y_t[16])) begin
                           obs_x_reg[16] <= 650;
                           obs_y_reg[16] <= 490;
                           obs_hit[16] = 1;
                           obs_score[16] <= 1;
                       end
  end
end
//--------------------------------------------------------------------------------------------------------------------------------//
assign obs_x_l[17] = obs_x_reg[17]; 
assign obs_x_r[17] = obs_x_l[17] + OBS_SIZE - 1; 
assign obs_y_t[17] = obs_y_reg[17]; 
assign obs_y_b[17] = obs_y_t[17] + OBS_SIZE - 1;

//color
assign obs_on17[0] = (x>= ( obs_x_l[17]) && x <= (obs_x_r[17] - 27)&& y>=obs_y_t[17] && y  <= (obs_y_b[17] - 25))? 1 : 0;
assign obs_on17[1] = (x>= ( 8 + obs_x_l[17]) && x <= (obs_x_r[17] - 18 )&& y>=obs_y_t[17] && y  <= (obs_y_b[17] - 25))? 1 : 0;
assign obs_on17[2] = (x>= (17+ obs_x_l[17]) && x <= (obs_x_r[17] -9)&& y>=  obs_y_t[17] && y  <= (obs_y_b[17] - 25))? 1 : 0;
assign obs_on17[3] = (x>= ( 26 + obs_x_l[17]) && x <= (obs_x_r[17])&& y>=  obs_y_t[17] && y  <= (obs_y_b[17] - 25))? 1 : 0;
assign obs_on17[4] = (x>= (  obs_x_l[17]) && x <= (obs_x_r[17]  )&& y>=( 4 + obs_y_t[17]) && y  <= (obs_y_b[17] -20))? 1 : 0;
assign obs_on17[5] = (x>= (  obs_x_l[17]) && x <= (obs_x_r[17] - 28 )&&  y>= (9 + obs_y_t[17]) && y  <= (obs_y_b[17] - 15))? 1 : 0;
assign obs_on17[6] = (x>= ( 2+obs_x_l[17]  ) && x <= (obs_x_r[17]- 25)&& y>= ( 11+ obs_y_t[17]) && y  <= (obs_y_b[17] - 15))? 1 : 0;
assign obs_on17[7] = (x>= (9+ obs_x_l[17]) && x <= (obs_x_r[17] - 18 )&& y>= ( 11+ obs_y_t[17]) && y  <= (obs_y_b[17] -15))? 1 : 0;
assign obs_on17[8] = (x>= ( 11 + obs_x_l[17]) && x <= (obs_x_r[17] - 12 )&& y>= (9 + obs_y_t[17] ) && y  <= (obs_y_b[17] - 15))? 1 : 0;
assign obs_on17[9] = (x>= (17+  obs_x_l[17]) && x <= (obs_x_r[17]-10)&& y>= ( 11+ obs_y_t[17]) && y  <= (obs_y_b[17] - 15))? 1 : 0;
assign obs_on17[10] = (x>= ( 24+ obs_x_l[17]) && x <= (obs_x_r[17] - 3 )&& y>= ( 11 + obs_y_t[17]) && y  <= (obs_y_b[17] - 15))? 1 : 0;
assign obs_on17[11] = (x>= ( 26 + obs_x_l[17]) && x <= (obs_x_r[17]  )&& y>=( 9+ obs_y_t[17]) && y  <= (obs_y_b[17] - 15))? 1 : 0;
assign obs_on17[12] = (x>= (  obs_x_l[17]) && x <= (obs_x_r[17]  )&& y>= (14 + obs_y_t[17] ) && y  <= (obs_y_b[17] - 10))? 1 : 0;
assign obs_on17[13] = (x>= (  obs_x_l[17]) && x <= (obs_x_r[17] - 28)&& y>= ( 19 + obs_y_t[17] )&& y  <= (obs_y_b[17]))? 1 : 0;
assign obs_on17[14] = (x>= ( 1 + obs_x_l[17]) && x <= (obs_x_r[17] - 23 )&& y>=( 24 + obs_y_t[17] )&& y  <= (obs_y_b[17]))? 1 : 0;
assign obs_on17[15] = (x>= ( 6 + obs_x_l[17]) && x <= (obs_x_r[17] - 21 )&& y>=( 19+ obs_y_t[17] )&& y  <= (obs_y_b[17]))? 1 : 0;
assign obs_on17[16] = (x>= ( 8 + obs_x_l[17]) && x <= (obs_x_r[17] - 16 )&& y>=( 24 + obs_y_t[17] )&& y  <= (obs_y_b[17]))? 1 : 0;
assign obs_on17[17] = (x>= ( 13 + obs_x_l[17]) && x <= (obs_x_r[17] - 14 )&& y>=( 19 + obs_y_t[17] )&& y  <= (obs_y_b[17]))? 1 : 0;
assign obs_on17[18] = (x>= ( 15 + obs_x_l[17]) && x <= (obs_x_r[17] - 9 )&& y>=( 24 + obs_y_t[17] )&& y  <= (obs_y_b[17]))? 1 : 0;
assign obs_on17[19] = (x>= ( 20 + obs_x_l[17]) && x <= (obs_x_r[17] - 7 )&& y>=( 19 + obs_y_t[17] )&& y  <= (obs_y_b[17]))? 1 : 0;
assign obs_on17[20] = (x>= ( 22 + obs_x_l[17]) && x <= (obs_x_r[17] - 2 )&& y>=( 24 + obs_y_t[17] )&& y  <= (obs_y_b[17]))? 1 : 0;
assign obs_on17[21] = (x>= ( 27 + obs_x_l[17]) && x <= (obs_x_r[17]  )&& y>=( 19 + obs_y_t[17] )&& y  <= (obs_y_b[17]))? 1 : 0;


always @ (posedge clk or posedge rst) begin
 if(stage3 == 1) begin
    if(rst | game_stop) begin
        obs_x_reg[17] <= 269; 
        obs_y_reg[17] <= 400; 
        obs_score[17] <= 0;
    end    
    else if (refr_tick) begin
        obs_x_reg[17] <= obs_x_reg[17] + obs3_vx_reg[5]; 
        obs_y_reg[17] <= obs_y_reg[17] + obs3_vy_reg;
        obs_score[17] <= 0;
        end
    else if ((shot_x_l >= obs_x_l[17]) && (shot_x_r <= obs_x_r[17]) && (shot_y_b <= obs_y_b[17]) && (shot_y_t >= obs_y_t[17])) begin
                           obs_x_reg[17] <= 650;
                           obs_y_reg[17] <= 490;
                           obs_hit[17] = 1;
                           obs_score[17] <= 1;
                       end
  end
end

assign wall_right_3_1 = (obs_x_r[12] == MAX_X) ? 1 : 0 ; // right wall
assign wall_right_3_2 = (obs_x_r[13] == MAX_X) ? 1 : 0 ; // right wall
assign wall_right_3_3 = (obs_x_r[14] == MAX_X) ? 1 : 0 ; // right wall
assign wall_right_3_4 = (obs_x_r[15] == MAX_X) ? 1 : 0 ; // right wall
assign wall_right_3_5 = (obs_x_r[16] == MAX_X) ? 1 : 0 ; // right wall
assign wall_right_3_6 = (obs_x_r[17] == MAX_X) ? 1 : 0 ; // right wall

assign wall_left_3_1 = (obs_x_l[12] == 0) ? 1 : 0 ; //left wall
assign wall_left_3_2 = (obs_x_l[13] == 0) ? 1 : 0 ; //left wall
assign wall_left_3_3 = (obs_x_l[14] == 0) ? 1 : 0 ; //left wall
assign wall_left_3_4 = (obs_x_l[15] == 0) ? 1 : 0 ; //left wall
assign wall_left_3_5 = (obs_x_l[16] == 0) ? 1 : 0 ; //left wall
assign wall_left_3_6 = (obs_x_l[17] == 0) ? 1 : 0 ; //left wall

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs3_vx_reg[0] <= OBS_V;
        obs3_vy_reg[0] <= 0;
    end
    else begin
        if(wall_right_3_1) obs3_vx_reg[0] <= -1*OBS_V;
        else if(wall_left_3_1) obs3_vx_reg[0]<= OBS_V;
    end 
end

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs3_vx_reg[1] <= OBS_V;
        obs3_vy_reg[1] <= 0;
    end
    else begin
        if(wall_right_3_2) obs3_vx_reg[1] <= -1*OBS_V;
        else if(wall_left_3_2) obs3_vx_reg[1] <= OBS_V;
    end 
end

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs3_vx_reg[2] <= OBS_V;
        obs3_vy_reg[2] <= 0;
    end
    else begin
        if(wall_right_3_3) obs3_vx_reg[2] <= -1*OBS_V;
        else if(wall_left_3_3) obs3_vx_reg[2] <= OBS_V;
    end 
end

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs3_vx_reg[3] <= OBS_V;
        obs3_vy_reg[3] <= 0;
    end
    else begin
        if(wall_right_3_4) obs3_vx_reg[3] <= -1*OBS_V;
        else if(wall_left_3_4) obs3_vx_reg[3] <= OBS_V;
    end 
end

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs3_vx_reg[4] <= OBS_V;
        obs3_vy_reg[4] <= 0;
    end
    else begin
        if(wall_right_3_5) obs3_vx_reg[4] <= -1*OBS_V;
        else if(wall_left_3_5) obs3_vx_reg[4] <= OBS_V;
    end 
end

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs3_vx_reg[5] <= OBS_V;
        obs3_vy_reg[5] <= 0;
    end
    else begin
        if(wall_right_3_6) obs3_vx_reg[5] <= -1*OBS_V;
        else if(wall_left_3_6) obs3_vx_reg[5] <= OBS_V;
    end 
end


/*---------------------------------------------------------*/
// obs - 4stage / 18~23
/*---------------------------------------------------------*/
assign obs_x_l[18] = obs_x_reg[18]; 
assign obs_x_r[18] = obs_x_l[18] + OBS_SIZE - 1; 
assign obs_y_t[18] = obs_y_reg[18]; 
assign obs_y_b[18] = obs_y_t[18] + OBS_SIZE - 1;

//color
assign obs_on18[0] = (x>= ( 10+ obs_x_l[18]) && x <= (obs_x_r[18] - 18)&& y>=(3+obs_y_t[18]) && y  <= (obs_y_b[18] - 25))? 1 : 0;
assign obs_on18[1] = (x>= ( 12 + obs_x_l[18]) && x <= (obs_x_r[18] - 13 )&& y>=(3+obs_y_t[18]) && y  <= (obs_y_b[18] - 25))? 1 : 0;
assign obs_on18[2] = (x>= ( 17+obs_x_l[18]) && x <= (obs_x_r[18] -11)&&y>=(3+obs_y_t[18]) && y  <= (obs_y_b[18] - 25))? 1 : 0;
assign obs_on18[3] = (x>= ( 1 + obs_x_l[18]) && x <= (obs_x_r[18] - 23 )&& y>= ( 4 + obs_y_t[18]) && y  <= (obs_y_b[18] - 23))? 1 : 0;
assign obs_on18[4] = (x>= ( 10 + obs_x_l[18]) && x <= (obs_x_r[18] - 11 )&& y>=( 4 + obs_y_t[18]) && y  <= (obs_y_b[18] - 25))? 1 : 0;
assign obs_on18[5] = (x>= ( 23 + obs_x_l[18]) && x <= (obs_x_r[18] - 1 )&&  y>= (4 + obs_y_t[18]) && y  <= (obs_y_b[18] - 23))? 1 : 0;
assign obs_on18[6] = (x>= (2+obs_x_l[18]  ) && x <= (obs_x_r[18]-24 )&& y>= ( 6 + obs_y_t[18]) && y  <= (obs_y_b[18] - 18))? 1 : 0;
assign obs_on18[7] = (x>= ( 5+ obs_x_l[18]) && x <= (obs_x_r[18] - 19 )&& y>= (9+ obs_y_t[18]) && y  <= (obs_y_b[18] - 18))? 1 : 0;
assign obs_on18[8] = (x>= (10+ obs_x_l[18]) && x <= (obs_x_r[18] - 18 )&& y>= (6 + obs_y_t[18] ) && y  <= (obs_y_b[18] - 18))? 1 : 0;
assign obs_on18[9] = (x>= (11 +  obs_x_l[18]) && x <= (obs_x_r[18]-17)&& y>= ( 7+ obs_y_t[18]) && y  <= (obs_y_b[18] - 18))? 1 : 0;
assign obs_on18[10] = (x>= ( 12+ obs_x_l[18]) && x <= (obs_x_r[18] - 13 )&& y>= ( 5 + obs_y_t[18]) && y  <= (obs_y_b[18] - 19))? 1 : 0;
assign obs_on18[11] = (x>= ( 16 + obs_x_l[18]) && x <= (obs_x_r[18] - 12 )&& y>=( 7 + obs_y_t[18]) && y  <= (obs_y_b[18] - 18))? 1 : 0;
assign obs_on18[12] = (x>= ( 17 + obs_x_l[18]) && x <= (obs_x_r[18] - 11)&& y>= (6 + obs_y_t[18] ) && y  <= (obs_y_b[18] - 18))? 1 : 0;
assign obs_on18[13] = (x>= ( 18 + obs_x_l[18]) && x <= (obs_x_r[18] - 5 )&& y>= ( 9 + obs_y_t[18] )&& y  <= (obs_y_b[18]-18))? 1 : 0;
assign obs_on18[14] = (x>= ( 24 + obs_x_l[18]) && x <= (obs_x_r[18] - 2 )&& y>=( 6 + obs_y_t[18] )&& y  <= (obs_y_b[18]-18))? 1 : 0;
assign obs_on18[15] = (x>= ( 8 + obs_x_l[18]) && x <= (obs_x_r[18] - 9 )&& y>=( 11 + obs_y_t[18] )&& y  <= (obs_y_b[18]-14))? 1 : 0;
assign obs_on18[16] = (x>= ( 3 + obs_x_l[18]) && x <= (obs_x_r[18] - 4 )&& y>=( 15 + obs_y_t[18] )&& y  <= (obs_y_b[18]-7))? 1 : 0;
assign obs_on18[17] = (x>= ( 3 + obs_x_l[18]) && x <= (obs_x_r[18] - 20)&& y>=( 22 + obs_y_t[18] )&& y  <= (obs_y_b[18]-3))? 1 : 0;
assign obs_on18[18] = (x>= ( 19 + obs_x_l[18]) && x <= (obs_x_r[18] - 4 )&& y>=( 22 + obs_y_t[18] )&& y  <= (obs_y_b[18]-3))? 1 : 0;
assign obs_on18[19] = (x>= ( 1+ obs_x_l[18]) && x <= (obs_x_r[18] - 18 )&& y>=( 26 + obs_y_t[18] )&& y  <= (obs_y_b[18]))? 1 : 0;
assign obs_on18[20] = (x>= ( 17 + obs_x_l[18]) && x <= (obs_x_r[18] - 1 )&& y>=( 26 + obs_y_t[18] )&& y  <= (obs_y_b[18]))? 1 : 0;

always @ (posedge clk or posedge rst) begin
 if(stage4 == 1) begin
    if(rst | game_stop) begin
        obs_x_reg[18] <= 20; 
        obs_y_reg[18] <=0; 
        obs_score[18] <= 0;
    end    
    else if(refr_tick) begin
        obs_x_reg[18] <= obs_x_reg[18] + obs4_vx_reg[0]; 
        obs_y_reg[18] <= obs_y_reg[18] + obs4_vy_reg[0];
        obs_score[18] <= 0;
        end
    else if ((shot_x_l >= obs_x_l[18]) && (shot_x_r <= obs_x_r[18]) && (shot_y_b <= obs_y_b[18]) && (shot_y_t >= obs_y_t[18])) begin
        obs_x_reg[18] <= 650;
        obs_y_reg[18] <= 500;
        obs_hit[18] = 1;
        obs_score[18] <= 1;
   end
  end
end
//--------------------------------------------------------------------------------------------------------------------------------//
assign obs_x_l[19] = obs_x_reg[19]; 
assign obs_x_r[19] = obs_x_l[19] + OBS_SIZE - 1; 
assign obs_y_t[19] = obs_y_reg[19]; 
assign obs_y_b[19] = obs_y_t[19] + OBS_SIZE - 1;

//color
assign obs_on19[0] = (x>= ( 10+ obs_x_l[19]) && x <= (obs_x_r[19] - 18)&& y>=(3+obs_y_t[19]) && y  <= (obs_y_b[19] - 25))? 1 : 0;
assign obs_on19[1] = (x>= ( 12 + obs_x_l[19]) && x <= (obs_x_r[19] - 13 )&& y>=(3+obs_y_t[19]) && y  <= (obs_y_b[19] - 25))? 1 : 0;
assign obs_on19[2] = (x>= ( 17+obs_x_l[19]) && x <= (obs_x_r[19] -11)&&y>=(3+obs_y_t[19]) && y  <= (obs_y_b[19] - 25))? 1 : 0;
assign obs_on19[3] = (x>= ( 1 + obs_x_l[19]) && x <= (obs_x_r[19] - 23 )&& y>= ( 4 + obs_y_t[19]) && y  <= (obs_y_b[19] - 23))? 1 : 0;
assign obs_on19[4] = (x>= ( 10 + obs_x_l[9]) && x <= (obs_x_r[19] - 11 )&& y>=( 4 + obs_y_t[19]) && y  <= (obs_y_b[19] - 25))? 1 : 0;
assign obs_on19[5] = (x>= ( 23 + obs_x_l[19]) && x <= (obs_x_r[19] - 1 )&&  y>= (4 + obs_y_t[19]) && y  <= (obs_y_b[19] - 23))? 1 : 0;
assign obs_on19[6] = (x>= (2+obs_x_l[19]  ) && x <= (obs_x_r[19]-24 )&& y>= ( 6 + obs_y_t[19]) && y  <= (obs_y_b[19] - 18))? 1 : 0;
assign obs_on19[7] = (x>= ( 5+ obs_x_l[19]) && x <= (obs_x_r[19] - 19 )&& y>= (9+ obs_y_t[19]) && y  <= (obs_y_b[19] - 18))? 1 : 0;
assign obs_on19[8] = (x>= (10+ obs_x_l[19]) && x <= (obs_x_r[19] - 18 )&& y>= (6 + obs_y_t[19] ) && y  <= (obs_y_b[19] - 18))? 1 : 0;
assign obs_on19[9] = (x>= (11 +  obs_x_l[19]) && x <= (obs_x_r[19]-17)&& y>= ( 7+ obs_y_t[19]) && y  <= (obs_y_b[19] - 18))? 1 : 0;
assign obs_on19[10] = (x>= ( 12+ obs_x_l[19]) && x <= (obs_x_r[19] - 13 )&& y>= ( 5 + obs_y_t[19]) && y  <= (obs_y_b[19] - 19))? 1 : 0;
assign obs_on19[11] = (x>= ( 16 + obs_x_l[19]) && x <= (obs_x_r[19] - 12 )&& y>=( 7 + obs_y_t[19]) && y  <= (obs_y_b[19] - 18))? 1 : 0;
assign obs_on19[12] = (x>= ( 17 + obs_x_l[19]) && x <= (obs_x_r[19] - 11)&& y>= (6 + obs_y_t[19] ) && y  <= (obs_y_b[19] - 18))? 1 : 0;
assign obs_on19[13] = (x>= ( 18 + obs_x_l[19]) && x <= (obs_x_r[19] - 5 )&& y>= ( 9 + obs_y_t[19] )&& y  <= (obs_y_b[19]-18))? 1 : 0;
assign obs_on19[14] = (x>= ( 24 + obs_x_l[19]) && x <= (obs_x_r[19] - 2 )&& y>=( 6 + obs_y_t[19] )&& y  <= (obs_y_b[19]-18))? 1 : 0;
assign obs_on19[15] = (x>= ( 8 + obs_x_l[19]) && x <= (obs_x_r[19] - 9 )&& y>=( 11 + obs_y_t[19] )&& y  <= (obs_y_b[19]-14))? 1 : 0;
assign obs_on19[16] = (x>= ( 3 + obs_x_l[19]) && x <= (obs_x_r[19] - 4 )&& y>=( 15 + obs_y_t[19] )&& y  <= (obs_y_b[19]-7))? 1 : 0;
assign obs_on19[17] = (x>= ( 3 + obs_x_l[19]) && x <= (obs_x_r[19] - 20)&& y>=( 22 + obs_y_t[19] )&& y  <= (obs_y_b[19]-3))? 1 : 0;
assign obs_on19[18] = (x>= ( 19+ obs_x_l[19]) && x <= (obs_x_r[19] - 4 )&& y>=( 22 + obs_y_t[19] )&& y  <= (obs_y_b[19]-3))? 1 : 0;
assign obs_on19[19] = (x>= ( 1+ obs_x_l[19]) && x <= (obs_x_r[19] - 18 )&& y>=( 26 + obs_y_t[19] )&& y  <= (obs_y_b[19]))? 1 : 0;
assign obs_on19[20] = (x>= ( 17 + obs_x_l[19]) && x <= (obs_x_r[19] - 1 )&& y>=( 26 + obs_y_t[19] )&& y  <= (obs_y_b[19]))? 1 : 0;

always @ (posedge clk or posedge rst) begin
 if(stage4 == 1 ) begin
    if(rst | game_stop) begin
        obs_x_reg[19] <= 84; 
        obs_y_reg[19] <= 150; 
        obs_score[19] <= 0;
    end    
    else if (refr_tick) begin
        obs_x_reg[19] <= obs_x_reg[19] + obs4_vx_reg[1]; 
        obs_y_reg[19] <= obs_y_reg[19] + obs4_vy_reg[1];
        obs_score[19] <= 0;
        end
    else if ((shot_x_l >= obs_x_l[19]) && (shot_x_r <= obs_x_r[19]) && (shot_y_b <= obs_y_b[19]) && (shot_y_t >= obs_y_t[19])) begin
        obs_x_reg[19] <= 650;
        obs_y_reg[19] <= 500;
        obs_hit[19] = 1;
        obs_score[19] <= 1;
    end
   end
end
//--------------------------------------------------------------------------------------------------------------------------------//
assign obs_x_l[20] = obs_x_reg[20]; 
assign obs_x_r[20] = obs_x_l[20] + OBS_SIZE - 1; 
assign obs_y_t[20] = obs_y_reg[20]; 
assign obs_y_b[20] = obs_y_t[20] + OBS_SIZE - 1;

//color
assign obs_on20[0] = (x>= ( 10+ obs_x_l[20]) && x <= (obs_x_r[20] - 18)&& y>=(3+obs_y_t[20]) && y  <= (obs_y_b[20] - 25))? 1 : 0;
assign obs_on20[1] = (x>= ( 12 + obs_x_l[20]) && x <= (obs_x_r[20] - 13 )&& y>=(3+obs_y_t[20]) && y  <= (obs_y_b[20] - 25))? 1 : 0;
assign obs_on20[2] = (x>= ( 17+obs_x_l[20]) && x <= (obs_x_r[20] -11)&&y>=(3+obs_y_t[20]) && y  <= (obs_y_b[20] - 25))? 1 : 0;
assign obs_on20[3] = (x>= ( 1 + obs_x_l[20]) && x <= (obs_x_r[20] - 23 )&& y>= ( 4 + obs_y_t[20]) && y  <= (obs_y_b[20] - 23))? 1 : 0;
assign obs_on20[4] = (x>= ( 10 + obs_x_l[20]) && x <= (obs_x_r[20] - 11 )&& y>=( 4 + obs_y_t[20]) && y  <= (obs_y_b[20] - 25))? 1 : 0;
assign obs_on20[5] = (x>= ( 23 + obs_x_l[20]) && x <= (obs_x_r[20] - 1 )&&  y>= (4 + obs_y_t[20]) && y  <= (obs_y_b[20] - 23))? 1 : 0;
assign obs_on20[6] = (x>= (2+obs_x_l[20]  ) && x <= (obs_x_r[20]-24 )&& y>= ( 6 + obs_y_t[20]) && y  <= (obs_y_b[20] - 18))? 1 : 0;
assign obs_on20[7] = (x>= ( 5+ obs_x_l[20]) && x <= (obs_x_r[20] - 19 )&& y>= (9+ obs_y_t[20]) && y  <= (obs_y_b[20] - 18))? 1 : 0;
assign obs_on20[8] = (x>= (10+ obs_x_l[20]) && x <= (obs_x_r[20] - 18 )&& y>= (6 + obs_y_t[20] ) && y  <= (obs_y_b[20] - 18))? 1 : 0;
assign obs_on20[9] = (x>= (11 +  obs_x_l[20]) && x <= (obs_x_r[20]-17)&& y>= ( 7+ obs_y_t[20]) && y  <= (obs_y_b[20] - 18))? 1 : 0;
assign obs_on20[10] = (x>= ( 12+ obs_x_l[20]) && x <= (obs_x_r[20] - 13 )&& y>= ( 5 + obs_y_t[20]) && y  <= (obs_y_b[20] - 19))? 1 : 0;
assign obs_on20[11] = (x>= ( 16 + obs_x_l[20]) && x <= (obs_x_r[20] - 12 )&& y>=( 7 + obs_y_t[20]) && y  <= (obs_y_b[20] - 18))? 1 : 0;
assign obs_on20[12] = (x>= ( 17 + obs_x_l[20]) && x <= (obs_x_r[20] - 11)&& y>= (6 + obs_y_t[20] ) && y  <= (obs_y_b[20] - 18))? 1 : 0;
assign obs_on20[13] = (x>= ( 18 + obs_x_l[20]) && x <= (obs_x_r[20] - 5 )&& y>= ( 9 + obs_y_t[20] )&& y  <= (obs_y_b[20]-18))? 1 : 0;
assign obs_on20[14] = (x>= ( 24 + obs_x_l[20]) && x <= (obs_x_r[20] - 2 )&& y>=( 6 + obs_y_t[20] )&& y  <= (obs_y_b[20]-18))? 1 : 0;
assign obs_on20[15] = (x>= ( 8 + obs_x_l[20]) && x <= (obs_x_r[20] - 9 )&& y>=( 11 + obs_y_t[20] )&& y  <= (obs_y_b[20]-14))? 1 : 0;
assign obs_on20[16] = (x>= ( 3 + obs_x_l[20]) && x <= (obs_x_r[20] - 4 )&& y>=( 15 + obs_y_t[20] )&& y  <= (obs_y_b[20]-7))? 1 : 0;
assign obs_on20[17] = (x>= ( 3 + obs_x_l[20]) && x <= (obs_x_r[20] - 20)&& y>=( 22 + obs_y_t[20] )&& y  <= (obs_y_b[20]-3))? 1 : 0;
assign obs_on20[18] = (x>= ( 19+ obs_x_l[20]) && x <= (obs_x_r[20] - 4 )&& y>=( 22 + obs_y_t[20] )&& y  <= (obs_y_b[20]-3))? 1 : 0;
assign obs_on20[19] = (x>= ( 1 + obs_x_l[20]) && x <= (obs_x_r[20] - 18)&& y>=( 26 + obs_y_t[20] )&& y  <= (obs_y_b[20]))? 1 : 0;
assign obs_on20[20] = (x>= ( 17+ obs_x_l[20]) && x <= (obs_x_r[20] - 1 )&& y>=( 26 + obs_y_t[20] )&& y  <= (obs_y_b[20]))? 1 : 0;

always @ (posedge clk or posedge rst) begin
 if(stage4 == 1) begin
    if(rst | game_stop) begin
        obs_x_reg[20] <= 148; 
        obs_y_reg[20] <= 150; 
        obs_score[20] <= 0;
    end    
    else if (refr_tick) begin
        obs_x_reg[20] <= obs_x_reg[20] + obs4_vx_reg[2]; 
        obs_y_reg[20] <= obs_y_reg[20] + obs4_vy_reg[2];
        obs_score[20] <= 0;
        end
    else if ((shot_x_l >= obs_x_l[20]) && (shot_x_r <= obs_x_r[20]) && (shot_y_b <= obs_y_b[20]) && (shot_y_t >= obs_y_t[20])) begin
        obs_x_reg[20] <= 650;
        obs_y_reg[20] <= 500;
        obs_hit[20] = 1;
        obs_score[20] <= 1;
    end
  end
end
//--------------------------------------------------------------------------------------------------------------------------------//
assign obs_x_l[21] = obs_x_reg[21]; 
assign obs_x_r[21] = obs_x_l[21] + OBS_SIZE - 1; 
assign obs_y_t[21] = obs_y_reg[21]; 
assign obs_y_b[21] = obs_y_t[21] + OBS_SIZE - 1;

//color
assign obs_on21[0] = (x>= ( 10+ obs_x_l[21]) && x <= (obs_x_r[21] - 18)&& y>=(3+obs_y_t[21]) && y  <= (obs_y_b[21] - 25))? 1 : 0;
assign obs_on21[1] = (x>= ( 12 + obs_x_l[21]) && x <= (obs_x_r[21] - 13 )&& y>=(3+obs_y_t[21]) && y  <= (obs_y_b[21] - 25))? 1 : 0;
assign obs_on21[2] = (x>= ( 17+obs_x_l[21]) && x <= (obs_x_r[21] -11)&&y>=(3+obs_y_t[21]) && y  <= (obs_y_b[21] - 25))? 1 : 0;
assign obs_on21[3] = (x>= ( 1 + obs_x_l[21]) && x <= (obs_x_r[21] - 23 )&& y>= ( 4 + obs_y_t[21]) && y  <= (obs_y_b[21] - 23))? 1 : 0;
assign obs_on21[4] = (x>= ( 10 + obs_x_l[21]) && x <= (obs_x_r[21] - 11 )&& y>=( 4 + obs_y_t[21]) && y  <= (obs_y_b[21] - 25))? 1 : 0;
assign obs_on21[5] = (x>= ( 23 + obs_x_l[21]) && x <= (obs_x_r[21] - 1 )&&  y>= (4 + obs_y_t[21]) && y  <= (obs_y_b[21] - 23))? 1 : 0;
assign obs_on21[6] = (x>= (2+obs_x_l[21]  ) && x <= (obs_x_r[21]-24 )&& y>= ( 6 + obs_y_t[21]) && y  <= (obs_y_b[21] - 18))? 1 : 0;
assign obs_on21[7] = (x>= ( 5+ obs_x_l[21]) && x <= (obs_x_r[21] - 19 )&& y>= (9+ obs_y_t[21]) && y  <= (obs_y_b[21] - 18))? 1 : 0;
assign obs_on21[8] = (x>= (10+ obs_x_l[21]) && x <= (obs_x_r[21] - 18 )&& y>= (6 + obs_y_t[21] ) && y  <= (obs_y_b[21] - 18))? 1 : 0;
assign obs_on21[9] = (x>= (11 +  obs_x_l[21]) && x <= (obs_x_r[21]-17)&& y>= ( 7+ obs_y_t[21]) && y  <= (obs_y_b[21] - 18))? 1 : 0;
assign obs_on21[10] = (x>= ( 12+ obs_x_l[21]) && x <= (obs_x_r[21] - 13 )&& y>= ( 5 + obs_y_t[21]) && y  <= (obs_y_b[21] - 19))? 1 : 0;
assign obs_on21[11] = (x>= ( 16 + obs_x_l[21]) && x <= (obs_x_r[21] - 12 )&& y>=( 7 + obs_y_t[21]) && y  <= (obs_y_b[21] - 18))? 1 : 0;
assign obs_on21[12] = (x>= ( 17 + obs_x_l[21]) && x <= (obs_x_r[21] - 11)&& y>= (6 + obs_y_t[21] ) && y  <= (obs_y_b[21] - 18))? 1 : 0;
assign obs_on21[13] = (x>= ( 18 + obs_x_l[21]) && x <= (obs_x_r[21] - 5 )&& y>= ( 9 + obs_y_t[21] )&& y  <= (obs_y_b[21]-18))? 1 : 0;
assign obs_on21[14] = (x>= ( 24 + obs_x_l[21]) && x <= (obs_x_r[21] - 2 )&& y>=( 6 + obs_y_t[21] )&& y  <= (obs_y_b[21]-18))? 1 : 0;
assign obs_on21[15] = (x>= ( 8 + obs_x_l[21]) && x <= (obs_x_r[21] - 9 )&& y>=( 11 + obs_y_t[21] )&& y  <= (obs_y_b[21]-14))? 1 : 0;
assign obs_on21[16] = (x>= ( 3 + obs_x_l[21]) && x <= (obs_x_r[21] - 4 )&& y>=( 15 + obs_y_t[21] )&& y  <= (obs_y_b[21]-7))? 1 : 0;
assign obs_on21[17] = (x>= ( 3 + obs_x_l[21]) && x <= (obs_x_r[21] - 20)&& y>=( 22 + obs_y_t[21] )&& y  <= (obs_y_b[21]-3))? 1 : 0;
assign obs_on21[18] = (x>= ( 19 + obs_x_l[21]) && x <= (obs_x_r[21] - 4 )&& y>=( 22 + obs_y_t[21] )&& y  <= (obs_y_b[21]-3))? 1 : 0;
assign obs_on21[19] = (x>= ( 1 + obs_x_l[21]) && x <= (obs_x_r[21] - 18 )&& y>=( 26 + obs_y_t[21] )&& y  <= (obs_y_b[21]))? 1 : 0;
assign obs_on21[20] = (x>= ( 17 + obs_x_l[21]) && x <= (obs_x_r[21] - 1 )&& y>=( 26 + obs_y_t[21] )&& y  <= (obs_y_b[21]))? 1 : 0;

always @ (posedge clk or posedge rst) begin
  if(stage4 == 1) begin
    if(rst | game_stop) begin
        obs_x_reg[21] <= 212; 
        obs_y_reg[21] <= 150;
        obs_score[21] <= 0; 
    end    
    else if (refr_tick) begin
        obs_x_reg[21] <= obs_x_reg[21] + obs4_vx_reg[3]; 
        obs_y_reg[21] <= obs_y_reg[21] + obs4_vy_reg[3];
        obs_score[21] <= 0; 
        end
    else if ((shot_x_l >= obs_x_l[21]) && (shot_x_r <= obs_x_r[21]) && (shot_y_b <= obs_y_b[21]) && (shot_y_t >= obs_y_t[21])) begin
        obs_x_reg[21] <= 650;
        obs_y_reg[21] <= 500;
        obs_hit[21] = 1;
        obs_score[21] <= 1; 
    end
  end
end
//--------------------------------------------------------------------------------------------------------------------------------//
assign obs_x_l[22] = obs_x_reg[22]; 
assign obs_x_r[22] = obs_x_l[22] + OBS_SIZE - 1; 
assign obs_y_t[22] = obs_y_reg[22]; 
assign obs_y_b[22] = obs_y_t[22] + OBS_SIZE - 1;

//color
assign obs_on22[0] = (x>= ( 10+ obs_x_l[22]) && x <= (obs_x_r[22] - 18)&& y>=(3+obs_y_t[22]) && y  <= (obs_y_b[22] - 25))? 1 : 0;
assign obs_on22[1] = (x>= ( 12 + obs_x_l[22]) && x <= (obs_x_r[22] - 13 )&& y>=(3+obs_y_t[22]) && y  <= (obs_y_b[22] - 25))? 1 : 0;
assign obs_on22[2] = (x>= ( 17+obs_x_l[22]) && x <= (obs_x_r[22] -11)&&y>=(3+obs_y_t[22]) && y  <= (obs_y_b[22] - 25))? 1 : 0;
assign obs_on22[3] = (x>= ( 1 + obs_x_l[22]) && x <= (obs_x_r[22] - 23 )&& y>= ( 4 + obs_y_t[22]) && y  <= (obs_y_b[22] - 23))? 1 : 0;
assign obs_on22[4] = (x>= ( 10 + obs_x_l[22]) && x <= (obs_x_r[22] - 11 )&& y>=( 4 + obs_y_t[22]) && y  <= (obs_y_b[22] - 25))? 1 : 0;
assign obs_on22[5] = (x>= ( 23 + obs_x_l[22]) && x <= (obs_x_r[22] - 1 )&&  y>= (4 + obs_y_t[22]) && y  <= (obs_y_b[22] - 23))? 1 : 0;
assign obs_on22[6] = (x>= (2+obs_x_l[22]  ) && x <= (obs_x_r[22]-24 )&& y>= ( 6 + obs_y_t[22]) && y  <= (obs_y_b[22] - 18))? 1 : 0;
assign obs_on22[7] = (x>= ( 5+ obs_x_l[22]) && x <= (obs_x_r[22] - 19 )&& y>= (9+ obs_y_t[22]) && y  <= (obs_y_b[22] - 18))? 1 : 0;
assign obs_on22[8] = (x>= (10+ obs_x_l[22]) && x <= (obs_x_r[22] - 18 )&& y>= (6 + obs_y_t[22] ) && y  <= (obs_y_b[22] - 18))? 1 : 0;
assign obs_on22[9] = (x>= (11 +  obs_x_l[22]) && x <= (obs_x_r[22]-17)&& y>= ( 7+ obs_y_t[22]) && y  <= (obs_y_b[22] - 18))? 1 : 0;
assign obs_on22[10] = (x>= ( 12+ obs_x_l[22]) && x <= (obs_x_r[22] - 13 )&& y>= ( 5 + obs_y_t[22]) && y  <= (obs_y_b[22] - 19))? 1 : 0;
assign obs_on22[11] = (x>= ( 16 + obs_x_l[22]) && x <= (obs_x_r[22] - 12 )&& y>=( 7 + obs_y_t[22]) && y  <= (obs_y_b[22] - 18))? 1 : 0;
assign obs_on22[12] = (x>= ( 17 + obs_x_l[22]) && x <= (obs_x_r[22] - 11)&& y>= (6 + obs_y_t[22] ) && y  <= (obs_y_b[22] - 18))? 1 : 0;
assign obs_on22[13] = (x>= ( 18 + obs_x_l[22]) && x <= (obs_x_r[22] - 5 )&& y>= ( 9 + obs_y_t[22] )&& y  <= (obs_y_b[22]-18))? 1 : 0;
assign obs_on22[14] = (x>= ( 24 + obs_x_l[22]) && x <= (obs_x_r[22] - 2 )&& y>=( 6 + obs_y_t[22] )&& y  <= (obs_y_b[22]-18))? 1 : 0;
assign obs_on22[15] = (x>= ( 8 + obs_x_l[22]) && x <= (obs_x_r[22] - 9 )&& y>=( 11 + obs_y_t[22] )&& y  <= (obs_y_b[22]-14))? 1 : 0;
assign obs_on22[16] = (x>= ( 3 + obs_x_l[22]) && x <= (obs_x_r[22] - 4 )&& y>=( 15 + obs_y_t[22] )&& y  <= (obs_y_b[22]-7))? 1 : 0;
assign obs_on22[17] = (x>= ( 3 + obs_x_l[22]) && x <= (obs_x_r[22] - 20)&& y>=( 22 + obs_y_t[22] )&& y  <= (obs_y_b[22]-3))? 1 : 0;
assign obs_on22[18] = (x>= ( 19 + obs_x_l[22]) && x <= (obs_x_r[22] - 4 )&& y>=( 22 + obs_y_t[22] )&& y  <= (obs_y_b[22]-3))? 1 : 0;
assign obs_on22[19] = (x>= ( 1 + obs_x_l[22]) && x <= (obs_x_r[22] - 18 )&& y>=( 26 + obs_y_t[22] )&& y  <= (obs_y_b[22]))? 1 : 0;
assign obs_on22[20] = (x>= ( 17+ obs_x_l[22]) && x <= (obs_x_r[22] - 1 )&& y>=( 26 + obs_y_t[22] )&& y  <= (obs_y_b[22]))? 1 : 0;

always @ (posedge clk or posedge rst) begin
 if(stage4 == 1) begin
    if(rst | game_stop) begin
        obs_x_reg[22] <= 276; 
        obs_y_reg[22] <= 150; 
        obs_score[22] <= 0; 
    end    
    else if (refr_tick) begin
        obs_x_reg[22] <= obs_x_reg[22] + obs4_vx_reg[4]; 
        obs_y_reg[22] <= obs_y_reg[22] + obs4_vy_reg[4];
        obs_score[22] <= 0; 
        end
    else if ((shot_x_l >= obs_x_l[22]) && (shot_x_r <= obs_x_r[22]) && (shot_y_b <= obs_y_b[22]) && (shot_y_t >= obs_y_t[22])) begin
        obs_x_reg[22] <= 650;
        obs_y_reg[22] <= 500;
        obs_hit[22] = 1;
        obs_score[22] <= 1; 
    end
  end
end
//--------------------------------------------------------------------------------------------------------------------------------//
assign obs_x_l[23] = obs_x_reg[23]; 
assign obs_x_r[23] = obs_x_l[23] + OBS_SIZE - 1; 
assign obs_y_t[23] = obs_y_reg[23]; 
assign obs_y_b[23] = obs_y_t[23] + OBS_SIZE - 1;

//color
assign obs_on23[0] = (x>= ( 10+ obs_x_l[23]) && x <= (obs_x_r[23] - 18)&& y>=(3+obs_y_t[23]) && y  <= (obs_y_b[23] - 25))? 1 : 0;
assign obs_on23[1] = (x>= ( 12 + obs_x_l[23]) && x <= (obs_x_r[23] - 13 )&& y>=(3+obs_y_t[23]) && y  <= (obs_y_b[23] - 25))? 1 : 0;
assign obs_on23[2] = (x>= ( 17+obs_x_l[23]) && x <= (obs_x_r[23] -11)&&y>=(3+obs_y_t[23]) && y  <= (obs_y_b[23] - 25))? 1 : 0;
assign obs_on23[3] = (x>= ( 1 + obs_x_l[23]) && x <= (obs_x_r[23] - 23 )&& y>= ( 4 + obs_y_t[23]) && y  <= (obs_y_b[23] - 23))? 1 : 0;
assign obs_on23[4] = (x>= ( 10 + obs_x_l[23]) && x <= (obs_x_r[23] - 11 )&& y>=( 4 + obs_y_t[23]) && y  <= (obs_y_b[23] - 25))? 1 : 0;
assign obs_on23[5] = (x>= ( 23 + obs_x_l[23]) && x <= (obs_x_r[23] - 1 )&&  y>= (4 + obs_y_t[23]) && y  <= (obs_y_b[23] - 23))? 1 : 0;
assign obs_on23[6] = (x>= (2+obs_x_l[23]  ) && x <= (obs_x_r[23]-24 )&& y>= ( 6 + obs_y_t[23]) && y  <= (obs_y_b[23] - 18))? 1 : 0;
assign obs_on23[7] = (x>= ( 5+ obs_x_l[23]) && x <= (obs_x_r[23] - 19 )&& y>= (9+ obs_y_t[23]) && y  <= (obs_y_b[23] - 18))? 1 : 0;
assign obs_on23[8] = (x>= (10+ obs_x_l[23]) && x <= (obs_x_r[23] - 18 )&& y>= (6 + obs_y_t[23] ) && y  <= (obs_y_b[23] - 18))? 1 : 0;
assign obs_on23[9] = (x>= (11 +  obs_x_l[23]) && x <= (obs_x_r[23]-17)&& y>= ( 7+ obs_y_t[23]) && y  <= (obs_y_b[23] - 18))? 1 : 0;
assign obs_on23[10] = (x>= ( 12+ obs_x_l[23]) && x <= (obs_x_r[23] - 13 )&& y>= ( 5 + obs_y_t[23]) && y  <= (obs_y_b[23] - 19))? 1 : 0;
assign obs_on23[11] = (x>= ( 16 + obs_x_l[23]) && x <= (obs_x_r[23] - 12 )&& y>=( 7 + obs_y_t[23]) && y  <= (obs_y_b[23] - 18))? 1 : 0;
assign obs_on23[12] = (x>= ( 17 + obs_x_l[23]) && x <= (obs_x_r[23] - 11)&& y>= (6 + obs_y_t[23] ) && y  <= (obs_y_b[23] - 18))? 1 : 0;
assign obs_on23[13] = (x>= ( 18 + obs_x_l[23]) && x <= (obs_x_r[23] - 5 )&& y>= ( 9 + obs_y_t[23] )&& y  <= (obs_y_b[23]-18))? 1 : 0;
assign obs_on23[14] = (x>= ( 24 + obs_x_l[23]) && x <= (obs_x_r[23] - 2 )&& y>=( 6 + obs_y_t[23] )&& y  <= (obs_y_b[23]-18))? 1 : 0;
assign obs_on23[15] = (x>= ( 8 + obs_x_l[23]) && x <= (obs_x_r[23] - 9 )&& y>=( 11 + obs_y_t[23] )&& y  <= (obs_y_b[23]-14))? 1 : 0;
assign obs_on23[16] = (x>= ( 3 + obs_x_l[23]) && x <= (obs_x_r[23] - 4 )&& y>=( 15 + obs_y_t[23] )&& y  <= (obs_y_b[23]-7))? 1 : 0;
assign obs_on23[17] = (x>= ( 3 + obs_x_l[23]) && x <= (obs_x_r[23] - 20)&& y>=( 22 + obs_y_t[23] )&& y  <= (obs_y_b[23]-3))? 1 : 0;
assign obs_on23[18] = (x>= ( 19 + obs_x_l[23]) && x <= (obs_x_r[23] - 4 )&& y>=( 22 + obs_y_t[23] )&& y  <= (obs_y_b[23]-3))? 1 : 0;
assign obs_on23[19] = (x>= ( 1 + obs_x_l[23]) && x <= (obs_x_r[23] - 18 )&& y>=( 26 + obs_y_t[23] )&& y  <= (obs_y_b[23]))? 1 : 0;
assign obs_on23[20] = (x>= ( 17 + obs_x_l[23]) && x <= (obs_x_r[23] - 1 )&& y>=( 26 + obs_y_t[23] )&& y  <= (obs_y_b[23]))? 1 : 0;

always @ (posedge clk or posedge rst) begin
 if(stage4 == 1) begin
    if(rst | game_stop) begin
        obs_x_reg[23] <= 340; 
        obs_y_reg[23] <= 150; 
        obs_score[23] <= 0; 
    end    
    else if (refr_tick) begin
        obs_x_reg[23] <= obs_x_reg[23] + obs4_vx_reg[5]; 
        obs_y_reg[23] <= obs_y_reg[23] + obs4_vy_reg[5];
        obs_score[23] <= 0; 
        end
    else if ((shot_x_l >= obs_x_l[23]) && (shot_x_r <= obs_x_r[23]) && (shot_y_b <= obs_y_b[23]) && (shot_y_t >= obs_y_t[23])) begin
        obs_x_reg[23] <= 650;
        obs_y_reg[23] <= 500;
        obs_hit[23] = 1;
        obs_score[23] <= 1; 
    end
  end
end

//assign wall_right_4 = ((obs_x_r[18] == MAX_X) || (obs_x_r[19] == MAX_X) || (obs_x_r[20] == MAX_X) || (obs_x_r[21] == MAX_X) || (obs_x_r[22] == MAX_X) || (obs_x_r[23] == MAX_X)) ? 1 : 0 ; // right wall
//assign wall_left_4 = ((obs_x_l[18] == 640-MAX_X) || (obs_x_l[19] == 640-MAX_X) || (obs_x_l[20] == 640-MAX_X) || (obs_x_l[21] == 640-MAX_X) || (obs_x_l[22] == 640-MAX_X) || (obs_x_l[23] == 640-MAX_X)) ? 1 : 0 ; //left wall
//assign reach_bottom = ((obs_y_b[18] > MAX_Y-1) || (obs_y_b[19] > MAX_Y-1) || (obs_y_b[20] > MAX_Y-1) || (obs_y_b[21] > MAX_Y-1) || (obs_y_b[22] > MAX_Y-1) || (obs_y_b[23] > MAX_Y-1))? 1 :0; // bottom 
//assign reach_top = ((obs_y_t[18] == 0) || (obs_y_t[19] == 0) || (obs_y_t[20] == 0) || (obs_y_t[21] == 0) || (obs_y_t[22] == 0) || (obs_y_t[23] == 0))? 1:0; // top 

assign wall_right_4_1 = (obs_x_r[18] == MAX_X) ? 1 : 0 ; // right wall
assign wall_right_4_2 = (obs_x_r[19] == MAX_X) ? 1 : 0 ; // right wall
assign wall_right_4_3 = (obs_x_r[20] == MAX_X) ? 1 : 0 ; // right wall
assign wall_right_4_4 = (obs_x_r[21] == MAX_X) ? 1 : 0 ; // right wall
assign wall_right_4_5 = (obs_x_r[22] == MAX_X) ? 1 : 0 ; // right wall
assign wall_right_4_6 = (obs_x_r[23] == MAX_X) ? 1 : 0 ; // right wall

assign wall_left_4_1 = (obs_x_l[18] == 0) ? 1 : 0 ; //left wall
assign wall_left_4_2 = (obs_x_l[19] == 0) ? 1 : 0 ; //left wall
assign wall_left_4_3 = (obs_x_l[20] == 0) ? 1 : 0 ; //left wall
assign wall_left_4_4 = (obs_x_l[21] == 0) ? 1 : 0 ; //left wall
assign wall_left_4_5 = (obs_x_l[22] == 0) ? 1 : 0 ; //left wall
assign wall_left_4_6 = (obs_x_l[23] == 0) ? 1 : 0 ; //left wall

assign reach_bottom_1 = (obs_y_b[18] > MAX_Y-1) ? 1 : 0 ; //bottom wall
assign reach_bottom_2 = (obs_y_b[19] > MAX_Y-1) ? 1 : 0 ;
assign reach_bottom_3 = (obs_y_b[20] > MAX_Y-1) ? 1 : 0 ;
assign reach_bottom_4 = (obs_y_b[21] > MAX_Y-1) ? 1 : 0 ;
assign reach_bottom_5 = (obs_y_b[22] > MAX_Y-1) ? 1 : 0 ;
assign reach_bottom_6 = (obs_y_b[23] > MAX_Y-1) ? 1 : 0 ;

assign reach_top_1 = (obs_y_t[18] == 0) ? 1 : 0 ; //top wall
assign reach_top_2 = (obs_y_t[19] == 0) ? 1 : 0 ;
assign reach_top_3 = (obs_y_t[20] == 0) ? 1 : 0 ;
assign reach_top_4 = (obs_y_t[21] == 0) ? 1 : 0 ;
assign reach_top_5 = (obs_y_t[22] == 0) ? 1 : 0 ;
assign reach_top_6 = (obs_y_t[23] == 0) ? 1 : 0 ;

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
       obs4_vx_reg[0] <= -1*OBS_V;
       obs4_vy_reg[0] <= OBS_V;
    end
    else if(obs_hit[18]) begin
        obs4_vx_reg[0] <= 0;
        obs4_vy_reg[0] <= 0;
    end
    else begin
         if(wall_right_4_1) obs4_vx_reg[0] <= -1*OBS_V;
         else if(wall_left_4_1) obs4_vx_reg[0] <= OBS_V;
         else if(reach_bottom_1) obs4_vy_reg[0] <= -1*OBS_V;
         else if(reach_top_1) obs4_vy_reg[0] <= OBS_V;
    end
end

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
       obs4_vx_reg[1] <= OBS_V;
       obs4_vy_reg[1] <= OBS_V;
    end
    else if(obs_hit[19]) begin
        obs4_vx_reg[1] <= 0;
        obs4_vy_reg[1] <= 0;
    end
    else begin
         if(wall_right_4_2) obs4_vx_reg[1] <= -1*OBS_V;
         else if(wall_left_4_2) obs4_vx_reg[1] <= OBS_V;
         else if(reach_bottom_2) obs4_vy_reg[1] <= -1*OBS_V;
         else if(reach_top_2) obs4_vy_reg[1] <= OBS_V;
    end
end

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
       obs4_vx_reg[2] <= OBS_V;
       obs4_vy_reg[2] <= -1 *OBS_V;
    end
    else if(obs_hit[20]) begin
        obs4_vx_reg[2] <= 0;
        obs4_vy_reg[2] <= 0;
    end
    else begin
         if(wall_right_4_3) obs4_vx_reg[2] <= -1*OBS_V;
         else if(wall_left_4_3) obs4_vx_reg[2] <= OBS_V;
         else if(reach_bottom_3) obs4_vy_reg[2] <= -1*OBS_V;
         else if(reach_top_3) obs4_vy_reg[2] <= OBS_V;
    end
end

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
       obs4_vx_reg[3] <= -1*OBS_V;
       obs4_vy_reg[3] <= -1*OBS_V;
    end
    else if(obs_hit[21]) begin
        obs4_vx_reg[3] <= 0;
        obs4_vy_reg[3] <= 0;
    end
    else begin
         if(wall_right_4_4) obs4_vx_reg[3] <= -1*OBS_V;
         else if(wall_left_4_4) obs4_vx_reg[3] <= OBS_V;
         else if(reach_bottom_4) obs4_vy_reg[3] <= -1*OBS_V;
         else if(reach_top_4) obs4_vy_reg[3] <= OBS_V;
    end
end

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
       obs4_vx_reg[4] <= -1*OBS_V;
       obs4_vy_reg[4] <= OBS_V;
    end
    else if(obs_hit[22]) begin
        obs4_vx_reg[4] <= 0;
        obs4_vy_reg[4] <= 0;
    end
    else begin
         if(wall_right_4_5) obs4_vx_reg[4] <= -1*OBS_V;
         else if(wall_left_4_5) obs4_vx_reg[4] <= OBS_V;
         else if(reach_bottom_5) obs4_vy_reg[4] <= -1*OBS_V;
         else if(reach_top_5) obs4_vy_reg[4] <= OBS_V;
    end
end

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
       obs4_vx_reg[5] <= OBS_V;
       obs4_vy_reg[5] <= OBS_V;
    end
    else if(obs_hit[23]) begin
        obs4_vx_reg[5] <= 0;
        obs4_vy_reg[5] <= 0;
    end
    else begin
         if(wall_right_4_6) obs4_vx_reg[5] <= -1*OBS_V;
         else if(wall_left_4_6) obs4_vx_reg[5] <= OBS_V;
         else if(reach_bottom_6) obs4_vy_reg[5] <= -1*OBS_V;
         else if(reach_top_6) obs4_vy_reg[5] <= OBS_V;
    end
end


/*---------------------------------------------------------*/
// if hit_obs, score ++
/*---------------------------------------------------------*/
reg d_inc, d_clr;
wire hit_obs, hit_bomb, hit_minus;
wire hit_score;
reg [3:0] dig0, dig1;

//assign hit = ((shot_y_t <= obs_y_b[0]) || (shot_y_t <= obs_y_b[1]) | (shot_y_t <= obs_y_b[2]) | (shot_y_t <= obs_y_b[3]) | (shot_y_t <= obs_y_b[4]) | (shot_y_t <= obs_y_b[5]))? 1 : 0; //hit socre
assign reach_obs = ((obs_score[0] == 1) || (obs_score[1] ==1) || (obs_score[2] ==1) || (obs_score[3] ==1) || (obs_score[4] == 1 ) || (obs_score[5] == 1)  || (obs_score[6] == 1) || (obs_score[7] ==1) || (obs_score[8] ==1) || (obs_score[9] ==1) || (obs_score[10] == 1 ) || (obs_score[11] == 1) || (obs_score[12] == 1) || (obs_score[13] ==1) || (obs_score[14] ==1) || (obs_score[15] ==1) || (obs_score[16] == 1 ) || (obs_score[17] == 1) || (obs_score[18] == 1) || (obs_score[19] ==1) || (obs_score[20] ==1) || (obs_score[21] ==1) || (obs_score[22] == 1 ) || (obs_score[23] == 1))? 1 : 0; //hit obs
assign reach_bomb = ((bomb_hit[0] == 1) || (bomb_hit[1] ==1) || (bomb_hit[2] ==1))? 1 : 0; //hit bomb

assign hit_obs = (reach_obs==1 && refr_tick == 1)? 1 : 0; //hit obs
assign hit_bomb = (reach_bomb ==1 && refr_tick == 1)? 1 : 0; //hit bomb
assign hit_score = (hit_obs == 1 && refr_tick ==1)? 1 : 0; //hit socre
assign hit_minus = (hit_bomb == 1 && refr_tick == 1)? 1 : 0;
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
reg [2:0] state_reg, state_next;
reg [1:0] life_reg, life_next;
reg [1:0] stage_reg, stage_next;
wire button;
assign button = (bomb_hit[0] == 1 || bomb_hit[1] == 1 || bomb_hit[2] == 1) ? 1 : 0;
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
                life_next = 2'b11; //left life 3
                stage_next = 2'b00; //stage 0
                stage1 = 1;
                stage2 = 0;
                stage3 = 0;
                stage4 = 0;
            end else begin
                state_next = NEWGAME; //no key push,
                life_next = 2'b11; //left life 3
                stage_next = 2'b00; //stage init
            end
         end
          PLAY: begin
                    game_stop = 0; //game running
                    d_inc = hit_obs;
                    stage1 = 1;              
                    //life_next = 2'b11;
               if((obs_hit[0] == 1) && (obs_hit[1] ==1) && (obs_hit[2] ==1) && (obs_hit[3] ==1) && (obs_hit[4] == 1) && (obs_hit[5] == 1)) begin
                    stage_next = 2'b01; //stage1
                    state_next = PLAY;
                    
                    stage2 = 1;
                    if(bomb_hit[0] == 1 || bomb_hit[1] == 1 || bomb_hit[2] == 1) begin
                              life_next = 2'b10;
                              state_next = PLAY;
                                                                                 
                              if(((bomb_hit[0] == 1) && (bomb_hit[1] == 1)) || ((bomb_hit[0] == 1) && (bomb_hit[2] == 1)) || ((bomb_hit[1] == 1) && (bomb_hit[2] == 1))) begin
                                       life_next = 2'b01;
                                       state_next = PLAY;
                                                                                       
                                       if(bomb_hit[2] == 1 && bomb_hit[1] == 1 && bomb_hit[0] == 1) begin
                                                 life_next = 2'b00;
                                                 game_over = 1;
                                                 state_next = NEWGAME;
                                       end 
                               end
                               
                     end
                    if((obs_hit[6] == 1) && (obs_hit[7] ==1) && (obs_hit[8] ==1) && (obs_hit[9] ==1) && (obs_hit[10] == 1) && (obs_hit[11] == 1)) begin
                        stage_next = 2'b10; //stage2
                        state_next = PLAY;
                   
                        stage3 = 1;
                        if(bomb_hit[0] == 1 || bomb_hit[1] == 1 || bomb_hit[2] == 1) begin
                               life_next = 2'b10;
                               state_next = PLAY;
                                                                                                       
                               if(((bomb_hit[0] == 1) && (bomb_hit[1] == 1)) || ((bomb_hit[0] == 1) && (bomb_hit[2] == 1)) || ((bomb_hit[1] == 1) && (bomb_hit[2] == 1))) begin
                                      life_next = 2'b01;
                                      state_next = PLAY;
                                                                                                           
                                      if(bomb_hit[2] == 1 && bomb_hit[1] == 1 && bomb_hit[0] == 1) begin
                                                life_next = 2'b00;
                                                game_over = 1;
                                                state_next = NEWGAME;
                                      end 
                                end
                          end
                        if((obs_hit[12] == 1) && (obs_hit[13] ==1) && (obs_hit[14] ==1) && (obs_hit[15] ==1) && (obs_hit[16] == 1) && (obs_hit[17] == 1)) begin
                            stage_next = 2'b11; //stage3
                            state_next = PLAY;
                        
                            stage4 = 1;
                            if(bomb_hit[0] == 1 || bomb_hit[1] == 1 || bomb_hit[2] == 1) begin
                                    life_next = 2'b10;
                                    state_next = PLAY;
                                                                                                           
                                    if(((bomb_hit[0] == 1) && (bomb_hit[1] == 1)) || ((bomb_hit[0] == 1) && (bomb_hit[2] == 1)) || ((bomb_hit[1] == 1) && (bomb_hit[2] == 1))) begin
                                            life_next = 2'b01;
                                            state_next = PLAY;
                                                                                                               
                                            if(bomb_hit[2] == 1 && bomb_hit[1] == 1 && bomb_hit[0] == 1) begin
                                                      life_next = 2'b00;
                                                      game_over = 1;
                                                      state_next = NEWGAME;
                                            end 
                                    end
                            end
                           if((obs_hit[18] == 1) && (obs_hit[19] ==1) && (obs_hit[20] ==1) && (obs_hit[21] ==1) && (obs_hit[22] == 1) && (obs_hit[23] == 1)) begin
                                game_clear = 1;
                                if(bomb_hit[0] == 1 || bomb_hit[1] == 1 || bomb_hit[2] == 1) begin
                                       life_next = 2'b10;
                                       state_next = PLAY;
                                                                                                                   
                                       if(((bomb_hit[0] == 1) && (bomb_hit[1] == 1)) || ((bomb_hit[0] == 1) && (bomb_hit[2] == 1)) || ((bomb_hit[1] == 1) && (bomb_hit[2] == 1))) begin
                                               life_next = 2'b01;
                                               state_next = PLAY;
                                                                                                                       
                                               if(bomb_hit[2] == 1 && bomb_hit[1] == 1 && bomb_hit[0] == 1) begin
                                                    life_next = 2'b00;
                                                    game_over = 1;
                                                    state_next = NEWGAME;
                                               end 
                                       end
                                  end
                             end
                        end
                    end
                end
                else begin
                      if(bomb_hit[0] == 1 || bomb_hit[1] == 1 || bomb_hit[2] == 1) begin
                                 life_next = 2'b10;
                                 state_next = PLAY;
                                                                                                                               
                            if(((bomb_hit[0] == 1) && (bomb_hit[1] == 1)) || ((bomb_hit[0] == 1) && (bomb_hit[2] == 1)) || ((bomb_hit[1] == 1) && (bomb_hit[2] == 1))) begin
                                       life_next = 2'b01;
                                       state_next = PLAY;
                                                                                                                                   
                                       if(bomb_hit[2] == 1 && bomb_hit[1] == 1 && bomb_hit[0] == 1) begin
                                              life_next = 2'b00;
                                              game_over = 1;
                                              state_next = NEWGAME;
                                       end 
                            end
                         end
                                                                                                                       
                        else state_next = PLAY;
                end
         end
         
         NEWGUN: begin
            if(key[4] == 1) state_next = PLAY;
            else state_next = NEWGUN;
         end
        OVER: begin
            if(key[4] == 1) begin //key push, new game
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
reg [6:0] char_addr_s, char_addr_l, char_addr_o, char_addr_stage, char_addr_clear;
wire [2:0] bit_addr;
reg [2:0] bit_addr_s, bit_addr_l, bit_addr_o, bit_addr_stage, bit_addr_clear;
wire [3:0] row_addr, row_addr_s, row_addr_l, row_addr_o, row_addr_stage, row_addr_clear; //4bit
wire score_on, life_on, over_on, stage_on, clear_on;
wire font_bit;
wire [7:0] font_word;
wire [10:0] rom_addr;
font_rom_vhd font_rom_inst (clk, rom_addr, font_word);
assign rom_addr = {char_addr, row_addr};
assign font_bit = font_word[~bit_addr]; 
assign char_addr = (score_on)? char_addr_s : (life_on)? char_addr_l : (over_on)? char_addr_o : (stage_on)? char_addr_stage : (clear_on)? char_addr_clear : 0;
assign row_addr = (score_on)? row_addr_s : (life_on)? row_addr_l : (over_on)? row_addr_o : (stage_on)? row_addr_stage : (clear_on)? row_addr_clear : 0; 
assign bit_addr = (score_on)? bit_addr_s : (life_on)? bit_addr_l : (over_on)? bit_addr_o :(stage_on)? bit_addr_stage : (clear_on)? bit_addr_clear : 0; 
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
// game clear
assign clear_on = (game_clear==1 && y[9:6]==3 && x[9:5]>=5 && x[9:5]<=14)? 1 : 0; 
assign row_addr_clear = y[5:2];
always @(*) begin
    bit_addr_clear = x[4:2];
    case (x[9:5]) 
        5: char_addr_clear = 7'b1000111; // G x47
        6: char_addr_clear = 7'b1100001; // a x61
        7: char_addr_clear = 7'b1101101; // m x6d
        8: char_addr_clear = 7'b1100101; // e x65
        9: char_addr_clear = 7'b0000000; //                      
        10: char_addr_clear = 7'b1000011; // C x43
        11: char_addr_clear = 7'b1101100; // l x6c
        12: char_addr_clear = 7'b1100101; // e x65
        13: char_addr_clear = 7'b1100001; // a x61
        14: char_addr_clear = 7'b1110010; // r x72
        default: char_addr_clear = 0; 
    endcase
end
/*---------------------------------------------------------*/
// color setting
/*---------------------------------------------------------*/
assign rgb = 
                 (font_bit & score_on)? 3'b111 : //black text
                 (font_bit & life_on)? 3'b110 : // yellow text  
                 (font_bit & stage_on)? 3'b110 : // yellow text  
                 (font_bit & over_on)? 3'b100 : //red text
                 (font_bit & clear_on)? 3'b001 :
                 
                 (shot_on[0]) ? 3'b100 : // red shot
                 (shot_on[1]) ? 3'b100 : // red shot
                 (shot_on[2]) ? 3'b100 : // red shot
                 (shot_on[3]) ? 3'b100 : // red shot
                 (shot_on[4]) ? 3'b100 : // red shot
                 (shot_on[5]) ? 3'b100 : // red shot
                 (shot_on[6]) ? 3'b100 : // red shot
                 
                 (gun_on[0])? 3'b111 : //white gun
                 (gun_on[1])? 3'b111 : //white gun
                 (gun_on[2])? 3'b111 : //white gun
                 
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
                 
             //cyan
             (stage1 == 0)? 3'b000 : (obs_on0[0]) ? 3'b011 : //1stage
             (stage1 == 0)? 3'b000 : (obs_on0[1]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on0[2]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on0[3]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on0[4]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on0[5]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on0[6]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on0[7]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on0[8]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on0[9]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on0[10]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on0[11]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on0[12]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on0[13]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on0[14]) ? 3'b011 :
             
             (stage1 == 0)? 3'b000 : (obs_on1[0]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on1[1]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on1[2]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on1[3]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on1[4]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on1[5]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on1[6]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on1[7]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on1[8]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on1[9]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on1[10]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on1[11]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on1[12]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on1[13]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on1[14]) ? 3'b011 :
             
             (stage1 == 0)? 3'b000 : (obs_on2[0]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on2[1]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on2[2]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on2[3]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on2[4]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on2[5]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on2[6]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on2[7]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on2[8]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on2[9]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on2[10]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on2[11]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on2[12]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on2[13]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on2[14]) ? 3'b011 :
             
             (stage1 == 0)? 3'b000 : (obs_on3[0]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on3[1]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on3[2]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on3[3]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on3[4]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on3[5]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on3[6]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on3[7]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on3[8]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on3[9]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on3[10]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on3[11]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on3[12]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on3[13]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on3[14]) ? 3'b011 :
             
             (stage1 == 0)? 3'b000 : (obs_on4[0]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on4[1]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on4[2]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on4[3]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on4[4]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on4[5]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on4[6]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on4[7]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on4[8]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on4[9]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on4[10]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on4[11]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on4[12]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on4[13]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on4[14]) ? 3'b011 :
             
             (stage1 == 0)? 3'b000 : (obs_on5[0]) ? 3'b011 :     
             (stage1 == 0)? 3'b000 : (obs_on5[1]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on5[2]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on5[3]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on5[4]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on5[5]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on5[6]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on5[7]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on5[8]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on5[9]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on5[10]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on5[11]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on5[12]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on5[13]) ? 3'b011 :
             (stage1 == 0)? 3'b000 : (obs_on5[14]) ? 3'b011 :
              
             //green        
             (stage2 == 0)? 3'b000 : (obs_on6[0]) ? 3'b010 : //2stage
             (stage2 == 0)? 3'b000 : (obs_on6[1]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on6[2]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on6[3]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on6[4]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on6[5]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on6[6]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on6[7]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on6[8]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on6[9]) ? 3'b010 :

             (stage2 == 0)? 3'b000 : (obs_on7[0]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on7[1]) ? 3'b010:
             (stage2 == 0)? 3'b000 : (obs_on7[2]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on7[3]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on7[4]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on7[5]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on7[6]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on7[7]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on7[8]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on7[9]) ? 3'b010 :

             (stage2 == 0)? 3'b000 : (obs_on8[0]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on8[1]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on8[2]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on8[3]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on8[4]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on8[5]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on8[6]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on8[7]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on8[8]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on8[9]) ? 3'b010 :

             (stage2 == 0)? 3'b000 : (obs_on9[0]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on9[1]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on9[2]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on9[3]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on9[4]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on9[5]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on9[6]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on9[7]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on9[8]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on9[9]) ? 3'b010 :

             (stage2 == 0)? 3'b000 : (obs_on10[0]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on10[1]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on10[2]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on10[3]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on10[4]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on10[5]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on10[6]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on10[7]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on10[8]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on10[9]) ? 3'b010 :

             (stage2 == 0)? 3'b000 : (obs_on11[0]) ? 3'b010 :     
             (stage2 == 0)? 3'b000 : (obs_on11[1]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on11[2]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on11[3]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on11[4]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on11[5]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on11[6]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on11[7]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on11[8]) ? 3'b010 :
             (stage2 == 0)? 3'b000 : (obs_on11[9]) ? 3'b010 :
             
             //blue
             (stage3 == 0)? 3'b000 : (obs_on12[0]) ? 3'b001 : //stage3     
             (stage3 == 0)? 3'b000 : (obs_on12[1]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on12[2]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on12[3]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on12[4]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on12[5]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on12[6]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on12[7]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on12[8]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on12[9]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on12[10]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on12[11]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on12[12]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on12[13]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on12[14]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on12[15]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on12[16]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on12[17]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on12[18]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on12[19]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on12[20]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on12[21]) ? 3'b001 : 
             
             (stage3 == 0)? 3'b000 : (obs_on13[0]) ? 3'b001 : //stage3     
             (stage3 == 0)? 3'b000 : (obs_on13[1]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on13[2]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on13[3]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on13[4]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on13[5]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on13[6]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on13[7]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on13[8]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on13[9]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on13[10]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on13[11]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on13[12]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on13[13]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on13[14]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on13[15]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on13[16]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on13[17]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on13[18]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on13[19]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on13[20]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on13[21]) ? 3'b001 : 
             
             (stage3 == 0)? 3'b000 : (obs_on14[0]) ? 3'b001 : //stage3     
             (stage3 == 0)? 3'b000 : (obs_on14[1]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on14[2]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on14[3]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on14[4]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on14[5]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on14[6]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on14[7]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on14[8]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on14[9]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on14[10]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on14[11]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on14[12]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on14[13]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on14[14]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on14[15]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on14[16]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on14[17]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on14[18]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on14[19]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on14[20]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on14[21]) ? 3'b001 : 
            
             (stage3 == 0)? 3'b000 : (obs_on15[0]) ? 3'b001 : //stage3     
             (stage3 == 0)? 3'b000 : (obs_on15[1]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on15[2]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on15[3]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on15[4]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on15[5]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on15[6]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on15[7]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on15[8]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on15[9]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on15[10]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on15[11]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on15[12]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on15[13]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on15[14]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on15[15]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on15[16]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on15[17]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on15[18]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on15[19]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on15[20]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on15[21]) ? 3'b001 : 
            
             (stage3 == 0)? 3'b000 : (obs_on16[0]) ? 3'b001 : //stage3     
             (stage3 == 0)? 3'b000 : (obs_on16[1]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on16[2]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on16[3]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on16[4]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on16[5]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on16[6]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on16[7]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on16[8]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on16[9]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on16[10]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on16[11]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on16[12]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on16[13]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on16[14]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on16[15]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on16[16]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on16[17]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on16[18]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on16[19]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on16[20]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on16[21]) ? 3'b001 : 
             
             (stage3 == 0)? 3'b000 : (obs_on17[0]) ? 3'b001 : //stage3     
             (stage3 == 0)? 3'b000 : (obs_on17[1]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on17[2]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on17[3]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on17[4]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on17[5]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on17[6]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on17[7]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on17[8]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on17[9]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on17[10]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on17[11]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on17[12]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on17[13]) ? 3'b001 :
             (stage3 == 0)? 3'b000 : (obs_on17[14]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on17[15]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on17[16]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on17[17]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on17[18]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on17[19]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on17[20]) ? 3'b001 :   
             (stage3 == 0)? 3'b000 : (obs_on17[21]) ? 3'b001 : 
             
             //magenta
             (stage4 == 0)? 3'b000 : (obs_on18[0]) ? 3'b101 : //stage4     
             (stage4 == 0)? 3'b000 : (obs_on18[1]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on18[2]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on18[3]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on18[4]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on18[5]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on18[6]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on18[7]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on18[8]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on18[9]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on18[10]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on18[11]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on18[12]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on18[13]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on18[14]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on18[15]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on18[16]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on18[17]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on18[18]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on18[19]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on18[20]) ? 3'b101 :   
             
             (stage4 == 0)? 3'b000 : (obs_on19[0]) ? 3'b101 : //stage4     
             (stage4 == 0)? 3'b000 : (obs_on19[1]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on19[2]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on19[3]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on19[4]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on19[5]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on19[6]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on19[7]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on19[8]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on19[9]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on19[10]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on19[11]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on19[12]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on19[13]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on19[14]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on19[15]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on19[16]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on19[17]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on19[18]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on19[19]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on19[20]) ? 3'b101 :   
             
             (stage4 == 0)? 3'b000 : (obs_on20[0]) ? 3'b101 : //stage4     
             (stage4 == 0)? 3'b000 : (obs_on20[1]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on20[2]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on20[3]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on20[4]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on20[5]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on20[6]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on20[7]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on20[8]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on20[9]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on20[10]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on20[11]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on20[12]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on20[13]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on20[14]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on20[15]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on20[16]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on20[17]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on20[18]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on20[19]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on20[20]) ? 3'b101 :   
             
             (stage4 == 0)? 3'b000 : (obs_on21[0]) ? 3'b101 : //stage4     
             (stage4 == 0)? 3'b000 : (obs_on21[1]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on21[2]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on21[3]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on21[4]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on21[5]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on21[6]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on21[7]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on21[8]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on21[9]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on21[10]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on21[11]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on21[12]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on21[13]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on21[14]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on21[15]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on21[16]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on21[17]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on21[18]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on21[19]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on21[20]) ? 3'b101 :   
             
             (stage4 == 0)? 3'b000 : (obs_on22[0]) ? 3'b101 : //stage4     
             (stage4 == 0)? 3'b000 : (obs_on22[1]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on22[2]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on22[3]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on22[4]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on22[5]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on22[6]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on22[7]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on22[8]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on22[9]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on22[10]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on22[11]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on22[12]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on22[13]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on22[14]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on22[15]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on22[16]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on22[17]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on22[18]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on22[19]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on22[20]) ? 3'b101 :   
             
             (stage4 == 0)? 3'b000 : (obs_on23[0]) ? 3'b101 : //stage4     
             (stage4 == 0)? 3'b000 : (obs_on23[1]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on23[2]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on23[3]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on23[4]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on23[5]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on23[6]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on23[7]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on23[8]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on23[9]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on23[10]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on23[11]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on23[12]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on23[13]) ? 3'b101 :
             (stage4 == 0)? 3'b000 : (obs_on23[14]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on23[15]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on23[16]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on23[17]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on23[18]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on23[19]) ? 3'b101 :   
             (stage4 == 0)? 3'b000 : (obs_on23[20]) ? 3'b101 :                                                                  

             3'b000 ; //black background   
//end
endmodule
