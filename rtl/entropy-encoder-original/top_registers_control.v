module top_control (
    input clk, reset_ctrl,
    output reg carry_ctrl
    );


    // There is still a problem to deal with that is the gap between Stage 2 and Stage 3.
    // The stage 2 requires the output_range everytime in order to execute some equations.
    // However, right the output_range (output_range[v[i-1]]) will only be ready in the end of the 3rd stage.
    // Hence, it creates a gap of one cycle.

    // As a temporary solution, I put a permanent gap in the whole pipeline, which means that every 2 cycles I'll get an output ready.
    // Hence, because of this restriction, I also need to throw data into the architecture in the same rate (1 data each 2 cycles).

    localparam start_1 = 0, start_2 = 1, start_3 = 2;
    localparam main = 3;
    reg [2:0] state;

    always @ (posedge clk) begin
        if(reset_ctrl)
            state <= start_1;
        else begin
            case (state)
                start_1  : state <= start_2;
                start_2  : state <= start_3;
                start_3  : state <= main;
                main     : state <= main;
            endcase
        end
    end

    always @ ( * ) begin
        case (state)
            start_1 : begin
                carry_ctrl <= 1'b0;
            end
            start_2 : begin
                carry_ctrl <= 1'b0;
            end
            start_3 : begin
                carry_ctrl <= 1'b0;
            end
            main     : begin
                carry_ctrl <= 1'b1;
            end
        endcase
    end
endmodule
