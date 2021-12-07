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
wire [1:0]reach_wall;
wire reach_top;
wire reach_bottom;
reg game_stop, game_over;  
reg obs;
reg [4:0] stage_reg, stage_next;
parameter NEWGAME=2'b00, PLAY=2'b01, NEWGUN=2'b10, OVER=2'b11, STAGE1=3'b001, STAGE2=3'b010, STAGE3=3'b011, STAGE4=3'b100, CLEAR=3'b101;
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
reg [9:0] obs3_xl,obs3_xr,obs4_xl,obs4_xr,obs4_y_t,obs4_y_b,obs1_vy_reg, obs1_vx_reg , obs2_vx_reg ,obs2_vy_reg, obs3_vy_reg, obs3_vx_reg, obs4_vy_reg, obs4_vx_reg;
wire [9:0] obs_x_l[39:0], obs_x_r[39:0], obs_y_t[39:0], obs_y_b[39:0];
wire obs_on[39:0];
reg [3:0] level1_reg, level2_reg, level3_reg, level4_reg;
wire gone1 = ((obs_x_reg[0] >= 650) || (obs_x_reg[1] >= 650) || (obs_x_reg[2] >= 650) || (obs_x_reg[3] >= 650) || (obs_x_reg[4] >= 650) || (obs_x_reg[5] >= 650) || (obs_x_reg[6] >= 650) || (obs_x_reg[7] >= 650) || (obs_x_reg[8] >= 650) || (obs_x_reg[9] >= 650))? 1 : 0;
wire gone2 =((obs_x_reg[10] >= 650) || (obs_x_reg[11] >= 650) || (obs_x_reg[12] >= 650) || (obs_x_reg[13] >= 650) || (obs_x_reg[14] >= 650) || (obs_x_reg[15] >= 650) || (obs_x_reg[16] >= 650) || (obs_x_reg[17] >= 650) || (obs_x_reg[18] >= 650) || (obs_x_reg[19] >= 650))? 1 : 0;
wire gone3;
wire gone4;
assign obs_x_l[0] = obs_x_reg[0]; 
assign obs_x_r[0] = obs_x_l[0] + OBS_SIZE - 1; 
assign obs_y_t[0] = obs_y_reg[0]; 
assign obs_y_b[0] = obs_y_t[0] + OBS_SIZE - 1;
assign obs_on[0] = (x>=obs_x_l[0] && x<=obs_x_r[0] && y>=obs_y_t[0] && y<=obs_y_b[0])? 1 : 0; //obs regionion

always @ (posedge clk or posedge rst) begin
   if(rst | game_stop | (stage_reg==STAGE1)) begin
        obs_x_reg[0] <= 20; 
        obs_y_reg[0] <= 150;
   end 
    else if(refr_tick) begin
         obs_x_reg[0] <= obs_x_reg[0] + obs1_vx_reg; 
         obs_y_reg[0] <= obs_y_reg[0] + obs1_vy_reg;
    end
    else if ((shot_x_l >= obs_x_l[0]) && (shot_x_r <= obs_x_r[0]) && (shot_y_b <= obs_y_b[0])) begin
        obs_x_reg[0] <= 650;
        obs_y_reg[0] <= 480;
    end
end

assign obs_x_l[1] = obs_x_reg[1]; 
assign obs_x_r[1] = obs_x_l[1] + OBS_SIZE - 1; 
assign obs_y_t[1] = obs_y_reg[1]; 
assign obs_y_b[1] = obs_y_t[1] + OBS_SIZE - 1;
assign obs_on[1] = (x>=obs_x_l[1] && x<=obs_x_r[1] && y>=obs_y_t[1] && y<=obs_y_b[1])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop | (stage_reg==STAGE1)) begin
        obs_x_reg[1] <= 84; 
        obs_y_reg[1] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[1] <= obs_x_reg[1] + obs1_vx_reg; 
        obs_y_reg[1] <= obs_y_reg[1] + obs1_vy_reg;
    end
     else if ((shot_x_l >= obs_x_l[1]) && (shot_x_r <= obs_x_r[1]) && (shot_y_b <= obs_y_b[1])) begin
           obs_x_reg[1] <= 650;
           obs_y_reg[1] <= 480;
       end
end

assign obs_x_l[2] = obs_x_reg[2]; 
assign obs_x_r[2] = obs_x_l[2] + OBS_SIZE - 1; 
assign obs_y_t[2] = obs_y_reg[2]; 
assign obs_y_b[2] = obs_y_t[2] + OBS_SIZE - 1;
assign obs_on[2] = (x>=obs_x_l[2] && x<=obs_x_r[2] && y>=obs_y_t[2] && y<=obs_y_b[2])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop | (stage_reg==STAGE1)) begin
        obs_x_reg[2] <= 148; 
        obs_y_reg[2] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[2] <= obs_x_reg[2] + obs1_vx_reg; 
        obs_y_reg[2] <= obs_y_reg[2] + obs1_vy_reg;
    end
     else if ((shot_x_l >= obs_x_l[2]) && (shot_x_r <= obs_x_r[2]) && (shot_y_b <= obs_y_b[2])) begin
           obs_x_reg[2] <= 650;
           obs_y_reg[2] <= 480;
       end
end

assign obs_x_l[3] = obs_x_reg[3]; 
assign obs_x_r[3] = obs_x_l[3] + OBS_SIZE - 1; 
assign obs_y_t[3] = obs_y_reg[3]; 
assign obs_y_b[3] = obs_y_t[3] + OBS_SIZE - 1;
assign obs_on[3] = (x>=obs_x_l[3] && x<=obs_x_r[3] && y>=obs_y_t[3] && y<=obs_y_b[3])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop | (stage_reg==STAGE1)) begin
        obs_x_reg[3] <= 212; 
        obs_y_reg[3] <= 150;        
    end    
    else if (refr_tick) begin
        obs_x_reg[3] <= obs_x_reg[3] + obs1_vx_reg; 
        obs_y_reg[3] <= obs_y_reg[3] + obs1_vy_reg;
    end
     else if ((shot_x_l >= obs_x_l[3]) && (shot_x_r <= obs_x_r[3]) && (shot_y_b <= obs_y_b[3])) begin
           obs_x_reg[3] <= 650;
           obs_y_reg[3] <= 480;       
       end
