
module d2d_runtime_controller (
    input wire clk,
    input wire reset,

    // Transaction control inputs
    input wire transaction_start,
    input wire message_valid,
    input wire transaction_complete,

    // Controller outputs
    output reg transaction_authorized,
    output reg ledger_commit,
    output reg busy
);

    // Controller states
    localparam IDLE      = 2'b00;
    localparam VALIDATE  = 2'b01;
    localparam WAIT_DONE = 2'b10;

    reg [1:0] state;

    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            transaction_authorized <= 1'b0;
            ledger_commit <= 1'b0;
            busy <= 1'b0;
        end else begin

            // Default: commit is a one-cycle pulse
            ledger_commit <= 1'b0;

            case (state)

                IDLE: begin
                    transaction_authorized <= 1'b0;
                    busy <= 1'b0;

                    if (transaction_start) begin
                        state <= VALIDATE;
                        busy <= 1'b1;
                    end
                end

                VALIDATE: begin
                    if (message_valid) begin
                        transaction_authorized <= 1'b1;
                        state <= WAIT_DONE;
                    end else begin
                        transaction_authorized <= 1'b0;
                        state <= IDLE;
                    end
                end
                

                WAIT_DONE: begin
                    if (transaction_complete &&
                        transaction_authorized) begin
                        ledger_commit <= 1'b1;
                        transaction_authorized <= 1'b0;
                        busy <= 1'b0;
                        state <= IDLE;
                    end
                end

                default: begin
                    state <= IDLE;
                    transaction_authorized <= 1'b0;
                    ledger_commit <= 1'b0;
                    busy <= 1'b0;
                end

            endcase
        end
    end

endmodule
