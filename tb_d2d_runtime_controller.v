
module tb_d2d_runtime_controller;

    reg clk;
    reg reset;
    reg transaction_start;
    reg message_valid;
    reg transaction_complete;

    wire transaction_authorized;
    wire ledger_commit;
    wire busy;

    d2d_runtime_controller uut (
        .clk(clk),
        .reset(reset),
        .transaction_start(transaction_start),
        .message_valid(message_valid),
        .transaction_complete(transaction_complete),
        .transaction_authorized(transaction_authorized),
        .ledger_commit(ledger_commit),
        .busy(busy)
    );

    // Generate a clock with a 10 ns period
    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        transaction_start = 1'b0;
        message_valid = 1'b0;
        transaction_complete = 1'b0;

        // Reset controller
        @(posedge clk);
        #1;
        reset = 1'b0;

        // Test 1: Start a transaction
        @(negedge clk);
        transaction_start = 1'b1;

        @(negedge clk);
        transaction_start = 1'b0;

        @(negedge clk);
        if (busy !== 1'b1)
            $fatal(1, "FAIL: Controller did not enter busy state");

        $display("PASS: Transaction started");

        // Test 2: Reject an invalid message
        message_valid = 1'b0;

        @(negedge clk);

        if (transaction_authorized !== 1'b0)
            $fatal(1, "FAIL: Invalid message was authorized");

        if (busy !== 1'b0)
            $fatal(1, "FAIL: Busy was not cleared after rejection");

        $display("PASS: Invalid message rejected");

        // Test 3: Start a new transaction
        transaction_start = 1'b1;

        @(negedge clk);
        transaction_start = 1'b0;

        // Test 4: Accept a valid message
        message_valid = 1'b1;

        @(negedge clk);
        message_valid = 1'b0;

        if (transaction_authorized !== 1'b1)
            $fatal(1, "FAIL: Valid message was not authorized");

        $display("PASS: Valid message authorized");

        // Test 5: Verify no commit before completion
        if (ledger_commit !== 1'b0)
            $fatal(1, "FAIL: Unexpected commit before completion");

        $display("PASS: No commit before transaction completion");

        // Test 6: Complete the authorized transaction
        transaction_complete = 1'b1;

        @(negedge clk);
        transaction_complete = 1'b0;

        if (ledger_commit !== 1'b1)
            $fatal(1, "FAIL: Ledger commit pulse missing");

        $display("PASS: Ledger commit generated after completion");

        // Test 7: Verify commit is only one cycle
        @(negedge clk);

        if (ledger_commit !== 1'b0)
            $fatal(1, "FAIL: Commit was not a one-cycle pulse");

        if (busy !== 1'b0)
            $fatal(1, "FAIL: Controller remained busy");

        $display("PASS: Controller returned to idle");

        $display("ALL RUNTIME CONTROLLER TESTS PASSED");
        $finish;
    end

endmodule