end

assign obs_x_l[4] = obs_x_reg[4]; 
assign obs_x_r[4] = obs_x_l[4] + OBS_SIZE - 1; 
assign obs_y_t[4] = obs_y_reg[4]; 
assign obs_y_b[4] = obs_y_t[4] + OBS_SIZE - 1;
assign obs_on[4] = (x>=obs_x_l[4] && x<=obs_x_r[4] && y>=obs_y_t[4] && y<=obs_y_b[4])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop | (stage_reg==STAGE1)) begin
        obs_x_reg[4] <= 276; 
        obs_y_reg[4] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[4] <= obs_x_reg[4] + obs1_vx_reg; 
        obs_y_reg[4] <= obs_y_reg[4] + obs1_vy_reg;
    end
     else if ((shot_x_l >= obs_x_l[4]) && (shot_x_r <= obs_x_r[4]) && (shot_y_b <= obs_y_b[4])) begin
           obs_x_reg[4] <= 650;
           obs_y_reg[4] <= 480;      
       end
end

assign obs_x_l[5] = obs_x_reg[5]; 
assign obs_x_r[5] = obs_x_l[5] + OBS_SIZE - 1; 
assign obs_y_t[5] = obs_y_reg[5]; 
assign obs_y_b[5] = obs_y_t[5] + OBS_SIZE - 1;
assign obs_on[5] = (x>=obs_x_l[5] && x<=obs_x_r[5] && y>=obs_y_t[5] && y<=obs_y_b[5])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop | (stage_reg==STAGE1)) begin
        obs_x_reg[5] <= 340; 
        obs_y_reg[5] <= 150;    
    end    
    else if (refr_tick) begin
        obs_x_reg[5] <= obs_x_reg[5] + obs1_vx_reg; 
        obs_y_reg[5] <= obs_y_reg[5] + obs1_vy_reg;
    end
     else if ((shot_x_l >= obs_x_l[5]) && (shot_x_r <= obs_x_r[5]) && (shot_y_b <= obs_y_b[5])) begin
           obs_x_reg[5] <= 650;
           obs_y_reg[5] <= 480; 
       end
end

assign obs_x_l[6] = obs_x_reg[6]; 
assign obs_x_r[6] = obs_x_l[6] + OBS_SIZE - 1; 
assign obs_y_t[6] = obs_y_reg[6]; 
assign obs_y_b[6] = obs_y_t[6] + OBS_SIZE - 1;
assign obs_on[6] = (x>=obs_x_l[6] && x<=obs_x_r[6] && y>=obs_y_t[6] && y<=obs_y_b[6])? 1 : 0; //obs regionion
                   
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop | (stage_reg==STAGE1)) begin
        obs_x_reg[6] <= 404; 
        obs_y_reg[6] <= 150;      
    end    
    else if (refr_tick) begin
        obs_x_reg[6] <= obs_x_reg[6] + obs1_vx_reg; 
        obs_y_reg[6] <= obs_y_reg[6] + obs1_vy_reg;
    end
     else if ((shot_x_l >= obs_x_l[6]) && (shot_x_r <= obs_x_r[6]) && (shot_y_b <= obs_y_b[6])) begin
           obs_x_reg[6] <= 650;
           obs_y_reg[6] <= 480;     
       end
end

assign obs_x_l[7] = obs_x_reg[7]; 
assign obs_x_r[7] = obs_x_l[7] + OBS_SIZE - 1; 
assign obs_y_t[7] = obs_y_reg[7]; 
assign obs_y_b[7] = obs_y_t[7] + OBS_SIZE - 1;
assign obs_on[7] = (x>=obs_x_l[7] && x<=obs_x_r[7] && y>=obs_y_t[7] && y<=obs_y_b[7])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop | (stage_reg==STAGE1)) begin
        obs_x_reg[7] <= 468; 
        obs_y_reg[7] <= 150;   
    end    
    else if (refr_tick) begin
        obs_x_reg[7] <= obs_x_reg[7] + obs1_vx_reg; 
        obs_y_reg[7] <= obs_y_reg[7] + obs1_vy_reg;
    end
     else if ((shot_x_l >= obs_x_l[7]) && (shot_x_r <= obs_x_r[7]) && (shot_y_b <= obs_y_b[7])) begin
           obs_x_reg[7] <= 650;
           obs_y_reg[7] <= 480;       
       end
end

assign obs_x_l[8] = obs_x_reg[8]; 
assign obs_x_r[8] = obs_x_l[8] + OBS_SIZE - 1; 
assign obs_y_t[8] = obs_y_reg[8]; 
assign obs_y_b[8] = obs_y_t[8] + OBS_SIZE - 1;
assign obs_on[8] = (x>=obs_x_l[8] && x<=obs_x_r[8] && y>=obs_y_t[8] && y<=obs_y_b[8])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop | (stage_reg==STAGE1)) begin
        obs_x_reg[8] <= 532; 
        obs_y_reg[8] <= 150;      
    end    
    else if (refr_tick) begin
        obs_x_reg[8] <= obs_x_reg[8] + obs1_vx_reg; 
        obs_y_reg[8] <= obs_y_reg[8] + obs1_vy_reg;
    end
     else if ((shot_x_l >= obs_x_l[8]) && (shot_x_r <= obs_x_r[8]) && (shot_y_b <= obs_y_b[8])) begin
           obs_x_reg[8] <= 650;
           obs_y_reg[8] <= 480;    
       end
