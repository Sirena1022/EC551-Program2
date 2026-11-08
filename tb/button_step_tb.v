
`timescale 1ns / 1ps

module button_step_tb;

    reg clk = 0;
    reg reset = 1;
    reg btn = 0;
    wire step;

    integer pulse_count = 0;
    integer passed = 0;
    integer failed = 0;

    // 100 MHz clock
    always #5 clk = ~clk;

    // Module under test
    button_step #(
        .DEBOUNCE_CYCLES(4)
    ) uut (
        .clk(clk),
        .reset(reset),
        .btn(btn),
        .step(step)
    );

    // Count generated step pulses
    always @(negedge clk) begin
        if (step)
            pulse_count = pulse_count + 1;
    end

    task wait_cycles;
        input integer n;
        begin
            repeat (n) @(negedge clk);
            #1;
        end
    endtask

    task check_count;
        input integer expected;
        begin
            if (pulse_count == expected) begin
                passed = passed + 1;
                $display("PASS: pulse count = %0d",
                         pulse_count);
            end
            else begin
                failed = failed + 1;
                $display("FAIL: expected=%0d actual=%0d",
                         expected, pulse_count);
            end
        end
    endtask

    initial begin
        $display("EC551 - Button Step Test");

        // Reset
        wait_cycles(3);
        reset = 0;

        // Test 1: First button press
        btn = 1;
        wait_cycles(10);
        check_count(1);

        // Test 2: Hold button
        wait_cycles(10);
        check_count(1);

        // Release button
        btn = 0;
        wait_cycles(10);

        // Test 3: Second button press
        btn = 1;
        wait_cycles(10);
        check_count(2);

        // Release again
        btn = 0;
        wait_cycles(10);

        // Test 4: Short bounce, no new step
        btn = 1;
        wait_cycles(2);
        btn = 0;
        wait_cycles(10);
        check_count(2);

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
