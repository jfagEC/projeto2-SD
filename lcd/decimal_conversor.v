module decimal_conversor(

input wire [15:0] binIn,
input wire clk,
input wire enable, //enable vai puxar o reset do lcd

output wire[7:0] sig,
output wire[7:0] numA, //msb
output wire[7:0] numB,
output wire[7:0] numC,
output wire[7:0] numD,
output wire[7:0] numE //lsb

);

localparam[1:0]
    CONVERT = 2'd0,
    ADDAPT = 2'd1,
	 WAIT = 2'd2;
	 
 localparam[3:0]
	ZERO = 4'd0,
	ONE = 4'd1,
	TWO = 4'd2,
	THREE = 4'd3,
	FOUR = 4'd4,
	FIVE = 4'd5,
	SIX = 4'd6,
	SEVEN = 4'd7,
	EIGHT = 4'd8,
	NINE = 4'd9;

integer soma;
integer idx;
integer var;
/*reg[31:0] soma;
reg[15:0] tmpSum;*/
reg[1:0] currState;

reg[7:0] decOut [5:0];

//reg[3:0] somaArr[4:0]; //5 digitos de 0 ate 9(4 bits)

initial begin
    currState <= WAIT;
	 soma = 0;
	 idx = 0;
	 decOut[0] = 8'd0;
	 decOut[1] = 8'd0;
	 decOut[2] = 8'd0;
	 decOut[3] = 8'd0;
	 decOut[4] = 8'd0;
	 decOut[5] = 8'd0;
end

always @(posedge clk)begin
	case(currState)
		CONVERT: begin
			if(idx < 15) soma = soma + binIn[idx] * (1 << idx); 
			idx = idx + 1;
			if(idx == 15) begin 
				currState <= ADDAPT;
				idx <= 0;
			end
		end
		ADDAPT: begin
			if(idx < 5) begin
				var = soma % 10;
				case(var)
					ZERO: decOut[idx] <= "0";
					ONE: decOut[idx] <= "1";
					TWO: decOut[idx] <= "2";
					THREE: decOut[idx] <= "3";
					FOUR: decOut[idx] <= "4";
					FIVE: decOut[idx] <= "5";
					SIX: decOut[idx] <= "6";
					SEVEN: decOut[idx] <= "7";
					EIGHT: decOut[idx] <= "8";
					NINE: decOut[idx] <= "9";		
				endcase
				soma = soma/10;
				idx = idx + 1;
			end else if(idx == 5) begin
				decOut[idx] = binIn[15] ? "-": "+" ;
				idx = idx + 1;
			end else begin
				idx <= 0;
				currState <= WAIT;
			end
		end
		WAIT: begin
			soma <= 0;
			idx <= 0;
			if(enable) currState <= CONVERT;
			else currState <= WAIT;
		
		end
	
	endcase




end





assign sig = decOut[5];
assign numA = decOut[4];
assign numB = decOut[3];
assign numC = decOut[2];
assign numD = decOut[1];
assign numE = decOut[0];



endmodule