end

assign obs_x_l[9] = obs_x_reg[9]; 
assign obs_x_r[9] = obs_x_l[9] + OBS_SIZE - 1; 
assign obs_y_t[9] = obs_y_reg[9]; 
assign obs_y_b[9] = obs_y_t[9] + OBS_SIZE - 1;
assign obs_on[9] = (x>=obs_x_l[9] && x<=obs_x_r[9] && y>=obs_y_t[9] && y<=obs_y_b[9])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop | (stage_reg==STAGE1)) begin
        obs_x_reg[9] <= 590; 
        obs_y_reg[9] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[9] <= obs_x_reg[9] + obs1_vx_reg; 
        obs_y_reg[9] <= obs_y_reg[9] + obs1_vy_reg;
    end
     else if ((shot_x_l >= obs_x_l[9]) && (shot_x_r <= obs_x_r[9]) && (shot_y_b <= obs_y_b[9])) begin
           obs_x_reg[9] <= 650;
           obs_y_reg[9] <= 480;     
       end
end

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

always @ (posedge rst or posedge clk) begin
   if(rst | game_stop | (stage_reg==STAGE1)) begin
       level1_reg <= 3'b0;
   end
   else if(gone1 == 1) begin
       level1_reg <= level1_reg + 1;
   end
 end

//obs - 2stage
/*---------------------------------------------------------*/

assign obs_x_l[10] = obs_x_reg[10]; 
assign obs_x_r[10] = obs_x_l[10] + OBS_SIZE - 1; 
assign obs_y_t[10] = obs_y_reg[10]; 
assign obs_y_b[10] = obs_y_t[10] + OBS_SIZE - 1;
assign obs_on[10] = (x>=obs_x_l[10] && x<=obs_x_r[10] && y>=obs_y_t[10] && y<=obs_y_b[10])? 1 : 0; //obs regionion

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop | (stage_reg==STAGE2)) begin
        obs_x_reg[10] <= 20; 
        obs_y_reg[10] <=0; 
    end    
    else if(refr_tick) begin
        obs_x_reg[10] <= obs_x_reg[10] + obs1_vx_reg; 
        obs_y_reg[10] <= obs_y_reg[10] + obs1_vy_reg;
        end
     else if ((shot_x_l >= obs_x_l[10]) && (shot_x_r <= obs_x_r[10]) && (shot_y_b <= obs_y_b[10])) begin
           obs_x_reg[10] <= 650;
           obs_y_reg[10] <= 480;       
       end
end

assign obs_x_l[11] = obs_x_reg[11]; 
assign obs_x_r[11] = obs_x_l[11] + OBS_SIZE - 1; 
assign obs_y_t[11] = obs_y_reg[11]; 
assign obs_y_b[11] = obs_y_t[11] + OBS_SIZE - 1;
assign obs_on[11] = (x>=obs_x_l[11] && x<=obs_x_r[11] && y>=obs_y_t[11] && y<=obs_y_b[11])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop | (stage_reg==STAGE2)) begin
        obs_x_reg[11] <= 84; 
        obs_y_reg[11] <= 150;      
    end    
    else if (refr_tick) begin
        obs_x_reg[11] <= obs_x_reg[11] + obs1_vx_reg; 
        obs_y_reg[11] <= obs_y_reg[11] + obs1_vy_reg;
        end
     else if ((shot_x_l >= obs_x_l[11]) && (shot_x_r <= obs_x_r[11]) && (shot_y_b <= obs_y_b[11])) begin
           obs_x_reg[11] <= 650;
           obs_y_reg[11] <= 480;     
       end
end

assign obs_x_l[12] = obs_x_reg[12]; 
assign obs_x_r[12] = obs_x_l[12] + OBS_SIZE - 1; 
assign obs_y_t[12] = obs_y_reg[12]; 
assign obs_y_b[12] = obs_y_t[12] + OBS_SIZE - 1;
assign obs_on[12] = (x>=obs_x_l[12] && x<=obs_x_r[12] && y>=obs_y_t[12] && y<=obs_y_b[12])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop | (stage_reg==STAGE2)) begin
        obs_x_reg[12] <= 148; 
        obs_y_reg[12] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[12] <= obs_x_reg[12] + obs1_vx_reg; 
        obs_y_reg[12] <= obs_y_reg[12] + obs1_vy_reg;
        end
     else if ((shot_x_l >= obs_x_l[12]) && (shot_x_r <= obs_x_r[12]) && (shot_y_b <= obs_y_b[12])) begin
           obs_x_reg[12] <= 650;
           obs_y_reg[12] <= 480;
       end
end

assign obs_x_l[13] = obs_x_reg[13]; 
assign obs_x_r[13] = obs_x_l[13] + OBS_SIZE - 1; 
assign obs_y_t[13] = obs_y_reg[3]; 
assign obs_y_b[13] = obs_y_t[13] + OBS_SIZE - 1;
assign obs_on[13] = (x>=obs_x_l[13] && x<=obs_x_r[13] && y>=obs_y_t[13] && y<=obs_y_b[13])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop | (stage_reg==STAGE2)) begin
        obs_x_reg[13] <= 212; 
        obs_y_reg[13] <= 150;  
    end    
    else if (refr_tick) begin
        obs_x_reg[13] <= obs_x_reg[13] + obs1_vx_reg; 
        obs_y_reg[13] <= obs_y_reg[13] + obs1_vy_reg;
        end
     else if ((shot_x_l >= obs_x_l[13]) && (shot_x_r <= obs_x_r[13]) && (shot_y_b <= obs_y_b[13])) begin
           obs_x_reg[13] <= 650;
           obs_y_reg[13] <= 480;         
       end
end

