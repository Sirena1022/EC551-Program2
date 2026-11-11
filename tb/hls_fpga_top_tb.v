
`timescale 1ns / 1ps

module hls_fpga_top_tb;

    reg clk = 0;
    reg reset = 1;
    reg btn = 0;
    reg [15:0] sw = 0;

    wire [15:0] led;

    integer passed = 0;
    integer failed = 0;

    // 100 MHz clock
    always #5 clk = ~clk;

    // Device Under Test
    hls_fpga_top #(
        .DEBOUNCE_CYCLES(4)
    ) uut (
        .clk(clk),
        .reset(reset),
        .btn(btn),
        .sw(sw),
        .led(led)
    );

    // ==========================================
    // Wait for clock cycles
    // ==========================================

    task wait_cycles;
        input integer n;
        begin
            repeat (n) @(negedge clk);
            #1;
        end
    endtask

    // ==========================================
    // Simulate one physical button press
    // ==========================================

    task press_button;
        begin
            @(negedge clk);
            btn = 1;
            wait_cycles(12);

            btn = 0;
            wait_cycles(12);
        end
    endtask

    // ==========================================
    // Check LED output
    // ==========================================

    task check_led;
        input [15:0] expected;
        begin
            #1;

            if (led === expected) begin
                passed = passed + 1;
                $display(
                    "PASS: LED=%0d",
                    led
                );
            end
            else begin
                failed = failed + 1;
                $display(
                    "FAIL: expected=%0d actual=%0d",
                    expected,
                    led
                );
            end
        end
    endtask

    // ==========================================
    // Main Test Sequence
    // ==========================================

    initial begin

        $display(
            "EC551 HLS FPGA Observation Test"
        );

        // Reset
        wait_cycles(5);
        reset = 0;
        wait_cycles(5);

        // Input A = 12, B = 5
        sw[7:4]  = 4'd12;
        sw[11:8] = 4'd5;

        // ======================================
        // Test 1: Initial state
        // ======================================

        sw[13] = 0;
        sw[12] = 0;
        sw[3:2] = 2'b00;

        check_led(0);

        // ======================================
        // Step 1: Enter Cycle 1
        // ======================================

        press_button();

        // Test 2: Adder output = A+B = 17
        sw[12] = 1;
        sw[1:0] = 2'b00;
        sw[15:14] = 2'b00;

        check_led(17);

        // ======================================
        // Step 2: Calculate X
        // ======================================

        press_button();

        // Test 3: Saved X = 17
        sw[12] = 0;
        sw[3:2] = 2'b00;

        check_led(17);

        // Test 4: Adder X+A = 29
        sw[12] = 1;
        sw[1:0] = 2'b00;

        check_led(29);

        // Test 5: Subtractor X-B = 12
        sw[1:0] = 2'b01;

        check_led(12);

        // Test 6: Invalid unit index
        sw[1:0] = 2'b00;
        sw[15:14] = 2'b01;

        check_led(0);

        sw[15:14] = 2'b00;

        // ======================================
        // Step 3: Calculate Y and Z
        // ======================================

        press_button();

        // Test 7: Y = 29
        sw[12] = 0;
        sw[3:2] = 2'b01;

        check_led(29);

        // Test 8: Z = 12
        sw[3:2] = 2'b10;

        check_led(12);

        // Test 9: Multiplier B*Z = 60
        sw[12] = 1;
        sw[1:0] = 2'b10;

        check_led(60);

        // ======================================
        // Step 4: Calculate Q
        // ======================================

        press_button();

        // Test 10: Q = 60
        sw[12] = 0;
        sw[3:2] = 2'b11;

        check_led(60);

        // Test 11: Done = 1
        sw[13] = 1;

        check_led(1);

        // Test 12: Done remains high
        wait_cycles(20);

        check_led(1);

        // ======================================
        // Step 5: Return to IDLE
        // ======================================

        press_button();

        // Test 13: Done clears
        check_led(0);

        // Test 14: Q remains stored
        sw[13] = 0;
        sw[12] = 0;
        sw[3:2] = 2'b11;

        check_led(60);

        // ======================================
        // Test 15: Reset
        // ======================================

        reset = 1;
        wait_cycles(5);

        check_led(0);

        // Additional Done reset check
        sw[13] = 1;
        check_led(0);

        // ======================================
        // Final Results
        // ======================================

        $display(
            "-------------------------"
        );

        $display(
            "Passed: %0d", passed
        );

        $display(
            "Failed: %0d", failed
        );

        if (failed == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;

    end

endmodule
