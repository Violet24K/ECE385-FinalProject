module characterAddress
(
    input  int           distX, distY,
    input  int           half_width, half_height,
    output logic [14:0]  character_color_address
);
	assign character_color_address = (half_height + distY) * 42 + (half_width + distX);
endmodule

module characterRAM
(
	input   logic [14:0]    character_color_address,
    input   int             choice,  // 0 ~ 5 
	output  logic [23:0]    color_character // 3 * 8 = 24
);
	logic [23:0] colors [15:0];
	assign colors[ 0] = 24'h000000;
	assign colors[ 1] = 24'h1A1813;
	assign colors[ 2] = 24'h003119;
	assign colors[ 3] = 24'hF3F0E8;
	assign colors[ 4] = 24'hFFFCFC;
	assign colors[ 5] = 24'h353333;
	assign colors[ 6] = 24'h545353;
	assign colors[ 7] = 24'h999696;
	assign colors[ 8] = 24'h360000;
	assign colors[ 9] = 24'hBF1919;
	assign colors[10] = 24'h7C0202;
	assign colors[11] = 24'h016740;
	assign colors[12] = 24'hE1AE98;
	assign colors[13] = 24'h0057CF;
	assign colors[14] = 24'h1DD38F;
	assign colors[15] = 24'hEF867F;

	logic [3 : 0]  mem_left_still     [0 : 2351];      // 42 * 56 = 2352
	logic [3 : 0]  mem_left_1         [0 : 2351];      // 42 * 56 = 2352
	logic [3 : 0]  mem_left_2         [0 : 2351];      // 42 * 56 = 2352
	logic [3 : 0]  mem_right_still    [0 : 2351];      // 42 * 56 = 2352
	logic [3 : 0]  mem_right_1        [0 : 2351];      // 42 * 56 = 2352
	logic [3 : 0]  mem_right_2        [0 : 2351];      // 42 * 56 = 2352

	initial
	begin
	    $readmemh("character/santa_left_still.txt", mem_left_still);
	    $readmemh("character/santa_left_1.txt", mem_left_1);
	    $readmemh("character/santa_left_2.txt", mem_left_2);
	    $readmemh("character/santa_right_still.txt", mem_right_still);
	    $readmemh("character/santa_right_1.txt", mem_right_1);
	    $readmemh("character/santa_right_2.txt", mem_right_2);
	end
	
	always_comb
	begin
    case (choice)
        0 : // left still
            color_character = colors[mem_left_still[character_color_address]];
        1 : // left frame 1
            color_character = colors[mem_left_1[character_color_address]];
        2 : // left frame 2
            color_character = colors[mem_left_2[character_color_address]];
        3 : // right still
            color_character = colors[mem_right_still[character_color_address]];
        4 : // right frame 1
            color_character = colors[mem_right_1[character_color_address]];
        5 : // right frame 2
            color_character = colors[mem_right_2[character_color_address]];
        default: 
            color_character = colors[mem_left_still[character_color_address]];
    endcase
	end
endmodule