assign obs_x_l[14] = obs_x_reg[14]; 
assign obs_x_r[14] = obs_x_l[14] + OBS_SIZE - 1; 
assign obs_y_t[14] = obs_y_reg[14]; 
assign obs_y_b[14] = obs_y_t[14] + OBS_SIZE - 1;
assign obs_on[14] = (x>=obs_x_l[14] && x<=obs_x_r[14] && y>=obs_y_t[14] && y<=obs_y_b[14])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop | (stage_reg==STAGE2)) begin
        obs_x_reg[14] <= 276; 
        obs_y_reg[14] <= 150;       
    end    
    else if (refr_tick) begin
        obs_x_reg[14] <= obs_x_reg[14] + obs1_vx_reg; 
        obs_y_reg[14] <= obs_y_reg[14] + obs1_vy_reg;
        end
    else if ((shot_x_l >= obs_x_l[14]) && (shot_x_r <= obs_x_r[14]) && (shot_y_b <= obs_y_b[14])) begin
        obs_x_reg[14] <= 650;
        obs_y_reg[14] <= 480;            
    end
end

assign obs_x_l[15] = obs_x_reg[15]; 
assign obs_x_r[15] = obs_x_l[15] + OBS_SIZE - 1; 
assign obs_y_t[15] = obs_y_reg[15]; 
assign obs_y_b[15] = obs_y_t[15] + OBS_SIZE - 1;
assign obs_on[15] = (x>=obs_x_l[15] && x<=obs_x_r[15] && y>=obs_y_t[15] && y<=obs_y_b[15])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop | (stage_reg==STAGE2)) begin
        obs_x_reg[15] <= 340; 
        obs_y_reg[15] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[15] <= obs_x_reg[15] + obs1_vx_reg; 
        obs_y_reg[15] <= obs_y_reg[15] + obs1_vy_reg;
        end
    else if ((shot_x_l >= obs_x_l[15]) && (shot_x_r <= obs_x_r[15]) && (shot_y_b <= obs_y_b[15])) begin
                   obs_x_reg[15] <= 650;
                   obs_y_reg[15] <= 480;
               end
end

assign obs_x_l[16] = obs_x_reg[16]; 
assign obs_x_r[16] = obs_x_l[16] + OBS_SIZE - 1; 
assign obs_y_t[16] = obs_y_reg[16]; 
assign obs_y_b[16] = obs_y_t[16] + OBS_SIZE - 1;
assign obs_on[16] = (x>=obs_x_l[16] && x<=obs_x_r[16] && y>=obs_y_t[16] && y<=obs_y_b[16])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop | (stage_reg==STAGE2)) begin
        obs_x_reg[16] <= 404; 
        obs_y_reg[16] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[16] <= obs_x_reg[16] + obs1_vx_reg; 
        obs_y_reg[16] <= obs_y_reg[16] + obs1_vy_reg;
        end
    else if ((shot_x_l >= obs_x_l[16]) && (shot_x_r <= obs_x_r[16]) && (shot_y_b <= obs_y_b[16])) begin
                   obs_x_reg[16] <= 650;
                   obs_y_reg[16] <= 480;
               end
end

assign obs_x_l[17] = obs_x_reg[17]; 
assign obs_x_r[17] = obs_x_l[17] + OBS_SIZE - 1; 
assign obs_y_t[17] = obs_y_reg[17]; 
assign obs_y_b[17] = obs_y_t[17] + OBS_SIZE - 1;
assign obs_on[17] = (x>=obs_x_l[17] && x<=obs_x_r[17] && y>=obs_y_t[17] && y<=obs_y_b[17])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop | (stage_reg==STAGE2)) begin
        obs_x_reg[17] <= 468; 
        obs_y_reg[17] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[17] <= obs_x_reg[17] + obs1_vx_reg; 
        obs_y_reg[17] <= obs_y_reg[17] + obs1_vy_reg;
        end
    else if ((shot_x_l >= obs_x_l[17]) && (shot_x_r <= obs_x_r[17]) && (shot_y_b <= obs_y_b[17])) begin
                   obs_x_reg[17] <= 650;
                   obs_y_reg[17] <= 480;
               end
end

assign obs_x_l[18] = obs_x_reg[18]; 
assign obs_x_r[18] = obs_x_l[18] + OBS_SIZE - 1; 
assign obs_y_t[18] = obs_y_reg[18]; 
assign obs_y_b[18] = obs_y_t[18] + OBS_SIZE - 1;
assign obs_on[18] = (x>=obs_x_l[18] && x<=obs_x_r[18] && y>=obs_y_t[18] && y<=obs_y_b[18])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop | (stage_reg==STAGE2)) begin
        obs_x_reg[18] <= 532; 
        obs_y_reg[18] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[18] <= obs_x_reg[18] + obs1_vx_reg; 
        obs_y_reg[18] <= obs_y_reg[18] + obs1_vy_reg;
        end
    else if ((shot_x_l >= obs_x_l[18]) && (shot_x_r <= obs_x_r[18]) && (shot_y_b <= obs_y_b[18])) begin
                   obs_x_reg[18] <= 650;
                   obs_y_reg[18] <= 480;
               end
end

assign obs_x_l[19] = obs_x_reg[19]; 
assign obs_x_r[19] = obs_x_l[19] + OBS_SIZE - 1; 
assign obs_y_t[19] = obs_y_reg[19]; 
assign obs_y_b[19] = obs_y_t[19] + OBS_SIZE - 1;
assign obs_on[19] = (x>=obs_x_l[19] && x<=obs_x_r[19] && y>=obs_y_t[19] && y<=obs_y_b[19])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop | (stage_reg==STAGE2)) begin
        obs_x_reg[19] <= 590; 
        obs_y_reg[19] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[19] <= obs_x_reg[19] + obs1_vx_reg; 
        obs_y_reg[19] <= obs_y_reg[19] + obs1_vy_reg;
        end
   else if ((shot_x_l >= obs_x_l[19]) && (shot_x_r <= obs_x_r[19]) && (shot_y_b <= obs_y_b[19])) begin
                   obs_x_reg[19] <= 650;
                   obs_y_reg[19] <= 480;
               end
