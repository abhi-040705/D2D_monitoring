
module tb_upgrade_transaction;

    reg clk, reset;
    reg start_upgrade;
    reg [1:0] source;
    reg ledger_found;
    reg [1:0] ledger_state;
    reg [2:0] ledger_sharers;
    reg ack_valid;
    reg [1:0] ack_source;

    wire transaction_done;
    wire violation_valid;
    wire [1:0] violation_code;
    wire [2:0] received_acks;

    upgrade_transaction uut (
        .clk(clk),
        .reset(reset),
        .start_upgrade(start_upgrade),
        .source(source),
        .ledger_found(ledger_found),
        .ledger_state(ledger_state),
        .ledger_sharers(ledger_sharers),
        .ack_valid(ack_valid),
        .ack_source(ack_source),
        .transaction_done(transaction_done),
        .violation_valid(violation_valid),
        .violation_code(violation_code),
        .received_acks(received_acks)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        start_upgrade = 0;
        source = 1;
        ledger_found = 1;
        ledger_state = 2'b01;
        ledger_sharers = 3'b110;
        ack_valid = 0;
        ack_source = 0;

        repeat (2) @(negedge clk);
        reset = 0;

        // Test 1: Valid request
        @(negedge clk);
        start_upgrade = 1;
        @(negedge clk);
        start_upgrade = 0;

        if (violation_valid !== 0)
            $fatal(1, "FAIL: Valid request rejected");
        $display("PASS: Valid UPGRADE request accepted");

        // Test 2: Unexpected ACK from chiplet 0
        ack_valid = 1;
        ack_source = 0;
        @(negedge clk);
        ack_valid = 0;

        if (transaction_done !== 0)
            $fatal(1, "FAIL: Unexpected ACK completed transaction");
        $display("PASS: Unexpected ACK did not complete transaction");

        // Test 3: Required ACK from chiplet 2
        ack_valid = 1;
        ack_source = 2;
        @(negedge clk);
        ack_valid = 0;

        // Allow completion logic to observe tracker status
        @(negedge clk);
        if (transaction_done !== 1)
            $fatal(1, "FAIL: Transaction did not complete after required ACK");

        $display("PASS: Transaction completed after required ACK");

        // Test 4: Invalid request for unknown line
        ledger_found = 0;
        @(negedge clk);
        start_upgrade = 1;
        @(negedge clk);
        start_upgrade = 0;

        if (violation_valid !== 1 || violation_code !== 2'b11)
            $fatal(1, "FAIL: Unknown-line request not rejected");

        $display("PASS: Unknown-line request rejected");
        $display("ALL UPGRADE TRANSACTION TESTS PASSED");
        $finish;
    end

endmodule
