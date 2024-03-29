`timescale 1ns/1ps
`include "defines.v"

module openmips_min_sopc_tb ();
    
    reg CLOCK_50;
    reg rst;

    //每隔10ns信号翻转??次，??个周期是20ns??50MHz
    initial begin
        CLOCK_50 = 1'b0;
        forever #10 CLOCK_50 = ~CLOCK_50;
    end

    initial begin
        rst = `RstEnable;
        #195 rst = `RstDisable;
        #3000 $stop;
    end

    openmips_min_sopc openmips_min_sopc0(
        .clk(CLOCK_50),
        .rst(rst)
    );


endmodule