module stoneAddress
(
    input   int           X_offset, Y_offset,
    output  logic [14:0]  stone_color_address
);
	assign stone_color_address = Y_offset * 16 + X_offset;
endmodule



module stoneRAM 
(
   input   logic [14:0]    stone_color_address, 
	output  logic [23:0]    color_stone // 3 * 8 = 24
);
	logic [23:0] stone_colors [15:0];
	assign stone_colors[ 0] = 24'h000000;
	assign stone_colors[ 1] = 24'h735035;
	assign stone_colors[ 2] = 24'h986B4A;
	assign stone_colors[ 3] = 24'hAD7B66;
	assign stone_colors[ 4] = 24'h47363D;
	
	
	logic [3 : 0]  stone        [0 : 575];      // 24 * 24 = 576

	initial
	begin
	    $readmemh("block/stone.txt", stone);   // dirt
	end

	always_comb
	begin
		color_stone = stone_colors[stone[stone_color_address]];
	end
endmodule



module stone
(
   input                Clk,                // 50 MHz clock
                        Reset,              // Active-high reset signal
   input [9:0]          DrawX, DrawY,       // Current pixel coordinates
	
   output logic         is_stone,        // Whether current pixel belongs to a block or background
   output logic [23:0]  color_stone
);

	parameter [9:0]   X_Start = 10'd46;
	parameter [9:0]   Y_Start = 10'd22;
   logic [14:0]      stone_color_address;

	int X_offset, Y_offset;

	assign X_offset = DrawX - DrawX / 16 * 16;
	assign Y_offset = DrawY - DrawY / 16 * 16;

   stoneAddress stone_address(.X_offset, .Y_offset, .stone_color_address);
   stoneRAM stone_ram(.stone_color_address, .color_stone);
	
	always_comb
	begin
		if ((DrawX >= X_Start) && (DrawX < X_Start + 16) && (DrawY >= Y_Start) && (DrawY < Y_Start + 16))
			is_stone = 1;
		else
			is_stone = 0;
	end
	
endmodule


