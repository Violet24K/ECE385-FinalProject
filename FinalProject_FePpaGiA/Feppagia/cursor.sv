module cursorAddress
(
    input  int           X_offset, Y_offset,
    output logic [14:0]  cursor_color_address
);
	assign cursor_color_address =  Y_offset * 14 + X_offset;
endmodule

module cursorRAM
(
	input   logic [14:0]    cursor_color_address, 
	output  logic [23:0]    color_cursor // 3 * 8
);
	logic [23:0] colors [15:0];

	assign colors[ 0] = 24'h000000;
	assign colors[ 1] = 24'hFFFFFF;
	assign colors[ 2] = 24'hAAAAAA;
	assign colors[ 3] = 24'hDCDCDC;

	logic [3 : 0]  cursor [0 : 195];      // 14 * 14 = 196

	initial
	begin
	    $readmemh("UI/cursor.txt", cursor);
	end
	
	always_comb
	begin
        color_cursor = colors[cursor[cursor_color_address]];
	end
endmodule

module cursor   
(   
   input               Clk,                // 50 MHz clock
                       Reset,              // Active-high reset signal
                       frame_clk,          // The clock indicating a new frame (~60Hz)
   input [9:0]         DrawX, DrawY,       // Current pixel coordinates
   input [15:0]        keycode_mouse,      // key pressed

	output logic        is_cursor,          // Whether current pixel belongs to cursor or background
   output logic [23:0] color_cursor,
   output logic [9:0]  cursor_X, cursor_Y,
   output logic cursor_left, cursor_right,
	output logic cursor_roll_left, cursor_roll_right
);
   parameter [9:0] ball_X_Start = 10'd400;      // Start position on the X axis
   parameter [9:0] ball_Y_Start = 10'd400;      // Start position on the Y axis

   parameter [9:0] ball_X_Min = 10'd0;        // Leftmost point on the X axis
   parameter [9:0] ball_X_Max = 10'd639;      // Rightmost point on the X axis
   parameter [9:0] ball_Y_Min = 10'd0;        // Topmost point on the Y axis
   parameter [9:0] ball_Y_Max = 10'd479;      // Bottommost point on the Y axis

   parameter [9:0] ball_X_Step = 10'd3;       // Step size on the X axis
   parameter [9:0] ball_Y_Step = 10'd3;       // Step size on the Y axis

   parameter [9:0] height = 10'd14;      // ball height
   parameter [9:0] width = 10'd14;       // ball width
	 
   logic [14:0]  cursor_color_address;

   // variables for position and speed
   logic [9:0] ball_X_Pos, ball_X_Motion, ball_Y_Pos, ball_Y_Motion;
   logic [9:0] ball_X_Pos_in, ball_X_Motion_in, ball_Y_Pos_in, ball_Y_Motion_in;


   // Detect rising edge of frame_clk
   logic frame_clk_delayed, frame_clk_rising_edge;
	
	
	initial
	begin
		ball_X_Pos      <= ball_X_Start;
		ball_Y_Pos      <= ball_Y_Start;
		ball_X_Motion   <= 10'd0;
		ball_Y_Motion   <= 10'd0;
	end 
	
	
   always_ff @ (posedge Clk) begin
      frame_clk_delayed <= frame_clk;
      frame_clk_rising_edge <= (frame_clk == 1'b1) && (frame_clk_delayed == 1'b0);
   end

   // Update registers
   always_ff @ (posedge Clk)
   begin
      if (Reset)
			begin
            ball_X_Pos      <= ball_X_Start;
            ball_Y_Pos      <= ball_Y_Start;
            ball_X_Motion   <= 10'd0;
            ball_Y_Motion   <= 10'd0;
         end
      else
         begin
				ball_X_Pos      <= ball_X_Pos_in;
				ball_Y_Pos      <= ball_Y_Pos_in;
				ball_X_Motion   <= ball_X_Motion_in;
				ball_Y_Motion   <= ball_Y_Motion_in;
         end
   end

   // 4-left, 6-right, 8-up, 5-down ; 7-left click, 9-right-click
	always_comb
   begin
       // By default, keep motion and position unchanged
      ball_X_Pos_in = ball_X_Pos;
      ball_Y_Pos_in = ball_Y_Pos;
      ball_X_Motion_in = ball_X_Motion;
      ball_Y_Motion_in = ball_Y_Motion;
		cursor_left = 0;
		cursor_right = 0;
		cursor_roll_left = 0;
		cursor_roll_right = 0;
		if ((keycode_mouse[7:0] == 8'h5f) || (keycode_mouse[15:8] == 8'h5f) )
			cursor_left = 1;
		else if ((keycode_mouse[7:0] == 8'h61) || (keycode_mouse[15:8] == 8'h61))
			cursor_right = 1;
		if ((keycode_mouse[7:0] == 8'h59) || (keycode_mouse[15:8] == 8'h59) )
			cursor_roll_left = 1;
		else if ((keycode_mouse[7:0] == 8'h5b) || (keycode_mouse[15:8] == 8'h5b))
			cursor_roll_right = 1;

  

			// Update position and motion only at rising edge of frame clock
      if (frame_clk_rising_edge)
		begin
			case (keycode_mouse[15:0])
				// 4: left
				16'h005c :
					begin
						// motion control
						ball_X_Motion_in = (~(ball_X_Step) + 1'b1);
						ball_Y_Motion_in = 0;
						// boundary checks
//                            if( ball_Y_Pos >= ball_Y_Max )  // ball is at the bottom edge, STOP!
//                                ball_Y_Motion_in = 0;  
//                            else if ( ball_Y_Pos <= ball_Y_Min )  // ball is at the top edge, STOP!
//                                ball_Y_Motion_in = 0;
//                            if ( ball_X_Pos + ball_X_Motion_in <= ball_X_Min )  // ball is at the left edge, STOP!
//                                ball_X_Motion_in = 0;
//									 else if ( ball_X_Pos >= ball_X_Max ) // ball is at the right edge, STOP!
//										  ball_X_Motion_in = 0;
					end

				// 6: right
				16'h005e :
					begin
						// motion control
						ball_X_Motion_in = ball_X_Step;
						ball_Y_Motion_in = 0;
					end

				// 8: up
				16'h0060 : 
					begin    
						// motion control
						ball_X_Motion_in = 0;
						ball_Y_Motion_in = (~(ball_Y_Step) + 1'b1);
					end
						
				// 5: down
				16'h005d : 
					begin    
						// motion control
						ball_X_Motion_in = 0;
						ball_Y_Motion_in = ball_Y_Step;
					end				
		
				// 48/84: left up
				16'h5c60:
					begin
						ball_X_Motion_in = (~(ball_X_Step) + 1'b1);
						ball_Y_Motion_in = (~(ball_Y_Step) + 1'b1);
					end
					
				16'h605c:
					begin
						ball_X_Motion_in = (~(ball_X_Step) + 1'b1);
						ball_Y_Motion_in = (~(ball_Y_Step) + 1'b1);
					end
					
					
				// 68/86: right up
				16'h5e60:
					begin
						ball_X_Motion_in = ball_X_Step;
						ball_Y_Motion_in = (~(ball_Y_Step) + 1'b1);
					end
					
				16'h605e:
					begin
						ball_X_Motion_in = ball_X_Step;
						ball_Y_Motion_in = (~(ball_Y_Step) + 1'b1);
					end
					
				
				// 45/54: left down
				16'h5c5d:
					begin
						ball_X_Motion_in = (~(ball_X_Step) + 1'b1);
						ball_Y_Motion_in = ball_Y_Step;
					end
					
				16'h5d5c:
					begin
						ball_X_Motion_in = (~(ball_X_Step) + 1'b1);
						ball_Y_Motion_in = ball_Y_Step;
					end
					
					
				// 65/56: right down
				16'h5e5d:
					begin
						ball_X_Motion_in = ball_X_Step;
						ball_Y_Motion_in = ball_Y_Step;
					end
					
				16'h5d5e:
					begin
						ball_X_Motion_in = ball_X_Step;
						ball_Y_Motion_in = ball_Y_Step;
					end
					
					
				// press nothing
				default:
					begin
						ball_X_Motion_in = 0;
						ball_Y_Motion_in = 0;
					end
			endcase

				// Update the ball's position with its motion
				ball_X_Pos_in = ball_X_Pos + ball_X_Motion_in;
				ball_Y_Pos_in = ball_Y_Pos + ball_Y_Motion_in;
		end
				
		// left boundary
		if ((ball_X_Pos < ball_X_Max/2) && (ball_X_Pos_in > ball_X_Max) )
		begin
			ball_X_Pos_in = ball_X_Min;
			ball_X_Motion_in = 0;
		end
		// right boundary
		if ((ball_X_Pos > ball_X_Max/2) && (ball_X_Pos_in > ball_X_Max))
		begin
			ball_X_Pos_in = ball_X_Max;
			ball_X_Motion_in = 0;
		end
		// up boundary
		if ((ball_Y_Pos < ball_Y_Max/2) && (ball_Y_Pos_in > ball_Y_Max))
		begin
			ball_Y_Pos_in = ball_Y_Min;
			ball_Y_Motion_in = 0;
		end
		// down boundary
		if ((ball_Y_Pos > ball_Y_Max/2) && (ball_Y_Pos_in > ball_Y_Max))
		begin
			ball_Y_Pos_in = ball_Y_Max;
			ball_Y_Motion_in = 0;
		end
				
				
	end

   // Compute whether the pixel corresponds to cursor or background
   int X_offset, Y_offset;
   assign X_offset = DrawX - ball_X_Pos;
   assign Y_offset = DrawY - ball_Y_Pos;
    
   cursorAddress cursor_address(.X_offset, .Y_offset, .cursor_color_address);
   cursorRAM cursor_ram(.cursor_color_address, .color_cursor);

   always_comb 
   begin
      if ( (X_offset >= 0) && (Y_offset >= 0) && (X_offset <= (width - 1)) && (Y_offset <= (height - 1)) )
         is_cursor = 1'b1;
      else
         is_cursor = 1'b0;

      cursor_X = ball_X_Pos;
      cursor_Y = ball_Y_Pos;
   end
endmodule
