
`timescale 1ns / 1ps

module fpga_top (
    input  wire        clk,
    input  wire        reset,
    input  wire        btn,
    input  wire [15:0] sw,
    output reg  [15:0] led
);

    // Fixed input values for demonstration
    wire [15:0] a = 16'd12;
    wire [15:0] b = 16'd5;

    // Arithmetic results
    wire [15:0] add_result;
    wire [15:0] sub_result;
    wire [15:0] mul_result;

    adder #(.WIDTH(16)) u_adder (
        .a(a),
        .b(b),
        .result(add_result)
    );

    subtractor #(.WIDTH(16)) u_subtractor (
        .a(a),
        .b(b),
        .result(sub_result)
    );

    multiplier #(.WIDTH(16)) u_multiplier (
        .a(a),
        .b(b),
        .result(mul_result)
    );

    // Button control: one step pulse per press
    wire step;

    button_step #(
        .DEBOUNCE_CYCLES(1000000)
    ) u_button_step (
        .clk(clk),
        .reset(reset),
        .btn(btn),
        .step(step)
    );

    // Select an arithmetic result using switches
    reg [15:0] selected_result;

    always @(*) begin
        case (sw[1:0])
            2'b00: selected_result = add_result;
            2'b01: selected_result = sub_result;
            2'b10: selected_result = mul_result;
            default: selected_result = 16'd0;
        endcase
    end

    // Update LEDs only when button generates a step
    always @(posedge clk) begin
        if (reset)
            led <= 16'd0;
        else if (step)
            led <= selected_result;
    end

endmodule
