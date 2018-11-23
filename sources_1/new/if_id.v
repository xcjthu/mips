
`include "defines.v"

module if_id(

	input wire clk,
	input wire rst,

	//���Կ���ģ�����Ϣ
	input wire[5:0]               stall,	
	input wire                    flush,

	input wire[`InstAddrBus]	  if_pc,
	input wire[`InstBus]          if_inst,
	output reg[`InstAddrBus]      id_pc,
	output reg[`InstBus]          id_inst  
	
);

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			id_pc <= `ZeroWord;
			id_inst <= `ZeroWord;
		end else if(flush == 1'b1 ) begin
			id_pc <= `ZeroWord;
			id_inst <= `ZeroWord;					
		end else if(stall[1] == `Stop && stall[2] == `NoStop) begin
			id_pc <= `ZeroWord;
			id_inst <= `ZeroWord;	
	    end else if(stall[1] == `NoStop) begin
	        if (if_pc[1:0] != 2'b00) begin
	           id_inst = `ZeroWord;
	        end else begin
	           id_inst <= {if_inst[7:0], if_inst[15:8], if_inst[23:16], if_inst[31:24]};   
	        end
		    id_pc <= if_pc;
		    //id_inst <= if_inst;
		end
	end

endmodule