module character   
(   
    input               Clk,                // 50 MHz clock
                        Reset,              // Active-high reset signal
                        frame_clk,          // The clock indicating a new frame (~60Hz)
    input [9:0]         DrawX, DrawY,       // Current pixel coordinates
	 output [9:0]        character_X, character_Y,
	 input [3:0] 			stop_at,
    input [15:0]        keycode,            // key pressed
    
    output logic        is_character,       // Whether current pixel belongs to ball or background
    output logic [23:0] color_character
);
    parameter [9:0] ball_X_Start = 10'd320;      // Start position on the X axis
    parameter [9:0] ball_Y_Start = 10'd320;      // Start position on the Y axis

    parameter [9:0] ball_X_Min = 10'd0;        // Leftmost point on the X axis
    parameter [9:0] ball_X_Max = 10'd639;      // Rightmost point on the X axis
    parameter [9:0] ball_Y_Min = 10'd10;        // Topmost point on the Y axis
    parameter [9:0] ball_Y_Max = 10'd449;      // Bottommost point on the Y axis

    parameter [9:0] ball_X_Step = 10'd2;       // Step size on the X axis
    parameter [9:0] ball_Y_Step = 10'd4;       // Step size on the Y axis

    parameter [9:0] ball_Height = 10'd56;      // ball height
    parameter [9:0] ball_Width = 10'd42;       // ball width

    parameter [9:0] gravity = 10'd2;
	 
	 logic [14:0]  character_color_address;

	// this counter is used to update the speed
	int counter = 0, counter_next;
	int counter_anime = 0, counter_anime_next;
	int counter_anime2 = 0, counter_anime2_next;
	int counter_max = 10;

    // for animation
    int choice = 3, choice_next; // right still
	 int left = 0, right = 0;
	 int left_next, right_next;
	 int side = 1, side_next;		// default right 0 left 1 right

    // variables for position and speed
    logic [9:0] ball_X_Pos, ball_X_Motion, ball_Y_Pos, ball_Y_Motion;
    logic [9:0] ball_X_Pos_in, ball_X_Motion_in, ball_Y_Pos_in, ball_Y_Motion_in;

    // half height and half width are used to determine whether out of bound
    int half_height, half_width;
    assign half_height = ball_Height / 2;
    assign half_width = ball_Width / 2;
	 int horizontal_space = 15;

    // Detect rising edge of frame_clk
    logic frame_clk_delayed, frame_clk_rising_edge;
    always_ff @ (posedge Clk) begin
        frame_clk_delayed <= frame_clk;
        frame_clk_rising_edge <= (frame_clk == 1'b1) && (frame_clk_delayed == 1'b0);
    end

	 
	 
	 
	 initial
	 begin
		 ball_X_Pos      <= ball_X_Start;
		 ball_Y_Pos      <= ball_Y_Start;
		 ball_X_Motion   <= 10'd0;
		 ball_Y_Motion   <= 10'd0;
		 counter         <= 0;
		 counter_anime   <= 0;
		 counter_anime2   <= 0;
		 choice          <= 3;    // default: facing right, standing still
		 left            <= 0;
		 right           <= 0;
		 side            <= 1;
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
                counter         <= 0;
					 counter_anime   <= 0;
					 counter_anime2   <= 0;
                choice          <= 3;    // default: facing right, standing still
					 left            <= 0;
					 right           <= 0;
					 side            <= 1;
            end
        else
            begin
                ball_X_Pos      <= ball_X_Pos_in;
                ball_Y_Pos      <= ball_Y_Pos_in;
                ball_X_Motion   <= ball_X_Motion_in;
                ball_Y_Motion   <= ball_Y_Motion_in;
                counter         <= counter_next;
					 counter_anime   <= counter_anime_next;
					 counter_anime2  <= counter_anime2_next;
                choice          <= choice_next;
					 left            <= left_next;
					 right           <= right_next;
					 side            <= side_next;
            end
    end

    // W-A-S-D
    always_comb
    begin
		// counter cannot exceed:
		counter_next = counter + 1;
		if (counter == counter_max)
            counter_next = 0;

		
		counter_anime_next = counter_anime + 1;
		counter_anime2_next = counter_anime2;
		if (counter_anime == 5000)
		begin
            counter_anime_next = 0;
				counter_anime2_next = counter_anime2 + 1;
		end
		if (counter_anime2 == 5000)
				counter_anime2_next = 0;

        // By default, keep motion and position unchanged
        ball_X_Pos_in = ball_X_Pos;
        ball_Y_Pos_in = ball_Y_Pos;
        ball_X_Motion_in = ball_X_Motion;
        ball_Y_Motion_in = ball_Y_Motion;

        // by default, keep choice unchanged
        choice_next = choice;
		
		  // by default, keep the facing direction
		  side_next = side;
		  left_next = left;
		  right_next = right;
		
		  if (left)
		  begin
				// direction control
            if (counter_anime2 < 2500)
					choice_next = 1;
            else
               choice_next = 2;
		  end
		  else if (right)
		  begin
	         // direction control
			   if (counter_anime2 < 2500)
					choice_next = 4;
				else
					choice_next = 5;
		  end
		  else
		  begin
				// direction control
				if (side == 0)
					 choice_next = 0;
				else
					 choice_next = 3;
		  end
	  // Update position and motion only at rising edge of frame clock
        if (frame_clk_rising_edge)
			begin
				case (keycode[15:0])
					// A: left
					16'h0004 :
						begin
						side_next = 0;
						left_next = 1;
						right_next = 0;
						// motion control
						ball_X_Motion_in = (~(ball_X_Step) + 1'b1);

						if (counter == counter_max)
							 ball_Y_Motion_in = ball_Y_Motion + gravity;
						else
							 ball_Y_Motion_in = ball_Y_Motion;
								 
//								 // boundary checks
//								 if( ball_Y_Pos + half_height >= ball_Y_Max )  // ball is at the bottom edge, STOP!
//									  ball_Y_Motion_in = 0;  
//								 else if ( ball_Y_Pos <= ball_Y_Min + half_height )  // ball is at the top edge, STOP!
//									  ball_Y_Motion_in = 1;
//								 if ( ball_X_Pos <= ball_X_Min + half_width )  // ball is at the left edge, STOP!
//									  ball_X_Motion_in = 0;
						end

						
					16'h0407 :
					begin
						side_next = 0;
						left_next = 1;
						right_next = 0;
						// motion control
						ball_X_Motion_in = (~(ball_X_Step) + 1'b1);

						if (counter == counter_max)
							 ball_Y_Motion_in = ball_Y_Motion + gravity;
						else
							 ball_Y_Motion_in = ball_Y_Motion;
					end
					
					// D: right
					16'h0007 :
					begin
						side_next = 1;
						right_next = 1;
						left_next = 0;
						// motion control
						ball_X_Motion_in = ball_X_Step;

						if (counter == counter_max)
							ball_Y_Motion_in = ball_Y_Motion + gravity;
						else
							ball_Y_Motion_in = ball_Y_Motion;
									  
//								 // boundary checks
//								 if( ball_Y_Pos + half_height >= ball_Y_Max )  // ball is at the bottom edge, STOP!
//									  ball_Y_Motion_in = 0;  
//								 else if ( ball_Y_Pos <= ball_Y_Min + half_height )  // ball is at the top edge, STOP!
//									  ball_Y_Motion_in = 1;
//								 if( ball_X_Pos + half_width >= ball_X_Max )  // ball is at the right edge, STOP!
//									  ball_X_Motion_in = 0;  
					end
					
					
					16'h0704 :
					begin
						side_next = 1;
						right_next = 1;
						left_next = 0;
						// motion control
						ball_X_Motion_in = ball_X_Step;

						if (counter == counter_max)
							ball_Y_Motion_in = ball_Y_Motion + gravity;
						else
							ball_Y_Motion_in = ball_Y_Motion;
					end

				// space: jump
					16'h002c : 
					begin    
						// motion control
						ball_X_Motion_in = 0;
						ball_Y_Motion_in = (~(ball_Y_Step) + 1'b1);

//								 // boundary checks
//						   if ( ball_Y_Pos <= ball_Y_Min + half_height )  // ball is at the top edge, STOP!
// 						   ball_Y_Motion_in = 0;
//								 if( ball_X_Pos + half_width >= ball_X_Max )  // ball is at the right edge, STOP!
//									  ball_X_Motion_in = 0;  
//								 else if ( ball_X_Pos <= ball_X_Min + half_width )  // ball is at the left edge, STOP!
//									  ball_X_Motion_in = 0;
					end
							
							
					// jump while left
					16'h2c04:
					begin
							side_next = 0;
							left_next = 1;
							right_next = 0;
							// motion control
							ball_X_Motion_in = (~(ball_X_Step) + 1'b1);
							
							ball_Y_Motion_in = (~(ball_Y_Step) + 1'b1);
					end
						
						
					16'h042c:
					begin
						side_next = 0;
						left_next = 1;
						right_next = 0;
						// motion control
						ball_X_Motion_in = (~(ball_X_Step) + 1'b1);
						
						ball_Y_Motion_in = (~(ball_Y_Step) + 1'b1);
					end
						
						
					// jump while right	
					16'h2c07:
					begin
						side_next = 1;
						right_next = 1;
						left_next = 0;
						// motion control
						ball_X_Motion_in = ball_X_Step;
						
						ball_Y_Motion_in = (~(ball_Y_Step) + 1'b1);
					end
						
						
					16'h072c:
					begin
						side_next = 1;
						right_next = 1;
						left_next = 0;
						// motion control
						ball_X_Motion_in = ball_X_Step;
						
						ball_Y_Motion_in = (~(ball_Y_Step) + 1'b1);
					end

					  // press nothing
					default:
						begin
						left_next = 0;
						right_next = 0;
						// motion control
						ball_X_Motion_in = 0;
						if (counter == counter_max)
							ball_Y_Motion_in = ball_Y_Motion + gravity;
						else
							ball_Y_Motion_in = ball_Y_Motion;

								 // boundary checks
//								 if  (ball_X_Pos + half_width >= ball_X_Max )  // ball is at the right edge, STOP!
//									  ball_X_Motion_in = 0;  
//								 else if (ball_X_Pos <= ball_X_Min + half_width )  // ball is at the left edge, STOP!
//									  ball_X_Motion_in = 0;
//								 if  (ball_Y_Pos + half_height >= ball_Y_Max )  // ball is at the bottom edge, STOP!
//									  ball_Y_Motion_in = 0;  
//								 else if ( ball_Y_Pos <= ball_Y_Min + half_height )  // ball is at the top edge, STOP!
//									  ball_Y_Motion_in = 1;
							end
				 endcase

				 // Update the ball's position with its motion
				 ball_X_Pos_in = ball_X_Pos + ball_X_Motion;
				 ball_Y_Pos_in = ball_Y_Pos + ball_Y_Motion;
			end
			
			
			// check boundaries
			// left boundary
			if ((ball_X_Pos < ball_X_Max/2 + half_width) && (ball_X_Pos_in < half_width) )
			begin
				ball_X_Pos_in = ball_X_Min + half_width;
				ball_X_Motion_in = 0;
			end
			// right boundary
			if ((ball_X_Pos + half_width > ball_X_Max/2) && (ball_X_Pos_in + half_width > ball_X_Max))
			begin
				ball_X_Pos_in = ball_X_Max - half_width;
				ball_X_Motion_in = 0;
			end
			// up boundary
			if ((ball_Y_Pos  < ball_Y_Max/2 + half_height) && (ball_Y_Pos_in < half_height))
			begin
				ball_Y_Pos_in = ball_Y_Min + half_height;
				ball_Y_Motion_in = 0;
			end
			// down boundary
			if ((ball_Y_Pos + half_height > ball_Y_Max/2) && (ball_Y_Pos_in + half_height > ball_Y_Max))
			begin
				ball_Y_Pos_in = ball_Y_Max - half_height;
				ball_Y_Motion_in = 0;
			end
			
			
			// check_collisions
			// horizontal_space is the left-middle and middle-right width of the bounding box
			
			// left_collision
			if ( stop_at[3] == 1 )
			begin
				if ( (ball_X_Motion_in[9] == 1) || (ball_X_Motion_in == 9'b0))
				begin
					ball_X_Pos_in = ((character_X - horizontal_space)/ 16 * 16) + horizontal_space + 15;	// 15 is blocksize - 1
					ball_X_Motion_in = 0;
				end
			end
				
			// right_collision
			if ( stop_at[2] == 1 )
			begin
				if (ball_X_Motion_in[9] == 0)
				begin
					ball_X_Pos_in = ((character_X + horizontal_space)/ 16 * 16) - horizontal_space;
					ball_X_Motion_in = 0;
				end
			end
			
			// up_collision
			if ( stop_at[1] == 1 )
			begin
				if ( (ball_Y_Motion_in[9] == 1) || (ball_Y_Motion_in == 9'b0))
				begin
					ball_Y_Pos_in = ((character_Y - half_height)/ 16 * 16) + half_height + 15;	
					ball_Y_Motion_in = 0;
				end
			end
			
			// down_collision
			if ( stop_at[0] == 1 )
			begin
				if (ball_Y_Motion_in[9] == 0)
				begin
					ball_Y_Pos_in = ((character_Y + half_height)/ 16 * 16) - half_height;
					ball_Y_Motion_in = 0;
				end
			end
	end

    // Compute whether the pixel corresponds to ball or background
    int DistX, DistY;
    assign DistX = DrawX > ball_X_Pos ? DrawX - ball_X_Pos : ball_X_Pos - DrawX;
    assign DistY = DrawY > ball_Y_Pos ? DrawY - ball_Y_Pos : ball_Y_Pos - DrawY;

    int distX, distY;
    assign distX = DrawX - ball_X_Pos;
    assign distY = DrawY - ball_Y_Pos;
    
    characterAddress character_address(.distX, .distY, .half_width, .half_height, .character_color_address);
    characterRAM character_ram(.character_color_address, .choice, .color_character);

    always_comb 
    begin
        if ( DistX <= half_width && DistY <= half_height )
            is_character = 1'b1;
        else
            is_character = 1'b0;
		  character_X = ball_X_Pos;
		  character_Y = ball_Y_Pos;
    end
endmodule
