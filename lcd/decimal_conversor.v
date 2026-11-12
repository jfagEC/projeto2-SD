module decimal_conversor(

input wire [15:0] binIn,
input wire clk,

output wire[7:0] sig,
output wire[7:0] numA, //msb
output wire[7:0] numB,
output wire[7:0] numC,
output wire[7:0] numD,
output wire[7:0] numE //lsb

);

localparam[0:0]
    CONVERT = 1'd0,
    ADDAPT = 1'd1;
	 
 localparam[3:0]
	ZERO = 3'd0,
	ONE = 3'd1,
	TWO = 3'd2,
	THREE = 3'd3,
	FOUR = 3'd4,
	FIVE = 3'd5,
	SIX = 3'd6,
	SEVEN = 3'd7,
	EIGHT = 3'd8,
	NINE = 3'd9;

integer idx, soma, var;
reg currState;

reg[7:0] decOut [5:0];

initial begin
    idx = 0;
    soma = 0;
	 var = 0;
    currState = CONVERT;
end

always @(*)begin
    case(currState)
		 CONVERT:begin
				soma = 0;
				//soma = soma;
			  //decOut <= decOut;
			  for(idx = 0; idx < 15; idx = idx + 1)begin
				  if(idx < 15)begin
						soma = soma + (binIn[idx]*(1 << idx));
				  end else if(idx == 15 && binIn[idx] == 1) begin
						soma <= -soma; //caso seja negativo
				  end
			  end
			  idx <= 0;
		 end
		 ADDAPT: begin
			  if(idx == 0)begin
				 if(soma < 0) decOut[5] <= "-";
				 else decOut[5] <= "+";
				 idx = idx + 1;
			  end else if(idx < 6)begin //pegando so o modulo do numero
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
					soma <= soma - var * (10 * (1 - idx));
					idx = idx + 1;
				end else begin
					soma <= 0;
					idx <= 0;
			  end
		 end

    endcase
 end

 always @(posedge clk)begin
	case(currState)
		CONVERT: begin
			if(idx < 15) currState <= CONVERT;
			else begin
				//idx <= 0;
				currState <= ADDAPT;
			end
		end
		ADDAPT: begin
			if(idx < 6) currState <= ADDAPT;
			else begin
				//idx <= 0;
				currState <= CONVERT;
			end
		
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