end


always @ (posedge clk or posedge rst) begin
    if(rst | game_stop | (stage_reg==STAGE2)) begin
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
assign obs_on[20] = (x>=obs_x_l[20] && x<=obs_x_r[20] && y>=obs_y_t[20] && y<=obs_y_b[20])? 1 : 0; //obs regionion

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[20] <= 20; 
        obs_y_reg[20] <=0; 
    end    
    else if(refr_tick) begin
        obs_x_reg[20] <= obs_x_reg[20] + obs1_vx_reg; 
        obs_y_reg[20] <= obs_y_reg[20] + obs1_vy_reg;
        end
    else if ((shot_x_l >= obs_x_l[20]) && (shot_x_r <= obs_x_r[20]) && (shot_y_b <= obs_y_b[20])) begin
         obs_x_reg[20] <= 650;
         obs_y_reg[20] <= 480;
    end
end

assign obs_x_l[21] = obs_x_reg[21]; 
assign obs_x_r[21] = obs_x_l[21] + OBS_SIZE - 1; 
assign obs_y_t[21] = obs_y_reg[21]; 
assign obs_y_b[21] = obs_y_t[21] + OBS_SIZE - 1;
assign obs_on[21] = (x>=obs_x_l[21] && x<=obs_x_r[21] && y>=obs_y_t[21] && y<=obs_y_b[31])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[21] <= 84; 
        obs_y_reg[21] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[21] <= obs_x_reg[21] + obs1_vx_reg; 
        obs_y_reg[21] <= obs_y_reg[21] + obs1_vy_reg;
        end
   else if ((shot_x_l >= obs_x_l[21]) && (shot_x_r <= obs_x_r[21]) && (shot_y_b <= obs_y_b[21])) begin
        obs_x_reg[21] <= 650;
        obs_y_reg[21] <= 480;
    end
end

assign obs_x_l[22] = obs_x_reg[22]; 
assign obs_x_r[22] = obs_x_l[22] + OBS_SIZE - 1; 
assign obs_y_t[22] = obs_y_reg[22]; 
assign obs_y_b[22] = obs_y_t[22] + OBS_SIZE - 1;
assign obs_on[22] = (x>=obs_x_l[22] && x<=obs_x_r[22] && y>=obs_y_t[22] && y<=obs_y_b[22])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[22] <= 148; 
        obs_y_reg[22] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[22] <= obs_x_reg[22] + obs1_vx_reg; 
        obs_y_reg[22] <= obs_y_reg[22] + obs1_vy_reg;
        end
    else if ((shot_x_l >= obs_x_l[22]) && (shot_x_r <= obs_x_r[22]) && (shot_y_b <= obs_y_b[22])) begin
        obs_x_reg[22] <= 650;
        obs_y_reg[22] <= 480;
    end
end

assign obs_x_l[23] = obs_x_reg[23]; 
assign obs_x_r[23] = obs_x_l[23] + OBS_SIZE - 1; 
assign obs_y_t[23] = obs_y_reg[23]; 
assign obs_y_b[23] = obs_y_t[23] + OBS_SIZE - 1;
assign obs_on[23] = (x>=obs_x_l[23] && x<=obs_x_r[23] && y>=obs_y_t[23] && y<=obs_y_b[23])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[23] <= 212; 
        obs_y_reg[23] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[23] <= obs_x_reg[23] + obs1_vx_reg; 
        obs_y_reg[23] <= obs_y_reg[23] + obs1_vy_reg;
        end
    else if ((shot_x_l >= obs_x_l[23]) && (shot_x_r <= obs_x_r[23]) && (shot_y_b <= obs_y_b[23])) begin
        obs_x_reg[23] <= 650;
        obs_y_reg[23] <= 480;
    end
end

assign obs_x_l[24] = obs_x_reg[24]; 
assign obs_x_r[24] = obs_x_l[24] + OBS_SIZE - 1; 
assign obs_y_t[24] = obs_y_reg[24]; 
assign obs_y_b[24] = obs_y_t[24] + OBS_SIZE - 1;
assign obs_on[24] = (x>=obs_x_l[24] && x<=obs_x_r[24] && y>=obs_y_t[24] && y<=obs_y_b[24])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[24] <= 276; 
        obs_y_reg[24] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[24] <= obs_x_reg[24] + obs1_vx_reg; 
        obs_y_reg[24] <= obs_y_reg[24] + obs1_vy_reg;
        end
    else if ((shot_x_l >= obs_x_l[24]) && (shot_x_r <= obs_x_r[24]) && (shot_y_b <= obs_y_b[24])) begin
        obs_x_reg[24] <= 650;
        obs_y_reg[24] <= 480;
    end
end

assign obs_x_l[25] = obs_x_reg[25]; 
assign obs_x_r[25] = obs_x_l[25] + OBS_SIZE - 1; 
assign obs_y_t[25] = obs_y_reg[25]; 
assign obs_y_b[25] = obs_y_t[25] + OBS_SIZE - 1;
assign obs_on[25] = (x>=obs_x_l[25] && x<=obs_x_r[25] && y>=obs_y_t[25] && y<=obs_y_b[25])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[25] <= 340; 
        obs_y_reg[25] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[25] <= obs_x_reg[25] + obs1_vx_reg; 
        obs_y_reg[25] <= obs_y_reg[25] + obs1_vy_reg;
        end
    else if ((shot_x_l >= obs_x_l[25]) && (shot_x_r <= obs_x_r[25]) && (shot_y_b <= obs_y_b[25])) begin
        obs_x_reg[25] <= 650;
        obs_y_reg[25] <= 480;
    end
end

