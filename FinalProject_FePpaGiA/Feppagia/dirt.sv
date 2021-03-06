module dirtAddress
(
    input   int           X_offset, Y_offset,
    output  logic [14:0]  dirt_color_address
);
	assign dirt_color_address = Y_offset * 16 + X_offset;
endmodule



module dirtRAM 
(
   input   logic [14:0]    dirt_color_address, 
	output  logic [23:0]    color_dirt // 3 * 8 = 24
);
	logic [23:0] dirt_colors [15:0];
	assign dirt_colors[ 0] = 24'h000000;
	assign dirt_colors[ 1] = 24'h735035;
	assign dirt_colors[ 2] = 24'h986B4A;
	assign dirt_colors[ 3] = 24'hAD7B66;
	assign dirt_colors[ 4] = 24'h47363D;
	
	
	logic [3 : 0]  dirt        [0 : 575];      // 24 * 24 = 576

	initial
	begin
	    $readmemh("block/block1.txt", dirt);   // dirt
	end

	always_comb
	begin
		color_dirt = dirt_colors[dirt[dirt_color_address]];
	end
endmodule



module dirt
(
   input                Clk,                // 50 MHz clock
                        Reset,              // Active-high reset signal
   input [9:0]          DrawX, DrawY,       // Current pixel coordinates
	
   output logic         is_dirt,        // Whether current pixel belongs to a block or background
   output logic [23:0]  color_dirt
);

	parameter [9:0]   X_Start = 10'd22;
	parameter [9:0]   Y_Start = 10'd22;
   logic [14:0]      dirt_color_address;

	int X_offset, Y_offset;

	assign X_offset = DrawX - DrawX / 16 * 16;
	assign Y_offset = DrawY - DrawY / 16 * 16;

   dirtAddress dirt_address(.X_offset, .Y_offset, .dirt_color_address);
   dirtRAM dirt_ram(.dirt_color_address, .color_dirt);
	
	always_comb
	begin
		if ((DrawX >= X_Start) && (DrawX < X_Start + 16) && (DrawY >= Y_Start) && (DrawY < Y_Start + 16))
			is_dirt = 1;
		else
			is_dirt = 0;
	end
	
endmodule


