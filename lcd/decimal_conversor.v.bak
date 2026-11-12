module decimal_conversor(

input[15:0] wire binIn,
input wire clk,
output [6:0] reg decOut

);

localparam[1:0]
    CONVERT = 1'd0,
    ADDAPT = 1'd1;

integer idx, soma;
reg currState;

initial begin
    idx = 0;
    soma = 0;
    currState = CONVERT
end

always @(posedge clk)begin
    case(currState)
    CONVERT:begin
        if(idx < 15)begin
            soma = soma + (binIn[idx]*(2 << idx));
            idx = idx + 1;
        end else if(idx == 15) begin
            if(binIn[idx] == 1) soma = -soma; //caso seja negativo
            idx = idx + 1;
        end else begin 
            idx = 0;
            currState <= ADDAPT;
        end
    end
    ADDAPT: begin
        if(idx < 5)begin //pegando so o modulo do numero
            if(idx == 0)begin
                if(soma < 0) decOut[6] = "-";
                else decOut[6] = "+"; 
            end
            decOut[idx] = soma % 10;
            soma = soma - decOut[idx] * (10 * (idx - 1));
            idx = idx + 1;
        end else begin
            idx = 0;
            soma = 0;
            currState <= CONVERT;
        end

    end

    endcase

    



end















endmodule