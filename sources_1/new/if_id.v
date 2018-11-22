
`include "defines.v"

module if_id(

	input wire clk,
	input wire rst,

	//来自控制模块的信息
	input wire[5:0] stall,
    
    // info about exception
    input wire flush,
    
	input wire[`InstAddrBus] if_pc,
	input wire[`InstBus] if_inst,
	output reg[`InstAddrBus] id_pc,
	output reg[`InstBus] id_inst  
	
);

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			id_pc <= `ZeroWord;
			id_inst <= `ZeroWord;
		end else if (flush == 1'b1) begin
		    //flush == 1时，异常发生，需要将流水线清除，即需要复位哥哥寄存器
		    id_pc <= `ZeroWord;
		    id_inst <= `ZeroWord;
		    
		end else if(stall[1] == `Stop && stall[2] == `NoStop) begin
			id_pc <= `ZeroWord;
			id_inst <= `ZeroWord;	
	  end else if(stall[1] == `NoStop) begin
		  id_pc <= if_pc;
		  id_inst <= {if_inst[7:0], if_inst[15:8], if_inst[23:16], if_inst[31:24]};
		end
	end

endmodule