
`timescale 1ns / 1ps

module button_step #(
    parameter integer DEBOUNCE_CYCLES = 1000000
)(
    input  wire clk,
    input  wire reset,
    input  wire btn,
    output reg  step
);

    // Synchronize the button input
    reg btn_meta = 0;
    reg btn_sync = 0;

    always @(posedge clk) begin
        if (reset) begin
            btn_meta <= 0;
            btn_sync <= 0;
        end
        else begin
            btn_meta <= btn;
            btn_sync <= btn_meta;
        end
    end

    // Debounce and detect a new press
    reg stable_btn = 0;
    reg [31:0] counter = 0;

    always @(posedge clk) begin
        if (reset) begin
            counter    <= 0;
            stable_btn <= 0;
            step       <= 0;
        end
        else begin
            step <= 0;

            if (btn_sync == stable_btn) begin
                counter <= 0;
            end
            else if (counter >= DEBOUNCE_CYCLES - 1) begin
                stable_btn <= btn_sync;
                counter    <= 0;

                // Generate one pulse on a confirmed press
                if (btn_sync == 1'b1)
                    step <= 1'b1;
            end
            else begin
                counter <= counter + 1;
            end
        end
    end

endmodule
