// ---------------------------------------------------------------------------
// Módulo: lcd_controller_top
// Função: Controlador principal do LCD.
//         Aguarda o módulo lcd_init_hd44780 terminar a inicialização e,
//         em seguida, escreve uma mensagem fixa na primeira linha do LCD.
//
// Estilo de FSM:
//   - Bloco 1 (sequencial): state, delay_cnt, msg_index
//   - Bloco 2 (combinacional): next_state, next_delay_cnt, next_msg_index
//   - Bloco 3 (combinacional): geração de saídas (Moore)
//
// Dependência: módulo lcd_init_hd44780 (já com sua própria FSM em 3 always).
// ---------------------------------------------------------------------------
module lcd_controller_top (
    input  wire       clk,
    input  wire       rst,
    input wire[2:0]   Opcode, //entrada do seletor
    input wire[3:0]   regDispIN, //registrador eh p mostar em binario ou decimal?
    input wire[15:0]   numIn, //mostar em decimal, 16 bits dao 5 digitos(mais 1 de sinal)

    // Saídas para o LCD
    output wire  [7:0] lcd_data,
    output wire        lcd_rs,
    output wire        lcd_rw,
    output wire        lcd_e
);

//reg[2:0] Opcode;
//reg [3:0] regDisp;
	wire[7:0] regDisp [3:0];	
	
    // -----------------------------------------------------------------------
    // Instância do módulo de inicialização
    // -----------------------------------------------------------------------
    wire [7:0] init_data;
    wire       init_rs;
    wire       init_rw;
    wire       init_e;
    wire       init_done;

    reg        start_init;  // gerado pelo controlador
	 
    wire[7:0] numDisp[5:0];

    lcd_init_hd44780 lcd_init (
        .clk      (clk),
        .rst      (rst),
        .start    (start_init),
        .done     (init_done),
        .lcd_data (init_data),
        .lcd_rs   (init_rs),
        .lcd_rw   (init_rw),
        .lcd_e    (init_e)
    );
    decimal_conversor conversor( //para tratar o numero do reg
        .binIn (numIn),
        .clk (clk),
        .enable(rst),
		  .sig(numDisp[5]), //valores de saida pra escrever
		  .numA(numDisp[4]),
		  .numB(numDisp[3]),
		  .numC(numDisp[2]),
		  .numD(numDisp[1]),
		  .numE(numDisp[0])
    );
	 
	 bin_conversor conversorBin(
			.binIn (regDispIN),
			.clk(clk),
			.rst(rst),
			.numA(regDisp[3]),
			.numB(regDisp[2]),
			.numC(regDisp[1]),
			.numD(regDisp[0])
	 
	 );
	 //CASO QUEIRA TESTAR PELO WAVE FORM 
	//reg init_done = 1'b1; 
	// precisa modificar o wire init_done e tambem oq entra no modulo do init p outra coisa																	

    // -----------------------------------------------------------------------
    // MUX: decide quem controla o LCD (init ou controlador principal)
    // -----------------------------------------------------------------------
    wire controller_mode = init_done;
    assign lcd_data = (controller_mode == 0) ? init_data : wr_data;
    assign lcd_rs   = (controller_mode == 0) ? init_rs   : wr_rs;
    assign lcd_rw   = (controller_mode == 0) ? init_rw   : wr_rw;
    assign lcd_e    = (controller_mode == 0) ? init_e    : wr_e;

    // -----------------------------------------------------------------------
    // Mensagem a ser exibida
    // -----------------------------------------------------------------------
    localparam integer MSG_LEN = 32;

    reg [7:0] message [0:MSG_LEN-1];
	 
	 localparam[2:0] //opcoes para aparecer no lcd
		OP_LOAD = 3'b 000,
		OP_ADD  = 3'b 001,
		OP_ADDI = 3'b 010,
		OP_SUB  = 3'b 011,
		OP_SUBI = 3'b 100,
		OP_MUL  = 3'b 101,
		OP_CLR  = 3'b 110,
		OP_DPL  = 3'b 111;

    integer i;
	 initial begin
		//Opcode = 4'd0;
		//regDisp = 4'd1;
		/*
		numDisp[5] = "+";
		numDisp[4] = "0";
		numDisp[3] = "0";
		numDisp[2] = "0";
		numDisp[1] = "0";
		numDisp[0] = "0";*/
		
		message[0] = "-";
		message[1] = "-";
		message[2] = "-";
		message[3] = "-";
		message[4] = " ";
		message[5] = " ";
		message[6] = " ";
		message[7] = " ";
		message[8] = " ";
		message[9] = " "; 
		message[10] = "["; //esses 4 espacos sao p o reg
		message[11] = "-";
		message[12] = "-";
		message[13] = "-";
		message[14] = "-"; //valor fix
		message[15] = "]"; //'jump'
		message[16] = " ";
		message[17] = " ";
		message[18] = " ";
		message[19] = " ";
		message[20] = " ";
		message[21] = " ";
		message[22] = " ";
		message[23] = " ";
		message[24] = " ";
		message[25] = " ";
		message[26] = "+"; //daqui p baixo eh o num, com sinal
		message[27] = "0";
		message[28] = "0";
		message[29] = "0";
		message[30] = "0";
		message[31] = "0";
	 end

    
    
	 

    // -----------------------------------------------------------------------
    // Temporizações para escrita de caracteres (ajustar ao clock real)
    // -----------------------------------------------------------------------
    // Exemplo para 50 MHz:
    localparam [31:0] DELAY_WRITE = 32'd2000; // ~40 us
    localparam [31:0] DELAY_PULSE = 32'd50;   // ~1 us
    localparam [31:0] DELAY_JUMP = 32'd2500;
	 
	 //cmd pro jump de linha
	 localparam [7:0] CMD_CURSOR_JUMP = 8'b11000001; //colocando p o endreco seguinte pq ta com algum bug na escrita do caracter

    // -----------------------------------------------------------------------
    // Estados da FSM principal
    // -----------------------------------------------------------------------
    localparam [2:0]
        S_WAIT_INIT  = 3'd0,
        S_PREPARE    = 3'd1,
        S_PULSE_E    = 3'd2,
        S_WAIT       = 3'd3,
        S_DONE       = 3'd4,
        S_JUMP       = 3'd5;
		  

    reg [2:0]  state, next_state;
    reg [31:0] delay_cnt, next_delay_cnt;
    reg [4:0]  msg_index, next_msg_index; // até 31 caracteres
	 

    // =======================================================================
    // 1) BLOCO SEQUENCIAL: registra estado, contador e índice da mensagem
    // =======================================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state      <= S_WAIT_INIT;
            delay_cnt  <= 32'd0;
            msg_index  <= 5'd0;
        end else begin
            state      <= next_state;
            delay_cnt  <= next_delay_cnt;
            msg_index  <= next_msg_index;
        end
    end

    // =======================================================================
    // 2) BLOCO COMBINACIONAL: cálculo do próximo estado/contador/índice
    // =======================================================================
    always @(*) begin
        // valores padrão
        next_state     = state;
        next_delay_cnt = delay_cnt;
        next_msg_index = msg_index;
		if(rst) begin
		case(Opcode)
			OP_LOAD: begin
				message[0] = "L";
				message[1] = "O";
				message[2] = "A";
				message[3] = "D";
			end
			OP_ADD: begin
				message[0] = "A";
				message[1] = "D";
				message[2] = "D";
				message[3] = " ";
			end
			OP_ADDI: begin
				message[0] = "A";
				message[1] = "D";
				message[2] = "D";
				message[3] = "I";
			end
			OP_SUB: begin
				message[0] = "S";
				message[1] = "U";
				message[2] = "B";
				message[3] = " ";
			end
			OP_SUBI: begin
				message[0] = "S";
				message[1] = "U";
				message[2] = "B";
				message[3] = "I";
			end
			OP_MUL: begin
				message[0] = "M";
				message[1] = "U";
				message[2] = "L";
				message[3] = " ";
			end
			OP_CLR: begin
				message[0] = "C";
				message[1] = "L";
				message[2] = "R";
				message[3] = " ";
			end
			OP_DPL: begin
				message[0] = "D";
				message[1] = "P";
				message[2] = "L";
				message[3] = " ";
			end
			default: begin
				message[0] = "-";
				message[1] = "-";
				message[2] = "-";
				message[3] = "-";
			end
		endcase
        //colocando as outras saidas que nao dependem do op code reg ->10 - 13
        message[11] = regDisp[3];
		  message[12] = regDisp[2]; 
		  message[13] = regDisp[1]; 
		  message[14] = regDisp[0];
        //colocando o num -> 26 - 31
        message[26] = numDisp[5];
        message[27] = numDisp[4]; 
		  message[28] = numDisp[3]; 
		  message[29] = numDisp[2]; 
		  message[30] = numDisp[1]; 
		  message[31] = numDisp[0];
	  end
        case (state)
            // ---------------------------------------------------------------
            // Espera a inicialização do LCD ser concluída
            // ---------------------------------------------------------------
            S_WAIT_INIT: begin
                if (init_done) begin
                    next_state     = S_PREPARE;
                    next_msg_index = 5'd0;
                end
            end

            // ---------------------------------------------------------------
            // Prepara para escrever o caractere atual
            // ---------------------------------------------------------------
            S_PREPARE: begin
                // apenas configura o próximo estado e o delay para o pulso
                next_state     = S_PULSE_E;
                next_delay_cnt = DELAY_PULSE;
            end

            // ---------------------------------------------------------------
            // Gera pulso de Enable
            // ---------------------------------------------------------------
            S_PULSE_E: begin
                if (delay_cnt > 0) begin
                    next_delay_cnt = delay_cnt - 1;
                end else begin
                    next_state     = S_WAIT;
                    next_delay_cnt = DELAY_WRITE;
                end
            end

            // ---------------------------------------------------------------
            // Espera o tempo de escrita do caractere
            // ---------------------------------------------------------------
            S_WAIT: begin
                if (delay_cnt > 0) begin
                    next_delay_cnt = delay_cnt - 1;
                end else begin
						  if(msg_index==(MSG_LEN/2) -1) begin
								next_state = S_JUMP;
								next_delay_cnt = DELAY_JUMP;
								next_msg_index = msg_index + 1;
						  end else if (msg_index == (MSG_LEN-1)) begin
                        next_state = S_DONE;
                    end else begin
                        next_msg_index = msg_index + 1;
                        next_state     = S_PREPARE;
                    end
                end
            end

            // ---------------------------------------------------------------
            // Mensagem completa
            // ---------------------------------------------------------------
            S_DONE: begin
                // Permanece nesse estado até reset
                next_state = S_DONE;
            end
				S_JUMP: begin
					if (delay_cnt > 0) begin
                    next_delay_cnt = delay_cnt - 1;
					end else begin
						next_state = S_PREPARE;
					end
				end

            default: begin
                next_state     = S_WAIT_INIT;
                next_delay_cnt = 32'd0;
                next_msg_index = 5'd0;
            end
        endcase
    end

    // =======================================================================
    // 3) BLOCO COMBINACIONAL: geração das saídas
    //     - start_init
    //     - sinais de escrita (wr_rs, wr_rw, wr_e, wr_data)
