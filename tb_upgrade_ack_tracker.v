
module tb_upgrade_ack_tracker;

    reg clk;
    reg reset;
    reg start_upgrade;
    reg [2:0] expected_acks;
    reg ack_valid;
    reg [1:0] ack_source;

    wire ack_complete;
    wire upgrade_busy;
    wire [2:0] received_acks;

    upgrade_ack_tracker uut (
        .clk(clk),
        .reset(reset),
        .start_upgrade(start_upgrade),
        .expected_acks(expected_acks),
        .ack_valid(ack_valid),
        .ack_source(ack_source),
        .ack_complete(ack_complete),
        .upgrade_busy(upgrade_busy),
        .received_acks(received_acks)
    );

    // 10 ns clock period
    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        start_upgrade = 1'b0;
        expected_acks = 3'b000;
        ack_valid = 1'b0;
        ack_source = 2'b00;

        // Reset
        @(negedge clk);
        reset = 1'b0;

        // Test 1: Start upgrade requiring ACKs from chiplets 1 and 2
        expected_acks = 3'b110;
        start_upgrade = 1'b1;

        @(negedge clk);
        start_upgrade = 1'b0;

        if (ack_complete !== 1'b0 || upgrade_busy !== 1'b1)
            $fatal(1, "FAIL: Tracker did not wait for required ACKs");

        $display("PASS: Tracker waits for required ACKs");

        // Test 2: ACK from chiplet 1
        ack_valid = 1'b1;
        ack_source = 2'd1;

        @(negedge clk);
        ack_valid = 1'b0;

        if (received_acks !== 3'b010)
            $fatal(1, "FAIL: ACK from chiplet 1 not recorded");

        if (ack_complete !== 1'b0)
            $fatal(1, "FAIL: Completed before all ACKs arrived");

        $display("PASS: First ACK recorded; tracker still waiting");

        // Test 3: ACK from chiplet 2
        ack_valid = 1'b1;
        ack_source = 2'd2;

        @(negedge clk);
        ack_valid = 1'b0;

        if (received_acks !== 3'b110)
            $fatal(1, "FAIL: ACK from chiplet 2 not recorded");

        if (ack_complete !== 1'b1 || upgrade_busy !== 1'b0)
            $fatal(1, "FAIL: Tracker did not complete after all ACKs");

        $display("PASS: Upgrade completes after all required ACKs");

        // Test 4: No ACKs required
        @(negedge clk);
        expected_acks = 3'b000;
        start_upgrade = 1'b1;

        @(negedge clk);
        start_upgrade = 1'b0;

        if (ack_complete !== 1'b1 || upgrade_busy !== 1'b0)
            $fatal(1, "FAIL: Zero-ACK upgrade did not complete");

        $display("PASS: Upgrade completes when no ACKs are required");
      
        // Test 5: Unexpected ACK must be ignored
        @(negedge clk);
        expected_acks = 3'b010;  // Only Chiplet 1 is required
        start_upgrade = 1'b1;
        @(negedge clk);
        start_upgrade = 1'b0;

        // Send ACK from Chiplet 0, which is not required
        ack_valid = 1'b1;
        ack_source = 2'd0;
        @(negedge clk);
        ack_valid = 1'b0;

        if (ack_complete !== 1'b0 || upgrade_busy !== 1'b1)
            $fatal(1, "FAIL: Unexpected ACK incorrectly completed upgrade");

        $display("PASS: Unexpected ACK ignored");
        $display("ALL ACK TRACKER TESTS PASSED");
        $finish;
    end

endmodule

