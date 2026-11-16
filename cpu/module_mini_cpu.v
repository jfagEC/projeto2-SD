module module_mini_cpu(
input wire[17:0] instrucao,
input wire on, //liga/desliga
input wire send, //botao p enviar 
input wire clk,
//saidas de debug, remover depois, PRECISAM SER COLOCADOS COMO REGISTRADORES INTERNOS
output reg[2:0] opcode,
output reg[3:0] regDestino,
output reg[3:0] reg1,
output reg[3:0] reg2,
output reg[6:0] imm,
output reg [15:0] n1,
output reg [15:0] n2,
output reg [2:0] estadoAtual,
output reg [6:0] valor_mem, //Debuggar o que mexe na memória isso NAO precisa virar registrador interno, pode expurgar
output reg[15:0] numLcd,
//saidas do lcd
output wire  [7:0] lcd_data,
output wire        lcd_rs,
output wire        lcd_rw,
output wire        lcd_e
);



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
    STORE = 3'd4,
	 RESET = 3'd5, //esses ultimos 2 estados so servem para garantir que a mudança seja apos soltar o botao e loops infinitos
	 PROCESS_SEND = 3'd6,
	 LCD_UPD = 3'd7;

integer contadorSEND=32'd0;
integer contadorSTORE=32'd0;

//variaveis de controle dos submodulos -> comportamento de booleana
reg memClear;
reg lcdWrite; 
reg lcdClear;

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
	.clear(memClear),
	.q(q)
);

//parameters ULA
wire [15:0] out;
reg [2:0] sel;

module_alu ULA(
	.sel(opcode),
	.n1(n1),
	.n2(n2),
	.out(out)
);
//wire[15:0] numLcd;
//assign numLcd = (opcode == DISPLAY) ? n1: data; //quando eh display nao vai p o load, nao atualiza o data

lcd_controller_top LCD(
	.clk(clk),
	.rst(lcdWrite), //ATIVO => 1
	.clearStatus(lcdClear), //ATIVO =>1
	.Opcode(opcode),
	.regDispIN(regDestino),
	.numIn(data),
	.lcd_data(lcd_data),
	.lcd_rs(lcd_rs),
	.lcd_rw(lcd_rw),
	.lcd_e(lcd_e)
);



initial begin
    estadoAtual = OFF;
	 contadorSEND=0;
	 contadorSTORE=0;
	 lcdWrite = 1; //precisa dar o clear no lcd, p tirar a mensagem padrao
	 lcdClear = 1;
	 memClear = 0;
 end

reg[2:0] oldState;
//ver se precisa ter esse posedge on e posedge send
always @(posedge clk)begin //alternancia dos estados, sensivel ao clk e aos botoes
		 case(estadoAtual)
			  RESET: begin //estado q vai quando aperta o on/off
					if(~on) estadoAtual <= RESET;
					else if(oldState == SEND_WAIT) estadoAtual <= OFF;
					else estadoAtual <= SEND_WAIT;
			  end
			  PROCESS_SEND: begin //estado q vai quando aperta o send
					if(~send) estadoAtual <= PROCESS_SEND;
					else estadoAtual <= DECODE; //vai p decode depois que soltar o botao
			  
			  end
			  OFF: begin //NECESSARIO FAZER OS TESTES NO BOTÃO NA PLACA, P VER O LIGA/DESLIGA
					oldState = OFF;
					if(on)
						 estadoAtual <= OFF;
					else begin
						 estadoAtual <= RESET;
					end
			  end
			  SEND_WAIT: begin
					 oldState = estadoAtual;
					 if(~on) estadoAtual <= RESET;
					 else if(send) estadoAtual <= SEND_WAIT;
					else estadoAtual <= PROCESS_SEND; //para garantir que so sai quando soltar o botao
			  end
			  DECODE: begin
					if(opcode != CLEAR) estadoAtual <= SEND; //passa somente um pulso para fazer o decode
					else estadoAtual <= SEND_WAIT; //volta p esperar outras instrucoes direto se der clear
			  end 
			  SEND: begin //talvez passar mais tempo aq, ver as limitacoes de hardware, sao necessarias no max 4 operacoes
					if(contadorSEND>3 && opcode != DISPLAY) estadoAtual <= STORE;
					else if(contadorSEND>3 && opcode == DISPLAY) estadoAtual <= LCD_UPD; //nao precisa passar pelo store
			  end
			  STORE: begin //talvez passar mais tempo aq, ver as limitacoes de hardware, sao necessarias no max 5 operacoes
				if(contadorSTORE>5) estadoAtual <= LCD_UPD;
			  end
			  LCD_UPD: begin
					estadoAtual <= SEND_WAIT;
			  end
		 endcase
	 
end

