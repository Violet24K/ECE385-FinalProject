module treeAddress (input [9:0] DrawX, DrawY,
						  input [9:0] character_X, character_Y,
					output logic [14:0] tree_color_address);
			assign tree_color_address = (DrawY / 4 + character_Y / 32) * 200 + DrawX/4 + character_X / 32;
endmodule

module treeRAM
(
		input [14:0] tree_color_address,
		output logic [23:0] color_tree
);

	logic [3:0] mem[0: 29999];
	logic [23:0] colors_tree [2:0];
	assign colors_tree[0] = 24'h000000;
	assign colors_tree[1] = 24'h286f58;
	assign colors_tree[2] = 24'h289260;
	
	assign color_tree = colors_tree[mem[tree_color_address]];
	
	
	initial
	begin
		$readmemh("background/trees_200_150.txt", mem);
	end 
//	assign color_tree = 24'h286f58;

endmodule