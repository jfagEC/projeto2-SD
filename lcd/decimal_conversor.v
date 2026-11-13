module decimal_conversor(

input wire [15:0] binIn,
input wire clk,
input wire enable, //enable vai puxar o reset do lcd

output wire[7:0] sig,
output wire[7:0] numA, //msb
output wire[7:0] numB,
output wire[7:0] numC,
output wire[7:0] numD,
output wire[7:0] numE, //lsb
output wire [31:0] debug,
output wire [31:0] debug2

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

integer idx, var, soma;
/*
reg[31:0] idx;
reg[31:0] var;
reg[31:0] soma;
*/
reg[1:0] currState;

reg[7:0] decOut [5:0];

//reg[3:0] somaArr[4:0]; //5 digitos de 0 ate 9(4 bits)

initial begin
    currState <= WAIT;
	 soma <= 32'd0;
	 decOut[0] = 8'd0;
	 decOut[1] = 8'd0;
	 decOut[2] = 8'd0;
	 decOut[3] = 8'd0;
	 decOut[4] = 8'd0;
	 decOut[5] = 8'd0;
end

always @(*)begin
var = soma % 10;
    case(currState)
		 CONVERT:begin
			
		 end
		 ADDAPT: begin
			  
		 end
		 WAIT: begin
		 
		 end
	endcase

 end

 always @(posedge clk, posedge enable)begin //aq vai usar 15 + 6 + 1 pulsos, que eh menor q os 50 no setup pos reset
	case(currState)
		CONVERT: begin
			if(idx < 14) begin
				soma = soma  + (binIn[idx] * (1 << idx));
				idx = idx + 1;
			end else begin
				soma <= soma;	
				currState <= ADDAPT;
				idx <= 32'd0;
			end
		 //var <= var;
		 decOut[0] = 8'd0;
		 decOut[1] = 8'd0;
		 decOut[2] = 8'd0;
		 decOut[3] = 8'd0;
		 decOut[4] = 8'd0;
		 decOut[5] = 8'd0;
		end
		ADDAPT: begin
			if(idx < 6)begin
				case(var)
						ZERO: decOut[idx] <= 8'b00110000;
						ONE: decOut[idx] <= 8'b00110001;
						TWO: decOut[idx] <= 8'b00110010;
						THREE: decOut[idx] <= 8'b00110011;
						FOUR: decOut[idx] <= 8'b00110100;
						FIVE: decOut[idx] <= 8'b00110101;
						SIX: decOut[idx] <= 8'b00110110;
						SEVEN: decOut[idx] <= 8'b00110111;
						EIGHT: decOut[idx] <= 8'b00111000;
						NINE: decOut[idx] <= 8'b00111001;
						default: decOut[idx] <= 8'b01011000;
				endcase
				soma = soma/10; //corta a virgula 
				idx = idx + 1;
			end else begin 
				decOut[5] <= binIn[15] ? 8'b00101101 : 8'b00101011;
				idx <= 32'd0;
				soma = 32'd0;
				currState <= WAIT;
			end
		end
		WAIT: begin
			 decOut[0] = 8'd0;
			 decOut[1] = 8'd0;
			 decOut[2] = 8'd0;
			 decOut[3] = 8'd0;
			 decOut[4] = 8'd0;
			 decOut[5] = 8'd0;
			soma <= 0;
			//var <= 0;
			idx <= 0;
			if(enable) currState<= CONVERT; //dexei igual ao rst no top, ver adequacao a placa
			else currState<= WAIT;
		end
	
	endcase

end



assign sig = decOut[5];
assign numA = decOut[4];
assign numB = decOut[3];
assign numC = decOut[2];
assign numD = decOut[1];
assign numE = decOut[0];
assign debug = var;
assign debug2 = soma;




endmodule