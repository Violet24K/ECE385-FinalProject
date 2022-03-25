// color_mapper: Decide which color to be output to VGA for each pixel.
module  color_mapper ( input  logic start,
							  input	logic is_character,
							  input  logic is_cursor,
							  input  logic is_block,
							  input  logic is_bar0,
							  input  logic is_bar1,
							  input  logic is_dirt,
							  input  logic is_stone,
							  //input  logic is_tree,
							  //input  logic is_mountain,
							  input  logic [23:0] color_cover,
							  input  logic [23:0] color_tree,
							  input  logic [23:0] color_mountain,
							  input  logic [23:0] color_cloud,
							  input  logic [23:0] color_character,
							  input  logic [23:0] color_cursor,
							  input  logic [23:0] color_block,
							  input  logic [23:0] color_bar0,
							  input  logic [23:0] color_bar1,
							  input  logic [23:0] color_dirt,
							  input  logic [23:0] color_stone,
                                                              //   or background (computed in ball.sv)
                       input        [9:0] DrawX, DrawY,       // Current pixel coordinates
                       output logic [7:0] VGA_R, VGA_G, VGA_B // VGA RGB output
                     );

	logic [7:0] Red, Green, Blue;
    
   // Output colors to VGA
   assign VGA_R = Red;
   assign VGA_G = Green;
   assign VGA_B = Blue;
    
	always_comb
	begin
		if ( start == 0 )
		begin
			Red = color_cover[23:16];
			Green = color_cover[15:8];
			Blue = color_cover[7:0];
		end
	   else if (is_cursor == 1 && color_cursor != 24'h000000)
		begin
		   Red = color_cursor[23:16];
			Green = color_cursor[15:8];
			Blue = color_cursor[7:0];
		end
		else if (is_bar0 == 1 && color_bar0 != 24'h000000)
		begin
		   Red = color_bar0[23:16];
			Green = color_bar0[15:8];
			Blue = color_bar0[7:0];
		end
		else if (is_bar1 == 1 && color_bar1 != 24'h000000)
		begin
		   Red = color_bar1[23:16];
			Green = color_bar1[15:8];
			Blue = color_bar1[7:0];
		end
		else if (is_dirt == 1 && color_dirt != 24'h000000)
		begin
		   Red = color_dirt[23:16];
			Green = color_dirt[15:8];
			Blue = color_dirt[7:0];
		end
		else if (is_stone == 1 && color_stone != 24'h000000)
		begin
		   Red = color_stone[23:16];
			Green = color_stone[15:8];
			Blue = color_stone[7:0];
		end
	   else if (is_character == 1 && color_character != 24'h000000)
		begin
			Red = color_character[23:16];
			Green = color_character[15:8];
			Blue = color_character[7:0];
		end
		else if (is_block == 1 && color_block != 24'h000000)
		begin
			Red = color_block[23:16];
			Green = color_block[15:8];
			Blue = color_block[7:0];
		end
		else
		begin
			 if (color_tree != 24'h000000)
				begin
					Red = color_tree[23:16];
					Green = color_tree[15:8];
					Blue = color_tree[7:0];
				end
			 else if (color_cloud != 24'h000000)
			   begin
					Red = color_cloud[23:16];
					Green = color_cloud[15:8];
					Blue = color_cloud[7:0];
				end
			 else
				begin
					if (color_mountain == 24'h000000)
					begin
						Red = 8'h6b;
						Green = 8'h83;
						Blue = 8'hfe;
					end
					else
					begin
						Red = color_mountain[23:16];
						Green = color_mountain[15:8];
						Blue = color_mountain[7:0];
					end
			 end
		end
	end
endmodule


