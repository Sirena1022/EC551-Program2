
`timescale 1ns / 1ps

module testbench;

    parameter WIDTH = 16;

    reg  [WIDTH-1:0] a;
    reg  [WIDTH-1:0] b;

    wire [WIDTH-1:0] add_result;
    wire [WIDTH-1:0] sub_result;
    wire [WIDTH-1:0] mul_result;

    integer tests_passed = 0;
    integer tests_failed = 0;

    // Connect the three hardware modules
    adder #(.WIDTH(WIDTH)) u_adder (
        .a(a), .b(b), .result(add_result)
    );

    subtractor #(.WIDTH(WIDTH)) u_subtractor (
        .a(a), .b(b), .result(sub_result)
    );

    multiplier #(.WIDTH(WIDTH)) u_multiplier (
        .a(a), .b(b), .result(mul_result)
    );

    // Check all three results
    task check_results;
        input [WIDTH-1:0] expected_add;
        input [WIDTH-1:0] expected_sub;
        input [WIDTH-1:0] expected_mul;
        begin
            #10;

            if ((add_result === expected_add) &&
                (sub_result === expected_sub) &&
                (mul_result === expected_mul)) begin

                tests_passed = tests_passed + 1;
                $display("PASS: a=%0d b=%0d | add=%0d sub=%0d mul=%0d",
                         a, b, add_result, sub_result, mul_result);
            end
            else begin
                tests_failed = tests_failed + 1;
                $display("FAIL: a=%0d b=%0d | add=%0d sub=%0d mul=%0d",
                         a, b, add_result, sub_result, mul_result);
            end
        end
    endtask

    initial begin
        $display("EC551 Program 2 - Arithmetic Module Test");

        // Test 1
        a = 12; b = 5;
        check_results(17, 7, 60);

        // Test 2
        a = 20; b = 10;
        check_results(30, 10, 200);

        // Test 3
        a = 100; b = 2;
        check_results(102, 98, 200);

        // Test 4
        a = 255; b = 1;
        check_results(256, 254, 255);

        // Test 5
        a = 0; b = 0;
        check_results(0, 0, 0);

        $display("-----------------------------");
        $display("Passed: %0d", tests_passed);
        $display("Failed: %0d", tests_failed);

        if (tests_failed == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

endmodule

