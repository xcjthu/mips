
`include "defines.v"

module ctrl(

	input wire rst,

	input wire[31:0] excepttype_i,
	input wire[`RegBus] cp0_epc_i,
	input wire[`RegBus] cp0_ebase_i,

	input wire stallreq_from_id,


	input wire stallreq_from_ex,

	output reg[`RegBus] new_pc,
	output reg flush,	
	output reg[5:0] stall       
	
);


	always @ (*) begin
		if(rst == `RstEnable) begin
			stall <= 6'b000000;
			flush <= 1'b0;
			new_pc <= `ZeroWord;
		end else if(excepttype_i != `ZeroWord) begin
        flush <= 1'b1;
        stall <= 6'b000000;
        case (excepttype_i)
            // set pc value according to the type of exception
            32'h00000001: begin // 中断
                new_pc <= {cp0_ebase_i[31:12], 12'h000};
                //new_pc <= 32'h00000020;
            end
            32'h00000008: begin // syscall
                new_pc <= {cp0_ebase_i[31:12], 12'h180};
                //new_pc <= 32'h00000040;
            end
            32'h0000000a: begin // 无效指令
                new_pc <= {cp0_ebase_i[31:12], 12'h180};
                //new_pc <= 32'h00000040;
            end
            32'h0000000c: begin // overflow
                new_pc <= {cp0_ebase_i[31:12], 12'h180};
                //new_pc <= 32'h00000040;
            end
            32'h0000000e: begin // eret
                new_pc <= cp0_epc_i;
            end
            32'h0000000f: begin //break
                new_pc <= {cp0_ebase_i[31:12], 12'h180};
            end
            32'h00000010: begin // instruction address error
                new_pc <= {cp0_ebase_i[31:12], 12'h180};
            end
            32'h00000011: begin // load address error
                new_pc <= {cp0_ebase_i[31:12], 12'h180};
            end
            32'h00000012: begin // save address error
                new_pc <= {cp0_ebase_i[31:12], 12'h180};
            end
            default : begin
            end
        endcase 						
end else if(stallreq_from_ex == `Stop) begin
    stall <= 6'b001111;
    flush <= 1'b0;		
end else if(stallreq_from_id == `Stop) begin
    stall <= 6'b000111;	
    flush <= 1'b0;		
end else begin
    stall <= 6'b000000;
    flush <= 1'b0;
    new_pc <= `ZeroWord;		
end    //if
	end      //always
			

endmodule