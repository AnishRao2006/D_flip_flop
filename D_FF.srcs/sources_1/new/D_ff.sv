`timescale 1ns / 1ps

module DFF
    (
    //system inputs
    input logic clk,
    input logic reset,
    //input data
    input logic d,
    //output data
    output logic q,
    output logic q_bar
    );
    
always_ff @(posedge clk or posedge reset) begin
if(reset) begin 
{q,q_bar} <= {1'b0,1'b1};
end 
else begin
if(d) begin
{q,q_bar} <= {1'b1,1'b0};
end
else begin
{q,q_bar} <= {1'b0,1'b1};
end
end   
end 
    
endmodule : DFF
