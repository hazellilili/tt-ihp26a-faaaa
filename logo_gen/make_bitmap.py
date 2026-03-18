# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: Hazel Li

from PIL import Image

# Open the image
img = Image.open("logo.png")

# Convert the image to grayscale
img = img.convert("L")
pix = bytearray(256 * 256 // 8)

for y in range(img.height):
    for x in range(img.width):
        color = img.getpixel((x, y))
        if color < 128:
            pix[y * 32 + x // 8] |= 1 << (x % 8)

module = []
module.append("`default_nettype none")
module.append("module bitmap_rom (")
module.append("    input wire [7:0] x,")
module.append("    input wire [7:0] y,")
module.append("    output wire pixel")
module.append(");")
module.append("")
module.append("  wire [12:0] addr = {y[7:0], x[7:3]};")
module.append("  reg [7:0] data;")
module.append("")
module.append("  // Force synthesis into combinational logic instead of latches")
module.append("  always @(*) begin")
module.append("    case (addr)")

# OPTIMIZATION: Only write Verilog lines for bytes that actually have pixels
lines_written = 0
for i, byte in enumerate(pix):
    if byte != 0:
        module.append(f"      13'd{i}: data = 8'h{byte:02x};")
        lines_written += 1

module.append("      default: data = 8'h00;")
module.append("    endcase")
module.append("  end")
module.append("")
module.append("  assign pixel = data[x[2:0]];")
module.append("")
module.append("endmodule")
module.append("")

with open("../src/bitmap_rom.v", "w") as f:
    f.write("\n".join(module))
    
print(f"Success! Optimized ROM generated with {lines_written} non-empty bytes.")