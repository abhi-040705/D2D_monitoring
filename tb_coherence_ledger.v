
`include "d2d_defs.v"

module tb_coherence_ledger;

    reg clk;
    reg reset;

    reg write_enable;
    reg [15:0] write_address;
    reg [1:0] write_state;
    reg [1:0] write_owner;
    reg [2:0] write_sharers;

    reg [15:0] lookup_address;
    wire found;
    wire [1:0] lookup_state;
    wire [1:0] lookup_owner;
    wire [2:0] lookup_sharers;

    coherence_ledger dut (
        .clk(clk),
        .reset(reset),
        .write_enable(write_enable),
        .write_address(write_address),
        .write_state(write_state),
        .write_owner(write_owner),
        .write_sharers(write_sharers),
        .lookup_address(lookup_address),
        .found(found),
        .lookup_state(lookup_state),
        .lookup_owner(lookup_owner),
        .lookup_sharers(lookup_sharers)
    );

    // 10 ns clock period
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("simulation/coherence_ledger.vcd");
        $dumpvars(0, tb_coherence_ledger);

        reset = 1;
        write_enable = 0;
        write_address = 0;
        write_state = 0;
        write_owner = 0;
        write_sharers = 0;
        lookup_address = 16'h1000;

        // Reset the ledger
        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 0;

        // Confirm the address is initially absent
        #1;
        if (found !== 1'b0)
            $fatal(1, "FAIL: Entry should initially be absent");

        $display("PASS: Address 1000 initially absent");

        // Write line 1000 as MODIFIED, owned by chiplet 1
        write_enable = 1;
        write_address = 16'h1000;
        write_state = `MODIFIED;
        write_owner = 2'd1;
        write_sharers = 3'b010;

        @(posedge clk);
        #1;
        @(negedge clk);
        write_enable = 0;

        // Look up the written line
        #1;
        if (found !== 1'b1)
            $fatal(1, "FAIL: Written entry not found");

        if (lookup_state !== `MODIFIED)
            $fatal(1, "FAIL: Incorrect state");

        if (lookup_owner !== 2'd1)
            $fatal(1, "FAIL: Incorrect owner");

        if (lookup_sharers !== 3'b010)
            $fatal(1, "FAIL: Incorrect sharers");

        $display("PASS: Address 1000 found");
        $display("PASS: State = MODIFIED");
        $display("PASS: Owner = Chiplet 1");
        $display("PASS: Sharers = 010");

        $display("ALL LEDGER TESTS PASSED");
        $finish;
    end

endmodule
