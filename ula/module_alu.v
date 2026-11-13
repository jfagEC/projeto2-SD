module module_alu(input wire[2:0] sel, input wire[15:0] n1, input wire[15:0] n2, output wire[15:0] out);
	parameter ADD=1, ADDI=2, SUB=3, SUBI=4, MUL=5;

	integer res = 16'd0;
	
	always@(*) begin
		case(sel)
			ADDI, ADD: res <= n1+n2;
			SUB, SUBI: res <= n1-n2;
			MUL: res <= n1*n2;
			default: res<=16'd0;
		endcase
	end
	
	assign out = res;
	
endmodule