`timescale 1ns / 1ps

module vigenere_cipher(

    input clk,
    input rst,
    input start,
    input wire [2047:0] shift_key,
    input wire [2047:0] data_in,  // ik its humongoussss
    output reg done,
    output reg [2047:0] data_out // 8 x 256 

);

integer j;

reg [8:0] key_length;
reg [6:0] mem_data [0:255];
reg [2:0] state;
reg [5:0] key_num [0:255];
reg [8:0] key_length_two;

reg [5:0] expanded_key [0:255];
reg [8:0] key_length_three;

localparam IDLE = 0;
localparam OPERATE_KEY = 1;
localparam OPERATE_TEXT = 2;
localparam DONE = 3;

integer i;
always @* begin
                
    key_length_two = 9'd0;
    key_length_three = key_length;
    
    for (i = 0; i < 256; i = i + 1) begin
        expanded_key[i] = key_num[key_length_two];
        
        if (key_length > 0 && key_length_two == (key_length_three - 9'd1)) begin
            key_length_two = 9'd0;
        end
        else begin
            key_length_two = key_length_two + 9'd1;
        end
        
    end
end

reg [8:0] key_length_num;

integer m;
always @* begin
       
    key_length_num = 9'd256;   
    
    for (m = 255; m >= 0; m = m - 1) begin
        if(shift_key[(m*8) +: 8] == 8'd0) begin
            key_length_num = m;
        end
    end
end

wire [5:0] inprocess_key_num [0:255];

genvar k;
generate
    for (k = 0; k < 256; k = k + 1) begin : KEY_CALCULATION
        assign inprocess_key_num[k] = (shift_key[(k*8) +: 8] == 8'd0) ? 
                                      (6'd0) : 
                                      (shift_key[(k*8) +: 8] <= 8'd90) ? 
                                      (shift_key[(k*8) +: 8] - 8'd65) : 
                                      (shift_key[(k*8) +: 8] - 8'd97);
    end
endgenerate

wire [7:0] data_buffer [0:255];

genvar l;
generate 
    for (l = 0; l < 256; l = l + 1) begin : MAIN_CIPHER_CALCULATION
        wire [7:0] current_data = data_in[(l*8) +: 8];
        wire [8:0] raw_num;
        wire [7:0] offset;
        assign offset = (current_data <= 8'd90) ? 8'd65 : 8'd97;
        assign raw_num = (current_data - offset) + expanded_key[l];
        assign data_buffer[l] = (current_data == 8'd0) ? 8'd0 : 
                                (raw_num > 9'd25) ? (raw_num - 9'd26 + offset) : 
                                (raw_num + offset); 
    end
endgenerate

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        done <= 1'b0;
        data_out <= 2048'd0;
        state <= IDLE;
    end
    else begin
        case(state)
        
            IDLE: begin
                done <= 1'd0;
                key_length <= 9'd256;
                if (start) begin
                    state <= OPERATE_KEY;
                end
            end
            
            OPERATE_KEY: begin
                for (j = 0; j < 256; j = j + 1) begin
                    key_num[j] <= inprocess_key_num[j];
                end
                
                key_length <= key_length_num;
                
                state <= OPERATE_TEXT;
            end
            
            OPERATE_TEXT: begin
                
                for (j = 0; j < 256; j = j + 1) begin
                    data_out[(j*8) +: 8] <= data_buffer[j];
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
