`include "defines.v"
module pc_reg (
    input wire clk,
    input wire rst,
    input wire [5:0] stall,         //来自控制模块CTRL
    //来自译码阶段ID模块的信息

    input wire branch_flag_i,       //是否发生转移
    input wire [`RegBus] branch_target_address_i,//转移到的目标地址

    output reg [`InstAddrBus] pc,   //要读取的指令地址
    output reg ce                    //指令存储器使能信号
);
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            ce <= `ChipDisable;     //复位时禁用储存器
        end else begin
            ce <= `ChipEnable;      //复位结束储存器使能
        end
    end 

    always @(posedge clk) begin
        if(ce == `ChipDisable) begin
            pc <= 32'h0000_0000;
        end else if(stall[0] == `NoStop) begin  //当stall为NoStop时pc加4，否则pc不变
            if(branch_flag_i == `Branch) begin
                pc <= branch_target_address_i;
            end else begin
            pc <= pc + 4;           //储存器使能时每周期pc加4
            end
        end
    end
endmodule