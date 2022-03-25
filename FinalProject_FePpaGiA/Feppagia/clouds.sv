module cloudAddress (input [9:0] DrawX, DrawY,
						   input int cloud_counter3,
							output logic [14:0] cloud_color_address);
			assign cloud_color_address = DrawY / 4* 160 + DrawX/4 - cloud_counter3/4;
endmodule

module cloudRAM
(
		input [14:0] cloud_color_address,
		output logic [23:0] color_cloud
);

	logic [3:0] mem[0: 19199];
	logic [23:0] colors_cloud [4:0];
	assign colors_cloud[0] = 24'h000000;
	assign colors_cloud[1] = 24'hDAECF2;
	assign colors_cloud[2] = 24'h97C5E7;
	assign colors_cloud[3] = 24'hB0D4EF;
	assign colors_cloud[4] = 24'hC6E0F4;
	
	
	assign color_cloud = colors_cloud[mem[cloud_color_address]];
	
	
	initial
	begin
		$readmemh("background/clouds.txt", mem);
	end 
//	assign color_cloud = 24'h286f58;

endmodule