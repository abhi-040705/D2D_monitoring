
module d2d_monitor (
    input wire clk,
    input wire reset,

    // Incoming coherence message
    input wire [2:0] msg_type,
    input wire [1:0] source,
    input wire [15:0] address,

    // Ledger write interface
    input wire ledger_write_enable,
    input wire [15:0] ledger_write_address,
    input wire [1:0] ledger_write_state,
    input wire [1:0] ledger_write_owner,
    input wire [2:0] ledger_write_sharers,

    // Security alert outputs
    output wire violation_valid,
    output wire [1:0] violation_code
);

    // Ledger lookup signals
    wire ledger_found;
    wire [1:0] ledger_state;
    wire [1:0] ledger_owner;
    wire [2:0] ledger_sharers;

    // Per-cache-line coherence ledger
    coherence_ledger ledger (
        .clk(clk),
        .reset(reset),

        .write_enable(ledger_write_enable),
        .write_address(ledger_write_address),
        .write_state(ledger_write_state),
        .write_owner(ledger_write_owner),
        .write_sharers(ledger_write_sharers),

        .lookup_address(address),
        .found(ledger_found),
        .lookup_state(ledger_state),
        .lookup_owner(ledger_owner),
        .lookup_sharers(ledger_sharers)
    );

    // Validate incoming message against ledger
    d2d_validator validator (
        .msg_type(msg_type),
        .source(source),
        .address(address),

        .ledger_found(ledger_found),
        .ledger_state(ledger_state),
        .ledger_owner(ledger_owner),
        .ledger_sharers(ledger_sharers),

        .violation_valid(violation_valid),
        .violation_code(violation_code)
    );

endmodule
