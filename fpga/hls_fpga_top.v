
`timescale 1ns / 1ps

module hls_fpga_top #(
    parameter integer DEBOUNCE_CYCLES = 1000000
)(
    input wire clk,
    input wire reset,
    input wire btn,
    input wire [15:0] sw,
    output wire [15:0] led
);

    // ==========================================
    // 1. FPGA Input Switches
    // ==========================================

    wire [15:0] A;
    wire [15:0] B;

    // SW7-SW4: A
    // SW11-SW8: B
    assign A = {12'b0, sw[7:4]};
    assign B = {12'b0, sw[11:8]};


    // ==========================================
    // 2. Button Step Controller
    // ==========================================

    wire step;

    button_step #(
        .DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)
    ) u_button_step (
        .clk(clk),
        .reset(reset),
        .btn(btn),
        .step(step)
    );


    // ==========================================
    // 3. HLS Signals
    // ==========================================

    wire done;

    wire [15:0] out_X;
    wire [15:0] out_Y;
    wire [15:0] out_Z;
    wire [15:0] out_Q;

    wire [15:0] observe_data;

    wire [1:0] observe_type;
    wire [7:0] observe_index;

    assign observe_type = sw[1:0];

    // SW15-SW14 select functional unit index
    assign observe_index = {6'b0, sw[15:14]};


    // ==========================================
    // 4. Generated HLS Circuit
    // ==========================================

    generated_step_circuit u_hls (
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


    // ==========================================
    // 5. Variable Result Selection
    // ==========================================

    reg [15:0] variable_result;

    always @(*) begin
        case (sw[3:2])
            2'b00: variable_result = out_X;
            2'b01: variable_result = out_Y;
            2'b10: variable_result = out_Z;
            2'b11: variable_result = out_Q;
            default: variable_result = 16'd0;
        endcase
    end


    // ==========================================
    // 6. LED Display Modes
    // ==========================================

    // SW12 = 0: Variable result
    // SW12 = 1: Functional unit observation
    // SW13 = 1: Done status (highest priority)

    reg [15:0] led_value;

    always @(*) begin

        if (sw[13]) begin

            // Done status on LED0
            led_value = {15'd0, done};

        end
        else if (sw[12]) begin

            // Observe selected arithmetic unit
            led_value = observe_data;

        end
        else begin

            // Display X, Y, Z or Q
            led_value = variable_result;

        end

    end

    assign led = led_value;

endmodule
