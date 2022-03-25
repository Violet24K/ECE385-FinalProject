module blockAddress
(
    input   int           X_offset, Y_offset,
    output  logic [14:0]  block_color_address
);
	assign block_color_address = Y_offset * 16 + X_offset;
endmodule


module blockRAM 
(
   input   logic [14:0]    block_color_address, 
   input   logic [1:0]     block_choice,
	output  logic [23:0]    color_block // 3 * 8 = 24
);
	logic [23:0] dirt_colors [15:0];
	assign dirt_colors[ 0] = 24'h000000;
	assign dirt_colors[ 1] = 24'h735035;
	assign dirt_colors[ 2] = 24'h986B4A;
	assign dirt_colors[ 3] = 24'hAD7B66;
	assign dirt_colors[ 4] = 24'h47363D;

	logic [23:0] grass_colors [15:0];
	assign grass_colors[ 0] = 24'h000000;
	assign grass_colors[ 1] = 24'h735035;
	assign grass_colors[ 2] = 24'h976B4B;
	assign grass_colors[ 3] = 24'h189746;
	assign grass_colors[ 4] = 24'h05651F;
	assign grass_colors[ 5] = 24'h15D95E;
	
	logic [23:0] stone_colors [15:0];
	assign stone_colors[ 0] = 24'h000000;
	assign stone_colors[ 1] = 24'h404040;
	assign stone_colors[ 2] = 24'h636363;
	assign stone_colors[ 3] = 24'h808080;
	assign stone_colors[ 4] = 24'hA5A5A5;
	assign stone_colors[ 5] = 24'hCBCBCB;

	logic [3 : 0]  dirt        [0 : 255];      // 16 * 16 = 256
	logic [3 : 0]  grass       [0 : 255];      // 16 * 16 = 256
	logic [3 : 0]  stone       [0 : 255];      // 16 * 16 = 256

	initial
	begin
	    $readmemh("block/block1.txt", dirt);   // dirt
	    $readmemh("block/grass.txt", grass);   // grass
		 $readmemh("block/stone.txt", stone);   // stone
	end

	always_comb
	begin
		color_block = 24'h000000;
      if (block_choice == 2'b01)       // dirt
		   color_block = dirt_colors[dirt[block_color_address]];
      else if (block_choice == 2'b10)  // grass
		   color_block = grass_colors[grass[block_color_address]];
		else if (block_choice == 2'b11)  // stone
		   color_block = stone_colors[stone[block_color_address]];
	end
endmodule


module blockRegAddress
(
    input   int           X, Y,
    output  int  block_reg_address
);
	assign block_reg_address = Y / 16 * 40 + X / 16;
endmodule


module blockReg 
(
   input logic Clk, Reset,

   input int block_reg_address_read,
	input int block_reg_address_write,

    // read from block_matrix 
   output logic is_block,
   output logic [1:0] block_choice,

   // write to block_matrix
   input logic WRITE,
	input logic BREAK,
	
	input logic [9:0] character_X, character_Y,
   input logic [9:0]	query_left_bound, query_right_bound, query_up_bound, query_down_bound,
   output logic left_exist_block, right_exist_block, up_exist_block, down_exist_block,
	input logic [1:0] holding_block
);
   logic [1199:0][1:0] matrix;  // 30 * 40

	initial begin
		for (int i = 0; i < 30; i++)
			begin
				for (int j = 0; j < 40; j++)
				begin
					if (i < 24)
						matrix[i * 40 + j] <= 2'b00;  // nothing
               else if (i == 24)
                  matrix[i * 40 + j] <= 2'b10;  // grass
					else
						matrix[i * 40 + j] <= 2'b01;  // dirt
				end
			end
		end

   always_ff @( posedge Clk )
   begin
      if (Reset)
            begin
               for (int i = 0; i < 30; i++)
               begin
                  for (int j = 0; j < 40; j++)
                  begin
                     if (i < 26)
                        matrix[i * 40 + j] <= 2'b00;  // nothing
                     else if (i == 26)
                        matrix[i * 40 + j] <= 2'b10;  // grass
                     else
                        matrix[i * 40 + j] <= 2'b01;  // dirt
                  end
               end
            end
		else if (WRITE)
			matrix[block_reg_address_write] <= holding_block;    // dirt
		else if (BREAK)
			matrix[block_reg_address_write] <= 2'b00;
   end

   always_comb
   begin
		is_block = 0;
      block_choice = 2'b00;   
		if ( matrix[block_reg_address_read] != 0 )
			is_block = 1;
         block_choice = matrix[block_reg_address_read];    
   end

   // query
	int query_address;
	int point_X, point_Y;
	int query_address1, point_X1, point_Y1;
	
   always_comb 
   begin
      // test left, test left
      left_exist_block = 0;
		
		// test_point1
		point_X = character_X - 15;
		point_Y = character_Y;
		query_address = point_Y / 16 * 40 + point_X/ 16;
		if (matrix[query_address] != 0)
			left_exist_block = 1;
			
		// test_point2
		point_X = character_X - 15;
		point_Y = character_Y - 14;
		query_address = point_Y / 16 * 40 + point_X/ 16;
		if (matrix[query_address] != 0)
			left_exist_block = 1;

		// test_point3
		point_X = character_X - 15;
		point_Y = character_Y + 14;
		query_address = point_Y / 16 * 40 + point_X/ 16;
		if (matrix[query_address] != 0)
			left_exist_block = 1;
		
		// test right, test right
      right_exist_block = 0;
		
		// test_point1
		point_X = character_X + 15;
		point_Y = character_Y;
		query_address = point_Y / 16 * 40 + point_X / 16;
		if (matrix[query_address] != 0)
			right_exist_block = 1;
			
		// test_point2
		point_X = character_X + 15;
		point_Y = character_Y - 14;
		query_address = point_Y / 16 * 40 + point_X / 16;
		if (matrix[query_address] != 0)
			right_exist_block = 1;

		// test_point3
		point_X = character_X + 15;
		point_Y = character_Y + 14;
		query_address = point_Y / 16 * 40 + point_X / 16;
		if (matrix[query_address] != 0)
			right_exist_block = 1;
		
		// test up, test up
      up_exist_block = 0;
		
		// test_point1
		point_X = character_X;
		point_Y = query_up_bound;
		query_address = point_Y / 16 * 40 + point_X / 16;
		if (matrix[query_address] != 0)
			up_exist_block = 1;
			
		// test_point2
		point_X = character_X - 14;
		point_Y = query_up_bound;
		query_address = point_Y / 16 * 40 + point_X / 16;
		if (matrix[query_address] != 0)
			up_exist_block = 1;
			
		// test_point3
		point_X = character_X + 14;
		point_Y = query_up_bound;
		query_address = point_Y / 16 * 40 + point_X / 16;
		if (matrix[query_address] != 0)
			up_exist_block = 1;
		
		// test down, test down
      down_exist_block = 0;
		
		// test_point1
		point_X = character_X;
		point_Y = query_down_bound;
		query_address = point_Y / 16 * 40 + point_X / 16;
		if (matrix[query_address] != 0)
			down_exist_block = 1;
			
		// test_point2
		point_X = character_X - 14;
		point_Y = query_down_bound;
		query_address = point_Y / 16 * 40 + point_X / 16;
		if (matrix[query_address] != 0)
			down_exist_block = 1;
		
		// test_point3
		point_X = character_X + 14;
		point_Y = query_down_bound;
		query_address = point_Y / 16 * 40 + point_X / 16;
		if (matrix[query_address] != 0)
			down_exist_block = 1;
   end
endmodule


module block
(
   input                Clk,                // 50 MHz clock
                        Reset,              // Active-high reset signal
                        frame_clk,          // The clock indicating a new frame (~60Hz)
   input [9:0]          DrawX, DrawY,       // Current pixel coordinates
	input [9:0]			   cursor_X, cursor_Y,
	input [9:0]			   character_X, character_Y,
	input logic			   cursor_left, cursor_right,

   input logic [9:0]	   query_left_bound, query_right_bound, query_up_bound, query_down_bound,
   output logic 		   left_exist_block, right_exist_block, up_exist_block, down_exist_block,

   output logic         is_block,        // Whether current pixel belongs to a block or background
   output logic [23:0]  color_block,
	input logic [1:0] holding_block
);
   logic [14:0]      block_color_address;
   logic [1:0]       block_choice;

	int block_reg_address_read;
	int block_reg_address_write;
	int X_offset, Y_offset;

	assign X_offset = DrawX - DrawX / 16 * 16;
	assign Y_offset = DrawY - DrawY / 16 * 16;

	blockRegAddress blockregaddress1(.X(DrawX), .Y(DrawY), .block_reg_address(block_reg_address_read));
	blockRegAddress blockregaddress2(.X(cursor_X), .Y(cursor_Y), .block_reg_address(block_reg_address_write));
	blockReg block_reg (.Clk, .Reset, .block_reg_address_read, .block_reg_address_write, 
						.is_block, .block_choice,
                  .WRITE(cursor_right), .BREAK(cursor_left),
                  .query_left_bound, .query_right_bound, .query_up_bound, .query_down_bound,
                  .left_exist_block, .right_exist_block, .up_exist_block, .down_exist_block,
						.character_X, .character_Y, .holding_block);
   blockAddress block_address(.X_offset, .Y_offset, .block_color_address);
   blockRAM block_ram(.block_color_address, .block_choice, .color_block);
endmodule
