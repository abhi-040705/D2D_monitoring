
`timescale 1ns/1ps

module tb_d2d_monitor;

    reg clk;
    reg reset;

    reg [2:0] msg_type;
    reg [1:0] source;
    reg [15:0] address;

    reg trusted_update_enable;
    reg [15:0] trusted_update_address;
    reg [1:0] trusted_update_state;
    reg [1:0] trusted_update_owner;
    reg [2:0] trusted_update_sharers;

    wire violation_valid;
    wire [1:0] violation_code;
    wire ledger_found_debug;
    wire [1:0] ledger_state_debug;
    wire [1:0] ledger_owner_debug;

    d2d_monitor dut (
        .clk(clk),
        .reset(reset),
        .msg_type(msg_type),
        .source(source),
        .address(address),
        .trusted_update_enable(trusted_update_enable),
        .trusted_update_address(trusted_update_address),
        .trusted_update_state(trusted_update_state),
        .trusted_update_owner(trusted_update_owner),
        .trusted_update_sharers(trusted_update_sharers),
        
        .violation_valid(violation_valid),
        .violation_code(violation_code),
        .ledger_found_debug(ledger_found_debug),
        .ledger_state_debug(ledger_state_debug),
        .ledger_owner_debug(ledger_owner_debug)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;

        msg_type = 3'b000;
        source = 2'b00;
        address = 16'h1000;

        trusted_update_enable = 0;
        trusted_update_address = 16'h1000;
        trusted_update_state = 2'b10;
        trusted_update_owner = 2'b01;
        trusted_update_sharers = 3'b010;

        #12;
        reset = 0;

        // Initialize the ledger through the trusted interface.
        trusted_update_enable = 1;
        #10;
        trusted_update_enable = 0;
        #1;

        // Legitimate PUTM from the recorded owner.
        msg_type = 3'b100;
        source = 2'b01;
        #1;

        if (!violation_valid) begin
            $display("PASS: Legitimate PUTM accepted");
        end else begin
            $display("FAIL: Legitimate PUTM flagged");
            $fatal(1);
        end

        // Forged PUTM from a different chiplet.
        source = 2'b10;
        #1;

        if (violation_valid && violation_code == 2'b01) begin
            $display("PASS: Forged PUTM detected");
        end else begin
            $display("FAIL: Forged PUTM not detected");
            $fatal(1);
        end
        if (ledger_found_debug &&
            ledger_state_debug == 2'b10 &&
            ledger_owner_debug == 2'b01) begin
            $display("PASS: Ledger state remains unchanged after violation");
        end else begin
            $display("FAIL: Ledger state changed after violation");
            $fatal(1);
        end
        

        // Test: Illegal UPGRADE from a non-sharer
        // Chiplet 1 owns the line in MODIFIED state.
        // Chiplet 2 is not a recorded sharer.

        msg_type = 3'b010;  // UPGRADE
        source = 2'b10;     // Chiplet 2
        address = 16'h1000;
        #1;

        if (violation_valid && violation_code == 2'b10) begin
            $display("PASS: Illegal UPGRADE detected");
        end else begin
            $display("FAIL: Illegal UPGRADE not detected");
            $fatal(1);
        end

        // Confirm the ledger still records Chiplet 1 as owner.
        if (ledger_found_debug &&
            ledger_state_debug == 2'b10 &&
            ledger_owner_debug == 2'b01) begin
            $display("PASS: Ledger unchanged after illegal UPGRADE");
        end else begin
            $display("FAIL: Ledger changed after illegal UPGRADE");
            $fatal(1);
        end
        

        // Test: PUTM for an unknown cache line
        msg_type = 3'b100;  // PUTM
        source = 2'b01;     // Chiplet 1
        address = 16'h2000; // Address not in the ledger
        #1;

        if (violation_valid && violation_code == 2'b11) begin
            $display("PASS: Unknown cache line detected");
        end else begin
            $display("FAIL: Unknown cache line not detected");
            $fatal(1);
        end

        // Confirm the original ledger entry is still intact.
        address = 16'h1000;
        #1;

        if (ledger_found_debug &&
            ledger_state_debug == 2'b10 &&
            ledger_owner_debug == 2'b01) begin
            $display("PASS: Original ledger entry remains intact");
        end else begin
            $display("FAIL: Original ledger entry changed");
            $fatal(1);
        end
        

        // Test: UPGRADE for an unknown cache line
        msg_type = 3'b010;  // UPGRADE
        source = 2'b01;     // Chiplet 1
        address = 16'h3000; // Address not in the ledger
        #1;

        if (violation_valid && violation_code == 2'b11) begin
            $display("PASS: Unknown-line UPGRADE detected");
        end else begin
            $display("FAIL: Unknown-line UPGRADE not detected");
            $fatal(1);
        end

        // Verify the original ledger entry remains unchanged.
        address = 16'h1000;
        #1;

        if (ledger_found_debug &&
            ledger_state_debug == 2'b10 &&
            ledger_owner_debug == 2'b01) begin
            $display("PASS: Ledger unchanged after unknown-line UPGRADE");
        end else begin
            $display("FAIL: Ledger changed after unknown-line UPGRADE");
            $fatal(1);
        end


        $display("MONITOR TESTS PASSED");
        $finish;
    end

endmodule
