module coverAddress (input [9:0] DrawX, DrawY,
					output logic [14:0] cover_color_address);
	assign cover_color_address = DrawY / 4 * 160 + DrawX / 4;
endmodule

module coverRAM
(
	input [14:0] cover_color_address,
	output logic [23:0] color_cover
);
	logic [3:0] mem[0: 19199];  // 160 * 120 = 19200
	logic [23:0] colors_cover [15:0];
	assign colors_cover[ 0] = 24'h000000;
	assign colors_cover[ 1] = 24'hF7F6D8;
	assign colors_cover[ 2] = 24'h9FA2EB;
	assign colors_cover[ 3] = 24'h546AF5;
	assign colors_cover[ 4] = 24'h6B83FE;
	assign colors_cover[ 5] = 24'h3D8D2B;
	assign colors_cover[ 6] = 24'h387C5D;
	assign colors_cover[ 7] = 24'h1D600C;
	assign colors_cover[ 8] = 24'h46C864;
	assign colors_cover[ 9] = 24'h996A24;
	assign colors_cover[10] = 24'h494D56;
	assign colors_cover[11] = 24'h5174A6;
	assign colors_cover[12] = 24'h523E35;
	assign colors_cover[13] = 24'h747D82;
	assign colors_cover[14] = 24'h53B4B0;
	assign colors_cover[15] = 24'h2B3F39;

	assign color_cover = colors_cover[mem[cover_color_address]];

	initial
	begin
		$readmemh("UI/cover.txt", mem);
	end 

//	assign color_cover = 24'h6b83fe;
endmodule


module coverpage 
(
    input [9:0] DrawX, DrawY,
    output logic [23:0] color_cover
);
    logic [14:0] cover_color_address;
    coverAddress cover_address(.DrawX, .DrawY, .cover_color_address);
    coverRAM cover_ram(.cover_color_address, .color_cover);
endmodule