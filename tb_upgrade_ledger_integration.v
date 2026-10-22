
`timescale 1ns/1ps

`include "d2d_defs.v"

module tb_upgrade_ledger_integration;

    reg clk;
    reg reset;

    reg start_upgrade;
    reg [1:0] source;
    reg [15:0] address;

    reg ack_valid;
    reg [1:0] ack_source;

    reg init_write;
    reg [15:0] init_address;
    reg [1:0] init_state;
    reg [1:0] init_owner;
    reg [2:0] init_sharers;

    wire transaction_done;
    wire violation_valid;
    wire [1:0] violation_code;

    wire [2:0] received_acks;
    wire ledger_found_debug;
    wire [1:0] ledger_state_debug;
    wire [1:0] ledger_owner_debug;
    wire [2:0] ledger_sharers_debug;

    localparam [1:0] SHARED = `SHARED;
    localparam [1:0] MODIFIED = `MODIFIED;

    integer errors;

    upgrade_ledger_integration dut (
        .clk(clk),
        .reset(reset),

        .start_upgrade(start_upgrade),
        .source(source),
        .address(address),

        .ack_valid(ack_valid),
        .ack_source(ack_source),

        .init_write(init_write),
        .init_address(init_address),
        .init_state(init_state),
        .init_owner(init_owner),
        .init_sharers(init_sharers),

        .transaction_done(transaction_done),
        .violation_valid(violation_valid),
        .violation_code(violation_code),

        .received_acks(received_acks),
        .ledger_found_debug(ledger_found_debug),
        .ledger_state_debug(ledger_state_debug),
        .ledger_owner_debug(ledger_owner_debug),
        .ledger_sharers_debug(ledger_sharers_debug)
    );

    // 10 ns clock period
    initial clk = 1'b0;
    always #5 clk = ~clk;

    task check;
        input condition;
        input [8*100-1:0] message;
        begin
            if (condition === 1'b1) begin
                $display("PASS: %0s", message);
            end else begin
                $display("FAIL: %0s", message);
                errors = errors + 1;
            end
        end
    endtask

    task initialize_line;
        input [15:0] addr;
        input [1:0] state;
        input [1:0] line_owner;
        input [2:0] line_sharers;
        begin
            @(negedge clk);
            init_address = addr;
            init_state = state;
            init_owner = line_owner;
            init_sharers = line_sharers;
            init_write = 1'b1;

            @(negedge clk);
            init_write = 1'b0;

            // Allow nonblocking ledger writes to settle.
            #1;
        end
    endtask

    task start_request;
        input [15:0] addr;
        input [1:0] requester_id;
        begin
            @(negedge clk);
            address = addr;
            source = requester_id;
            start_upgrade = 1'b1;

            @(negedge clk);
            start_upgrade = 1'b0;
            #1;
        end
    endtask

    task send_ack;
        input [1:0] chiplet_id;
        begin
            @(negedge clk);
            ack_source = chiplet_id;
            ack_valid = 1'b1;

            // Sample outputs after the receiving rising edge.
            @(posedge clk);
            #1;

            @(negedge clk);
            ack_valid = 1'b0;
        end
    endtask

    initial begin
        errors = 0;

        reset = 1'b1;
        start_upgrade = 1'b0;
        source = 2'b00;
        address = 16'h1000;

        ack_valid = 1'b0;
        ack_source = 2'b00;

        init_write = 1'b0;
        init_address = 16'b0;
        init_state = `INVALID;
        init_owner = 2'b00;
        init_sharers = 3'b000;

        repeat (2) @(negedge clk);
        reset = 1'b0;

        // TEST 1: Initialize a shared line.
        initialize_line(16'h1000, SHARED, 2'd0, 3'b110);

        address = 16'h1000;
        #1;
        check(
            ledger_found_debug &&
            ledger_state_debug == SHARED &&
            ledger_sharers_debug == 3'b110,
            "Shared cache line initialized"
        );

        // TEST 2: Start a valid upgrade from chiplet 1.
        // Chiplet 2 must ACK; chiplet 1 is the requester.
        start_request(16'h1000, 2'd1);

        check(
            !transaction_done &&
            !violation_valid &&
            ledger_state_debug == SHARED,
            "Ledger unchanged while waiting for ACK"
        );

        // An ACK from chiplet 0 is not required and must be ignored.
        send_ack(2'd0);

        check(
            received_acks == 3'b000 &&
            !transaction_done &&
            ledger_state_debug == SHARED,
            "Unexpected ACK ignored"
        );

        // Required ACK from chiplet 2.
        send_ack(2'd2);

        check(
            transaction_done &&
            !violation_valid &&
            ledger_found_debug &&
            ledger_state_debug == MODIFIED &&
            ledger_owner_debug == 2'd1 &&
            ledger_sharers_debug == 3'b000,
            "Upgrade commits after required ACK"
        );

        // TEST 3: Unknown address must be rejected.
        start_request(16'h3000, 2'd0);

        check(
            violation_valid &&
            violation_code == 2'b11,
            "Unknown cache line rejected"
        );

        // TEST 4: Requester must be one of the current sharers.
        initialize_line(16'h2000, SHARED, 2'd0, 3'b011);

        start_request(16'h2000, 2'd2);

        check(
            violation_valid &&
            violation_code == 2'b10,
            "Non-sharer upgrade rejected"
        );

        // TEST 5: The original line remains Modified after success.
        address = 16'h1000;
        #1;
        check(
            ledger_found_debug &&
            ledger_state_debug == MODIFIED &&
            ledger_owner_debug == 2'd1,
            "Modified line ownership retained"
        );

        if (errors == 0) begin
            $display("");
            $display("ALL LEDGER INTEGRATION TESTS PASSED");
        end else begin
            $display("");
            $display("TESTS FAILED: %0d error(s)", errors);
            $fatal(1, "Integration testbench failed");
        end

        $finish;
    end

    initial begin
        #2000;
        $fatal(1, "Simulation timeout");
    end

endmodule
