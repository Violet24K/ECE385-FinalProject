//module music (input logic  Clk,
//				  input logic  [16:0]Add,
//				  output logic [16:0]music_content);
//				  
//	logic [16:0] music_memory [0:59999];
//	initial 
//	begin 
//		$readmemh("txt_town_day_hex_rom_20s.txt",music_memory);
//	end
//
//	always_ff @ (posedge Clk)
//		begin
//			music_content <= music_memory[Add];
//		end
//endmodule


module music (input logic  Clk,
				  input logic  [16:0]Add,
				  output logic [16:0]music_content);
				  
	logic [16:0] music_memory [0:109799];
	initial 
	begin 
		$readmemh("txt_town_day_hex_rom_36s.txt",music_memory);
	end

	always_ff @ (posedge Clk)
		begin
			music_content <= music_memory[Add];
		end
endmodule