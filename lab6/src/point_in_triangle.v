// Draw a triangle with three vertices (0), (1), (2)
// (0) -> (1) -> (2) follows counter-clockwise order
// Line i connecting points (i) and (i+1) is associated with three coefficients Ai, Bi, Ci
// (0)->(1): A0, B0, C0 -- line 0
// (1)->(2): A1, B1, C1 -- line 1
// (2)->(0): A2, B2, C2 -- line 2
// for a pixel (x, y) on image plane, denote Li = Ai * x + Bi * y + Ci
//   + Li < 0: (x, y) is on the RHS of the line i
//   + Li > 0: (x, y) is on the LHS of the line i
//   + Li = 0: (x, y) is on the line i
// How to determine Ai, Bi, Ci of the line (x{i}, y{i})->(x{i+1}, y{i+1})?
//   dx{i} = x{i+1} - x{i};
//   dy{i} = y{i+1} - y{i};
//   A{i} = -dy{i};
//   B{i} = dx{i};
//   C{i} = x{i} * dy{i} - y{i} * dx{i};
// To draw a triangle, we need to fill all the pixels within the three lines
// Reference: https://cs184.eecs.berkeley.edu/sp19/lecture/2/rasterization

// This module performs a "point-in-triangle" test to check if a pixel with
// a coordinate of (x, y) lies within a triangle formed by
// (point0, point1, point2). Note that we are referring to pixel coordinates,
// meaning that x increments from left to right, and y increments from top to bottom.
// The origin is at the top-left corner.
(* use_dsp = "no" *) module point_in_triangle(

// Also note the use of the attribute use_dsp here. It tells the Synthesis tool
// to avoid using DSP blocks to implement the arithmetic operations in the code.
// A DSP block can do a wide-width multiplication very effectively, among many other
// operations, and can help your circuit to achieve better frequency.
// To make the exercise more educational, we turn off the use of DSP blocks here,
// so that your circuit only involves LUTs and FFs.
// You can switch the attribute on later for your own exploration.

    input pixel_clk,

    // pixel (x, y)
    input [31:0] x_pixel,
    input [31:0] y_pixel,

    // point0 (x0, y0)
    input [31:0] x0,
    input [31:0] y0,

    // point1 (x1, y1)
    input [31:0] x1,
    input [31:0] y1,

    // point2 (x2, y2)
    input [31:0] x2,
    input [31:0] y2,

    output [31:0] x_pixel_out,
    output [31:0] y_pixel_out,
    // HIGH if (x_pixel_out, y_pixel_out) is in the triangle, LOW otherwise
    output is_inside
);

    // This module is originally pipelined with two stages
    // The first stage just register the input
    // The second stage registers the test result
    // It takes two cycles, from the arrival of an input pixel to the test result
    // of whether the pixel is in a triangle
    // Think of this like a pipeline: when we have new pixel arrived,
    // the current pixel is being tested, and the previous pixel is output

    // TODO: you should add a few more pipeline stages to improve the timing of the circuit
    // The goal is to meet 62.5 MHz clock frequency (16ns).
    // When you add a new pipeline stage, make sure to register all the signals
    // involved, otherwise it might cause cycle mismatches and lead to incorrect result.
    // The most straightforward way to do this is to draw the circuit on a paper,
    // then draw a vertical line to cut the circuit to pieces. Then, add a register
    // at every intersection of the line with the signal wires in your circuit.
    // You should use a good naming scheme that helps you to keep track of pipelined registers easily.
    // Feel free to change the code below to your own style as long as the functionality is correct.
    // Also, please use REGISTER* modules from lib/EECS151.v.

    wire signed [31:0] x_pixel_val0, y_pixel_val0;
    wire signed [31:0] x_pixel_val1, y_pixel_val1;

    wire signed [31:0] x0_val, y0_val;
    wire signed [31:0] x1_val, y1_val;
    wire signed [31:0] x2_val, y2_val;

    wire signed [31:0] y_pixel_val0_P1, x_pixel_val0_P1;
    wire signed [31:0] y_pixel_val0_P2, x_pixel_val0_P2;
    
    REGISTER #(.N(32)) x_pixel_reg0 (.q(x_pixel_val0), .d(x_pixel), .clk(pixel_clk));
    REGISTER #(.N(32)) x_pixel_reg1 (.q(x_pixel_val0_P2), .d(x_pixel_val0), .clk(pixel_clk));
    //REGISTER #(.N(32)) x_pixel_reg1 (.q(x_pixel_val1), .d(x_pixel_val0), .clk(pixel_clk));
    REGISTER #(.N(32)) x_pixel_reg2 (.q(x_pixel_val1), .d(x_pixel_val0_P1), .clk(pixel_clk));

    REGISTER #(.N(32)) y_pixel_reg0 (.q(y_pixel_val0), .d(y_pixel), .clk(pixel_clk));
    REGISTER #(.N(32)) y_pixel_reg1 (.q(y_pixel_val0_P2), .d(y_pixel_val0), .clk(pixel_clk));
    //REGISTER #(.N(32)) y_pixel_reg1 (.q(y_pixel_val1), .d(y_pixel_val0), .clk(pixel_clk));
    REGISTER #(.N(32)) y_pixel_reg2 (.q(y_pixel_val1), .d(y_pixel_val0_P1), .clk(pixel_clk));

    REGISTER #(.N(32)) x0_reg0 (.q(x0_val), .d(x0), .clk(pixel_clk));
    REGISTER #(.N(32)) y0_reg0 (.q(y0_val), .d(y0), .clk(pixel_clk));
    REGISTER #(.N(32)) x1_reg0 (.q(x1_val), .d(x1), .clk(pixel_clk));
    REGISTER #(.N(32)) y1_reg0 (.q(y1_val), .d(y1), .clk(pixel_clk));
    REGISTER #(.N(32)) x2_reg0 (.q(x2_val), .d(x2), .clk(pixel_clk));
    REGISTER #(.N(32)) y2_reg0 (.q(y2_val), .d(y2), .clk(pixel_clk));

    wire signed [31:0] A0, B0, C0;
    wire signed [31:0] A1, B1, C1;
    wire signed [31:0] A2, B2, C2;

    wire signed [31:0] dx0 = x1_val - x0_val;
    wire signed [31:0] dy0 = y1_val - y0_val;
    
    wire signed [31:0] dx0_P2;
    REGISTER #(.N(32)) regP2_0_1 (.q(dx0_P2), .d(dx0), .clk(pixel_clk));
    wire signed [31:0] dy0_P2;
    REGISTER #(.N(32)) regP2_0_2 (.q(dy0_P2), .d(dy0), .clk(pixel_clk));
    wire signed [31:0] x0_val_P2;
    REGISTER #(.N(32)) regP2_0_3 (.q(x0_val_P2), .d(x0_val), .clk(pixel_clk));
    wire signed [31:0] y0_val_P2;
    REGISTER #(.N(32)) regP2_0_4 (.q(y0_val_P2), .d(y0_val), .clk(pixel_clk));
    assign A0 = -dy0_P2;
    assign B0 = dx0_P2;
    wire signed [31:0] C0_part1,C0_part2;
    assign C0_part1 = x0_val_P2 * dy0_P2;
    assign C0_part2 = y0_val_P2 * dx0_P2;
    //assign A0 = -dy0;
    //assign B0 = dx0;
    //assign C0 = x0_val * dy0 - y0_val * dx0;
    //assign C0_part1 = x0_val * dy0;
    //assign C0_part2 = y0_val * dx0;

    REGISTER #(.N(32)) regP1_0_1 (.q(x_pixel_val0_P1), .d(x_pixel_val0_P2), .clk(pixel_clk));
    wire signed [31:0] B0_P1;
    REGISTER #(.N(32)) regP1_0_2 (.q(B0_P1), .d(B0), .clk(pixel_clk));
    wire signed [31:0] C0_part1_P1;
    REGISTER #(.N(32)) regP1_0_3 (.q(C0_part1_P1), .d(C0_part1), .clk(pixel_clk));
    wire signed [31:0] C0_part2_P1;
    REGISTER #(.N(32)) regP1_0_4 (.q(C0_part2_P1), .d(C0_part2), .clk(pixel_clk));
    wire signed [31:0] A0_P1;
    REGISTER #(.N(32)) regP1_0_5 (.q(A0_P1), .d(A0), .clk(pixel_clk));
    REGISTER #(.N(32)) regP1_0_6 (.q(y_pixel_val0_P1), .d(y_pixel_val0_P2), .clk(pixel_clk));
    wire signed [31:0] L0_part1,L0_part2;
    assign L0_part1 = A0_P1 * x_pixel_val0_P1;
    assign L0_part2 = B0_P1 * y_pixel_val0_P1;
    wire signed [31:0] C0_P1;
    assign C0_P1 = C0_part1_P1 - C0_part2_P1;

    wire signed [31:0] dx1 = x2_val - x1_val;
    wire signed [31:0] dy1 = y2_val - y1_val;
    
    wire signed [31:0] dx1_P2;
    REGISTER #(.N(32)) regP2_1_1 (.q(dx1_P2), .d(dx1), .clk(pixel_clk));
    wire signed [31:0] dy1_P2;
    REGISTER #(.N(32)) regP2_1_2 (.q(dy1_P2), .d(dy1), .clk(pixel_clk));
    wire signed [31:0] x1_val_P2;
    REGISTER #(.N(32)) regP2_1_3 (.q(x1_val_P2), .d(x1_val), .clk(pixel_clk));
    wire signed [31:0] y1_val_P2;
    REGISTER #(.N(32)) regP2_1_4 (.q(y1_val_P2), .d(y1_val), .clk(pixel_clk));
    assign A1 = -dy1_P2;
    assign B1 = dx1_P2;
    wire signed [31:0] C1_part1,C1_part2;
    assign C1_part1 = x1_val_P2 * dy1_P2;
    assign C1_part2 = y1_val_P2 * dx1_P2;
    
    //assign A1 = -dy1;
    //assign B1 = dx1;
    //assign C1 = x1_val * dy1 - y1_val * dx1;
    //wire signed [31:0] C1_part1,C1_part2;
    //assign C1_part1 = x1_val * dy1;
    //assign C1_part2 = y1_val * dx1;

    wire signed [31:0] B1_P1;
    REGISTER #(.N(32)) regP1_1_2 (.q(B1_P1), .d(B1), .clk(pixel_clk));
    wire signed [31:0] C1_part1_P1;
    REGISTER #(.N(32)) regP1_1_3 (.q(C1_part1_P1), .d(C1_part1), .clk(pixel_clk));
    wire signed [31:0] C1_part2_P1;
    REGISTER #(.N(32)) regP1_1_4 (.q(C1_part2_P1), .d(C1_part2), .clk(pixel_clk));
    wire signed [31:0] A1_P1;
    REGISTER #(.N(32)) regP1_1_5 (.q(A1_P1), .d(A1), .clk(pixel_clk));
    wire signed [31:0] L1_part1,L1_part2;
    assign L1_part1 = A1_P1 * x_pixel_val0_P1;
    assign L1_part2 = B1_P1 * y_pixel_val0_P1;
    wire signed [31:0] C1_P1;
    assign C1_P1 = C1_part1_P1 - C1_part2_P1;

    wire signed [31:0] dx2 = x0_val - x2_val;
    wire signed [31:0] dy2 = y0_val - y2_val;
    wire signed [31:0] dx2_P2;
    REGISTER #(.N(32)) regP2_2_1 (.q(dx2_P2), .d(dx2), .clk(pixel_clk));
    wire signed [31:0] dy2_P2;
    REGISTER #(.N(32)) regP2_2_2 (.q(dy2_P2), .d(dy2), .clk(pixel_clk));
    wire signed [31:0] x2_val_P2;
    REGISTER #(.N(32)) regP2_2_3 (.q(x2_val_P2), .d(x2_val), .clk(pixel_clk));
    wire signed [31:0] y2_val_P2;
    REGISTER #(.N(32)) regP2_2_4 (.q(y2_val_P2), .d(y2_val), .clk(pixel_clk));
    assign A2 = -dy2_P2;
    assign B2 = dx2_P2;
    wire signed [31:0] C2_part1,C2_part2;
    assign C2_part1 = x2_val_P2 * dy2_P2;
    assign C2_part2 = y2_val_P2 * dx2_P2;
    
    //assign A2 = -dy2;
    //assign B2 = dx2;
    //assign C2 = x2_val * dy2 - y2_val * dx2;
    //wire signed [31:0] C2_part1,C2_part2;
    //assign C2_part1 = x2_val * dy2;
    //assign C2_part2 = y2_val * dx2;

    wire signed [31:0] B2_P1;
    REGISTER #(.N(32)) regP1_2_2 (.q(B2_P1), .d(B2), .clk(pixel_clk));
    wire signed [31:0] C2_part1_P1;
    REGISTER #(.N(32)) regP1_2_3 (.q(C2_part1_P1), .d(C2_part1), .clk(pixel_clk));
    wire signed [31:0] C2_part2_P1;
    REGISTER #(.N(32)) regP1_2_4 (.q(C2_part2_P1), .d(C2_part2), .clk(pixel_clk));
    wire signed [31:0] A2_P1;
    REGISTER #(.N(32)) regP1_2_5 (.q(A2_P1), .d(A2), .clk(pixel_clk));
    wire signed [31:0] L2_part1,L2_part2;
    assign L2_part1 = A2_P1 * x_pixel_val0_P1;
    assign L2_part2 = B2_P1 * y_pixel_val0_P1;
    wire signed [31:0] C2_P1;
    assign C2_P1 = C2_part1_P1 - C2_part2_P1;

    wire signed [31:0] L0, L1, L2;
    //assign L0 = A0 * x_pixel_val0 + B0 * y_pixel_val0 + C0;
    //assign L1 = A1 * x_pixel_val0 + B1 * y_pixel_val0 + C1;
    //assign L2 = A2 * x_pixel_val0 + B2 * y_pixel_val0 + C2;
    assign L0 = L0_part1 + L0_part2 + C0_P1;
    assign L1 = L1_part1 + L1_part2 + C1_P1;
    assign L2 = L2_part1 + L2_part2 + C2_P1;

    wire is_inside_val;

    REGISTER #(.N(1)) is_inside_reg (
        .q(is_inside_val),
        .d(L0 <= 0 & L1 <= 0 & L2 <= 0),
        .clk(pixel_clk)
    );

    // When you add new pipeline registers/stages, make sure that x_pixel_out and y_pixel_out
    // are assigned to the last stages. Same thing for is_inside.
    // Therefore, is_inside is an indicator of whether pixel (x_pixel_out, y_pixel_out)
    // is within the triangle
    assign x_pixel_out = x_pixel_val1;
    assign y_pixel_out = y_pixel_val1;
    assign is_inside   = is_inside_val;

endmodule