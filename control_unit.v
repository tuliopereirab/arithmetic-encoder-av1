module control_unit (
    input clk, reset_ctrl,
    output reg pipeline_reg_1_2, pipeline_reg_2_3, pipeline_reg_final
    );


    // There is still a problem to deal with that is the gap between Stage 2 and Stage 3.
    // The stage 2 requires the output_range everytime in order to execute some equations.
    // However, right the output_range (output_range[v[i-1]]) will only be ready in the end of the 3rd stage.
    // Hence, it creates a gap of one cycle.

    // As a temporary solution, I put a permanent gap in the whole pipeline, which means that every 2 cycles I'll get an output ready.
    // Hence, because of this restriction, I also need to throw data into the architecture in the same rate (1 data each 2 cycles).

    localparam start_1 = 0;
    localparam main_1 = 1, main_2 = 2;
    reg [2:0] state;

    always @ (posedge clk) begin
        if(reset_ctrl)
            state <= start_1;
        else begin
            case (state)
                start_1 : state <= main_1;
                main_1 : state <= main_2;
                main_2 : state <= main_1;
            endcase
        end
    end

    always @ ( * ) begin
        case (state)
            start_1 : begin
                pipeline_reg_1_2 <= 1'b1;
                pipeline_reg_2_3 <= 1'b0;
                pipeline_reg_final <= 1'b0;
            end
            main_1  : begin
                pipeline_reg_1_2 <= 1'b0;
                pipeline_reg_2_3 <= 1'b1;
                pipeline_reg_final <= 1'b0;
            end
            main_2  : begin
                pipeline_reg_1_2 <= 1'b1;
                pipeline_reg_2_3 <= 1'b0;
                pipeline_reg_final <= 1'b1;
            end
        endcase
    end
endmodule
