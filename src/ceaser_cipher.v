`timescale 1ns / 1ps

module ceaser_cipher(
    input clk,
    input rst,
    input start,
    input wire [6:0] shift,
    input wire [2047:0] data_in,  // ik its humongoussss
    output reg done,
    output reg [2047:0] data_out // 8 x 256 
);

/*

8-bit wide 256 values are input
cipher supports ASCII encoding so it should be values should be 7 bit wide,
but I wanted to write accelarator for byte-addressable memory
so I am assuming that MSB is 0 followed by ASCII enconding which is 7 bit
also the current implementation is only for Capital Letters [A-Z] will develop for full ASCII

*/

integer j;

reg [1:0] state;
wire [7:0] data_buffer [0:255];

genvar i;
generate
    for (i = 0; i < 255; i = i + 1) begin : SHIFTING_PARALLELY // everything is calculated parallelly in one clk cycle
        wire [7:0] current_data = data_in[(i*8) +: 8];
        wire [7:0] raw_shift = current_data + {1'd0, shift};
            
        assign data_buffer[i] = (current_data == 8'b0) ? (8'b0) : (raw_shift > 90) ? (raw_shift - 8'd26) : raw_shift;
        // checking current_data ensures that we are not operating on null data 
        
    end 
endgenerate 

localparam IDLE = 0;
localparam OPERATE = 1;
localparam DONE = 2;

reg [6:0] mem_data [0:255];

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        done <= 1'b0;
        data_out <= 
        state <= IDLE;
    end
    else begin
        case(state)
        
            IDLE: begin
                done <= 1'd0;
                if (start) begin
                    state <= OPERATE;
                end
            end
            
            OPERATE: begin
                for (j = 0; j < 255; j = j + 1) begin
                    data_out[(j*8) +: 8] = data_buffer[j];
                end 
                state <= DONE;
            end
            
            DONE: begin
                done <= 1'b1;
                if (!start) begin 
                    state <= IDLE;
                end
            end
            
            default: state <= IDLE;
            
        endcase
    end
end

endmodule