assign obs_x_l[26] = obs_x_reg[26]; 
assign obs_x_r[26] = obs_x_l[26] + OBS_SIZE - 1; 
assign obs_y_t[26] = obs_y_reg[26]; 
assign obs_y_b[26] = obs_y_t[26] + OBS_SIZE - 1;
assign obs_on[26] = (x>=obs_x_l[26] && x<=obs_x_r[26] && y>=obs_y_t[26] && y<=obs_y_b[26])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[26] <= 404; 
        obs_y_reg[26] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[26] <= obs_x_reg[26] + obs1_vx_reg; 
        obs_y_reg[26] <= obs_y_reg[26] + obs1_vy_reg;
        end
    else if ((shot_x_l >= obs_x_l[26]) && (shot_x_r <= obs_x_r[26]) && (shot_y_b <= obs_y_b[26])) begin
        obs_x_reg[26] <= 650;
        obs_y_reg[26] <= 480;
    end
end

assign obs_x_l[27] = obs_x_reg[27]; 
assign obs_x_r[27] = obs_x_l[27] + OBS_SIZE - 1; 
assign obs_y_t[27] = obs_y_reg[27]; 
assign obs_y_b[27] = obs_y_t[27] + OBS_SIZE - 1;
assign obs_on[27] = (x>=obs_x_l[27] && x<=obs_x_r[27] && y>=obs_y_t[27] && y<=obs_y_b[27])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[27] <= 468; 
        obs_y_reg[27] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[27] <= obs_x_reg[27] + obs1_vx_reg; 
        obs_y_reg[27] <= obs_y_reg[27] + obs1_vy_reg;
        end
    else if ((shot_x_l >= obs_x_l[27]) && (shot_x_r <= obs_x_r[27]) && (shot_y_b <= obs_y_b[27])) begin
        obs_x_reg[27] <= 650;
        obs_y_reg[27] <= 480;
    end
end

assign obs_x_l[28] = obs_x_reg[28]; 
assign obs_x_r[28] = obs_x_l[28] + OBS_SIZE - 1; 
assign obs_y_t[28] = obs_y_reg[28]; 
assign obs_y_b[28] = obs_y_t[28] + OBS_SIZE - 1;
assign obs_on[28] = (x>=obs_x_l[28] && x<=obs_x_r[28] && y>=obs_y_t[28] && y<=obs_y_b[28])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[28] <= 532; 
        obs_y_reg[28] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[28] <= obs_x_reg[28] + obs1_vx_reg; 
        obs_y_reg[28] <= obs_y_reg[28] + obs1_vy_reg;
        end
    else if ((shot_x_l >= obs_x_l[28]) && (shot_x_r <= obs_x_r[28]) && (shot_y_b <= obs_y_b[28])) begin
        obs_x_reg[28] <= 650;
        obs_y_reg[28] <= 480;
    end
end

assign obs_x_l[29] = obs_x_reg[29]; 
assign obs_x_r[29] = obs_x_l[29] + OBS_SIZE - 1; 
assign obs_y_t[29] = obs_y_reg[29]; 
assign obs_y_b[29] = obs_y_t[29] + OBS_SIZE - 1;
assign obs_on[29] = (x>=obs_x_l[29] && x<=obs_x_r[29] && y>=obs_y_t[29] && y<=obs_y_b[29])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[29] <= 590; 
        obs_y_reg[29] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[29] <= obs_x_reg[29] + obs1_vx_reg; 
        obs_y_reg[29] <= obs_y_reg[29] + obs1_vy_reg;
        end
    else if ((shot_x_l >= obs_x_l[29]) && (shot_x_r <= obs_x_r[29]) && (shot_y_b <= obs_y_b[29])) begin
        obs_x_reg[29] <= 650;
        obs_y_reg[29] <= 480;
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
assign obs_on[30] = (x>=obs_x_l[30] && x<=obs_x_r[30] && y>=obs_y_t[30] && y<=obs_y_b[30])? 1 : 0; //obs regionion

always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[30] <= 20; 
        obs_y_reg[30] <=0; 
    end    
    else if(refr_tick) begin
        obs_x_reg[30] <= obs_x_reg[30] + obs1_vx_reg; 
        obs_y_reg[30] <= obs_y_reg[30] + obs1_vy_reg;
        end
    else if ((shot_x_l >= obs_x_l[30]) && (shot_x_r <= obs_x_r[30]) && (shot_y_b <= obs_y_b[30])) begin
        obs_x_reg[30] <= 650;
        obs_y_reg[30] <= 480;
    end
end

assign obs_x_l[31] = obs_x_reg[31]; 
assign obs_x_r[31] = obs_x_l[31] + OBS_SIZE - 1; 
assign obs_y_t[31] = obs_y_reg[31]; 
assign obs_y_b[31] = obs_y_t[31] + OBS_SIZE - 1;
assign obs_on[31] = (x>=obs_x_l[31] && x<=obs_x_r[31] && y>=obs_y_t[31] && y<=obs_y_b[31])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[31] <= 84; 
        obs_y_reg[31] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[31] <= obs_x_reg[31] + obs1_vx_reg; 
        obs_y_reg[31] <= obs_y_reg[31] + obs1_vy_reg;
        end
    else if ((shot_x_l >= obs_x_l[31]) && (shot_x_r <= obs_x_r[31]) && (shot_y_b <= obs_y_b[31])) begin
        obs_x_reg[31] <= 650;
        obs_y_reg[31] <= 480;
    end
end

assign obs_x_l[32] = obs_x_reg[32]; 
assign obs_x_r[32] = obs_x_l[32] + OBS_SIZE - 1; 
assign obs_y_t[32] = obs_y_reg[32]; 
assign obs_y_b[32] = obs_y_t[32] + OBS_SIZE - 1;
assign obs_on[32] = (x>=obs_x_l[32] && x<=obs_x_r[32] && y>=obs_y_t[32] && y<=obs_y_b[32])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[32] <= 148; 
        obs_y_reg[32] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[32] <= obs_x_reg[32] + obs1_vx_reg; 
        obs_y_reg[32] <= obs_y_reg[32] + obs1_vy_reg;
        end
    else if ((shot_x_l >= obs_x_l[32]) && (shot_x_r <= obs_x_r[32]) && (shot_y_b <= obs_y_b[32])) begin
        obs_x_reg[32] <= 650;
        obs_y_reg[32] <= 480;
    end
