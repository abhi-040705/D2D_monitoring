
`include "d2d_defs.v"

module d2d_generator;

    // Example transaction fields
    reg [1:0]  source;
    reg [2:0]  msg_type;
    reg [15:0] address;
    reg [31:0] data;

    initial begin
        $display("======================================");
        $display(" D2D Coherence Message Generator");
        $display("======================================");

        // Transaction 1: Chiplet 0 requests shared access
        source   = 2'd0;
        msg_type = `GETS;
        address  = 16'h1000;
        data     = 32'h00000000;
        #10;
        $display("Time=%0t | Source=%0d | Type=GETS | Address=%h",
                 $time, source, address);

        // Transaction 2: Chiplet 1 requests modified access
        source   = 2'd1;
        msg_type = `GETM;
        address  = 16'h1000;
        data     = 32'h00000000;
        #10;
        $display("Time=%0t | Source=%0d | Type=GETM | Address=%h",
                 $time, source, address);

        // Transaction 3: Chiplet 0 releases a shared line
        source   = 2'd0;
        msg_type = `PUTS;
        address  = 16'h1000;
        data     = 32'h00000000;
        #10;
        $display("Time=%0t | Source=%0d | Type=PUTS | Address=%h",
                 $time, source, address);

        // Transaction 4: Chiplet 1 releases a modified line
        source   = 2'd1;
        msg_type = `PUTM;
        address  = 16'h1000;
        data     = 32'hA5A5A5A5;
        #10;
        $display("Time=%0t | Source=%0d | Type=PUTM | Address=%h | Data=%h",
                 $time, source, address, data);

        $display("--------------------------------------");
        $display("Generator simulation completed.");
        $finish;
    end

endmodule
