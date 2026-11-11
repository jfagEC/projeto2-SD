module module_mini_cpu(
input wire[17:0] instrucao,
input wire on, //liga/desliga
input wire send, //botao p enviar 
input wire clk,
output reg[2:0] opcode,
output reg[3:0] regDestino,
output reg[3:0] reg1,
output reg[3:0] reg2,
output reg[6:0] imm
);

wire [3:0] sel;
reg [7:0] n1;
reg [7:0] n2;
reg [7:0] nR;

reg [7:0] n1Send;
reg [7:0] n2Send;

integer rst=1'd0;
integer data=8'd0;
integer we=1'd0;
reg [3:0] addr;
reg [15:0] q;
reg [7:0] out;

memory MEM(
	.data(data),
	.addr(addr),
	.we(we),
	.clk(clk),
	.q(q)
);

module_alu ULA(
	.sel(sel),
	.n1(n1Send),
	.n2(n2Send),
	.out(out)
);

lcd_controller_top LCD(
	.clk(clk),
	.rst(rst), //
	.Opcode(opcode),
	.n1(n1Send),
	.n2(n2Send),
	.nR(nR)
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
    WAIT_SEND = 3'd1, //enquanto n tem o trig do botao
    DECODE = 3'd2,
    SEND_ULA = 3'd3,
	 SEND_LCD = 3'd4,
    STORE = 3'd5,
	 READ_R1 = 3'd6,
	 READ_R2 = 3'd7;
	 READ_N1 = 3'd6,
	 READ_N2 = 3'd7;
	 READ_ULA = 3'd8;

reg [2:0] estadoAtual;

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
                estadoAtual <= WAIT_SEND;
            end
        end
        WAIT_SEND: begin
            if(send)
                estadoAtual <= WAIT_SEND;
            else
                estadoAtual <= DECODE;
				if(~on)
					estadoAtual <= OFF;
        end
        DECODE: begin
            estadoAtual <= READ_R1; //passa somente um pulso para fazer o decode
        end 
        SEND_ULA: begin //talvez passar mais tempo aq, ver as limitacoes de hardware
            estadoAtual <= STORE;
        end
        STORE: begin //talvez passar mais tempo aq, ver as limitacoes de hardware
            estadoAtual <= SEND_LCD;
        end
		  SEND_LCD: begin
				estadoAtual <= WAIT_SEND;
		  end
		  READ_R1: begin
				estadoAtual<=READ_N1;
		  end
		  READ_R2: begin
				estadoAtual<=READ_N2;
		  end
		  READ_N1: begin
				estadoAtual<=READ_R2;
		  end
		  READ_R2: begin
				estadoAtual<=READ_N2;
		  end
		  READ_N2: begin
				estadoAtual<=READ_ULA;
		  end
		  READ_ULA: begin
				estadoAtual<=STORE;
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
					LOAD: begin
						//pensar em alguma coisa aq
					end
			endcase
		end
		
		SEND_ULA: begin
			case(opcode) //bloco para decodificar
				ADD, SUB: begin
					n1Send <= n1;
					n2Send <= n2;
				end
				ADDI, SUBI, MUL: begin
					n1Send <= n1;
					n2Send <= imm;
				end
				default: begin
					
				end
			endcase
			
			assign nR <= out
			
		end
		
		STORE: begin
			
		end
		
		READ_R1: begin
			we <= 0;
			addr <= reg1;
		end
	  
		READ_R2: begin
			we <= 0;
			addr <= reg2;
		end
		
		READ_N1: begin
			n1 <= q;
		end
	  
		READ_N2: begin
			n2<=q;
		end
		
		READ_ULA: begin
			nR<=out;
			we <= 1;
			addr<=regDestino;
		end	
				
	endcase


end



endmodule