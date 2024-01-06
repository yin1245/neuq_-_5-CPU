`timescale 1ns / 1ps

module openmips(
	input wire clk,//ʱ���ź�
	input wire rst,//��λ�ź�
	
	input wire[31:0] rom_data_i,//��ָ��洢��ȡ�õ�ָ��
	output wire[31:0] rom_addr_o,//�����ָ��洢���ĵ�ַ
	output wire rom_ce_o,//ָ��洢��ʹ���ź�
	
  //�������ݴ洢��data_ram
	input wire[31:0] ram_data_i,//�����ݴ洢����ȡ������
	output wire[31:0] ram_addr_o,//Ҫ�ô�����ݴ洢����ַ
	output wire[31:0] ram_data_o,//Ҫд�����ݴ洢��������
	output wire ram_we_o,//�Ƿ��Ƕ����ݴ洢����д����
	output wire[3:0] ram_sel_o,//�ֽ�ѡ���ź�
	output wire[3:0] ram_ce_o//���ݴ洢��ʹ���ź�
	
);

	wire[31:0] pc;
	wire[31:0] id_pc_i;  // ����׶εĳ��������
	wire[31:0] id_inst_i;// ����׶ε�ָ��
	
	//��������׶�IDģ��������ID/EXģ�������
	wire[7:0] id_aluop_o;
	wire[2:0] id_alusel_o;
	wire[31:0] id_reg1_o;
	wire[31:0] id_reg2_o;
	wire id_wreg_o;
	wire[4:0] id_w_addr_o;
	wire id_is_in_delayslot_o;
    wire[31:0] id_link_address_o;	
    wire[31:0] id_inst_o;
	
	//����ID/EXģ��������ִ�н׶�EXģ�������
	wire[7:0] ex_aluop_i;
	wire[2:0] ex_alusel_i;
	wire[31:0] ex_reg1_i;
	wire[31:0] ex_reg2_i;
	wire ex_wreg_i;
	wire[4:0] ex_wd_i;
	wire ex_is_in_delayslot_i;	
    wire[31:0] ex_link_address_i;	
    wire[31:0] ex_inst_i;
	
	//����ִ�н׶�EXģ��������EX/MEMģ�������
	wire ex_wreg_o;
	wire[4:0] ex_w_addr_o;
	wire[31:0] ex_wdata_o;
	wire[31:0] ex_hi_o;
	wire[31:0] ex_lo_o;
	wire ex_whilo_o;
	wire[7:0] ex_aluop_o;
	wire[31:0] ex_mem_addr_o;
	wire[31:0] ex_reg1_o;
	wire[31:0] ex_reg2_o;	

	//����EX/MEMģ��������ô�׶�MEMģ�������
	wire mem_wreg_i;
	wire[4:0] mem_wd_i;
	wire[31:0] mem_wdata_i;
	wire[31:0] mem_hi_i;
	wire[31:0] mem_lo_i;
	wire mem_whilo_i;		
	wire[7:0] mem_aluop_i;
	wire[31:0] mem_mem_addr_i;
	wire[31:0] mem_reg1_i;
	wire[31:0] mem_reg2_i;		

	//���ӷô�׶�MEMģ��������MEM/WBģ�������
	wire mem_wreg_o;
	wire[4:0] mem_w_addr_o;
	wire[31:0] mem_wdata_o;
	wire[31:0] mem_hi_o;
	wire[31:0] mem_lo_o;
	wire mem_whilo_o;	
	wire mem_LLbit_value_o;
	wire mem_LLbit_we_o;		
	
	//����MEM/WBģ���������д�׶ε�����	
	wire wb_wreg_i;
	wire[4:0] wb_wd_i;
	wire[31:0] wb_wdata_i;
	wire[31:0] wb_hi_i;
	wire[31:0] wb_lo_i;
	wire wb_whilo_i;	
	wire wb_LLbit_value_i;
	wire wb_LLbit_we_i;	
	
	//��������׶�IDģ����ͨ�üĴ���Regfileģ��
    wire reg1_read;
    wire reg2_read;
    wire[31:0] reg1_data;
    wire[31:0] reg2_data;
    wire[4:0] reg1_addr;
    wire[4:0] reg2_addr;

	//����ִ�н׶���hiloģ����������ȡHI��LO�Ĵ���
	wire[31:0] 	hi;
	wire[31:0] lo;

  //����ִ�н׶���ex_regģ�飬���ڶ����ڵ�MADD��MADDU��MSUB��MSUBUָ��
	wire[63:0] hilo_temp_o;
	wire[1:0] cnt_o;
	
	wire[63:0] hilo_temp_i;
	wire[1:0] cnt_i;

	wire[63:0] div_result;
	wire div_ready;
	wire[31:0] div_opdata1;
	wire[31:0] div_opdata2;
	wire div_start;
	wire div_annul;
	wire signed_div;

	wire is_in_delayslot_i;
	wire is_in_delayslot_o;
	wire next_inst_in_delayslot_o;
	wire id_branch_flag_o;
	wire[31:0] branch_target_address;

	wire[5:0] stall;
	wire stallreq_from_id;	
	wire stallreq_from_ex;

	wire LLbit_o;
  
  //pc_reg����
	pc_reg pc_reg0(
		.clk(clk),
		.rst(rst),
		.stall(stall),
		.branch_flag_i(id_branch_flag_o),
		.branch_target_address_i(branch_target_address),		
		.pc(pc),
		.ce(rom_ce_o)	
			
	);
	
  assign rom_addr_o = pc;   //ȡָ

  //IF_IDģ������
	if_id if_id0(
		.clk(clk),
		.rst(rst),
		.stall(stall),
		.if_pc(pc),
		.if_inst(rom_data_i),
		.id_pc(id_pc_i),
		.id_inst(id_inst_i)      	
	);     // ȡָ->����
	
	//����׶�IDģ��
	id id0(
		.rst(rst),
		.pc_i(id_pc_i),
		.inst_i(id_inst_i),
  	    .ex_aluop_i(ex_aluop_o),
		.reg1_data_i(reg1_data),
		.reg2_data_i(reg2_data),
	  //����ִ�н׶ε�ָ��Ҫд���Ŀ�ļĴ�����Ϣ
		.ex_wreg_i(ex_wreg_o),
		.ex_wdata_i(ex_wdata_o),
		.ex_wd_i(ex_w_addr_o),
	  //���ڷô�׶ε�ָ��Ҫд���Ŀ�ļĴ�����Ϣ
		.mem_wreg_i(mem_wreg_o),
		.mem_wdata_i(mem_wdata_o),
		.mem_wd_i(mem_w_addr_o),
	    .is_in_delayslot_i(is_in_delayslot_i),
		//�͵�regfile����Ϣ
		.reg1_read_o(reg1_read),
		.reg2_read_o(reg2_read), 	  
		.reg1_addr_o(reg1_addr),
		.reg2_addr_o(reg2_addr), 
		//�͵�ID_EXģ�����Ϣ
		.aluop_o(id_aluop_o),
		.alusel_o(id_alusel_o),
		.reg1_o(id_reg1_o),
		.reg2_o(id_reg2_o),
		.w_addr_o(id_w_addr_o),
		.wreg_o(id_wreg_o),
		.inst_o(id_inst_o),
	 	.next_inst_in_delayslot_o(next_inst_in_delayslot_o),	
		.branch_flag_o(id_branch_flag_o),
		.branch_target_address_o(branch_target_address),       
		.link_addr_o(id_link_address_o),
		.is_in_delayslot_o(id_is_in_delayslot_o),
		.stallreq(stallreq_from_id)		
	);

  //ͨ�üĴ���Regfile����
	regfile regfile1(
		.clk (clk),
		.rst (rst),
		.we	(wb_wreg_i),
		.waddr (wb_wd_i),
		.wdata (wb_wdata_i),
		.re1 (reg1_read),
		.raddr1 (reg1_addr),
		.rdata1 (reg1_data),
		.re2 (reg2_read),
		.raddr2 (reg2_addr),
		.rdata2 (reg2_data)
	);

	//ID_EXģ������
	id_ex id_ex0(
		.clk(clk),
		.rst(rst),
		
		.stall(stall),
		
		//������׶�IDģ�鴫�ݵ���Ϣ
		.id_aluop(id_aluop_o),
		.id_alusel(id_alusel_o),
		.id_reg1(id_reg1_o),
		.id_reg2(id_reg2_o),
		.id_wd(id_w_addr_o),
		.id_wreg(id_wreg_o),
		.id_link_address(id_link_address_o),
		.id_is_in_delayslot(id_is_in_delayslot_o),
		.next_inst_in_delayslot_i(next_inst_in_delayslot_o),		
		.id_inst(id_inst_o),		
	
		//���ݵ�ִ�н׶�EXģ�����Ϣ
		.ex_aluop(ex_aluop_i),
		.ex_alusel(ex_alusel_i),
		.ex_reg1(ex_reg1_i),
		.ex_reg2(ex_reg2_i),
		.ex_wd(ex_wd_i),
		.ex_wreg(ex_wreg_i),
		.ex_link_address(ex_link_address_i),
  	    .ex_is_in_delayslot(ex_is_in_delayslot_i),
		.is_in_delayslot_o(is_in_delayslot_i),
		.ex_inst(ex_inst_i)		
	);		// ����->ִ��
	
	//EXģ��
	ex ex0(
		.rst(rst),
	
		//�͵�ִ�н׶�EXģ�����Ϣ
		.aluop_i(ex_aluop_i),
		.alusel_i(ex_alusel_i),
		.reg1_i(ex_reg1_i),
		.reg2_i(ex_reg2_i),
		.wd_i(ex_wd_i),
		.wreg_i(ex_wreg_i),
		.hi_i(hi),
		.lo_i(lo),
		.inst_i(ex_inst_i),

	    .wb_hi_i(wb_hi_i),
	    .wb_lo_i(wb_lo_i),
	    .wb_whilo_i(wb_whilo_i),
	    .mem_hi_i(mem_hi_o),
	    .mem_lo_i(mem_lo_o),
	    .mem_whilo_i(mem_whilo_o),

	    .hilo_temp_i(hilo_temp_i),
	    .cnt_i(cnt_i),

		.div_result_i(div_result),
		.div_ready_i(div_ready), 

	    .link_address_i(ex_link_address_i),
		.is_in_delayslot_i(ex_is_in_delayslot_i),	  
			  
	    //EXģ��������EX/MEMģ����Ϣ
		.w_addr_o(ex_w_addr_o),
		.wreg_o(ex_wreg_o),
		.wdata_o(ex_wdata_o),

		.hi_o(ex_hi_o),
		.lo_o(ex_lo_o),
		.whilo_o(ex_whilo_o),

		.hilo_temp_o(hilo_temp_o),
		.cnt_o(cnt_o),

		.div_opdata1_o(div_opdata1),
		.div_opdata2_o(div_opdata2),
		.div_start_o(div_start),
		.signed_div_o(signed_div),	

		.aluop_o(ex_aluop_o),
		.mem_addr_o(ex_mem_addr_o),
		.reg2_o(ex_reg2_o),
		
		.stallreq(stallreq_from_ex)     				
		
	);

  //EX_MEMģ��
  ex_mem ex_mem0(
		.clk(clk),
		.rst(rst),
	  
	    .stall(stall),
	  
		//����ִ�н׶�EXģ�����Ϣ	
		.ex_wd(ex_w_addr_o),
		.ex_wreg(ex_wreg_o),
		.ex_wdata(ex_wdata_o),
		.ex_hi(ex_hi_o),
		.ex_lo(ex_lo_o),
		.ex_whilo(ex_whilo_o),		

  	    .ex_aluop(ex_aluop_o),
		.ex_mem_addr(ex_mem_addr_o),
		.ex_reg2(ex_reg2_o),			

		.hilo_i(hilo_temp_o),
		.cnt_i(cnt_o),	

		//�͵��ô�׶�MEMģ�����Ϣ
		.mem_wd(mem_wd_i),
		.mem_wreg(mem_wreg_i),
		.mem_wdata(mem_wdata_i),
		.mem_hi(mem_hi_i),
		.mem_lo(mem_lo_i),
		.mem_whilo(mem_whilo_i),

  	    .mem_aluop(mem_aluop_i),
		.mem_mem_addr(mem_mem_addr_i),
		.mem_reg2(mem_reg2_i),
				
		.hilo_o(hilo_temp_i),
		.cnt_o(cnt_i)
						       	
	); // ִ��->�ô�׶�
	
  //MEMģ������
	mem mem0(
		.rst(rst),
	
		//����EX/MEMģ�����Ϣ	
		.wd_i(mem_wd_i),
		.wreg_i(mem_wreg_i),
		.wdata_i(mem_wdata_i),
		.hi_i(mem_hi_i),
		.lo_i(mem_lo_i),
		.whilo_i(mem_whilo_i),		

  	    .aluop_i(mem_aluop_i),
		.mem_addr_i(mem_mem_addr_i),
		.reg2_i(mem_reg2_i),
	
		//����memory����Ϣ
		.mem_data_i(ram_data_i),

		//LLbit_i��LLbit�Ĵ�����ֵ
		.LLbit_i(LLbit_o),
		//����һ��������ֵ����д�׶ο���ҪдLLbit�����Ի�Ҫ��һ���ж�
		.wb_LLbit_we_i(wb_LLbit_we_i),
		.wb_LLbit_value_i(wb_LLbit_value_i),

		.LLbit_we_o(mem_LLbit_we_o),
		.LLbit_value_o(mem_LLbit_value_o),
	  
		//�͵�MEM/WBģ�����Ϣ
		.w_addr_o(mem_w_addr_o),
		.wreg_o(mem_wreg_o),
		.wdata_o(mem_wdata_o),
		.hi_o(mem_hi_o),
		.lo_o(mem_lo_o),
		.whilo_o(mem_whilo_o),
		
		//�͵�memory����Ϣ
		.mem_addr_o(ram_addr_o),
		.mem_we_o(ram_we_o),
		.mem_sel_o(ram_sel_o),
		.mem_data_o(ram_data_o),
		.mem_ce_o(ram_ce_o)		
	);  // �ô�׶�

  //MEM/WBģ��
	mem_wb mem_wb0(
		.clk(clk),
		.rst(rst),

        .stall(stall),

		//���Էô�׶�MEMģ�����Ϣ	
		.mem_wd(mem_w_addr_o),
		.mem_wreg(mem_wreg_o),
		.mem_wdata(mem_wdata_o),
		.mem_hi(mem_hi_o),
		.mem_lo(mem_lo_o),
		.mem_whilo(mem_whilo_o),		

		.mem_LLbit_we(mem_LLbit_we_o),
		.mem_LLbit_value(mem_LLbit_value_o),						
	
		//�͵���д�׶ε���Ϣ
		.wb_wd(wb_wd_i),
		.wb_wreg(wb_wreg_i),
		.wb_wdata(wb_wdata_i),
		.wb_hi(wb_hi_i),
		.wb_lo(wb_lo_i),
		.wb_whilo(wb_whilo_i),

		.wb_LLbit_we(wb_LLbit_we_i),
		.wb_LLbit_value(wb_LLbit_value_i)				
									       	
	); // �ô�->��д�׶�

	hilo_reg hilo_reg0(
		.clk(clk),
		.rst(rst),
	
		//д�˿�
		.we(wb_whilo_i),
		.hi_i(wb_hi_i),
		.lo_i(wb_lo_i),
	
		//���˿�1
		.hi_o(hi),
		.lo_o(lo)	
	); // hi,lo�Ĵ���,�ֱ����ڴ洢�˷�����ĸ�32λ�ͳ˷�����ĵ�32λ�Լ��洢��������������
	
	ctrl ctrl0(
		.rst(rst),
	    //��������׶ε���ͣ����
		.stallreq_from_id(stallreq_from_id),
  	    //����ִ�н׶ε���ͣ����
		.stallreq_from_ex(stallreq_from_ex),
        //������ˮ���Ƿ�Ӧ��ͣ��
		.stall(stall)       	
	);  // ʵ�ֽṹ��ص��߼�

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

	LLbit_reg LLbit_reg0(
		.clk(clk),
		.rst(rst),
	    .flush(1'b0),
	  
		//д�˿�
		.LLbit_i(wb_LLbit_value_i),
		.we(wb_LLbit_we_i),
	
		//���˿�1
		.LLbit_o(LLbit_o)
	
	);// ����ʵ��ԭ�Ӳ���,��ʹ��LL��SCָ��ʱ,��������ʹ��LLbit���ж�������ָ��֮���Ƿ�����������������ͬ���ڴ�λ�ý����޸�,�����,SC����ʧ��.
	
endmodule