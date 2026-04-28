`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:17:26 04/28/2026 
// Design Name: 
// Module Name:    fir_filter_17tap_pipeline3 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////


module fir_filter_17tap_pipeline3(
    input clk,
    input signed [15:0] x_in,
    output reg signed [31:0] y_out
);

reg signed [15:0] x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16;
parameter signed h0=-1, h1=-1, h2=-2, h3=0, h4=7, h5=19, h6=34, h7=47;
parameter signed h8=52;

reg signed [16:0] s0,s1,s2,s3,s4,s5,s6,s7;
reg signed [15:0] s8;

reg signed [31:0] m0,m1,m2,m4,m5,m6,m7,m8; 

initial begin
    x1=0; x2=0; x3=0; x4=0; x5=0; x6=0; x7=0; x8=0;
    x9=0; x10=0; x11=0; x12=0; x13=0; x14=0; x15=0; x16=0;

    // stage 1
    s0=0; s1=0; s2=0; s3=0; s4=0; s5=0; s6=0; s7=0;
    s8=0;
    // stage 2
    m0=0; m1=0; m2=0; m4=0; m5=0; m6=0; m7=0; m8=0;
    // op
    y_out = 0;
end

// s1
always @(posedge clk) begin
    x16<=x15; x15<=x14; x14<=x13; x13<=x12;
    x12<=x11; x11<=x10; x10<=x9; x9<=x8;
    x8<=x7; x7<=x6; x6<=x5; x5<=x4;
    x4<=x3; x3<=x2; x2<=x1; x1<=x_in;

    s0 <= x1 + x16;
    s1 <= x2 + x15;
    s2 <= x3 + x14;
    s3 <= x4 + x13;
    s4 <= x5 + x12;
    s5 <= x6 + x11;
    s6 <= x7 + x10;
    s7 <= x8 + x9;
    s8 <= x8;
end

//s2
always @(posedge clk) begin
    m0 <= s0 * h0;
    m1 <= s1 * h1;
    m2 <= s2 * h2;
    m4 <= s4 * h4;
    m5 <= s5 * h5;
    m6 <= s6 * h6;
    m7 <= s7 * h7;
    m8 <= s8 * h8;
end

//s3
always @(posedge clk) begin
    y_out <= m0 + m1 + m2 + m4 + m5 + m6 + m7 + m8;
end

endmodule