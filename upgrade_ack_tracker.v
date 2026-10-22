
module upgrade_ack_tracker (
    input wire clk,
    input wire reset,
    input wire start_upgrade,
    input wire [2:0] expected_acks,
    input wire ack_valid,
    input wire [1:0] ack_source,
    output reg ack_complete,
    output reg upgrade_busy,
    output reg [2:0] received_acks
);

    reg [2:0] required_acks;
    reg [2:0] ack_mask;
    reg [2:0] next_ack_mask;

    always @(*) begin
        next_ack_mask = ack_mask;

        if (ack_valid && ack_source < 3 &&
            required_acks[ack_source]) begin
            next_ack_mask[ack_source] = 1'b1;
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            required_acks <= 3'b000;
            ack_mask <= 3'b000;
            received_acks <= 3'b000;
            ack_complete <= 1'b0;
            upgrade_busy <= 1'b0;
        end else begin
            // Completion is a one-cycle pulse.
            ack_complete <= 1'b0;

            if (start_upgrade && !upgrade_busy) begin
                required_acks <= expected_acks;
                ack_mask <= 3'b000;
                received_acks <= 3'b000;

                if (expected_acks == 3'b000) begin
                    ack_complete <= 1'b1;
                    upgrade_busy <= 1'b0;
                end else begin
                    upgrade_busy <= 1'b1;
                end
            end else if (upgrade_busy) begin
                ack_mask <= next_ack_mask;
                received_acks <= next_ack_mask;

                if ((next_ack_mask & required_acks) == required_acks) begin
                    ack_complete <= 1'b1;
                    upgrade_busy <= 1'b0;
                end
            end
        end
    end

endmodule