always @(posedge clk)begin //manipulacao dos valores numericos
    case(estadoAtual)
    OFF: begin
        opcode <= 3'd0;
        regDestino <= 4'd0;
        reg1 <= 4'd0;
        reg2 <= 4'd0;
        imm <= 7'd0;
		  lcdClear <= 0;
		  lcdWrite <= 0;
		  memClear <= 0;
    end
    DECODE: begin
        opcode = instrucao[17:15];
        case(opcode) //bloco para decodificar
            ADD: begin
                regDestino <= instrucao[14:11];
                reg1 <= instrucao[10:7];
                reg2 <= instrucao[6:3];
                //os ultimos 3 bits ficam sobrando
            end
            SUB: begin
                regDestino <= instrucao[14:11];
                reg1 <= instrucao[10:7];
					 //Os outros bits ficam sobrando
            end
            ADDI, SUBI, MUL: begin
                regDestino <= instrucao[14:11];
                reg1 <= instrucao[10:7];
                imm <= instrucao[6:0]; //bit 6 eh o de sinal
            end
            LOAD: begin
                regDestino <= instrucao[14:11]; //considerar como na posicao do registrador 1
                imm <= instrucao[6:0]; //bit 6 -> sinal; "SWs[6:0]"
            end
            DISPLAY: begin
                regDestino <= instrucao[14:11]; ////coloca em reg destino pq eh oq vai p o lcd, mas nao vai p store
            end
				CLEAR: begin
					lcdWrite = 1;
					lcdClear = 1;
					memClear <= 1;
					opcode = LOAD; //valor qualquer, somente para permitir a leitura depois
				end
        endcase
    end
	 
	 SEND_WAIT: begin
		contadorSTORE<=0;
		lcdWrite <= 0;
		lcdClear <= 0;
	 end
	 //Pegar o valor na memória
	  SEND: begin //talvez passar mais tempo aq, ver as limitacoes de hardware
			we<=0;
			case(opcode)
				ADD: begin 
					if(contadorSEND>=3) n2 <= q;
					else if(contadorSEND>=2) addr <= reg2;
					else if(contadorSEND>=1) n1 <= q;
					else if(contadorSEND>=0) addr <= reg1;
				end
				SUB: begin 
					if(contadorSEND >= 1) n1 <= q;
					else if(contadorSEND>=0) addr <= reg1; //nao precisa buscar na memoria, nem de n2
				end
				ADDI, SUBI, MUL: begin
					if(contadorSEND>=2) begin 
						if (imm[6] == 1) n2 <= -{10'd0, imm[5:0]}; //Tratamento pra ele passar o valor certo e colocar o bit de sinal certo
						else n2 <= {10'd0, imm[5:0]};
					end
					else if(contadorSEND>=1) n1 <= q;
					else if(contadorSEND>=0) addr <= reg1;
				end
				LOAD: begin
					if(contadorSEND>=0) n1 <= imm; //nao precisa buscar na memoria, nem de n2
				end
				DISPLAY: begin
					if(contadorSEND >= 2) begin
						//numLcd = n1;
						//lcdWrite = 1;
					end
					else if(contadorSEND>=1) n1 <= q;
					else if(contadorSEND>=0) addr <= regDestino; 
				
				end
			endcase
			contadorSEND<=contadorSEND+1;
			
			if(contadorSEND == 3 && opcode == DISPLAY) lcdWrite <= 1; //display n vai p o store, precisa escrever aq
	  end
	//Guardar na memória
	  STORE: begin //talvez passar mais tempo aq, ver as limitacoes de hardware
			//lcdWrite = 0;
			contadorSEND<=0;
			//verificar se precisa desses 2 estagios de debug
			if (contadorSTORE>=4) begin //Isso aqui é pra ver se o valor guardado na memória tá certo
				valor_mem <= q[6:0];
			end
			else if(contadorSTORE>=2) begin
				we<=1; //ESSE WE PRECISA SER MANTIDO, MESMO DEPOIS DE TIRAR AS PARADA DE DEBUG
				 
				if (opcode == SUB) valor_mem <= q[6:0]; //Debuggar o sub
			end
			else if(contadorSTORE>=1)begin
				addr <= regDestino;
				//numLcd <= data;
			end
			else if(contadorSTORE>=0) begin
				
				 if (opcode == SUB) 
					  data <= n1;
				 else if (opcode == LOAD) begin
					  if (imm[6] == 1)
							data <= -{10'd0, imm[5:0]};//Coloca o bit de sinal na frente
					  else 
							data <= {10'd0, imm[5:0]};//pega os 5bits de valor do immediato e completa com 10 bits de valor 0
				 end //fim do else if interno
				 else 
					  data <= out;
		
			end //fim do else if  
			
			contadorSTORE<=contadorSTORE+1;	
		end //fim do case de store
		LCD_UPD: begin
			numLcd = data;
			lcdWrite = 1;
			
		end

    endcase

end



endmodule