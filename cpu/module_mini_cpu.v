module module_mini_cpu(
input wire[17:0] instrucao,
input wire on, //liga/desliga
input wire send, //botao p enviar 
input wire clk,
output reg[2:0] opcode,
output reg[3:0] regDestino,
output reg[3:0] reg1,
output reg[3:0] reg2,
output reg[6:0] imm,
output reg [15:0] n1,
output reg [15:0] n2,
output reg [2:0] estadoAtual
);

//declarar os numeros como signed
//testar como negativos são anotados na memória

//adotar como convencao que maior indice => MSB

localparam[2:0]
    LOAD = 3'd0,
    ADD = 3'd1,
    ADDI = 3'd2,
    SUB = 3'd3,
    SUBI = 3'd4,
    MUL = 3'd5,
    CLEAR = 3'd6,
    DISPLAY = 3'd7;

localparam[2:0] //estados da FSM
    OFF = 3'd0,
    SEND_WAIT = 3'd1, //enquanto n tem o trig do botao
    DECODE = 3'd2,
    SEND = 3'd3,
    STORE = 3'd4;

integer contadorSEND=32'd0;
integer contadorSTORE=32'd0;

//parameters memory
reg [15:0] data;
reg [3:0] addr;
reg we;
wire [15:0] q;

memory MEM(
	.data(data),
	.addr(addr),
	.we(we),
	.clk(clk),
	.q(q)
);

//parameters ULA
// sel = estadoAtual;
wire [15:0] out;

module_alu ULA(
	.sel(estadoAtual),
	.n1(n1),
	.n2(n2),
	.out(out)
);

reg [15:0] numIn;
//lcd_controller_top LCD(
	//numIn(out);
//);

wire ativo;

initial begin
    estadoAtual = OFF;
//fazer inicializacao dos valores da memoria aq tb dps
end


always @(posedge clk, posedge on, posedge send)begin //alternancia dos estados, sensivel ao clk e aos botoes 
    case(estadoAtual)
        OFF: begin
            if(on)
                estadoAtual <= OFF;
            else begin
                estadoAtual <= SEND_WAIT;
            end
        end
        SEND_WAIT: begin
            if(send)
                estadoAtual <= SEND_WAIT;
            else
                estadoAtual <= DECODE;
        end
        DECODE: begin
            estadoAtual <= SEND_WAIT; //passa somente um pulso para fazer o decode
        end 
        SEND: begin //talvez passar mais tempo aq, ver as limitacoes de hardware
            if(contadorSEND==5) estadoAtual <= STORE;
        end
        STORE: begin //talvez passar mais tempo aq, ver as limitacoes de hardware
            if(contadorSTORE==4) estadoAtual <= SEND_WAIT;
        end
    endcase
end

always @(*)begin
    case(estadoAtual)
    OFF: begin
        opcode <= 3'd0;
        regDestino <= 4'd0;
        reg1 <= 4'd0;
        reg2 <= 4'd0;
        imm <= 7'd0;
    end
    DECODE: begin
        opcode = instrucao[17:15];
        case(opcode) //bloco para decodificar
            ADD, SUB: begin
                regDestino <= instrucao[14:11];
                reg1 <= instrucao[10:7];
                reg2 <= instrucao[6:3];
                //os ultimos 3 bits ficam sobrando
            end
            ADDI, SUBI, MUL: begin
                regDestino <= instrucao[14:11];
                reg1 <= instrucao[10:7];
                imm <= instrucao[6:0]; //bit 6 eh o de sinal
            end
            LOAD: begin
                regDestino <= instrucao[14:11]; //considerar como na posicao do registrador 1
                imm <= instrucao[10:4];
            end
            DISPLAY: begin
                regDestino <= instrucao[14:11]; //eh o resgistrador que vai p memoria
            end
				CLEAR: begin
					//resetar tudo
				end
        endcase
    end
	 
	 SEND_WAIT: begin
		contadorSTORE<=0;
	 end
	  
	  SEND: begin //talvez passar mais tempo aq, ver as limitacoes de hardware
			we<=0;
			case(opcode)
				ADD, SUB: begin
					if(contadorSEND==0) addr <= reg1;
					if(contadorSEND==1) n1 <= q;
					if(contadorSEND==2) addr <= reg2;
					if(contadorSEND==3) n2 <= q;
				end
				ADDI, SUBI, MUL: begin
					if(contadorSEND==0) addr <= reg1;
					if(contadorSEND==1) n1 <= q;
					if(contadorSEND==2) n2 <= imm;
				end
				default: begin
					numIn <= out;
				end
			endcase
			
			contadorSEND<=contadorSEND+1;
	  end

	  STORE: begin //talvez passar mais tempo aq, ver as limitacoes de hardware
			contadorSEND<=0;
			if(contadorSTORE==0) data <= out;
			if(contadorSTORE==1) addr <= regDestino;
			if(contadorSTORE==2) we<=1;
			
			contadorSTORE<=0;	
		end




    endcase

end




endmodule