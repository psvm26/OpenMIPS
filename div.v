`include "defines.v"

module div (
    input wire clk,
    input wire rst,

    input wire signed_div_i,        //是否有符号除法
    input wire [31:0] opdata1_i,    //被除数
    input wire [31:0] opdata2_i,    //除数
    input wire start_i,             //是否开始除法运算
    input wire annul_i,             //是否取消除法运算（为1取消）

    output reg [63:0] result_o,     //除法运算结果
    output reg ready_o              //除法运算是否结束
);

    wire [32:0] div_temp;
    reg [5:0] cnt;
    reg [64:0] dividend;
    reg [1:0] state;
    reg [31:0] divisor;
    reg [31:0] temp_op1;
    reg [31:0] temp_op2;

    //dividend的低32位保存的是被除数、中间结果，第k次迭代结束后dividend[k:0]
    //保存的就是当前得到的中间结果，dividend[31:k+1]保存的就是被除数中还没有
    //参与运算的数据，dividend高32位是每次迭代时的被减数，此处进行的是minuend-n
    //运算，结果保存在div_temp中
    assign div_temp = {1'b0, dividend[63:32]} - {1'b0, divisor};

    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            state <= `DivFree;
            ready_o <= `DivResultNotReady;
            result_o <= {`ZeroWord, `ZeroWord};
        end else begin
            case(state)
                //DivFree状态
                //（1）开始除法运算，但除数为0，进入DivByZero状态
                //（2）开始除法，且除数不为0，那么进入DivOn状态，初始化cnt为0，
                //    如果是有符号除法，且被除数或除数为负，那么对被除数或除数的最高位取补码。
                //    除数保存在divisor中，将被除数的最高位保存在dividend的第32位，进行第一次迭代
                //（3）没有开始除法运算，保持ready_o为DivResultNotReady
                `DivFree: begin
                    if(start_i == `DivStart && annul_i == 1'b0) begin
                        if(opdata2_i == `ZeroWord) begin
                            state <= `DivByZero;
                        end else begin
                            state <= `DivOn;
                            cnt <= 6'b000000;
                            if(signed_div_i == 1'b1 && opdata1_i[31] == 1'b1) begin
                                temp_op1 = ~opdata1_i + 1; //被除数取余码
                            end else begin
                                temp_op1 = opdata1_i;
                            end
                            if(signed_div_i == 1'b1 && opdata2_i[31] == 1'b1) begin
                                temp_op2 = ~opdata2_i + 1; //除数取余码
                            end else begin
                                temp_op2 = opdata2_i;
                            end
                            dividend <= {`ZeroWord, `ZeroWord};
                            dividend[32:1] <= temp_op1;
                            divisor <= temp_op2;
                        end
                    end else begin
                        ready_o <= `DivResultNotReady;
                        result_o <= {`ZeroWord, `ZeroWord};
                    end
                end
                `DivByZero: begin                           //DivByZero状态
                    dividend <= {`ZeroWord, `ZeroWord};
                    state <= `DivEnd;
                end
                //DivOn状态
                //（1）annul_i为1，处理器取消除法运算，DIV模块回到DivFree状态。
                //（2）annul_i为0，cnt不为32，表示试商法没有结束，若减法结果div_temp
                //    为负，此次迭代结果为0；若为正，此次迭代结果为1。dividend的最低位
                //    保存每次迭代的结果，同时保持DivOn的状态，cnt加1。
                //（3）annul_i为0，cnt为32，试商法结束，有符号除法且除数被除数一正一负，
                //    将试商法结果取补码（商、余数）。商保存在dividend的低32位，余数保存
                //    在高32位，进入DivEnd状态。
                `DivOn: begin
                    if(annul_i == 1'b0) begin
                        if(cnt != 6'b100000) begin
                            if(div_temp[32] == 1'b1) begin
                                //为1表示减法结果小于0，将dividend左移一位，
                                //这样就将被除数还没有参与运算的最高位加入到下次迭代的被减数中，
                                //同时将0追加到中间结果
                                dividend <= {dividend[63:0], 1'b0};
                            end else begin
                                //为0表示减法结果大于等于0，
                                //将减法结果与被除数还没有参与运算的最高位加入到下一次迭代的被减数中，
                                //同时将1追加到中间结果
                                dividend <= {div_temp[31:0], dividend[31:0], 1'b1};
                            end
                            cnt <= cnt + 1;
                        end else begin
                            //试商法结束
                            if((signed_div_i == 1'b1) &&
                               ((opdata1_i[31] ^ opdata2_i[31]) == 1'b1)) begin
                                dividend[31:0] <= (~dividend[31:0] + 1);
                               end 
                            if((signed_div_i == 1'b1) &&
                               ((opdata1_i[31] ^ dividend[64]) == 1'b1)) begin
                                dividend[64:33] <= (~dividend[64:33] + 1);
                               end
                            state <= `DivEnd;
                            cnt <= 6'b000000;
                        end
                    end else begin
                        state <= `DivFree;
                    end
                end
                //DivEnd状态
                //除法运算结束，result_o的宽度是64位，其高32位储存余数，低32位储存商，
                //设置输出信号ready_o为DivResultReady，表示除法结束，然后等待EX模块
                //送来DivStop信号，送来后DIV模块回到DivFree状态
                `DivEnd: begin
                    result_o <= {dividend[64:33], dividend[31:0]};
                    ready_o <= `DivResultReady;
                    if(start_i == `DivStop) begin
                        state <= `DivFree;
                        ready_o <= `DivResultNotReady;
                        result_o <= {`ZeroWord, `ZeroWord};
                    end
                end
            endcase
        end
    end
    
endmodule