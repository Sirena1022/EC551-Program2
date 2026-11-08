
`timescale 1ns / 1ps

module fpga_top_tb;

    reg  [15:0] sw;
    wire [15:0] led;

    integer passed = 0;
    integer failed = 0;

    // Connect the FPGA top module
    fpga_top uut (
        .sw(sw),
        .led(led)
    );

    // Check the LED output
    task check_output;
        input [1:0] selection;
        input [15:0] expected;
        begin
            sw = {14'b0, selection};
            #10;

            if (led === expected) begin
                passed = passed + 1;
                $display("PASS: sw=%b, led=%0d",
                         selection, led);
            end
            else begin
                failed = failed + 1;
                $display("FAIL: sw=%b, expected=%0d, actual=%0d",
                         selection, expected, led);
            end
        end
    endtask

    initial begin
        $display("EC551 Program 2 - FPGA Output Selection Test");

        // a = 12, b = 5
        check_output(2'b00, 16'd17); // Addition
        check_output(2'b01, 16'd7);  // Subtraction
        check_output(2'b10, 16'd60); // Multiplication
        check_output(2'b11, 16'd0);  // Default

        $display("-----------------------------");
        $display("Passed: %0d", passed);
        $display("Failed: %0d", failed);

        if (failed == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

endmodule
