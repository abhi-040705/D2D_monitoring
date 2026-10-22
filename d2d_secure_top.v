
`include "d2d_defs.v"

module d2d_secure_top (
    input wire clk,
    input wire reset,

    input wire init_write,
    input wire [15:0] init_address,
    input wire [1:0] init_state,
    input wire [1:0] init_owner,
    input wire [2:0] init_sharers,

    input wire start_upgrade,
    input wire [1:0] source,
    input wire [15:0] address,

    input wire ack_valid,
    input wire [1:0] ack_source,

    output wire transaction_done,
    output wire busy,
    output wire violation_valid,
    output wire [1:0] violation_code,

    output wire ledger_found_debug,
    output wire [1:0] ledger_state_debug,
    output wire [1:0] ledger_owner_debug,
    output wire [2:0] ledger_sharers_debug,
    output wire [2:0] received_acks
);

    wire ledger_found;
    wire [1:0] ledger_state;
    wire [1:0] ledger_owner;
    wire [2:0] ledger_sharers;

    wire upgrade_valid;
    wire [2:0] expected_acks;
    wire [1:0] manager_violation;

    wire transaction_authorized;
    wire ledger_commit;

    wire upgrade_done;
    wire upgrade_violation;
    wire [1:0] upgrade_violation_code;

    reg upgrade_start_pulse;
    reg pending_commit;
    reg [15:0] saved_address;
    reg [1:0] saved_source;

    reg ledger_write_enable;
    reg [15:0] ledger_write_address;
    reg [1:0] ledger_write_state;
    reg [1:0] ledger_write_owner;
    reg [2:0] ledger_write_sharers;

    reg transaction_complete_to_runtime;
    reg message_valid_to_runtime;

    assign ledger_found_debug = ledger_found;
    assign ledger_state_debug = ledger_state;
    assign ledger_owner_debug = ledger_owner;
    assign ledger_sharers_debug = ledger_sharers;

    // The runtime controller authorizes the transaction lifecycle.
    d2d_runtime_controller runtime_controller (
        .clk(clk),
        .reset(reset),
        .transaction_start(start_upgrade && !busy),
        .message_valid(message_valid_to_runtime),
        .transaction_complete(transaction_complete_to_runtime),
        .transaction_authorized(transaction_authorized),
        .ledger_commit(ledger_commit),
        .busy(busy)
    );

    // Look up the requested line in the trusted ledger.
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

    // Check that the requester is a valid sharer of a Shared line.
    upgrade_manager manager (
        .source(source),
        .ledger_found(ledger_found),
        .ledger_state(ledger_state),
        .ledger_sharers(ledger_sharers),
        .upgrade_valid(upgrade_valid),
        .expected_acks(expected_acks),
        .violation_code(manager_violation)
    );

    // Track invalidation ACKs for the active upgrade.
    upgrade_ack_tracker tracker (
        .clk(clk),
        .reset(reset),
        .start_upgrade(upgrade_start_pulse),
        .expected_acks(expected_acks),
        .ack_valid(ack_valid && transaction_authorized),
        .ack_source(ack_source),
        .ack_complete(upgrade_done),
        .upgrade_busy(),
        .received_acks(received_acks)
    );

    // Coordinate validation, ACK completion and ledger updates.
    always @(*) begin
        message_valid_to_runtime = upgrade_valid;
        transaction_complete_to_runtime = upgrade_done;

        ledger_write_enable = 1'b0;
        ledger_write_address = init_address;
        ledger_write_state = init_state;
        ledger_write_owner = init_owner;
        ledger_write_sharers = init_sharers;

        if (init_write && !busy) begin
            ledger_write_enable = 1'b1;
        end

        if (ledger_commit && pending_commit) begin
            ledger_write_enable = 1'b1;
            ledger_write_address = saved_address;
            ledger_write_state = `MODIFIED;
            ledger_write_owner = saved_source;
            ledger_write_sharers = 3'b000;
        end
    end

    reg violation_valid_reg;
    reg [1:0] violation_code_reg;

    assign violation_valid = violation_valid_reg;
    assign violation_code = violation_code_reg;
    assign transaction_done = ledger_commit && pending_commit;

    always @(posedge clk) begin
        if (reset) begin
            upgrade_start_pulse <= 1'b0;
            pending_commit <= 1'b0;
            saved_address <= 16'b0;
            saved_source <= 2'b00;
            violation_valid_reg <= 1'b0;
            violation_code_reg <= 2'b00;
        end else begin
            upgrade_start_pulse <= 1'b0;
            violation_valid_reg <= 1'b0;

            if (start_upgrade && !busy && !pending_commit) begin
                if (!upgrade_valid) begin
                    violation_valid_reg <= 1'b1;
                    violation_code_reg <= manager_violation;
                end else begin
                    saved_address <= address;
                    saved_source <= source;
                    pending_commit <= 1'b1;
                    upgrade_start_pulse <= 1'b1;
                end
            end

            if (ledger_commit && pending_commit) begin
                pending_commit <= 1'b0;
            end
        end
    end

endmodule
