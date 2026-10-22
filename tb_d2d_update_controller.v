
module tb_d2d_update_controller;

    reg reset;
    reg init_enable;
    reg update_request;
    wire update_enable;

    integer i;
    integer passed;

    d2d_update_controller uut (
        .reset(reset),
        .init_enable(init_enable),
        .update_request(update_request),
        .update_enable(update_enable)
    );

    initial begin
        passed = 0;

        $display("=== Update Controller Truth Table Tests ===");

        for (i = 0; i < 8; i = i + 1) begin
            {reset, init_enable, update_request} = i[2:0];
            #10;

            if (update_enable !==
                (init_enable && update_request && !reset)) begin
                $display("FAIL: reset=%b init=%b request=%b output=%b",
                         reset, init_enable, update_request, update_enable);
                $fatal(1, "Update controller truth table mismatch");
            end
            else begin
                passed = passed + 1;
                $display("PASS: reset=%b init=%b request=%b output=%b",
                         reset, init_enable, update_request, update_enable);
            end
        end

        $display("ALL UPDATE CONTROLLER TESTS PASSED (%0d/8)", passed);
        $finish;
    end

endmodule
