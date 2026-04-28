`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   18:19:32 04/28/2026
// Design Name:   fir_filter_17tap_pipeline3
// Module Name:   /home/ise/Desktop/Low Power VLSI/LowPowerVLSI/tb.v
// Project Name:  LowPowerVLSI
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: fir_filter_17tap_pipeline3
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////


module tb;

//ip
reg clk;
reg signed [15:0] x_in;

//op
wire signed [31:0] y_out;

fir_filter_17tap_pipeline3 uut (
    .clk(clk),
    .x_in(x_in),
    .y_out(y_out)
);

always #5 clk = ~clk;

initial begin
    clk = 0;
    x_in = 0;

    #20;

    repeat (100) begin
        x_in = $random % 50 - 25;
        #10;
    end

    $stop;
end

endmodule