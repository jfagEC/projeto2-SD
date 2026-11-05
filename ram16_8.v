module ram16_8(
input  wire [7:0] data,
input  wire [3:0] addr,
input  wire       we,
input  wire       clk,
output wire [7:0] q
);

    // declaracao da memoria RAM
    reg [7:0] ram [15:0];

    // registrador para armazenar o endereço de leitura
    reg [3:0] addr_reg;  // 2^3 = 8 posicoes de memoria
  
    //inicializacao da memoria
    initial begin 
      ram[0] <= 8'h0000;
      ram[1] <= 8'h0001;
      ram[2] <= 8'h0002;
      ram[3] <= 8'h0003;
      ram[4] <= 8'h0004;
      ram[5] <= 8'h0005;
      ram[6] <= 8'h0006;
      ram[7] <= 8'h0007;
		ram[8] <= 8'h0008;
		ram[9] <= 8'h0009;
		ram[10] <= 8'h000A;
		ram[11] <= 8'h000B;
		ram[12] <= 8'h000C;
		ram[13] <= 8'h000D;
		ram[14] <= 8'h000E;
		ram[15] <= 8'h000F;
    end

    always @(posedge clk) begin  //Precisa ser negedge, pois o botão da placa é pull up
        // escrita na memoria
        if (we)
            ram[addr] <= data;

        // registro do endereco de leitura
        addr_reg <= addr;
    end

    // leitura assincrona com base no endereco registrado
    assign q = ram[addr_reg];

endmodule