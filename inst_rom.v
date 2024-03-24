`include "defines.v"
module inst_rom (
    input wire ce,
    input wire [`InstAddrBus] addr,
    output reg [`InstBus] inst
);
    //指令存储器
    reg [`InstBus] inst_mem[0: `InstMemNum - 1];
    //使用文件inst_rom.data初始化指令存储器
    initial $readmemh("D:/cs/cpu/OpenMIPS/inst_rom/inst_rom9_3.data", inst_mem);

    //当复位信号无效时，依据输入的地址，给出储存器rom中对应的元素
    always @(*) begin
        if(ce == `ChipDisable) begin
            inst <= `ZeroWord;
        end else begin
            inst <= inst_mem[addr[`InstMemNumLog2 + 1: 2]];
        end
    end

endmodule