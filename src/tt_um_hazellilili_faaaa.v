/*
 * Copyright (c) 2024 Hazel Li
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

parameter LOGO_SIZE = 256;  // Size of the logo in pixels
parameter DISPLAY_WIDTH = 640;  // VGA display width
parameter DISPLAY_HEIGHT = 480;  // VGA display height

`define COLOR_WHITE 3'd7

module tt_um_faaaa (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // VGA signals
  wire hsync;
  wire vsync;
  reg [1:0] R;
  reg [1:0] G;
  reg [1:0] B;
  wire video_active;
  wire [9:0] pix_x;
  wire [9:0] pix_y;

  // Configuration
  wire cfg_tile = ui_in[0];
  wire cfg_solid_color = ui_in[1];

  // TinyVGA PMOD
  assign uo_out  = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  // Unused outputs assigned to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;

  // Suppress unused signals warning
  wire _unused_ok = &{ena, ui_in[7:1], uio_in};

  reg [9:0] prev_y;

  hvsync_generator vga_sync_gen (
      .clk(clk),
      .reset(~rst_n),
      .hsync(hsync),
      .vsync(vsync),
      .display_on(video_active),
      .hpos(pix_x),
      .vpos(pix_y)
  );

  reg [9:0] logo_left;
  reg [9:0] logo_top;
  reg dir_x;
  reg dir_y;

  wire pixel_value;
  reg [2:0] color_index;
  wire [5:0] color;

  wire [9:0] x = pix_x - logo_left;
  wire [9:0] y = pix_y - logo_top;
  wire logo_pixels = cfg_tile || (x[9:8] == 0 && y[9:8] == 0);

  bitmap_rom rom1 (
      .x(x[7:0]),
      .y(y[7:0]),
      .pixel(pixel_value)
  );

  // 1. The Solid Color Palette
  wire [5:0] palette_color;
  palette palette_inst (
      .color_index(color_index),
      .rrggbb(palette_color)
  );

  // 2. The CNY Diagonal Wave Generator (For the inside of the text!)
  // We use chunks of 64 pixels (bits [8:6]) to make thick, elegant stripes.
  // Adding logo_left makes the gradient slowly flow across the characters.
  wire [2:0] wave = y[4:2] - x[4:2] + logo_left[4:2];
  
  // Create a triangle wave (counts up, then down) for the Green channel
  wire [1:0] grad_g = wave[2] ? ~wave[1:0] : wave[1:0];
  
  // Assemble the 6-bit gradient color: Red maxed, Green waves, Blue off
  wire [5:0] cny_gradient = {2'b11, grad_g, 2'b00};

  // 3. Choose the Character Color based on the switch (ui_in[1])
  wire [5:0] char_color = cfg_solid_color ? palette_color : cny_gradient;

  // 4. The RGB Video Output Logic
  always @(posedge clk) begin
    if (~rst_n) begin
      R <= 0; G <= 0; B <= 0;
    end else begin
      // Default the background to pure black
      R <= 0; G <= 0; B <= 0;
      
      if (video_active) begin
        // If we are over the character bounding box, AND the pixel is a '1' in your ROM
        if (logo_pixels && pixel_value) begin
          // Draw the character using either the gradient or the palette color
          R <= char_color[5:4];
          G <= char_color[3:2];
          B <= char_color[1:0];
        end 
        // The background remains safely black because of the default above!
      end
    end
  end

  // Bouncing logic
  always @(posedge clk) begin
    if (~rst_n) begin
      logo_left <= 200;
      logo_top <= 200;
      dir_y <= 0;
      dir_x <= 1;
      color_index <= 0;
    end else begin
      prev_y <= pix_y;
      if (pix_y == 0 && prev_y != pix_y) begin
        logo_left <= logo_left + (dir_x ? 1 : -1);
        logo_top  <= logo_top + (dir_y ? 1 : -1);
        if (logo_left - 1 == 0 && !dir_x) begin
          dir_x <= 1;
          color_index <= color_index + 1;
        end
        if (logo_left + 1 == DISPLAY_WIDTH - LOGO_SIZE && dir_x) begin
          dir_x <= 0;
          color_index <= color_index + 1;
        end
        if (logo_top - 1 == 0 && !dir_y) begin
          dir_y <= 1;
          color_index <= color_index + 1;
        end
        if (logo_top + 1 == DISPLAY_HEIGHT - LOGO_SIZE && dir_y) begin
          dir_y <= 0;
          color_index <= color_index + 1;
        end
      end
    end
  end

endmodule
