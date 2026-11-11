
`timescale 1ns / 1ps

module generated_step_circuit (
    input wire clk,
    input wire reset,
    input wire step,
    input wire [15:0] A,
    input wire [15:0] B,
    output reg done,
    output wire [15:0] out_X,
    output wire [15:0] out_Y,
    output wire [15:0] out_Z,
    output wire [15:0] out_Q,
    input wire [7:0] observe_index,
    input wire [1:0] observe_type,
    output reg [15:0] observe_data
);

    reg [2:0] state;

    localparam IDLE    = 3'd0;
    localparam CYCLE_1 = 3'd1;
    localparam CYCLE_2 = 3'd2;
    localparam CYCLE_3 = 3'd3;
    localparam DONE    = 3'd4;

    reg [15:0] reg_X;
    reg [15:0] reg_Y;
    reg [15:0] reg_Z;
    reg [15:0] reg_Q;

    reg [15:0] add_a, add_b;
    reg [15:0] sub_a, sub_b;
    reg [15:0] mul_a, mul_b;

    wire [15:0] add_result;
    wire [15:0] sub_result;
    wire [15:0] mul_result;

    adder #(.WIDTH(16)) u_adder (
        .a(add_a),
        .b(add_b),
        .result(add_result)
    );

    subtractor #(.WIDTH(16)) u_subtractor (
        .a(sub_a),
        .b(sub_b),
        .result(sub_result)
    );

    multiplier #(.WIDTH(16)) u_multiplier (
        .a(mul_a),
        .b(mul_b),
        .result(mul_result)
    );

    // Datapath input selection
    always @(*) begin
        add_a = 0;
        add_b = 0;
        sub_a = 0;
        sub_b = 0;
        mul_a = 0;
        mul_b = 0;

        case (state)
            CYCLE_1: begin
                add_a = A;
                add_b = B;
            end

            CYCLE_2: begin
                add_a = reg_X;
                add_b = A;
                sub_a = reg_X;
                sub_b = B;
            end

            CYCLE_3: begin
                mul_a = B;
                mul_b = reg_Z;
            end

            default: begin end
        endcase
    end

    // FSM: advance only when step = 1
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            done  <= 0;
            reg_X <= 0;
            reg_Y <= 0;
            reg_Z <= 0;
            reg_Q <= 0;
        end
        else if (step) begin
            case (state)
                IDLE: begin
                    done <= 0;
                    state <= CYCLE_1;
                end

                CYCLE_1: begin
                    reg_X <= add_result;
                    state <= CYCLE_2;
                end

                CYCLE_2: begin
                    reg_Y <= add_result;
                    reg_Z <= sub_result;
                    state <= CYCLE_3;
                end

                CYCLE_3: begin
                    reg_Q <= mul_result;
                    done <= 1;
                    state <= DONE;
                end

                DONE: begin
                    done <= 0;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

    assign out_X = reg_X;
    assign out_Y = reg_Y;
    assign out_Z = reg_Z;
    assign out_Q = reg_Q;

    // Select arithmetic unit for observation
    always @(*) begin
        case (observe_type)
            2'b00: observe_data = add_result;
            2'b01: observe_data = sub_result;
            2'b10: observe_data = mul_result;
            default: observe_data = 16'd0;
        endcase
    end

endmodule
