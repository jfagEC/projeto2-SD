module memory(
input  wire [15:0] data,
input  wire [3:0] addr,
input  wire       we, //enable de leitura
input  wire       clk,
output wire [15:0] q
);

    // declaracao da memoria
    reg [15:0] ram [15:0];

    // registrador para o endereco atual
    reg [3:0] addr_reg; 
  
    //inicializacao da memoria em valores default
    initial begin 
        ram[0] <= 16'd0;
        ram[1] <= 16'd0;
        ram[2] <= 16'd0;
        ram[3] <= 16'd0;
        ram[4] <= 16'd0;
        ram[5] <= 16'd0;
        ram[6] <= 16'd0;
        ram[7] <= 16'd0;
        ram[8] <= 16'd0;
        ram[9] <= 16'd0;
        ram[10] <= 16'd0;
        ram[11] <= 16'd0;
        ram[12] <= 16'd0;
        ram[13] <= 16'd0;
        ram[14] <= 16'd0;
        ram[15] <= 16'd0;
    end

    always @(posedge clk) begin  //fica posedge p so atualizar quando soltar o botao
        if (we)
            ram[addr] <= data;

        // atualiza o endereco de leitura
        addr_reg <= addr;
    end

    // atualizacao da saida q em paralelo
    assign q = ram[addr_reg];

endmodule