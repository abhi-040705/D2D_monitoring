
`ifndef D2D_DEFS_V
`define D2D_DEFS_V

// Coherence message types
`define GETS    3'b000
`define GETM    3'b001
`define UPGRADE 3'b010
`define PUTS    3'b011
`define PUTM    3'b100
`define DATA    3'b101
`define INV     3'b110
`define ACK     3'b111

// Cache coherence states (simplified MSI protocol)
`define INVALID 2'b00
`define SHARED  2'b01
`define MODIFIED 2'b10

`endif
