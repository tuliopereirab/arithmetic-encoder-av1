module arith_encoder_software #(
    parameter TB_RANGE_WIDTH = 16,
    parameter TB_LOW_WIDTH = 24,
    parameter TB_SYMBOL_WIDTH = 4,
    parameter TB_LUT_ADDR_WIDTH = 8,
    parameter TB_LUT_DATA_WIDTH = 16,
    parameter TB_D_SIZE = 4,
    parameter INTERNAL_TB_SIZE = 99
    )();

    // functions
    int in_range_lzc, out_range_lzc, v_lzc;
    // ----------------------------------------
    int range, low, cnt;
    // ----------------------------------------

    // file reader
    integer fd;
    int file_fl, file_fh, file_symbol, file_nsyms;
    int temp_range_in, temp_low_in, temp_cnt_in;
    int temp_range_out, temp_low_out;
    int status;
    int i;
    // ----------------------

    leading_zero #(
        .RANGE_WIDTH_LCZ (TB_RANGE_WIDTH),
        .D_SIZE_LZC (TB_D_SIZE)
        ) lzc (
            .in_range (in_range_lzc),
            .lzc_out (out_range_lzc),
            .v (v_lzc)
        );

    function void od_ec_encode_q15;
        input bit [(TB_RANGE_WIDTH-1):0] fl, fh;
        input bit [(TB_SYMBOL_WIDTH-1):0] symbol;
        input bit [TB_SYMBOL_WIDTH:0] nsyms;
        bit [(TB_RANGE_WIDTH-1):0] u, v, r;
        bit [(TB_LOW_WIDTH-1):0] l;
        int N;
        N = nsyms - 1;
        r = range;
        l = low;
        $display("FL = %d\tFH = %d\tSymbol = %d\tNsyms = %d\n", fl, fh, symbol, nsyms);
        if(fl < 32768) begin
            u = ((r >> 8) * (fl >> 6) >> (7 - 6 - 0)) + 4 * (N - (symbol - 1));
            v = ((r >> 8) * (fh >> 6) >> (7 - 6 - 0)) + 4 * (N - (symbol + 0));
            l = l + r - u;
            r = u - v;
        end else begin
            r = r - (((r >> 8) * (fh >> 6) >> (7 - 6 - 0)) + 4 * (N - (symbol + 0)));
        end
        $display("Out Q15\tRange = %d\tLow = %d\n", r, l);
        od_ec_enc_normalize(r, l);
    endfunction
    function void od_ec_enc_normalize;
        input bit [(TB_RANGE_WIDTH-1):0] rng;
        input bit [(TB_LOW_WIDTH-1):0] low_norm;
        int d, c, s;
        c = cnt;
        $display("Norm stuff\tRange = %d\tLow = %d\tCnt = %d\n", rng, low_norm, c);
        in_range_lzc = rng;
        d = out_range_lzc;
        $display("Rng = %b\tlzc_in = %b\tlzc_out = %d\n", rng, in_range_lzc, d);
        s = c + d;
        if(s >= 0) begin
            int m;
            c = c + 16;
            m = (1 << c) - 1;
            if(s >= 8) begin
                low_norm = low_norm && m;
                c = c - 8;
                m = m >> 8;
            end
            s = c + d - 24;
            low_norm = low_norm && m;
        end
        low = low_norm << d;
        range = rng << d;
        cnt = s;
    endfunction

    initial begin
        $display("Starting simulation...\n");
        fd = $fopen("C:/Users/Tulio/Desktop/arithmetic_encoder_av1/verification_area/simulation_data/full-video-input-miss-america_150frames_176x144.csv", "r");
        range = 32768;
        cnt = -9;
        low = 0;
        while(!$feof(fd)) begin
            status = $fscanf (fd, "%d;%d;%d;%d;\n", file_fl, file_fh, file_symbol, file_nsyms);
            if(status != 4) begin
                $display("Problem reading the file\n");
            end
            else begin
                $display("Input:\nFL=%d\tFH=%d\tsymbol=%d\tnsyms=%d\n", file_fl, file_fh, file_symbol, file_nsyms);
                od_ec_encode_q15(file_fl, file_fh, file_symbol, file_nsyms);
                $display("Output:\nRange = %d\tLow = %d\tCnt = %d\n", range, low, cnt);
                $display("----------------------------------------------\n");
            end
            #1ns;
        end
        $fclose(fd);
    end

endmodule
