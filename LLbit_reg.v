`include "defines.v"
module LLbit_reg (
    input wire clk,
    input wire rst,

    //异常是否发生，为1表示发生，为0表示没有异常
    input wire flush,

    //写操作
    input wire LLbit_i,
    input wire we,

    //LLbit寄存器的值
    output reg LLbit_o
);

always @(posedge clk) begin
    if(rst == `RstEnable) begin
        LLbit_o <= 1'b0;
    end else if((flush == 1'b1)) begin
        LLbit_o <= 1'b0;
    end else if(we == `WriteEnable) begin
        LLbit_o <= LLbit_i;
    end
end
    
endmodule