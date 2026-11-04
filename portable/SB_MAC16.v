// SPDX-License-Identifier: CERN-OHL-S-2.0
`default_nettype none

// Model the full-width signed/unsigned multiply mode used by IceSID. This is
// an arithmetic compatibility model, not a cycle-accurate SB_MAC16 model:
// CLK is retained for interface compatibility but does not affect the output.
// Other output-selection modes are unsupported and fail in simulation.
module SB_MAC16 #(
    parameter A_SIGNED = 1'b0,
    parameter B_SIGNED = 1'b0,
    parameter [1:0] TOPOUTPUT_SELECT = 2'b00,
    parameter [1:0] BOTOUTPUT_SELECT = 2'b00
) (
    input wire         CLK,
    input wire  [15:0] A,
    input wire  [15:0] B,
    output wire [31:0] O
);
`ifndef SYNTHESIS
  initial begin
    if (TOPOUTPUT_SELECT != 2'b11 || BOTOUTPUT_SELECT != 2'b11) begin
      $fatal(1, "Portable SB_MAC16 model only supports full 16x16 multiply output");
    end
  end
`endif

  wire signed [16:0] multiplicand = A_SIGNED ? {A[15], A} : {1'b0, A};
  wire signed [16:0] multiplier = B_SIGNED ? {B[15], B} : {1'b0, B};
  wire signed [33:0] product = multiplicand * multiplier;

  assign O = product[31:0];
endmodule
