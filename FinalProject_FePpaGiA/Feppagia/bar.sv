module bar 
(
   input logic Clk, Reset,
	input logic cursor_roll_left,
	input logic cursor_roll_right,
   output logic [1:0] holding_block,
	output logic [1:0] item_bar
);
   logic [1:0] item_bar_next;  // [dirt, stone]
	logic roll_left_only_once, roll_right_only_once;
	logic rolled_left, rolled_right;
	
	
	
   initial begin
      item_bar = 2'b10;    // hold dirt
		rolled_left = 0;
		rolled_right = 0;
   end

   always_ff @( posedge Clk ) begin
	   // left only once
		if( cursor_roll_left && (rolled_left == 0))
		begin
			roll_left_only_once <= 1;
			rolled_left <= 1;
		end
		
		if( roll_left_only_once == 1)
			roll_left_only_once <= 0;
		
		if( (cursor_roll_left == 0) && rolled_left)
		begin
			rolled_left <= 0;
		end
		
		// right only once
		if( cursor_roll_right && (rolled_right == 0))
		begin
			roll_right_only_once <= 1;
			rolled_right <= 1;
		end
		
		if( roll_right_only_once == 1)
			roll_right_only_once <= 0;
		
		if( (cursor_roll_right == 0) && rolled_right)
		begin
			rolled_right <= 0;
		end
	
	
      if (Reset)
         item_bar <= 2'b10;
      else if (roll_left_only_once)
			begin
            if (item_bar == 2'b10)
					item_bar <= 2'b01;
				else
					item_bar <= (item_bar << 1);
			end
		else if (roll_right_only_once)
			begin
				if(item_bar == 2'b01)
					item_bar <= 2'b10;
				else
					item_bar <= (item_bar >> 1);
			end
   end

   always_comb begin
      holding_block = 2'b00;
      if (item_bar[1] == 1)
         holding_block = 2'b01;  // dirt
      else if (item_bar[0] == 1)
         holding_block = 2'b11;  // stone
   end
endmodule




module barAddress
(
    input   int           X_offset, Y_offset,
    output  logic [14:0]  bar_color_address
);
	assign bar_color_address = Y_offset * 24 + X_offset;
endmodule


module barRAM 
(
   input   logic [14:0]    bar_color_address, 
   input   logic bar_choice,
	output  logic [23:0]    color_bar // 3 * 8 = 24
);
	logic [23:0] bar0_colors [15:0];
	assign bar0_colors[ 0] = 24'h000000;
	assign bar0_colors[ 1] = 24'h525656;

	logic [23:0] bar1_colors [15:0];
	assign bar1_colors[ 0] = 24'h000000;
	assign bar1_colors[ 1] = 24'h1A0000;
	assign bar1_colors[ 2] = 24'h3E1A09;
	assign bar1_colors[ 3] = 24'h2F271E;
	assign bar1_colors[ 4] = 24'h78563D;
	assign bar1_colors[ 5] = 24'h4F4231;
	assign bar1_colors[ 6] = 24'hB39774;
	
	
	logic [3 : 0]  bar0        [0 : 575];      // 24 * 24 = 576
	logic [3 : 0]  bar1       [0 : 575];      // 24 * 24 = 576

	initial
	begin
	    $readmemh("itembar/bar_0.txt", bar0);   // dirt
	    $readmemh("itembar/bar_1.txt", bar1);   // grass

	end

	always_comb
	begin
		color_bar = 24'h000000;
      if (bar_choice == 0)       // dirt
		   color_bar = bar0_colors[bar0[bar_color_address]];
		else
		   color_bar = bar1_colors[bar1[bar_color_address]];
	end
endmodule



module itembar0
(
   input                Clk,                // 50 MHz clock
                        Reset,              // Active-high reset signal
   input [9:0]          DrawX, DrawY,       // Current pixel coordinates
	
   output logic         is_bar0,        // Whether current pixel belongs to a block or background
   output logic [23:0]  color_bar0,
	input logic [1:0] item_bar
);

	parameter [9:0]   X_Start = 10'd20;
	parameter [9:0]   Y_Start = 10'd20;
   logic [14:0]      bar_color_address;
   logic bar_choice;

	int block_reg_address_read;
	int block_reg_address_write;
	int X_offset, Y_offset;

	assign X_offset = DrawX - DrawX / 24 * 24;
	assign Y_offset = DrawY - DrawY / 24 * 24;

   barAddress bar_address(.X_offset, .Y_offset, .bar_color_address);
   barRAM bar_ram(.bar_color_address, .bar_choice, .color_bar(color_bar0));
	
	always_comb
	begin
		if (item_bar == 2'b10)
			bar_choice = 1;
		else
			bar_choice = 0;
		if ((DrawX >= X_Start) && (DrawX < X_Start + 24) && (DrawY >= Y_Start) && (DrawY < Y_Start + 24))
			is_bar0 = 1;
		else
			is_bar0 = 0;
	end
	
endmodule


module itembar1
(
   input                Clk,                // 50 MHz clock
                        Reset,              // Active-high reset signal
   input [9:0]          DrawX, DrawY,       // Current pixel coordinates
	
   output logic         is_bar1,        // Whether current pixel belongs to a block or background
   output logic [23:0]  color_bar1,
	input logic [1:0] item_bar
);

	parameter [9:0]   X_Start = 10'd44;
	parameter [9:0]   Y_Start = 10'd20;
   logic [14:0]      bar_color_address;
   logic bar_choice;

	int block_reg_address_read;
	int block_reg_address_write;
	int X_offset, Y_offset;

	assign X_offset = DrawX - DrawX / 24 * 24;
	assign Y_offset = DrawY - DrawY / 24 * 24;

   barAddress bar_address(.X_offset, .Y_offset, .bar_color_address);
   barRAM bar_ram(.bar_color_address, .bar_choice, .color_bar(color_bar1));
	
	always_comb
	begin
		if (item_bar == 2'b01)
			bar_choice = 1;
		else
			bar_choice = 0;
		if ((DrawX >= X_Start) && (DrawX < X_Start + 24) && (DrawY >= Y_Start) && (DrawY < Y_Start + 24))
			is_bar1 = 1;
		else
			is_bar1 = 0;
	end
	
endmodule
