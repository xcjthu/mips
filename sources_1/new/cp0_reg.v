`include "defines.v"

module cp0_reg(
    input wire clk,
    input wire rst,
    
    input wire we_i,
    input wire[4:0] waddr_i, //write addr
    input wire[4:0] raddr_i, //read addr
    input wire[`RegBus] data_i,//write data
    input wire[5:0] int_i, //hard ware break signal
    
    
    input wire[31:0] excepttype_i,
    input wire[`RegBus] current_inst_addr_i,
    input wire is_in_delayslot_i,
    
    
    output reg[`RegBus] data_o,
    output reg[`RegBus] count_o,
    output reg[`RegBus] compare_o,
    output reg[`RegBus] status_o,
    output reg[`RegBus] cause_o,
    output reg[`RegBus] epc_o,
    output reg[`RegBus] config_o,
    output reg[`RegBus] ebase_o,
    
    output reg timer_int_o //定时中断是否发生
    );
    
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            // set init value
            count_o <= `ZeroWord;
            compare_o <= `ZeroWord;
            status_o <= 32'b00010000000000000000000000000000;
            //first fout bit 0001 represents that only cp0 exists
            cause_o <= `ZeroWord;
            epc_o <= `ZeroWord;
            config_o <= 32'b0;
            ebase_o <= 32'b10000000000000000000000000000000;
            
            timer_int_o <= `InterruptNotAssert;
        end
        else begin
            count_o <= count_o + 1;
            
            cause_o[15:10] <= int_i;
            
            // when compare_o == count_o, 时钟中断
            if (compare_o != `ZeroWord && count_o == compare_o) begin
                timer_int_o <= `InterruptAssert;
            end
            
            case (excepttype_i)
                32'h00000001: begin // 外部中断
                    if (is_in_delayslot_i == `InDelaySlot) begin
                        epc_o <= current_inst_addr_i - 4;
                        cause_o[31] <= 1'b1;  // BD in cause register
                    end else begin
                        epc_o <= current_inst_addr_i;
                        cause_o[31] <= 1'b0;
                    end
                    status_o[1] <= 1'b1;  // EXL in status
                    cause_o[6:2] <= 5'b00000; // ExcCode in cause
                end
                
                32'h00000008: begin  //syscall
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i == `InDelaySlot) begin
                            epc_o <= current_inst_addr_i - 4;
                            cause_o[31] <= 1'b1;  // BD in cause register
                        end else begin
                            epc_o <= current_inst_addr_i;
                            cause_o[31] <= 1'b0;
                        end 
                    end
                    status_o[1] <= 1'b1;  // EXL in status
                    cause_o[6:2] <= 5'b01000; // ExcCode in cause
                end
                
                32'h0000000a: begin // invalid instruction exception
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i == `InDelaySlot) begin
                            epc_o <= current_inst_addr_i - 4;
                            cause_o[31] <= 1'b1;  // BD in cause register
                        end else begin
                            epc_o <= current_inst_addr_i;
                            cause_o[31] <= 1'b0;
                        end
                    end
                    status_o[1] <= 1'b1;  // EXL in status
                    cause_o[6:2] <= 5'b01010; // ExcCode in cause
                end
                
                32'h0000000c: begin  // overflow
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i == `InDelaySlot) begin
                            epc_o <= current_inst_addr_i - 4;
                            cause_o[31] <= 1'b1;  // BD in cause register
                        end else begin
                            epc_o <= current_inst_addr_i;
                            cause_o[31] <= 1'b0;
                        end
                    end
                    status_o[1] <= 1'b1;
                    cause_o[6:2] <= 5'b01100;
                end
                
                32'h0000000e: begin // eret
                    status_o[1] <= 1'b0;
                end
                default: begin
                end
            endcase
            
            if (we_i == `WriteEnable) begin
                case (waddr_i)
                    `CP0_REG_COUNT: 
                    begin
                       count_o <= data_i; 
                    end
                    `CP0_REG_COMPARE:
                    begin
                        compare_o <= data_i;
                        timer_int_o <= `InterruptNotAssert;
                    end
                    `CP0_REG_STATUS:
                    begin
                        status_o <= data_i;
                    end
                    `CP0_REG_EPC:
                    begin
                        epc_o <= data_i;
                    end
                    `CP0_REG_CAUSE:
                    begin
                        cause_o[9:8] <= data_i[9:8];
                        cause_o[23] <= data_i[23];
                        cause_o[22] <= data_i[22];
                    end
                    `CP0_REG_EBASE:
                    begin
                        if (ebase_o[11] == 1'b0) begin
                            ebase_o[29:12] <= data_i[29:12];
                        end else begin
                            ebase_o[31:12] <= data_i[31:12];
                        end
                        ebase_o[11] <= data_i[11];
                        
                    end
                endcase
            end
        end
    end
    
    always @(*) begin
        if (rst == `RstEnable) begin
            data_o <= `ZeroWord;
           
        end else begin
            case (raddr_i)
                `CP0_REG_COUNT:
                begin
                    data_o <= count_o;
                end
                `CP0_REG_COMPARE:
                begin
                    data_o <= compare_o;
                end
                `CP0_REG_STATUS:
                begin
                    data_o <= status_o;
                end
                `CP0_REG_CAUSE:
                begin
                    data_o <= cause_o;
                end
                `CP0_REG_EPC:
                begin
                    data_o <= epc_o;
                end
                `CP0_REG_EBASE:
                begin
                    data_o <= ebase_o;
                end
                `CP0_REG_CONFIG:
                begin
                    data_o <= config_o;
                end
                default:
                begin
                end
            endcase
        end
    end
    
    
endmodule