// =======================================================================
    reg [7:0] wr_data;
    reg       wr_rs;
    reg       wr_rw;
    reg       wr_e;

    always @(*) begin
        // -------------------------------------------------------------------
        // 3.1) Controle de quem controla os sinais do LCD
        // -------------------------------------------------------------------

        // start_init: fica em '1' enquanto estamos esperando a inicialização.
        // O módulo lcd_init só usa o nível de start para sair do IDLE.
        start_init = (state == S_WAIT_INIT) ? 1'b1 : 1'b0;

        // -------------------------------------------------------------------
        // 3.2) Sinais de escrita do controlador principal
        // -------------------------------------------------------------------
        // Default
        wr_data = 8'h00;
        wr_rs   = 1'b0;
        wr_rw   = 1'b0;
        wr_e    = 1'b0;

        case (state)
            // Durante a escrita da mensagem, usamos os caracteres da array
            S_PREPARE: begin
					 wr_rs   = 1'b1; // dado (caractere)
                wr_data <= message[msg_index];
                wr_rw   = 1'b0; // escrita
                wr_e    = 1'b0;
            end

            S_PULSE_E: begin
                wr_data = message[msg_index];
                wr_rs   = 1'b1;
                wr_rw   = 1'b0;
                wr_e    = 1'b1; // pulso de enable
            end
				
				S_JUMP:begin
					 wr_data = CMD_CURSOR_JUMP;
                wr_rs   = 1'b0;
                wr_rw   = 1'b0;
                wr_e    = 1'b1; 
				end

            S_WAIT: begin
                wr_data = message[msg_index];
                wr_rs   = 1'b1;
                wr_rw   = 1'b0;
                wr_e    = 1'b0;
            end

            S_DONE: begin
                // mensagem já escrita — manter sinais em estado "neutro"
                wr_rs = 1'b0;
                wr_rw = 1'b0;
                wr_e  = 1'b0;
                // wr_data pode permanecer com o último valor ou 0
            end

            default: begin
                // outros estados: controlador principal não mexe no LCD
                wr_rs = 1'b0;
                wr_rw = 1'b0;
                wr_e  = 1'b0;
                wr_data = 8'h00;
            end
        endcase
    end
	 
endmodule