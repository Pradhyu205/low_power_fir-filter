`timescale 1ns / 1ps
// Author: Pradhyumna D Rao
// Verification layer added on top of tb.v with AI assistance (Nov 2026).
// Self-checking testbench: compares DUT output with a behavioural 17-tap
// convolution using the same integer coefficients. Prints PASS/FAIL.
// Run (Icarus):  iverilog -o sim fir_filter_17tap_pipeline3.v tb_selfcheck.v && vvp sim
module tb_selfcheck;
    localparam N = 400, LAT = 2;   // y_out sampled just after posedge i reflects x[i-LAT]
    reg clk = 0;
    reg  signed [15:0] x_in = 0;
    wire signed [31:0] y_out;
    fir_filter_17tap_pipeline3 uut (.clk(clk), .x_in(x_in), .y_out(y_out));
    always #5 clk = ~clk;

    integer h [0:16];
    integer xs [0:N-1];
    integer i, k, acc, errors, seed;

    initial begin
        h[0]=-1; h[1]=-1; h[2]=-2; h[3]=0;  h[4]=7;  h[5]=19; h[6]=34; h[7]=47; h[8]=52;
        for (k = 0; k < 8; k = k + 1) h[16-k] = h[k];
        errors = 0; seed = 1;
        for (i = 0; i < N; i = i + 1) begin
            // impulse first, then pseudo-random samples
            xs[i] = (i == 0) ? 1000 : (i < 40) ? 0 : ($random(seed) % 2000) - 1000;
            x_in = xs[i];
            @(posedge clk); #1;
            if (i >= LAT) begin
                acc = 0;
                for (k = 0; k <= 16; k = k + 1)
                    if ((i - LAT - k) >= 0) acc = acc + h[k] * xs[i - LAT - k];
                if (y_out !== acc) begin
                    errors = errors + 1;
                    if (errors < 10) $display("MISMATCH i=%0d dut=%0d exp=%0d", i, y_out, acc);
                end
            end
        end
        if (errors == 0) $display("PASS: %0d samples match the golden 17-tap response", N);
        else             $display("FAIL: %0d mismatches", errors);
        $finish;
    end
endmodule