end

assign obs_x_l[33] = obs_x_reg[33]; 
assign obs_x_r[33] = obs_x_l[33] + OBS_SIZE - 1; 
assign obs_y_t[33] = obs_y_reg[33]; 
assign obs_y_b[33] = obs_y_t[33] + OBS_SIZE - 1;
assign obs_on[33] = (x>=obs_x_l[33] && x<=obs_x_r[33] && y>=obs_y_t[33] && y<=obs_y_b[33])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[33] <= 212; 
        obs_y_reg[33] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[33] <= obs_x_reg[33] + obs1_vx_reg; 
        obs_y_reg[33] <= obs_y_reg[33] + obs1_vy_reg;
        end
    else if ((shot_x_l >= obs_x_l[33]) && (shot_x_r <= obs_x_r[33]) && (shot_y_b <= obs_y_b[33])) begin
        obs_x_reg[33] <= 650;
        obs_y_reg[33] <= 480;
    end
end

assign obs_x_l[34] = obs_x_reg[34]; 
assign obs_x_r[34] = obs_x_l[34] + OBS_SIZE - 1; 
assign obs_y_t[34] = obs_y_reg[34]; 
assign obs_y_b[34] = obs_y_t[34] + OBS_SIZE - 1;
assign obs_on[34] = (x>=obs_x_l[34] && x<=obs_x_r[34] && y>=obs_y_t[34] && y<=obs_y_b[34])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[34] <= 276; 
        obs_y_reg[34] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[34] <= obs_x_reg[34] + obs1_vx_reg; 
        obs_y_reg[34] <= obs_y_reg[34] + obs1_vy_reg;
        end
    else if ((shot_x_l >= obs_x_l[34]) && (shot_x_r <= obs_x_r[34]) && (shot_y_b <= obs_y_b[34])) begin
        obs_x_reg[34] <= 650;
        obs_y_reg[34] <= 480;
    end
end

assign obs_x_l[35] = obs_x_reg[35]; 
assign obs_x_r[35] = obs_x_l[35] + OBS_SIZE - 1; 
assign obs_y_t[35] = obs_y_reg[35]; 
assign obs_y_b[35] = obs_y_t[35] + OBS_SIZE - 1;
assign obs_on[35] = (x>=obs_x_l[35] && x<=obs_x_r[35] && y>=obs_y_t[35] && y<=obs_y_b[35])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[35] <= 340; 
        obs_y_reg[35] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[35] <= obs_x_reg[35] + obs1_vx_reg; 
        obs_y_reg[35] <= obs_y_reg[35] + obs1_vy_reg;
        end
    else if ((shot_x_l >= obs_x_l[35]) && (shot_x_r <= obs_x_r[35]) && (shot_y_b <= obs_y_b[35])) begin
        obs_x_reg[35] <= 650;
        obs_y_reg[35] <= 480;
    end
end

assign obs_x_l[36] = obs_x_reg[36]; 
assign obs_x_r[36] = obs_x_l[36] + OBS_SIZE - 1; 
assign obs_y_t[36] = obs_y_reg[36]; 
assign obs_y_b[36] = obs_y_t[36] + OBS_SIZE - 1;
assign obs_on[36] = (x>=obs_x_l[36] && x<=obs_x_r[36] && y>=obs_y_t[36] && y<=obs_y_b[36])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[36] <= 404; 
        obs_y_reg[36] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[36] <= obs_x_reg[36] + obs1_vx_reg; 
        obs_y_reg[36] <= obs_y_reg[36] + obs1_vy_reg;
        end
    else if ((shot_x_l >= obs_x_l[36]) && (shot_x_r <= obs_x_r[36]) && (shot_y_b <= obs_y_b[36])) begin
        obs_x_reg[36] <= 650;
        obs_y_reg[36] <= 480;
    end
end

assign obs_x_l[37] = obs_x_reg[37]; 
assign obs_x_r[37] = obs_x_l[37] + OBS_SIZE - 1; 
assign obs_y_t[37] = obs_y_reg[37]; 
assign obs_y_b[37] = obs_y_t[37] + OBS_SIZE - 1;
assign obs_on[37] = (x>=obs_x_l[37] && x<=obs_x_r[37] && y>=obs_y_t[37] && y<=obs_y_b[37])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[37] <= 468; 
        obs_y_reg[37] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[37] <= obs_x_reg[37] + obs1_vx_reg; 
        obs_y_reg[37] <= obs_y_reg[37] + obs1_vy_reg;
        end
    else if ((shot_x_l >= obs_x_l[37]) && (shot_x_r <= obs_x_r[37]) && (shot_y_b <= obs_y_b[37])) begin
        obs_x_reg[37] <= 650;
        obs_y_reg[37] <= 480;
    end
end

assign obs_x_l[38] = obs_x_reg[38]; 
assign obs_x_r[38] = obs_x_l[38] + OBS_SIZE - 1; 
assign obs_y_t[38] = obs_y_reg[38]; 
assign obs_y_b[38] = obs_y_t[38] + OBS_SIZE - 1;
assign obs_on[38] = (x>=obs_x_l[38] && x<=obs_x_r[38] && y>=obs_y_t[38] && y<=obs_y_b[38])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[38] <= 532; 
        obs_y_reg[38] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[38] <= obs_x_reg[38] + obs1_vx_reg; 
        obs_y_reg[38] <= obs_y_reg[38] + obs1_vy_reg;
        end
    else if ((shot_x_l >= obs_x_l[38]) && (shot_x_r <= obs_x_r[38]) && (shot_y_b <= obs_y_b[38])) begin
        obs_x_reg[38] <= 650;
        obs_y_reg[38] <= 480;
    end
