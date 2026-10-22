
`include "d2d_defs.v"

module upgrade_transaction (
    input wire clk,
    input wire reset,

    input wire start_upgrade,
    input wire [1:0] source,
    input wire ledger_found,
    input wire [1:0] ledger_state,
    input wire [2:0] ledger_sharers,

    input wire ack_valid,
    input wire [1:0] ack_source,

    output reg transaction_done,
    output reg violation_valid,
    output reg [1:0] violation_code,
    output wire [2:0] received_acks
);

    wire upgrade_valid;
    wire [2:0] expected_acks;
    wire [1:0] manager_violation;

    reg tracker_start;
    reg [2:0] tracker_expected_acks;

    wire ack_complete;
    wire upgrade_busy;

    reg active;
    reg [1:0] requester;

    upgrade_manager manager (
        .source(source),
        .ledger_found(ledger_found),
        .ledger_state(ledger_state),
        .ledger_sharers(ledger_sharers),
        .upgrade_valid(upgrade_valid),
        .expected_acks(expected_acks),
        .violation_code(manager_violation)
    );

    upgrade_ack_tracker tracker (
        .clk(clk),
        .reset(reset),
        .start_upgrade(tracker_start),
        .expected_acks(tracker_expected_acks),
        .ack_valid(ack_valid && active),
        .ack_source(ack_source),
        .ack_complete(ack_complete),
        .upgrade_busy(upgrade_busy),
        .received_acks(received_acks)
    );

    always @(posedge clk) begin
        if (reset) begin
            transaction_done <= 1'b0;
            violation_valid <= 1'b0;
            violation_code <= 2'b00;
            tracker_start <= 1'b0;
            tracker_expected_acks <= 3'b000;
            active <= 1'b0;
            requester <= 2'b00;
        end else begin
            transaction_done <= 1'b0;
            violation_valid <= 1'b0;
            tracker_start <= 1'b0;

            if (start_upgrade && !active) begin
                if (upgrade_valid) begin
                    requester <= source;
                    tracker_expected_acks <= expected_acks;
                    tracker_start <= 1'b1;
                    active <= 1'b1;
                end else begin
                    violation_valid <= 1'b1;
                    violation_code <= manager_violation;
                end
            end else if (active && ack_complete) begin
                transaction_done <= 1'b1;
                active <= 1'b0;
            end
        end
    end

endmodule
