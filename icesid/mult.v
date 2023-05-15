// .___               _________.___________
// |   | ____  ____  /   _____/|   \______ \
// |   |/ ___\/ __ \ \_____  \ |   ||    |  \
// |   \  \__\  ___/ /        \|   ||    `   \
// |___|\___  >___  >_______  /|___/_______  /
//          \/    \/        \/             \/
`default_nettype none

/* verilator lint_off PINMISSING */

module mult_s16xu16 (
    input  wire signed [15:0] A,
    input  wire        [15:0] B,
    output reg  signed [31:0] O,
    input  wire               CLK
);
  `ifdef ICE40
    SB_MAC16 mac (
        .A  (A),
        .B  (B),
        .O  (O),
        .CLK(clk)
    );

    defparam mac.A_SIGNED = 1'b1;  // A is signed
    defparam mac.B_SIGNED = 1'b0;  // B is unsigned
    defparam mac.TOPOUTPUT_SELECT = 2'b11;  // Mult16x16 data output
    defparam mac.BOTOUTPUT_SELECT = 2'b11;  // Mult16x16 data output
  `else
    wire signed [16:0] s17 = B;   // Extend U16 to S17

    always @(posedge CLK) begin
        O <= A * s17;             // S16 x U16 product
    end
  `endif
endmodule

// 16x16 multiplier for the filters
module mult16x16 (
    input  wire               clk,
    input  wire signed [16:0] iSignal,
    input  wire        [15:0] iCoef,
    output wire signed [15:0] oOut
);

  wire signed [31:0] product;  // 16x16 product
  assign oOut = product[31:16];

  wire signed [15:0] clipped;
  clipper clip (
      iSignal,
      clipped
  );

  mult_s16xu16 mac (
      .A  (clipped),  // input is signed
      .B  (iCoef),    // coefficient is unsigned
      .O  (product),  // Mult16x16 data output
      .CLK(clk)
  );
endmodule

// 16x4 multiplier used for master volume
module mdac16x4 (
    input  wire               clk,
    input  wire signed [15:0] iMix,
    input  wire        [ 3:0] iVol,
    output wire signed [15:0] oOut
);

  wire signed [31:0] product;  // 16x16 product
  mult_s16xu16 mac (
      .A  (iMix),           // voice is signed
      .B  ({12'b0, iVol}),  // env is unsigned
      .O  (product),        // Mult16x16 data output
      .CLK(clk)
  );

  reg [15:0] out;
  assign oOut = out;
  always @(posedge clk) begin
    out <= product[19:4];
  end
endmodule

// 12x8 multiplier used for voice envelopes
module mdac12x8 (
    input  wire               clk,
    input  wire signed [11:0] iVoice,
    input  wire        [ 7:0] iEnv,
    output wire signed [15:0] oOut
);

  wire signed [31:0] product;  // 16x16 product
  mult_s16xu16 mac (
      .A  ({iVoice, 4'b0}), // voice is signed
      .B  ({8'b0, iEnv}),   // env is unsigned
      .O  (product),        // Mult16x16 data output
      .CLK(clk)
  );

  reg [15:0] out;
  assign oOut = out;
  always @(posedge clk) begin
    out <= product[23:8];
  end
endmodule

/* verilator lint_on PINMISSING */
