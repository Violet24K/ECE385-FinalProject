module judge 
(
    input logic [9:0]   character_X, character_Y,
    input logic         left_exist_block, right_exist_block, up_exist_block, down_exist_block,
    output logic [3:0]  stop_at,
    output logic [9:0]	query_left_bound, query_right_bound, query_up_bound, query_down_bound
);
    parameter [9:0] ball_Height = 10'd56;      // ball height
    parameter [9:0] ball_Width = 10'd42;       // ball width

    int half_height, half_width;
    assign half_height = ball_Height / 2;
    assign half_width = ball_Width / 2;

    always_comb 
    begin
        query_left_bound = character_X - half_width;
        query_right_bound = character_X + half_width;
        query_up_bound = character_Y - half_height;
        query_down_bound = character_Y + half_height;

        stop_at = {left_exist_block, right_exist_block, up_exist_block, down_exist_block};
    end

endmodule