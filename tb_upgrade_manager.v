
module tb_upgrade_manager;

    reg [1:0] source;
    reg ledger_found;
    reg [1:0] ledger_state;
    reg [2:0] ledger_sharers;

    wire upgrade_valid;
    wire [2:0] expected_acks;
    wire [1:0] violation_code;

    upgrade_manager uut (
        .source(source),
        .ledger_found(ledger_found),
        .ledger_state(ledger_state),
        .ledger_sharers(ledger_sharers),
        .upgrade_valid(upgrade_valid),
        .expected_acks(expected_acks),
        .violation_code(violation_code)
    );

    initial begin
        // Test 1: Valid requester; Chiplets 1 and 2 are sharers
        source = 2'd1;
        ledger_found = 1'b1;
        ledger_state = 2'b01;
        ledger_sharers = 3'b110;
        #10;

        if (upgrade_valid !== 1'b1 || expected_acks !== 3'b100)
            $fatal(1, "FAIL: Valid UPGRADE or ACK mask incorrect");
        $display("PASS: Valid UPGRADE and ACK mask");

        // Test 2: Unknown cache line
        ledger_found = 1'b0;
        #10;

        if (upgrade_valid !== 1'b0 || violation_code !== 2'b11)
            $fatal(1, "FAIL: Unknown line not rejected");
        $display("PASS: Unknown line rejected");

        // Test 3: Line is not Shared
        ledger_found = 1'b1;
        ledger_state = 2'b10;
        #10;

        if (upgrade_valid !== 1'b0 || violation_code !== 2'b10)
            $fatal(1, "FAIL: Invalid state not rejected");
        $display("PASS: Invalid state rejected");

        // Test 4: Requester is not a sharer
        ledger_state = 2'b01;
        ledger_sharers = 3'b100;
        source = 2'd0;
        #10;

        if (upgrade_valid !== 1'b0 || violation_code !== 2'b10)
            $fatal(1, "FAIL: Non-sharer not rejected");
        $display("PASS: Non-sharer rejected");

        $display("ALL UPGRADE MANAGER TESTS PASSED");
        $finish;
    end

endmodule