end

assign obs_x_l[39] = obs_x_reg[39]; 
assign obs_x_r[39] = obs_x_l[39] + OBS_SIZE - 1; 
assign obs_y_t[39] = obs_y_reg[39]; 
assign obs_y_b[39] = obs_y_t[39] + OBS_SIZE - 1;
assign obs_on[39] = (x>=obs_x_l[39] && x<=obs_x_r[39] && y>=obs_y_t[39] && y<=obs_y_b[39])? 1 : 0; //obs regionion
always @ (posedge clk or posedge rst) begin
    if(rst | game_stop) begin
        obs_x_reg[39] <= 590; 
        obs_y_reg[39] <= 150; 
    end    
    else if (refr_tick) begin
        obs_x_reg[39] <= obs_x_reg[39] + obs1_vx_reg; 
        obs_y_reg[39] <= obs_y_reg[39] + obs1_vy_reg;
        end
   else if ((shot_x_l >= obs_x_l[39]) && (shot_x_r <= obs_x_r[39]) && (shot_y_b <= obs_y_b[39])) begin
        obs_x_reg[39] <= 650;
        obs_y_reg[39] <= 480;
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
reg [1:0] state_reg, state_next;
reg [1:0] life_reg, life_next;

always @ (*) begin
    game_stop = 1; 
    d_clr = 0;
    d_inc = 0;
    life_next = life_reg;
    stage_next = stage_reg;
    game_over = 0;
    case(stage_reg)
       STAGE1 : begin
       case(state_reg) 
               NEWGAME: begin //new game
                   d_clr = 1; //score init
                   if(key[4] == 1) begin //if key push,
                       state_next = PLAY; //game start
                       life_next = 2'b10; //left life 2
                       stage_next = 3'b010; //level up
                   end else begin
                       state_next = NEWGAME; //no key push,
                       life_next = 2'b11; //left life 3
                       stage_next = 'b001; //level init
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
                       if(level1_reg == 9)
                        stage_next = STAGE2;
                       state_next = PLAY; 
               end
               NEWGUN: //new gun
                   if(key[4] == 1) state_next = PLAY;
                   else state_next = NEWGUN; 
               OVER: begin
                   if(key[4] == 1) begin //key push, ne game
                       state_next = STAGE1;
                   end else begin
                       state_next = OVER;
                   end
                   game_over = 1;
               end 
               default: 
                   state_next = STAGE2;
           endcase 
        end
        STAGE2 : begin
       case(state_reg) 
                NEWGAME: begin //new game
                    d_clr = 1; //score init
                    if(key[4] == 1) begin //if key push,
                        state_next = PLAY; //game start
                        life_next = 2'b10; //left life 2
                        stage_next = 3'b011; //level up
                    end else begin
                        state_next = NEWGAME; //no key push,
                        life_next = 2'b11; //left life 3
                        stage_next = 3'b010; //level init
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
                        if(hit == 10)
                         stage_next = STAGE3;
                        state_next = PLAY; 
                end
                NEWGUN: //new gun
                    if(key[4] == 1) state_next = PLAY;
                    else state_next = NEWGUN; 
                OVER: begin
                    if(key[4] == 1) begin //key push, ne game
                        state_next = STAGE1;
                    end else begin
                        state_next = OVER;
                    end
                    game_over = 1;
                end 
                default: 
                    state_next = STAGE3;
            endcase 
         end
        STAGE3 : begin
       case(state_reg) 
                NEWGAME: begin //new game
                    d_clr = 1; //score init
                    if(key[4] == 1) begin //if key push,
                        state_next = PLAY; //game start
                        life_next = 2'b10; //left life 2
                        stage_next = 3'b011; //level up
                    end else begin
                        state_next = NEWGAME; //no key push,
                        life_next = 2'b11; //left life 3
                        stage_next = 3'b010; //level init
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
                        if(hit == 10)
                         stage_next = STAGE4;
                        state_next = PLAY; 
                end
                NEWGUN: //new gun
                    if(key[4] == 1) state_next = PLAY;
                    else state_next = NEWGUN; 
                OVER: begin
                    if(key[4] == 1) begin //key push, ne game
                        state_next = STAGE1;
                    end else begin
                        state_next = OVER;
                    end
                    game_over = 1;
                end 
                default: 
                    state_next = STAGE4;
            endcase     
         end
        STAGE4 : begin
       case(state_reg) 
                NEWGAME: begin //new game
                    d_clr = 1; //score init
                    if(key[4] == 1) begin //if key push,
                        state_next = PLAY; //game start
                        life_next = 2'b10; //left life 2
                        stage_next = 3'b101; //level up
                    end else begin
                        state_next = NEWGAME; //no key push,
                        life_next = 2'b11; //left life 3
                        stage_next = 3'b100; //level init
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
                        if(hit == 10)
                         stage_next = CLEAR;
                        state_next = PLAY; 
                end
                NEWGUN: //new gun
                    if(key[4] == 1) state_next = PLAY;
                    else state_next = NEWGUN; 
                OVER: begin
                    if(key[4] == 1) begin //key push, ne game
                        state_next = STAGE1;
                    end else begin
                        state_next = OVER;
                    end
                    game_over = 1;
                end 
                default: 
                    state_next = CLEAR;
            endcase 
         end                  
        CLEAR : begin
                //clear �޽��� ����
        end  
        default :
            stage_next = STAGE1;
        endcase
end
always @ (posedge clk or posedge rst) begin
    if(rst) begin
        stage_reg <= STAGE1;
        state_reg <= NEWGAME; 
        life_reg <= 0;
    end 
    else begin
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