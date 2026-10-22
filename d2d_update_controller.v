
module d2d_update_controller (
    input wire reset,

    // Trusted initialization interface
    input wire init_enable,

    // Ledger update request
    input wire update_request,

    // Authorized ledger update
    output wire update_enable
);

    // Allow ledger writes only during trusted initialization.
    assign update_enable =
        init_enable && update_request && !reset;

endmodule
