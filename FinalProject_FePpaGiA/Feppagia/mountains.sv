module mountainAddress (input [9:0] DrawX, DrawY,
								input [9:0] character_X, character_Y,
						  output logic [14:0] mountain_color_address);
						  
			assign mountain_color_address = (DrawY / 4 + character_Y / 64) * 200 + DrawX/4 + character_X / 16;
				  
endmodule




module mountainRAM
(
		input [14:0] mountain_color_address,
		output logic [23:0] color_mountain
);

	logic [3:0] mem[0: 29999];
	logic [23:0] colors [12:0];
	assign colors[0] = 24'h000000;
	assign colors[1] = 24'h5D4A48;
	assign colors[2] = 24'h6B6052;
	assign colors[3] = 24'h756C59;
	assign colors[4] = 24'h597960;
	assign colors[5] = 24'h618463;
	assign colors[6] = 24'h4F695A;
	assign colors[7] = 24'h7BA4B7;
	assign colors[8] = 24'h8AAFC0;
	assign colors[9] = 24'hADD3E1;
	assign colors[10] = 24'h667485;
	assign colors[11] = 24'h8593A6;
	
	
	assign color_mountain = colors[mem[mountain_color_address]];
	initial
	begin
	$readmemh("background/mountains_200_150.txt", mem);
	end 
//	assign color_mountain = 24'h000000;
	
	

	
	

endmodule