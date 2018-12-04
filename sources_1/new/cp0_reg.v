
`include "defines.v"

module cp0_reg(

	input wire clk,
	input wire rst,
	
	
	input wire we_i,
	input wire[4:0] waddr_i,
	input wire[4:0] raddr_i,
	input wire[`RegBus] data_i,
	
	input wire[31:0] excepttype_i,
	input wire[5:0] int_i,
	input wire[`RegBus] current_inst_addr_i,
	input wire is_in_delayslot_i,
	input wire[`RegBus] badvaddr_i,
	
	output reg[`RegBus] data_o,
	output reg[`RegBus] count_o,
	output reg[`RegBus] compare_o,
	output reg[`RegBus] status_o,
	output reg[`RegBus] cause_o,
	output reg[`RegBus] epc_o,
	output reg[`RegBus] config_o,
	output reg[`RegBus] ebase_o,
	output reg[`RegBus] badvaddr_o,
	
	output reg[`RegBus] entryhi_o,
	output reg[`RegBus] entrylo0_o,
	output reg[`RegBus] entrylo1_o,
	output reg[`RegBus] pagemask_o,
	output reg[`RegBus] index_o,
	output reg[`RegBus] random_o,
	output reg[`RegBus] context_o,
	
	output reg timer_int_o    
	
);

	always @ (posedge clk) begin
		if(rst == `RstEnable) begin
			count_o <= `ZeroWord;
			compare_o <= `ZeroWord;
			
			status_o <= 32'b00010000000000000000000000000000;
			cause_o <= `ZeroWord;
			epc_o <= `ZeroWord;
			
			// config_o <= 32'b00000000000000001000000000000000;
			//config_o <= 32'b  
			entryhi_o <= 32'bxxxxxxxxxxxxxxxxxxx000xxxxxxxxxx;//config_o[28]
			entrylo0_o <= 32'b00xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
			entrylo1_o <= 32'b00xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
			
			pagemask_o <= 32'b000xxxxxxxxxxxxxxxx0000000000000;
            index_o <= 32'b0;
            random_o <= 32'b0;
            context_o <= 32'b0
			
			
			ebase_o <= 32'b10000000000000000000000000000000;
            timer_int_o <= `InterruptNotAssert;
		end else begin
		    count_o <= count_o + 1 ;
		    cause_o[15:10] <= int_i;
		
			if(compare_o != `ZeroWord && count_o == compare_o) begin
				timer_int_o <= `InterruptAssert;
			end
					
			if(we_i == `WriteEnable) begin
				case (waddr_i) 
					`CP0_REG_COUNT:		begin
						count_o <= data_i;
					end
					`CP0_REG_COMPARE:	begin
						compare_o <= data_i;
						//count_o <= `ZeroWord;
                        timer_int_o <= `InterruptNotAssert;
					end
					`CP0_REG_STATUS:	begin
						status_o <= data_i;
					end
					`CP0_REG_EPC:	begin
						epc_o <= data_i;
					end
					`CP0_REG_CAUSE:	begin
						cause_o[9:8] <= data_i[9:8];
						cause_o[23] <= data_i[23];
						cause_o[22] <= data_i[22];
					end
					`CP0_REG_EBASE: begin
                        if (ebase_o[11] == 1'b0) begin
                            ebase_o[29:12] <= data_i[29:12];
                        end else begin
                            ebase_o[31:12] <= data_i[31:12];
                        end
                        ebase_o[11] <= data_i[11];           
                    end	
                    `CP0_REG_ENTRYHI: begin
                        entryhi_o <= data_i;
                    end
                    `CP0_REG_ENTRYLO0: begin
                        entrylo0_o[29:0] <= data_i[29:0];
                    end
                    `CP0_REG_ENTRYLO1: begin
                        entrylo1_o[29:0] <= data_i[29:0];
                    end
                    `CP0_REG_PAGEMASK: begin
                        pagemask_o[28:11] <= data_i[28:11];
                    end
                    `CP0_REG_INDEX: begin
                        index_o <= data_i;
                    end
                    `CP0_REG_RANDOM: begin
                        random_o <= data_i;
                    end
                    `CP0_REG_CONTEXT: begin
                        
                    end
				endcase  //case addr_i
			end

			case (excepttype_i)
				32'h00000001:		begin // interrupt
					if(is_in_delayslot_i == `InDelaySlot ) begin
						epc_o <= current_inst_addr_i - 4 ;
						cause_o[31] <= 1'b1;
					end else begin
					  epc_o <= current_inst_addr_i;
					  cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b00000;
					
				end
				32'h00000008:		begin // syscall
					if(status_o[1] == 1'b0) begin
						if(is_in_delayslot_i == `InDelaySlot ) begin
							epc_o <= current_inst_addr_i - 4 ;
							cause_o[31] <= 1'b1;
						end else begin
					  	epc_o <= current_inst_addr_i;
					  	cause_o[31] <= 1'b0;
						end
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01000;			
				end
				32'h0000000a:		begin // inst valid
					if(status_o[1] == 1'b0) begin
						if(is_in_delayslot_i == `InDelaySlot ) begin
							epc_o <= current_inst_addr_i - 4 ;
							cause_o[31] <= 1'b1;
						end else begin
					  	epc_o <= current_inst_addr_i;
					  	cause_o[31] <= 1'b0;
						end
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01010;					
				end
				32'h0000000d:		begin // trap
					if(status_o[1] == 1'b0) begin
						if(is_in_delayslot_i == `InDelaySlot ) begin
							epc_o <= current_inst_addr_i - 4 ;
							cause_o[31] <= 1'b1;
						end else begin
					  	epc_o <= current_inst_addr_i;
					  	cause_o[31] <= 1'b0;
						end
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01101;					
				end
				32'h0000000c:		begin // overflow
					if(status_o[1] == 1'b0) begin
						if(is_in_delayslot_i == `InDelaySlot ) begin
							epc_o <= current_inst_addr_i - 4 ;
							cause_o[31] <= 1'b1;
						end else begin
					  	epc_o <= current_inst_addr_i;
					  	cause_o[31] <= 1'b0;
						end
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01100;					
				end				
				32'h0000000e:   begin // eret
					status_o[1] <= 1'b0;
				end
				32'h0000000f: begin // break
				    if (status_o[1] == 1'b0) begin
				        if (is_in_delayslot_i == `InDelaySlot) begin
				            epc_o <= current_inst_addr_i - 4;
				            cause_o[31] <= 1'b1;
				        end else begin
				            epc_o <= current_inst_addr_i;
				            cause_o[31] <= 1'b0;
				        end
				        status_o[1] = 1'b1;
				        cause_o[6:2] <= 5'b01001;
				    end
				end
				32'h00000010: begin // instruction address error
				    if (status_o[1] == 1'b0) begin
				        if (is_in_delayslot_i == `InDelaySlot) begin
                            epc_o <= current_inst_addr_i - 4;
                            cause_o[31] <= 1'b1;
                        end else begin
                            epc_o <= current_inst_addr_i;
                            cause_o[31] <= 1'b0;
                        end
                        badvaddr_o <= current_inst_addr_i;
                        status_o[1] = 1'b1;
                        cause_o[6:2] <= 5'b00100;
				    end
				end
				32'h00000011: begin // load address error
				    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i == `InDelaySlot) begin
                            epc_o <= current_inst_addr_i - 4;
                            cause_o[31] <= 1'b1;
                        end else begin
                            epc_o <= current_inst_addr_i;
                            cause_o[31] <= 1'b0;
                        end
                        status_o[1] = 1'b1;
                        cause_o[6:2] <= 5'b00100;
                        badvaddr_o <= badvaddr_i;
                    end
				end
				32'h00000012: begin // save address error
				    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i == `InDelaySlot) begin
                            epc_o <= current_inst_addr_i - 4;
                            cause_o[31] <= 1'b1;
                        end else begin
                            epc_o <= current_inst_addr_i;
                            cause_o[31] <= 1'b0;
                        end
                        status_o[1] = 1'b1;
                        cause_o[6:2] <= 5'b00101;
                        badvaddr_o <= badvaddr_i;
                    end
				end
				default: begin
				end
			endcase			
			
		end    //if
	end      //always
			
	always @ (*) begin
		if(rst == `RstEnable) begin
			data_o <= `ZeroWord;
		end else begin
            case (raddr_i) 
                `CP0_REG_COUNT:		begin
                    data_o <= count_o ;
                end
                `CP0_REG_COMPARE:	begin
                    data_o <= compare_o ;
                end
                `CP0_REG_STATUS:	begin
                    data_o <= status_o ;
                end
                `CP0_REG_CAUSE:	begin
                    data_o <= cause_o ;
                end
                `CP0_REG_EPC:	begin
                    data_o <= epc_o ;
                end
                `CP0_REG_EBASE: begin
                    data_o <= ebase_o;
                end
                `CP0_REG_CONFIG:	begin
                    data_o <= config_o ;
                end
                `CP0_REG_BADVADDR: begin
                    data_o <= badvaddr_o;
                end
                `CP0_REG_ENTRYHI: begin
                    data_o <= entryhi_o;
                end
                `CP0_REG_ENTRYLO0: begin
                    data_o <= entrylo0_o;
                end
                `CP0_REG_ENTRYLO1: begin
                    data_o <= entrylo1_o;
                end
                `CP0_REG_PAGEMASK: begin
                    data_o <= pagemask_o;
                end
                `CP0_REG_INDEX: begin
                    data_o <= index_o;
                end
                `CP0_REG_RANDOM: begin
                    data_o <= random_o;
                end
                `CP0_REG_CONTEXT: begin
                    data_o <= context_o;
                end
                default: 	begin
                end			
            endcase  //case addr_i			
		end    //if
	end      //always

endmodule