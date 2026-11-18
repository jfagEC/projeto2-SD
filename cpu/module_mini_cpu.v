module module_mini_cpu(
input wire[17:0] instrucao,
input wire on, //liga/desliga
input wire send, //botao p enviar 
input wire clk,
//saidas de debug, remover depois, PRECISAM SER COLOCADOS COMO REGISTRADORES INTERNOS
//output reg lcdWrite,
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

localparam[3:0] //estados da FSM
    OFF = 4'd0, //cpu desligada
    SEND_WAIT = 4'd1, //enquanto n tem o trig do botao
    DECODE = 4'd2, //decodificar a instrucao
    SEND = 4'd3, //buscar operandos/enviar para ula
    STORE = 4'd4, //armazenar resultados na memória
	 PROCESS_RESET = 4'd5, //processar quando apertar o liga/desliga - > so vai quando soltar
	 PROCESS_SEND = 4'd6, //processar quando apertar o send - > so vai quando soltar
	 LCD_UPD = 4'd7, //segura aq enquanto decodifica p jogar no lcd
	 BOOT = 4'd8; //somente para inicializar as coisas
	 
integer contadorSEND=32'd0;
integer contadorSTORE=32'd0;
integer contadorLcd = 32'd0;

//variaveis de controle dos submodulos -> comportamento de booleana
reg memClear;
reg lcdWrite; 
reg lcdClear;
reg lcdBlank;

//parameters memory
reg [15:0] data =0;
reg [3:0] addr =0;
reg we =0;
wire [15:0] q;
//registradores internos
reg[2:0] opcode =0;
reg[3:0] regDestino =0;
reg[3:0] reg1 =0;
reg[3:0] reg2 =0;
reg[6:0] imm =0;
reg [15:0] n1 =0;
reg [15:0] n2 =0;
reg [3:0] estadoAtual =0;


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

reg[15:0] numLcd; //valor q entra no lcd
integer contadorBoot;

lcd_controller_top LCD(
	.clk(clk),
	.rst(lcdWrite), //ATIVO => 1
	.clearStatus(lcdClear), //ATIVO =>1
	.blank(lcdBlank),
	.Opcode(opcode),
	.regDispIN(regDestino),
	.numIn(data),
	.lcd_data(lcd_data),
	.lcd_rs(lcd_rs),
	.lcd_rw(lcd_rw),
	.lcd_e(lcd_e)
);

integer contadorDebounce;
integer tempoLigado;

initial begin
    estadoAtual = OFF;
	 contadorSEND=0;
	 contadorSTORE=0;
	 contadorBoot = 0;
	 contadorDebounce = 0;
	 tempoLigado = 0;
	 lcdWrite = 1; //precisa dar o clear no lcd, p tirar a mensagem padrao
	 lcdClear = 0;
	 memClear = 0;
	 lcdBlank = 1;
 end

reg[2:0] oldState; //p saber p onde ir quando apertar o liga/desliga
always @(posedge clk)begin //alternancia dos estados, sensivel ao clk e aos botoes
		 case(estadoAtual)
			  PROCESS_RESET: begin //estado q vai quando aperta o on/off
					if(~on) estadoAtual <= PROCESS_RESET;
					else if(oldState == SEND_WAIT && contadorDebounce > 20 && tempoLigado == 2500000) estadoAtual <= OFF;
					else if(contadorDebounce > 20) estadoAtual <= BOOT;
					
			  end
			  PROCESS_SEND: begin //estado q vai quando aperta o send
					if(~send) estadoAtual <= PROCESS_SEND;
					else if(contadorDebounce > 20) estadoAtual <= DECODE; //vai p decode depois que soltar o botao
					
			  end
			  OFF: begin //NECESSARIO FAZER OS TESTES NO BOTÃO NA PLACA, P VER O LIGA/DESLIGA
					oldState <= OFF;
					if(on)
						 estadoAtual <= OFF;
					else begin
						 estadoAtual <= PROCESS_RESET;
					end
			  end
			  BOOT: begin
					if(contadorBoot > 23) estadoAtual <= SEND_WAIT;
					else estadoAtual <= BOOT;
			  end
			  SEND_WAIT: begin
					 oldState <= estadoAtual;
					 if(~on) estadoAtual <= PROCESS_RESET;
					 else if(send) estadoAtual <= SEND_WAIT;
					else estadoAtual <= PROCESS_SEND; //para garantir que so sai quando soltar o botao
			  end
			  DECODE: begin
					/*if(opcode != CLEAR)*/ estadoAtual <= SEND; //passa somente um pulso para fazer o decode
					//else estadoAtual <= SEND_WAIT; //volta direto p receber outras instrucoes, nao precisa esperar o decode do lcd
					//AVISO: CASO NAO ESTEJA DANDO CLEAR DIREITO NA MEMORIA, FAZ PASSAR PELO LCD_UPD QUE TEM TEMPO SUFICIENTE
			  end 
				SEND: begin
					 if(contadorSEND > 8) estadoAtual <= STORE;
					 else estadoAtual <= SEND;
				end
			  STORE: begin //talvez passar mais tempo aq, ver as limitacoes de hardware, sao necessarias no max 5 operacoes
				if(contadorSTORE>3) estadoAtual <= LCD_UPD;
			  end
			  LCD_UPD: begin
					if(contadorLcd > 22)estadoAtual <= SEND_WAIT; //precisa ficar a quantidade de pulsos p decodificar os valores
					else estadoAtual <= LCD_UPD;
			  end
		 endcase
	 
end

always @(posedge clk)begin //manipulacao dos valores numericos
	if(estadoAtual != OFF && tempoLigado < 2500000)tempoLigado <= tempoLigado + 1;
    case(estadoAtual)
	 PROCESS_RESET: begin 
		contadorDebounce <= contadorDebounce + 1;
		lcdWrite <= 1;
	 end
	 PROCESS_SEND: begin
		contadorDebounce <= contadorDebounce + 1;
	 end
    OFF: begin
		  lcdClear <= 0;
		  lcdWrite <= 0;
		  memClear <= 0;
		  lcdBlank <= 1;
		  contadorBoot <= 0;
		  contadorDebounce <= 0;
    end
	 BOOT: begin
		if(contadorBoot >= 2) begin 
			  lcdClear <= 1;
			  memClear <= 1;
			  opcode <= 3'd0;
			  regDestino <= 4'd0;
			  reg1 <= 4'd0;
			  reg2 <= 4'd0;
			  imm <= 7'd0;
			  n1 <= 0;
			  n2 <= 0;
			  lcdWrite <= 0;
		 end else if(contadorBoot >= 0)begin
				lcdBlank <= 0;
			   lcdWrite <= 1;
		 end
		 contadorDebounce <= 0;
		 contadorBoot <= contadorBoot + 1;
		  
	 
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
					 reg2 <= instrucao[6:3];
					 //Os outros bits ficam sobrando
            end
            ADDI, SUBI, MUL: begin
                regDestino <= instrucao[14:11];
                reg1 <= instrucao[10:7];
                imm <= instrucao[6:0]; //bit idx 6 eh o de sinal
            end
            LOAD: begin
                regDestino <= instrucao[14:11]; //considerar como na posicao do registrador 1
                imm <= instrucao[6:0]; //bit 6 -> sinal; "SWs[6:0]"
            end
            DISPLAY: begin
                regDestino <= instrucao[14:11]; ////coloca em reg destino pq eh oq vai p o lcd, mas nao vai p store
            end
				CLEAR: begin
					lcdWrite = 1; //nao vai passar pelo LCD_UPD, pq n precisa decodificar nada
					memClear = 1;
				end
        endcase
    end
	 
	 SEND_WAIT: begin
		we<=0;
		contadorSTORE<=0;
		contadorSEND<=0;
		contadorBoot <= 0;
		contadorDebounce <= 0;
		lcdWrite = 0;
		lcdClear = 0;
		contadorLcd <= 0;
		lcdBlank = 0;
		memClear=0;
	 end
	 //Pegar o valor na memória
	  SEND: begin //talvez passar mais tempo aq, ver as limitacoes de hardware
			we<=0;
			case(opcode)
					 ADD, SUB: begin
						  if(contadorSEND>=6)      n2   <= q;   
						  else if(contadorSEND>=4) addr <= reg2;
						  else if(contadorSEND>=2) n1   <= q; // aumento do intervalo entre atribuicoes dado pelo cont     
						  else                     addr <= reg1;
					 end
					 ADDI, SUBI, MUL: begin
						  if(contadorSEND>=4) begin
								if (imm[6] == 1) n2 <= -{10'd0, imm[5:0]};
								else             n2 <= {10'd0, imm[5:0]};
						  end else if(contadorSEND >= 2) n1 <= q;
						  else if(contadorSEND>=0)addr <= reg1;
					 end
					 LOAD: begin
						  n1 <= imm;
					 end
					 DISPLAY: begin
						  if(contadorSEND>=2) data <= q;
						  else                addr <= regDestino;
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
			if(contadorSTORE>=2) begin
				if(opcode != DISPLAY)we<=1; //ESSE WE PRECISA SER MANTIDO, MESMO DEPOIS DE TIRAR AS PARADA DE DEBUG
			end
			else if(contadorSTORE>=1)begin
				//addr <= regDestino;
				//numLcd = data;
			end
      else if(contadorSTORE>=0) begin
				addr <= regDestino;
				 if (opcode == LOAD) begin
					  if (imm[6] == 1)
							data <= -{10'd0, imm[5:0]};//Coloca o bit de sinal na frente
					  else 
							data <= {10'd0, imm[5:0]};//pega os 5bits de valor do immediato e completa com 10 bits de valor 0
				 end //fim do else if interno
			
				 else if(opcode!= DISPLAY)
					  data <= out;
				
			end //fim do else if  

			contadorSTORE<=contadorSTORE+1;	
		end //fim do case de store
		LCD_UPD: begin
			if(contadorLcd >=1) lcdWrite = 1;
			else if(contadorLcd >= 0) numLcd <= (opcode == DISPLAY)? n1: data; //o display n manda dnv p memoria, fica em n1
			contadorLcd <= contadorLcd + 1;
			
		end
		
		default: begin end

    endcase

end



endmodule