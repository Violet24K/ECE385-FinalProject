module lab8( input               CLOCK_50,
             input        [3:0]  KEY,          //bit 0 is set up as Reset
             output logic [6:0]  HEX0, HEX1, HEX2, HEX3,
				 output logic [7:0]  LEDG,
				 output logic [17:0] LEDR,

             // VGA Interface
             output logic [7:0]  VGA_R,        //VGA Red
                                 VGA_G,        //VGA Green
                                 VGA_B,        //VGA Blue
             output logic        VGA_CLK,      //VGA Clock
                                 VGA_SYNC_N,   //VGA Sync signal
                                 VGA_BLANK_N,  //VGA Blank signal
                                 VGA_VS,       //VGA virtical sync signal
                                 VGA_HS,       //VGA horizontal sync signal

             // CY7C67200 Interface
             inout  wire  [15:0] OTG_DATA,     //CY7C67200 Data bus 16 Bits
             output logic [1:0]  OTG_ADDR,     //CY7C67200 Address 2 Bits
             output logic        OTG_CS_N,     //CY7C67200 Chip Select
                                 OTG_RD_N,     //CY7C67200 Write
                                 OTG_WR_N,     //CY7C67200 Read
                                 OTG_RST_N,    //CY7C67200 Reset
             input               OTG_INT,      //CY7C67200 Interrupt

             // SDRAM Interface for Nios II Software
             output logic [12:0] DRAM_ADDR,    //SDRAM Address 13 Bits
             inout  wire  [31:0] DRAM_DQ,      //SDRAM Data 32 Bits
             output logic [1:0]  DRAM_BA,      //SDRAM Bank Address 2 Bits
             output logic [3:0]  DRAM_DQM,     //SDRAM Data Mast 4 Bits
             output logic        DRAM_RAS_N,   //SDRAM Row Address Strobe
                                 DRAM_CAS_N,   //SDRAM Column Address Strobe
                                 DRAM_CKE,     //SDRAM Clock Enable
                                 DRAM_WE_N,    //SDRAM Write Enable
                                 DRAM_CS_N,    //SDRAM Chip Select
                                 DRAM_CLK,      //SDRAM Clock

            // music interface
            output logic AUD_DACDAT, I2C_SDAT, I2C_SCLK, AUD_XCK,
            input logic AUD_BCLK,
            input logic AUD_ADCDAT,
            input logic AUD_DACLRCK, AUD_ADCLRCK);

    logic Reset_h, Clk;
    logic [7:0] led;
	 logic [17:0] ledr;
	 logic [15:0] keycode, keycode_mouse;
	 
	 
	 // variables for the cover
	 logic start = 0, start_next;
	 
	 // variables for the moving clouds;
	 int cloud_counter1 = 0, cloud_counter1_next;
	 int cloud_counter2 = 0, cloud_counter2_next;
	 int cloud_counter3 = 0, cloud_counter3_next;
	 
    assign Clk = CLOCK_50;
    always_ff @ (posedge Clk) begin
       Reset_h <= ~(KEY[0]);        // The push buttons are active low
		 LEDG <= led;
		 LEDR <= ledr;
		 start <= start_next;
		 cloud_counter1 <= cloud_counter1_next;
		 cloud_counter2 <= cloud_counter2_next;
		 cloud_counter3 <= cloud_counter3_next;
    end

    logic [1:0] hpi_addr;
    logic [15:0] hpi_data_in, hpi_data_out;
    logic hpi_r, hpi_w, hpi_cs, hpi_reset;

	 // local variables
    logic [9:0] DrawX, DrawY;
	 logic [9:0] cursor_X, cursor_Y;
	 logic cursor_left, cursor_right;
	 logic cursor_roll_left, cursor_roll_right;
	 logic [9:0] character_X, character_Y;
	 
	 // item bar
	 logic [1:0] holding_block;
	 logic [1:0] item_bar;
	 
	 
	 
	 // variables for collision detection
	 
	 logic [9:0] query_left_bound, query_right_bound, query_up_bound, query_down_bound;
	 logic left_exist_block, right_exist_block, up_exist_block, down_exist_block;
	 logic [3:0]  stop_at;

	 // variables for drawing
	 logic is_tree;
    logic is_mountain;
	 logic is_character;
	 logic is_cursor;
	 logic is_block;
	 logic is_bar0;
	 logic is_bar1;
	 logic is_dirt;
	 logic is_stone;
	 
	 logic [23:0] color_cover;
    logic [23:0] color_tree;
    logic [23:0] color_mountain;
	 logic [23:0] color_cloud;
    logic [23:0] color_character;
	 logic [23:0] color_cursor;
	 logic [23:0] color_block;
	 logic [23:0] color_bar0;
	 logic [23:0] color_bar1;
	 logic [23:0] color_dirt;
	 logic [23:0] color_stone;
	 
	 logic [14:0] cover_color_address;
    logic [14:0] tree_color_address;
    logic [14:0] mountain_color_address;
	 logic [14:0] cloud_color_address;
    logic [14:0] character_color_address;
	 logic [14:0] cursor_color_address;
	 

    
    // variables for music
    logic [16:0] music_address;
    logic [16:0] music_content;
    logic INIT;
    logic INIT_FINISH;
    logic data_over;
    logic adc_full;
    logic [31:0] ADCDATA;
	 
    // Interface between NIOS II and EZ-OTG chip
    hpi_io_intf hpi_io_inst(
                            .Clk(Clk),
                            .Reset(Reset_h),
                            // signals connected to NIOS II
                            .from_sw_address(hpi_addr),
                            .from_sw_data_in(hpi_data_in),
                            .from_sw_data_out(hpi_data_out),
                            .from_sw_r(hpi_r),
                            .from_sw_w(hpi_w),
                            .from_sw_cs(hpi_cs),
                            .from_sw_reset(hpi_reset),
                            // signals connected to EZ-OTG chip
                            .OTG_DATA(OTG_DATA),
                            .OTG_ADDR(OTG_ADDR),
                            .OTG_RD_N(OTG_RD_N),
                            .OTG_WR_N(OTG_WR_N),
                            .OTG_CS_N(OTG_CS_N),
                            .OTG_RST_N(OTG_RST_N)
    );

    // You need to make sure that the port names here match the ports in Qsys-generated codes.
    lab7_soc nios_system(
        .clk_clk(Clk),
        .reset_reset_n(1'b1),    // Never reset NIOS
        .sdram_wire_addr(DRAM_ADDR),
        .sdram_wire_ba(DRAM_BA),
        .sdram_wire_cas_n(DRAM_CAS_N),
        .sdram_wire_cke(DRAM_CKE),
        .sdram_wire_cs_n(DRAM_CS_N),
        .sdram_wire_dq(DRAM_DQ),
        .sdram_wire_dqm(DRAM_DQM),
        .sdram_wire_ras_n(DRAM_RAS_N),
        .sdram_wire_we_n(DRAM_WE_N),
        .sdram_clk_clk(DRAM_CLK),
        .keycode_external_connection_export(keycode),
        .keycode_mouse_external_connection_export(keycode_mouse),
        .otg_hpi_address_external_connection_export(hpi_addr),
        .otg_hpi_data_external_connection_in_port(hpi_data_in),
        .otg_hpi_data_external_connection_out_port(hpi_data_out),
        .otg_hpi_cs_external_connection_export(hpi_cs),
        .otg_hpi_r_external_connection_export(hpi_r),
        .otg_hpi_w_external_connection_export(hpi_w),
        .otg_hpi_reset_external_connection_export(hpi_reset)
    );

    // Use PLL to generate the 25MHZ VGA_CLK.
    vga_clk vga_clk_instance(.inclk0(Clk), .c0(VGA_CLK));
	 

    // VGA wants to draw at (DrawX, DrawY)
    VGA_controller vga_controller_instance(
        .Clk,
        .Reset(Reset_h),
        .VGA_HS,
        .VGA_VS,
        .VGA_CLK,
        .VGA_BLANK_N,
        .VGA_SYNC_N,
        .DrawX,
        .DrawY
    );

	 // characters
	 character character_instance(
        .Clk,
        .Reset(Reset_h),
        .frame_clk(VGA_VS),
        .DrawX,
        .DrawY,
		  .character_X,
		  .character_Y,
        .keycode,
        .is_character,
		  .color_character,
		  .stop_at
    );

	 // cursor
	 cursor cursor_instance(
        .Clk,
        .Reset(Reset_h),
        .frame_clk(VGA_VS),
        .DrawX,
        .DrawY,
        .keycode_mouse,
        .is_cursor,
        .color_cursor,
        .cursor_X,
        .cursor_Y,
		  .cursor_left,
		  .cursor_right,
		  .cursor_roll_left,
		  .cursor_roll_right
	 );
	
	 // blocks
	 block block_instance(
		  .Clk,
		  .Reset(Reset_h),
		  .frame_clk(VGA_VS),
		  .DrawX,
		  .DrawY,
		  .is_block,
		  .color_block,
		  .cursor_X,
		  .cursor_Y,
		  .cursor_left,
		  .cursor_right,
		  .character_X,
		  .character_Y,
		  .query_left_bound, .query_right_bound, .query_up_bound, .query_down_bound,
        .left_exist_block, .right_exist_block, .up_exist_block, .down_exist_block,
		  .holding_block
	 );
	 
	 
	 // item bar
	 bar bar_instance(.Clk, .Reset(Reset_h), .cursor_roll_left, .cursor_roll_right,
							.holding_block, .item_bar);
							
	 itembar0 bar0(.Clk,
                     .Reset(Reset_h),              
							.DrawX, .DrawY,       
							.is_bar0,
							.color_bar0,
							.item_bar
	 );
	 itembar1 bar1(.Clk,
                     .Reset(Reset_h),              
							.DrawX, .DrawY,       
							.is_bar1,
							.color_bar1,
							.item_bar
    );
	 
	 dirt dirt_instance(.Clk,
                     .Reset(Reset_h),              
							.DrawX, .DrawY,       
							.is_dirt,
							.color_dirt,
	 );
	 
	 stone stone_instance(.Clk,
                     .Reset(Reset_h),              
							.DrawX, .DrawY,       
							.is_stone,
							.color_stone,
	 );
	
	 // judge for collision
	 judge judge_instance(
			.character_X, .character_Y,
			.left_exist_block, .right_exist_block, .up_exist_block, .down_exist_block,
			.stop_at,
			.query_left_bound, .query_right_bound, .query_up_bound, .query_down_bound
	 );

    // trees
    treeAddress tree_address(.DrawX, .DrawY, .character_X, .character_Y, .tree_color_address);
    treeRAM tree_ram(.tree_color_address, .color_tree);

    // mountains
    mountainAddress mountain_address(.DrawX, .DrawY, .character_X, .character_Y, .mountain_color_address );
    mountainRAM mountain_ram(.mountain_color_address, .color_mountain);
	 
	 // clouds
	 cloudAddress cloud_address(.DrawX, .DrawY, .cloud_counter3, .cloud_color_address );
    cloudRAM cloud_ram(.cloud_color_address, .color_cloud);

	 // cover--Welcome to Feppagia!
	 coverpage cover_page(.DrawX, .DrawY, .color_cover);
	 
    // what do we draw at (DrawX, DrawY)
    color_mapper color_instance(
		  .start,
        .is_character,
		  .is_cursor,
		  .is_block,
		  .is_bar0,
		  .is_bar1,
		  .is_dirt,
		  .is_stone,
		  .color_cover,
        .color_tree,
        .color_mountain,
		  .color_cloud,
        .color_character,
		  .color_cursor,
		  .color_block,
		  .color_bar0,
		  .color_bar1,
		  .color_dirt,
		  .color_stone,
        .DrawX,
        .DrawY,
        .VGA_R,
        .VGA_G,
        .VGA_B
    );
	 
	 
	 
	 // music interface
    audio_interface audiointerface
    (	
      .LDATA(music_content), .RDATA(music_content),
      .clk(Clk), .Reset(Reset_h), .INIT(INIT),
      .INIT_FINISH(INIT_FINISH),
      .adc_full(adc_full), 			//OUT std_logic;
      .data_over(data_over),
      .AUD_MCLK(AUD_XCK),              //OUT std_logic; -- Codec master clock OUTPUT
      .AUD_BCLK(AUD_BCLK),              //IN std_logic; -- Digital Audio bit clock
      .AUD_ADCDAT(AUD_ADCDAT), 			//IN std_logic;
      .AUD_DACDAT(AUD_DACDAT),            //OUT std_logic; -- DAC data line
      .AUD_DACLRCK(AUD_DACLRCK), .AUD_ADCLRCK(AUD_ADCLRCK),           //IN std_logic; -- DAC data left/right select
      .I2C_SDAT(I2C_SDAT),              //OUT std_logic; -- serial interface data line
      .I2C_SCLK(I2C_SCLK),              //OUT std_logic;  -- serial interface clock
      .ADCDATA(ADCDATA)  				//OUT std_logic_vector(31 downto 0)
    );

    music musicmodule(.Clk, .Add(music_address), .music_content);
    
    audio audiomodule( .Clk, .Reset(Reset_h), 
                      .INIT_FINISH,
                      .data_over,
                      .INIT,
                      .Add(music_address));

    // Display keycode on hex display
    HexDriver hex_inst_0 (keycode[3:0], HEX0);
    HexDriver hex_inst_1 (keycode[7:4], HEX1);
	 HexDriver hex_inst_2 (keycode[11:8], HEX2);
	 HexDriver hex_inst_3 (keycode[15:12], HEX3);

    always_comb
    begin
		  start_next = start;
		  if (keycode[3:0] == 4'h2c)
				start_next = 1;
			
		  if (Reset_h)
				start_next = 0;
        led=8'b00000000;
		  
		  // cloud
		  cloud_counter1_next = cloud_counter1 + 1;
		  cloud_counter2_next = cloud_counter2;
		  cloud_counter3_next = cloud_counter3;
		  
		  if (cloud_counter1 == 50000)
		  begin
				cloud_counter1_next = 0;
		      cloud_counter2_next = cloud_counter2 + 1;
		  end
		  if (cloud_counter2 == 100)
		  begin
				cloud_counter2_next = 0;
				cloud_counter3_next = cloud_counter3 + 1;
		  end
		  if (cloud_counter3 == 639)
				cloud_counter3_next = 0;
		  
//      case(keycode)
//        8'h04:begin
//          led=8'b0010;
//          end
//        8'h07:begin
//          led=8'b0001;
//          end
//        8'h1a:begin
//          led=8'b1000;
//          end
//        8'h16:begin
//          led=8'b0100;
//          end
//      endcase
//		  case(keycode_mouse)
//          16'h0060:begin
//            led=8'b0010;
//            end
//          16'h005c:begin
//            led=8'b0001;
//            end
//          16'h005e:begin
//            led=8'b1000;
//            end
//          16'h005d:begin
//            led=8'b0100;
//            end
//        endcase
         led = keycode_mouse[7:0];
			
			
			ledr = 17'b0;
			ledr[3:0] = stop_at;
			ledr[17] = item_bar[1];
			ledr[16] = item_bar[0];
	  end
endmodule
