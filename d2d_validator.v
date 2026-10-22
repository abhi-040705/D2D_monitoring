
`include "d2d_defs.v"

module d2d_validator (
    input wire [2:0] msg_type,
    input wire [1:0] source,
    input wire [15:0] address,

    input wire ledger_found,
    input wire [1:0] ledger_state,
    input wire [1:0] ledger_owner,
    input wire [2:0] ledger_sharers,

    output reg violation_valid,
    output reg [1:0] violation_code
);

    // Violation codes
    localparam NO_VIOLATION     = 2'b00;
    localparam FORGED_WRITEBACK = 2'b01;
    localparam ILLEGAL_UPGRADE  = 2'b10;
    localparam UNKNOWN_LINE     = 2'b11;

    always @(*) begin
        violation_valid = 1'b0;
        violation_code  = NO_VIOLATION;

        // Validate modified-line release
        if (msg_type == `PUTM) begin
            if (!ledger_found) begin
                violation_valid = 1'b1;
                violation_code  = UNKNOWN_LINE;
            end else if ((ledger_state != `MODIFIED) ||
                         (source != ledger_owner)) begin
                violation_valid = 1'b1;
                violation_code  = FORGED_WRITEBACK;
            end
        end

        // Validate request to upgrade shared access
        else if (msg_type == `UPGRADE) begin
            if (!ledger_found) begin
                violation_valid = 1'b1;
                violation_code  = UNKNOWN_LINE;
            end else if ((ledger_state != `SHARED) ||
                         !ledger_sharers[source]) begin
                violation_valid = 1'b1;
                violation_code  = ILLEGAL_UPGRADE;
            end
        end
    end

endmodule
