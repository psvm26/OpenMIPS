`include "defines.v"
module openmips (
    input wire clk,
    input wire rst,
    input wire [`InstBus] rom_data_i,    //从指令存储器取到的指令
    output wire [`InstAddrBus] rom_addr_o,   //输出到指令存储器的地址
    output wire rom_ce_o                //指令存储器使能信号
);
    
    //IF/ID to ID
    wire [`InstAddrBus] pc;
    wire [`InstAddrBus] id_pc_i;
    wire [`InstBus] id_inst_i;

    //ID to ID/EX
    wire [`AluOpBus] id_aluop_o;
    wire [`AluSelBus] id_alusel_o;
    wire [`RegBus] id_reg1_o;
    wire [`RegBus] id_reg2_o;
    wire id_wreg_o;
    wire [`RegAddrBus] id_wd_o;

    //ID/EX to EX
    wire [`AluOpBus] ex_aluop_i;
    wire [`AluSelBus] ex_alusel_i;
    wire [`RegBus] ex_reg1_i;
    wire [`RegBus] ex_reg2_i;
    wire ex_wreg_i;
    wire [`RegAddrBus] ex_wd_i;

    //EX to EX/MEM
    wire ex_wreg_o;
    wire [`RegAddrBus] ex_wd_o;
    wire [`RegBus] ex_wdata_o;
    wire [`RegBus] ex_hi_o;
    wire [`RegBus] ex_lo_o;
    wire ex_whilo_o;

    //EX/MEM to MEM
    wire mem_wreg_i;
    wire [`RegAddrBus] mem_wd_i;
    wire [`RegBus] mem_wdata_i;    
    wire [`RegBus] mem_hi_i;
    wire [`RegBus] mem_lo_i;
    wire mem_whilo_i;

    //MEM to MEM/WB
    wire mem_wreg_o;
    wire [`RegAddrBus] mem_wd_o;
    wire [`RegBus] mem_wdata_o;   
    wire [`RegBus] mem_hi_o;
    wire [`RegBus] mem_lo_o;
    wire mem_whilo_o; 

    //MEM/WB to WB 
    wire wb_wreg_i;
    wire [`RegAddrBus] wb_wd_i;
    wire [`RegBus] wb_wdata_i;
    wire [`RegBus] wb_hi_i;
    wire [`RegBus] wb_lo_i;
    wire ex_whilo_i;

    //ID to Regfile
    wire reg1_read;
    wire reg2_read;
    wire [`RegBus] reg1_data;
    wire [`RegBus] reg2_data;
    wire [`RegAddrBus] reg1_addr;
    wire [`RegAddrBus] reg2_addr;

    //EX to hilo
    wire [`RegBus] hi;
    wire [`RegBus] lo;

    //连接执行阶段与ex_reg模块
    wire[`DoubleRegBus] hilo_temp_o;
	wire[1:0] cnt_o;
	
	wire[`DoubleRegBus] hilo_temp_i;
	wire[1:0] cnt_i;

    //div
    wire [`DoubleRegBus] div_result;
    wire div_ready;
    wire [`RegBus] div_opdata1;
    wire [`RegBus] div_opdata2;
    wire div_start;
    wire div_annul;
    wire signed_div;

    //暂停
    wire [5:0] stall;
    wire stallreq_from_id;
    wire stallreq_from_ex;

    //pc_reg
    pc_reg pc_reg0(
        .clk(clk),              .rst(rst), 
        .stall(stall),          .pc(pc),    
        .ce(rom_ce_o)
    );

    assign rom_addr_o = pc;

    //IF/ID
    if_id if_id0(
        .clk(clk),  .rst(rst),  .if_pc(pc),
        .stall(stall),
        .if_inst(rom_data_i),   .id_pc(id_pc_i),
        .id_inst(id_inst_i)
    );

    //ID
    id id0(
        .rst(rst),  .pc_i(id_pc_i), .inst_i(id_inst_i),

        //来自regfile的输入
        .reg1_data_i(reg1_data),    .reg2_data_i(reg2_data),

        //来自执行阶段EX的输入
        .ex_wreg_i(ex_wreg_o),      .ex_wdata_i(ex_wdata_o),
        .ex_wd_i(ex_wd_o),

        //来自访存阶段MEM的输入
        .mem_wreg_i(mem_wreg_o),      .mem_wdata_i(mem_wdata_o),
        .mem_wd_i(mem_wd_o),

        //送到regfile的信息
        .reg1_read_o(reg1_read),    .reg2_read_o(reg2_read),
        .reg1_addr_o(reg1_addr),    .reg2_addr_o(reg2_addr),

        //送到ID/EX模块的信息
        .aluop_o(id_aluop_o),   .alusel_o(id_alusel_o),
        .reg1_o(id_reg1_o),     .reg2_o(id_reg2_o),
        .wd_o(id_wd_o),         .wreg_o(id_wreg_o),
        .stallreq(stallreq_from_id)
    );

    //Regfile
    regfile regfile1(
        .clk(clk),          .rst(rst),
        .we(wb_wreg_i),     .waddr(wb_wd_i),
        .wdata(wb_wdata_i),  .re1(reg1_read),
        .raddr1(reg1_addr), .rdata1(reg1_data),
        .re2(reg2_read),    .raddr2(reg2_addr),
        .rdata2(reg2_data)
    );

    //ID/EX
    id_ex id_ex0(
        .clk(clk),              .rst(rst),
        .stall(stall),

        //从ID传过来的信息
        .id_aluop(id_aluop_o),  .id_alusel(id_alusel_o),
        .id_reg1(id_reg1_o),    .id_reg2(id_reg2_o),
        .id_wd(id_wd_o),         .id_wreg(id_wreg_o),

        //送到EX的信息
        .ex_aluop(ex_aluop_i),  .ex_alusel(ex_alusel_i),
        .ex_reg1(ex_reg1_i),    .ex_reg2(ex_reg2_i),
        .ex_wd(ex_wd_i),         .ex_wreg(ex_wreg_i)
    );

    //EX
    ex ex0(
        .rst(rst),

        //从ID/EX传过来的信息
        .aluop_i(ex_aluop_i),   .alusel_i(ex_alusel_i),
        .reg1_i(ex_reg1_i),     .reg2_i(ex_reg2_i),
        .wd_i(ex_wd_i),         .wreg_i(ex_wreg_i),
        .hi_i(hi),              .lo_i(lo),
        .wb_hi_i(wb_hi_i),      .wb_lo_i(wb_lo_i),
        .wb_whilo_i(wb_whilo_i),.mem_hi_i(mem_hi_o),
        .mem_lo_i(mem_lo_o),    .mem_whilo_i(mem_whilo_o),
        .hilo_temp_i(hilo_temp_i), .cnt_i(cnt_i),
        .div_result_i(div_result), .div_ready_i(div_ready),

        //输出到EX/MEM的信息
        .wd_o(ex_wd_o),         .wreg_o(ex_wreg_o),
        .wdata_o(ex_wdata_o),   .hi_o(ex_hi_o),
        .lo_o(ex_lo_o),         .whilo_o(ex_whilo_o),
        .stallreq(stallreq_from_ex),
        .hilo_temp_o(hilo_temp_o),
        .cnt_o(cnt_o),
        .div_opdata1_o(div_opdata1),
		.div_opdata2_o(div_opdata2),
		.div_start_o(div_start),
		.signed_div_o(signed_div)
    );

    //EX/MEM
    ex_mem ex_mem0(
        .clk(clk),              .rst(rst),
        .stall(stall),

        //来自EX的信息
        .ex_wd(ex_wd_o),        .ex_wreg(ex_wreg_o),
        .ex_wdata(ex_wdata_o),  .ex_hi(ex_hi_o),
        .ex_lo(ex_lo_o),        .ex_whilo(ex_whilo_o),
        .hilo_i(hilo_temp_o),   .cnt_i(cnt_o),

        //送到MEM的信息
        .mem_wd(mem_wd_i),      .mem_wreg(mem_wreg_i),
        .mem_wdata(mem_wdata_i),.mem_hi(mem_hi_i),
        .mem_lo(mem_lo_i),      .mem_whilo(mem_whilo_i),
        .hilo_o(hilo_temp_i),   .cnt_o(cnt_i)
    );

    //MEM
    mem mem0(
        .rst(rst),

        //来自EX/MEM的信息
        .wd_i(mem_wd_i),        .wreg_i(mem_wreg_i),
        .wdata_i(mem_wdata_i),  .hi_i(mem_hi_i),
        .lo_i(mem_lo_i),        .whilo_i(mem_whilo_i),

        //送到MEM/WB的信息
        .wd_o(mem_wd_o),        .wreg_o(mem_wreg_o),
        .wdata_o(mem_wdata_o),  .hi_o(mem_hi_o),
        .lo_o(mem_lo_o),        .whilo_o(mem_whilo_o)
    );

    //MEM/WB
    mem_wb mem_wb0(
        .clk(clk),              .rst(rst),
        .stall(stall),

        //来自MEM的信息
        .mem_wd(mem_wd_o),      .mem_wreg(mem_wreg_o),
        .mem_wdata(mem_wdata_o),.mem_hi(mem_hi_o),
        .mem_lo(mem_lo_o),      .mem_whilo(mem_whilo_o),

        //送到WB的信息
        .wb_wd(wb_wd_i),        .wb_wreg(wb_wreg_i),
        .wb_wdata(wb_wdata_i),  .wb_hi(wb_hi_i),
        .wb_lo(wb_lo_i),        .wb_whilo(wb_whilo_i)
    );

    //hilo
    hilo_reg hilo_reg0(
        .clk(clk),              .rst(rst),

        //写端口
        .we(wb_whilo_i),        .hi_i(wb_hi_i),
        .lo_i(wb_lo_i),

        //读端口1
        .hi_o(hi),              .lo_o(lo)
    );

    //ctrl
    ctrl ctrl0(
        .rst(rst),
        .stallreq_from_id(stallreq_from_id),
        .stallreq_from_ex(stallreq_from_ex),
        .stall(stall)
    );

    //div
    div div0(
		.clk(clk),
		.rst(rst),
	
		.signed_div_i(signed_div),
		.opdata1_i(div_opdata1),
		.opdata2_i(div_opdata2),
		.start_i(div_start),
		.annul_i(1'b0),
	
		.result_o(div_result),
		.ready_o(div_ready)
	);

endmodule