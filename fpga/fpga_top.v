
module fpga_top (
    input  wire [15:0] sw,
    output reg  [15:0] led
);

    wire [15:0] add_result;
    wire [15:0] sub_result;
    wire [15:0] mul_result;

    // Temporary test inputs
    wire [15:0] a = 16'd12;
    wire [15:0] b = 16'd5;

    // Arithmetic modules
    adder #(.WIDTH(16)) u_adder (
        .a(a), .b(b), .result(add_result)
    );

    subtractor #(.WIDTH(16)) u_subtractor (
        .a(a), .b(b), .result(sub_result)
    );

    multiplier #(.WIDTH(16)) u_multiplier (
        .a(a), .b(b), .result(mul_result)
    );

    // Select output using switches
    always @(*) begin
        case (sw[1:0])
            2'b00: led = add_result;
            2'b01: led = sub_result;
            2'b10: led = mul_result;
            default: led = 16'd0;
        endcase
    end

endmodule
