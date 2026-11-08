
`timescale 1ns / 1ps

module fpga_top_tb;

    reg clk = 0;
    reg reset = 1;
    reg btn = 0;
    reg [15:0] sw = 0;
    wire [15:0] led;

    integer passed = 0;
    integer failed = 0;

    // 100 MHz clock
    always #5 clk = ~clk;

    // FPGA top module
    fpga_top uut (
        .clk(clk),
        .reset(reset),
        .btn(btn),
        .sw(sw),
        .led(led)
    );

    // Wait for clock cycles
    task wait_cycles;
        input integer n;
        begin
            repeat (n) @(negedge clk);
            #1;
        end
    endtask

    // Check LED output
    task check_led;
        input [15:0] expected;
        begin
            if (led === expected) begin
                passed = passed + 1;
                $display("PASS: LED = %0d", led);
            end
            else begin
                failed = failed + 1;
                $display("FAIL: expected=%0d, actual=%0d",
                         expected, led);
            end
        end
    endtask

    // Simulate one button press
    task press_button;
        begin
            btn = 1;
            wait_cycles(1000010);
            btn = 0;
            wait_cycles(1000010);
        end
    endtask

    initial begin
        $display("EC551 - FPGA Button Integration Test");

        // Reset
        wait_cycles(5);
        reset = 0;
        wait_cycles(5);

        // Test 1: LED remains zero before button press
        sw = 2'b00;
        wait_cycles(5);
        check_led(16'd0);

        // Test 2: Addition, 12 + 5 = 17
        press_button();
        check_led(16'd17);

        // Test 3: Change switch without pressing
        sw = 2'b01;
        wait_cycles(10);
        check_led(16'd17);

        // Test 4: Subtraction, 12 - 5 = 7
        press_button();
        check_led(16'd7);

        // Test 5: Multiplication, 12 * 5 = 60
        sw = 2'b10;
        press_button();
        check_led(16'd60);

        // Test 6: Default output
        sw = 2'b11;
        press_button();
        check_led(16'd0);

        $display("-------------------------");
        $display("Passed: %0d", passed);
        $display("Failed: %0d", failed);

        if (failed == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

endmodule
