`timescale 1ns/1ps
`default_nettype none

module mult_tb;
  localparam integer MULT_VECTOR_COUNT = 12;
  localparam integer VOLUME_VECTOR_COUNT = 8;
  localparam integer VOICE_VECTOR_COUNT = 8;

  typedef struct packed {
    logic signed [16:0] signal_value;
    logic        [15:0] coefficient_value;
  } mult_vector_t;

  typedef struct packed {
    logic signed [15:0] mix_value;
    logic        [ 3:0] volume_value;
  } volume_vector_t;

  typedef struct packed {
    logic signed [11:0] voice_value;
    logic        [ 7:0] envelope_value;
  } voice_vector_t;

  localparam mult_vector_t MULT_VECTORS [0:MULT_VECTOR_COUNT-1] = '{
      '{17'sd32767, 16'hffff},
      '{-17'sd32768, 16'hffff},
      '{17'sd32768, 16'h8000},
      '{-17'sd32769, 16'h8001},
      '{-17'sd1, 16'h0001},
      '{17'sd0, 16'h0000},
      '{17'sd1, 16'h7fff},
      '{17'sd32766, 16'h8000},
      '{17'sd32768, 16'h0001},
      '{-17'sd32769, 16'h0000},
      '{-17'sd65536, 16'h8000},
      '{17'sd65535, 16'h0001}
  };

  localparam volume_vector_t VOLUME_VECTORS [0:VOLUME_VECTOR_COUNT-1] = '{
      '{-16'sd32768, 4'h0},
      '{-16'sd32767, 4'h1},
      '{-16'sd1, 4'hf},
      '{16'sd0, 4'h8},
      '{16'sd1, 4'h1},
      '{16'sd32767, 4'hf},
      '{16'sd16384, 4'h7},
      '{-16'sd12345, 4'he}
  };

  localparam voice_vector_t VOICE_VECTORS [0:VOICE_VECTOR_COUNT-1] = '{
      '{-12'sd2048, 8'h00},
      '{-12'sd2047, 8'h01},
      '{-12'sd1, 8'hff},
      '{12'sd0, 8'h80},
      '{12'sd1, 8'h7f},
      '{12'sd2047, 8'hff},
      '{12'sd1024, 8'hfe},
      '{-12'sd1234, 8'h80}
  };

  logic clk = 0;
  always #5 clk = ~clk;

  logic signed [16:0] signal_in;
  logic        [15:0] coefficient;
  wire signed [15:0] mult_out;

  logic signed [15:0] mix_in;
  logic        [ 3:0] volume;
  wire signed [15:0] volume_out;

  logic signed [11:0] voice_in;
  logic        [ 7:0] envelope;
  wire signed [15:0] voice_out;

  mult16x16 mult (
      .clk(clk),
      .iSignal(signal_in),
      .iCoef(coefficient),
      .oOut(mult_out)
  );

  mdac16x4 volume_mult (
      .clk(clk),
      .iMix(mix_in),
      .iVol(volume),
      .oOut(volume_out)
  );

  mdac12x8 voice_mult (
      .clk(clk),
      .iVoice(voice_in),
      .iEnv(envelope),
      .oOut(voice_out)
  );

  function automatic logic signed [15:0] expected_mult(
      input logic signed [16:0] signal_value,
      input logic        [15:0] coefficient_value
  );
    logic signed [15:0] clipped;
    logic signed [31:0] lhs;
    logic signed [31:0] rhs;
    logic signed [31:0] product;
    begin
      if (signal_value > 17'sd32767)
        clipped = 16'sh7fff;
      else if (signal_value < -17'sd32768)
        clipped = 16'sh8000;
      else
        clipped = signal_value[15:0];

      lhs = {{16{clipped[15]}}, clipped};
      rhs = {16'b0, coefficient_value};
      product = lhs * rhs;
      expected_mult = product[31:16];
    end
  endfunction

  function automatic logic signed [15:0] expected_volume(
      input logic signed [15:0] mix_value,
      input logic        [ 3:0] volume_value
  );
    logic signed [31:0] lhs;
    logic signed [31:0] rhs;
    logic signed [31:0] product;
    begin
      lhs = {{16{mix_value[15]}}, mix_value};
      rhs = {28'b0, volume_value};
      product = lhs * rhs;
      expected_volume = product[19:4];
    end
  endfunction

  function automatic logic signed [15:0] expected_voice(
      input logic signed [11:0] voice_value,
      input logic        [ 7:0] envelope_value
  );
    logic signed [31:0] lhs;
    logic signed [31:0] rhs;
    logic signed [31:0] product;
    begin
      lhs = {{16{voice_value[11]}}, voice_value, 4'b0};
      rhs = {24'b0, envelope_value};
      product = lhs * rhs;
      expected_voice = product[23:8];
    end
  endfunction

  task automatic check_mult_vectors;
    integer vector_index;
    begin
      for (vector_index = 0; vector_index < MULT_VECTOR_COUNT; vector_index = vector_index + 1) begin
        signal_in = MULT_VECTORS[vector_index].signal_value;
        coefficient = MULT_VECTORS[vector_index].coefficient_value;

        #1;
        if (mult_out !== expected_mult(signal_in, coefficient))
          $fatal(1, "mult16x16 mismatch at vector %0d: signal=%0d coefficient=%0d",
                 vector_index, signal_in, coefficient);
      end
    end
  endtask

  task automatic check_volume_vectors;
    integer vector_index;
    logic have_previous_sample;
    logic signed [15:0] previous_output;
    logic signed [15:0] expected_output;
    begin
      have_previous_sample = 0;
      for (vector_index = 0; vector_index < VOLUME_VECTOR_COUNT; vector_index = vector_index + 1) begin
        mix_in = VOLUME_VECTORS[vector_index].mix_value;
        volume = VOLUME_VECTORS[vector_index].volume_value;
        expected_output = expected_volume(mix_in, volume);

        #1;
        if (have_previous_sample && volume_out !== previous_output)
          $fatal(1, "mdac16x4 changed before clock at vector %0d", vector_index);

        @(negedge clk);
        #1;
        if (have_previous_sample && volume_out !== previous_output)
          $fatal(1, "mdac16x4 changed on falling edge at vector %0d", vector_index);

        @(posedge clk);
        #1;
        if (volume_out !== expected_output)
          $fatal(1, "mdac16x4 mismatch at vector %0d: mix=%0d volume=%0d",
                 vector_index, mix_in, volume);

        previous_output = volume_out;
        have_previous_sample = 1;
      end
    end
  endtask

  task automatic check_voice_vectors;
    integer vector_index;
    logic have_previous_sample;
    logic signed [15:0] previous_output;
    logic signed [15:0] expected_output;
    begin
      have_previous_sample = 0;
      for (vector_index = 0; vector_index < VOICE_VECTOR_COUNT; vector_index = vector_index + 1) begin
        voice_in = VOICE_VECTORS[vector_index].voice_value;
        envelope = VOICE_VECTORS[vector_index].envelope_value;
        expected_output = expected_voice(voice_in, envelope);

        #1;
        if (have_previous_sample && voice_out !== previous_output)
          $fatal(1, "mdac12x8 changed before clock at vector %0d", vector_index);

        @(negedge clk);
        #1;
        if (have_previous_sample && voice_out !== previous_output)
          $fatal(1, "mdac12x8 changed on falling edge at vector %0d", vector_index);

        @(posedge clk);
        #1;
        if (voice_out !== expected_output)
          $fatal(1, "mdac12x8 mismatch at vector %0d: voice=%0d envelope=%0d",
                 vector_index, voice_in, envelope);

        previous_output = voice_out;
        have_previous_sample = 1;
      end
    end
  endtask

  initial begin
    check_mult_vectors();
    check_volume_vectors();
    check_voice_vectors();
    $display("multiplier tests passed (%0d mult, %0d volume, %0d voice vectors)",
             MULT_VECTOR_COUNT, VOLUME_VECTOR_COUNT, VOICE_VECTOR_COUNT);
    $finish;
  end
endmodule

`default_nettype wire
