`default_nettype none

module palette (
    input  wire [2:0] color_index,
    output reg  [5:0] rrggbb
);

  // The 6-bit color format is: 
  // [5:4] Red   (00=Off, 01=Dim, 10=Medium, 11=Bright)
  // [3:2] Green (00=Off, 01=Dim, 10=Medium, 11=Bright)
  // [1:0] Blue  (00=Off, 01=Dim, 10=Medium, 11=Bright)

  always @(*) begin
    case (color_index)
      // 1. Traditional Bright Red (Luck and Joy)
      3'd0: rrggbb = 6'b11_00_00; 
      
      // 2. Imperial Gold (Wealth and Prosperity)
      // 100% Red + 66% Green makes a warm, elegant gold instead of harsh yellow
      3'd1: rrggbb = 6'b11_10_00; 
      
      // 3. Tangerine / Deep Orange (Good Fortune)
      3'd2: rrggbb = 6'b11_01_00; 
      
      // 4. Elegant Dark Crimson (A deeper, softer red that rests the eyes)
      3'd3: rrggbb = 6'b10_00_00; 
      
      // 5. Jade Green (Purity and Harmony)
      // Mixing 33% Red, 66% Green, and 33% Blue creates a muted, milky jade
      3'd4: rrggbb = 6'b01_10_01; 
      
      // 6. Plum Blossom / Warm Pink (Spring and Resilience)
      3'd5: rrggbb = 6'b11_00_01; 
      
      // 7. Ancient Bronze / Dark Gold
      3'd6: rrggbb = 6'b10_01_00; 
      
      // 8. Warm Silk White
      // Using 66% Blue instead of 100% keeps the white looking warm, not cold/blueish
      3'd7: rrggbb = 6'b11_11_10; 
      
      default: rrggbb = 6'b11_00_00;
    endcase
  end

endmodule
