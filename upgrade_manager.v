
`include "d2d_defs.v"

module upgrade_manager (
    input wire [1:0] source,
    input wire ledger_found,
    input wire [1:0] ledger_state,
    input wire [2:0] ledger_sharers,

    output reg upgrade_valid,
    output reg [2:0] expected_acks,
    output reg [1:0] violation_code
);

    localparam NO_VIOLATION    = 2'b00;
    localparam ILLEGAL_UPGRADE = 2'b10;
    localparam UNKNOWN_LINE    = 2'b11;

    always @(*) begin
        upgrade_valid = 1'b0;
        expected_acks = 3'b000;
        violation_code = NO_VIOLATION;

        if (!ledger_found) begin
            violation_code = UNKNOWN_LINE;
        end
        else if (ledger_state != `SHARED) begin
            violation_code = ILLEGAL_UPGRADE;
        end
        else if (source >= 3 || !ledger_sharers[source]) begin
            violation_code = ILLEGAL_UPGRADE;
        end
        else begin
            upgrade_valid = 1'b1;

            // Every other current sharer must acknowledge invalidation.
            expected_acks = ledger_sharers & ~(3'b001 << source);
        end
    end

endmodule

