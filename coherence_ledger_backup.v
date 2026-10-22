
module coherence_ledger #(
    parameter ENTRIES = 16
)(
    input wire clk,
    input wire reset,

    // Write interface
    input wire write_enable,
    input wire [15:0] write_address,
    input wire [1:0] write_state,
    input wire [1:0] write_owner,
    input wire [2:0] write_sharers,

    // Lookup interface
    input wire [15:0] lookup_address,
    output reg found,
    output reg [1:0] lookup_state,
    output reg [1:0] lookup_owner,
    output reg [2:0] lookup_sharers
);

    reg valid [0:ENTRIES-1];
    reg [15:0] line_addr [0:ENTRIES-1];
    reg [1:0] line_state [0:ENTRIES-1];
    reg [1:0] owner [0:ENTRIES-1];
    reg [2:0] sharers [0:ENTRIES-1];

    integer i;
    integer j;
    integer match_index;
    integer free_index;

    // Reset all entries
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < ENTRIES; i = i + 1) begin
                valid[i] <= 1'b0;
                line_addr[i] <= 16'b0;
                line_state[i] <= 2'b00;
                owner[i] <= 2'b00;
                sharers[i] <= 3'b000;
            end
        end else if (write_enable) begin
            match_index = -1;
            free_index = -1;

            for (j = 0; j < ENTRIES; j = j + 1) begin
                if (valid[j] && line_addr[j] == write_address)
                    match_index = j;

                if (!valid[j] && free_index == -1)
                    free_index = j;
            end

            if (match_index != -1) begin
                line_state[match_index] <= write_state;
                owner[match_index] <= write_owner;
                sharers[match_index] <= write_sharers;
            end else if (free_index != -1) begin
                valid[free_index] <= 1'b1;
                line_addr[free_index] <= write_address;
                line_state[free_index] <= write_state;
                owner[free_index] <= write_owner;
                sharers[free_index] <= write_sharers;
            end
        end
    end

    // Combinational lookup
    always @(*) begin
        found = 1'b0;
        lookup_state = 2'b00;
        lookup_owner = 2'b00;
        lookup_sharers = 3'b000;

        for (integer k = 0; k < ENTRIES; k = k + 1) begin
            if (valid[k] && line_addr[k] == lookup_address) begin
                found = 1'b1;
                lookup_state = line_state[k];
                lookup_owner = owner[k];
                lookup_sharers = sharers[k];
            end
        end
    end

endmodule
