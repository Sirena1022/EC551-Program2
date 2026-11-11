
`timescale 1ns / 1ps

module generated_step_tb;

    reg clk = 0;
    reg reset = 1;
    reg step = 0;

    reg [15:0] A = 12;
    reg [15:0] B = 5;

    reg [7:0] observe_index = 0;
    reg [1:0] observe_type = 0;

    wire done;
    wire [15:0] out_X;
    wire [15:0] out_Y;
    wire [15:0] out_Z;
    wire [15:0] out_Q;
    wire [15:0] observe_data;

    integer passed = 0;
    integer failed = 0;

    // 100 MHz clock
    always #5 clk = ~clk;

    generated_step_circuit uut (
        .clk(clk),
        .reset(reset),
        .step(step),
        .A(A),
        .B(B),
        .done(done),
        .out_X(out_X),
        .out_Y(out_Y),
        .out_Z(out_Z),
        .out_Q(out_Q),
        .observe_index(observe_index),
        .observe_type(observe_type),
        .observe_data(observe_data)
    );

    // Generate one step pulse
    task press_step;
        begin
            @(negedge clk);
            step = 1;
            @(negedge clk);
            step = 0;
            #1;
        end
    endtask

    // Verify all saved results
    task check_results;
        input [15:0] exp_X;
        input [15:0] exp_Y;
        input [15:0] exp_Z;
        input [15:0] exp_Q;
        input exp_done;
        begin
            if (out_X === exp_X &&
                out_Y === exp_Y &&
                out_Z === exp_Z &&
                out_Q === exp_Q &&
                done === exp_done) begin

                passed = passed + 1;
                $display("PASS: X=%0d Y=%0d Z=%0d Q=%0d Done=%b",
                         out_X, out_Y, out_Z, out_Q, done);
            end
            else begin
                failed = failed + 1;
                $display("FAIL: X=%0d Y=%0d Z=%0d Q=%0d Done=%b",
                         out_X, out_Y, out_Z, out_Q, done);
                $display("Expected: X=%0d Y=%0d Z=%0d Q=%0d Done=%b",
                         exp_X, exp_Y, exp_Z, exp_Q, exp_done);
            end
        end
    endtask

    initial begin
        $display("EC551 Generated Step Circuit Test");

        // Reset circuit
        repeat (3) @(negedge clk);
        reset = 0;
        #1;

        // Initial values
        check_results(0, 0, 0, 0, 0);

        // Step 1: Enter Cycle 1
        press_step();
        check_results(0, 0, 0, 0, 0);

        // Step 2: X = A + B = 17
        press_step();
        check_results(17, 0, 0, 0, 0);

        // Step 3:
        // Y = X + A = 29
        // Z = X - B = 12
        press_step();
        check_results(17, 29, 12, 0, 0);

        // Step 4: Q = B * Z = 60
        press_step();
        check_results(17, 29, 12, 60, 1);

        // Hold without step
        repeat (10) @(negedge clk);
        #1;
        check_results(17, 29, 12, 60, 1);

        // Step 5: Return to IDLE
        press_step();
        check_results(17, 29, 12, 60, 0);

        // Reset all registers
        @(negedge clk);
        reset = 1;
        @(negedge clk);
        #1;
        check_results(0, 0, 0, 0, 0);

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
