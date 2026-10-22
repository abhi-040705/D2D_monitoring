
module d2d_monitor (
    input wire clk,
    input wire reset,

    // Incoming D2D message
    input wire [2:0] msg_type,
    input wire [1:0] source,
    input wire [15:0] address,

    // Trusted initialization interface
    input wire trusted_update_enable,
    input wire [15:0] trusted_update_address,
    input wire [1:0] trusted_update_state,
    input wire [1:0] trusted_update_owner,
    input wire [2:0] trusted_update_sharers,

    // Violation outputs
    output wire violation_valid,
    output wire [1:0] violation_code,
    output wire ledger_found_debug,
    output wire [1:0] ledger_state_debug,
    output wire [1:0] ledger_owner_debug
);

    wire ledger_found;
    wire [1:0] ledger_state;
    wire [1:0] ledger_owner;
    wire [2:0] ledger_sharers;

    wire update_enable;

    assign ledger_found_debug = ledger_found;
    assign ledger_state_debug = ledger_state;
    assign ledger_owner_debug = ledger_owner;

    // Authorize ledger writes during initialization only.
    d2d_update_controller update_controller (
        .reset(reset),
        .init_enable(trusted_update_enable),
        .update_request(trusted_update_enable),
        .update_enable(update_enable)
    );

    // Per-cache-line coherence ledger
    coherence_ledger ledger (
        .clk(clk),
        .reset(reset),
        .write_enable(update_enable),
        .write_address(trusted_update_address),
        .write_state(trusted_update_state),
        .write_owner(trusted_update_owner),
        .write_sharers(trusted_update_sharers),
        .lookup_address(address),
        .found(ledger_found),
        .lookup_state(ledger_state),
        .lookup_owner(ledger_owner),
        .lookup_sharers(ledger_sharers)
    );

    // Validate incoming D2D messages
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
