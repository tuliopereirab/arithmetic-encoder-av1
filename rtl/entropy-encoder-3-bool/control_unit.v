module control_unit (
  input clk, reset_ctrl,
  output reg pipeline_reg_1_2, pipeline_reg_2_3, pipeline_reg_final
  );

  localparam start_1 = 0, start_2 = 1;
  localparam main = 3;
  reg [2:0] state;

  always @ (posedge clk) begin
    if(reset_ctrl)
      state <= start_1;
    else begin
      case (state)
        start_1   : state <= start_2;
        start_2   : state <= main;
        main      : state <= main;
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
      start_2 : begin
        pipeline_reg_1_2 <= 1'b1;
        pipeline_reg_2_3 <= 1'b1;
        pipeline_reg_final <= 1'b0;
      end
      main : begin
        pipeline_reg_1_2 <= 1'b1;
        pipeline_reg_2_3 <= 1'b1;
        pipeline_reg_final <= 1'b1;
      end
    endcase
  end
endmodule
