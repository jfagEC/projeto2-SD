module bin_conversor(
input wire[3:0] binIn,
input wire clk,
input wire rst,

output wire[7:0] numA, //msb
output wire[7:0] numB,
output wire[7:0] numC,
output wire[7:0] numD //lsb

);

integer cont;
reg currState;

reg[7:0] out [3:0];

localparam[0:0]
	READ = 1'b0,
	WAIT = 1'b1;

initial begin
	cont <= 0;
	currState <= WAIT;
end



always @(posedge clk)begin

	case(currState)
		READ: begin
			if(binIn[cont] == 1)begin 
				out[cont] <= "1";
			end else begin 
				out[cont] <= "0";
			end
			cont = cont + 1;
			if(cont == 4)begin 
				cont <= 0;
				currState <= WAIT;
			end
		end
		WAIT: begin
			if(rst) currState <= READ;
			else begin
				currState <= WAIT;
			end
		
		end
	
	endcase

end

assign numA = out[3];
assign numB = out[2];
assign numC = out[1];
assign numD = out[0];


endmodule