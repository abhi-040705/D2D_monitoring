
`include "d2d_defs.v"

module tb_d2d_validator;

    reg [2:0]  msg_type;
    reg [1:0]  source;
    reg [15:0] address;

    reg        ledger_found;
    reg [1:0]  ledger_state;
    reg [1:0]  ledger_owner;
    reg [2:0]  ledger_sharers;

    wire       violation_valid;
    wire [1:0] violation_code;

    d2d_validator dut (
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

    initial begin
        $display("=== D2D Security Validator Tests ===");

        // Test 1: Legitimate PUTM from owner
        msg_type = `PUTM;
        source = 2'd1;
        address = 16'h1000;
        ledger_found = 1'b1;
        ledger_state = `MODIFIED;
        ledger_owner = 2'd1;
        ledger_sharers = 3'b010;
        #10;

        if (violation_valid !== 1'b0)
            $fatal(1, "FAIL: Legitimate PUTM rejected");
        else
            $display("PASS 1: Legitimate PUTM accepted");

        // Test 2: Forged PUTM from non-owner
        source = 2'd2;
        #10;

        if (violation_valid !== 1'b1 ||
            violation_code !== 2'b01)
            $fatal(1, "FAIL: Forged PUTM not detected");
        else
            $display("PASS 2: Forged PUTM detected");

        // Test 3: Legitimate UPGRADE by a sharer
        msg_type = `UPGRADE;
        source = 2'd1;
        ledger_state = `SHARED;
        ledger_sharers = 3'b010;
        #10;

        if (violation_valid !== 1'b0)
            $fatal(1, "FAIL: Legitimate UPGRADE rejected");
        else
            $display("PASS 3: Legitimate UPGRADE accepted");

        // Test 4: UPGRADE by non-sharer
        source = 2'd2;
        #10;

        if (violation_valid !== 1'b1 ||
            violation_code !== 2'b10)
            $fatal(1, "FAIL: Illegal UPGRADE not detected");
        else
            $display("PASS 4: Non-sharer UPGRADE rejected");

        // Test 5: PUTM for unknown line
        msg_type = `PUTM;
        source = 2'd1;
        ledger_found = 1'b0;
        #10;

        if (violation_valid !== 1'b1 ||
            violation_code !== 2'b11)
            $fatal(1, "FAIL: Unknown line not detected");
        else
            $display("PASS 5: Unknown cache line detected");

        // Test 6: UPGRADE when line is not SHARED
        ledger_found = 1'b1;
        msg_type = `UPGRADE;
        source = 2'd1;
        ledger_state = `MODIFIED;
        ledger_sharers = 3'b010;
        #10;

        if (violation_valid !== 1'b1 ||
            violation_code !== 2'b10)
            $fatal(1, "FAIL: UPGRADE from non-SHARED state not rejected");
        else
            $display("PASS 6: UPGRADE from non-SHARED state rejected");

        // Test 7: PUTM from non-owner
        msg_type = `PUTM;
        source = 2'd2;
        ledger_state = `MODIFIED;
        ledger_owner = 2'd1;
        #10;

        if (violation_valid !== 1'b1 ||
            violation_code !== 2'b01)
            $fatal(1, "FAIL: Non-owner PUTM not detected");
        else
            $display("PASS 7: Non-owner PUTM detected");

        $display("ALL VALIDATOR TESTS PASSED (7/7)");
        $finish;
    end

endmodule
