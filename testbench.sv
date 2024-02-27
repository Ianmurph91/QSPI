`timescale 1ns / 1ps

module tb();
    logic sys_clk25;
    logic sys_rst25n;
    wire [3:0] DQ0; // inout ports need to be connected to wires
    logic SPI_CLK, CE;
    logic [7:0] data_in;
    logic di_valid;
    logic spi_busy;
    
    initial begin
        sys_clk25 = 0;
        sys_rst25n = 0;
        data_in = 0;
        di_valid = 0;
        #200;
        sys_rst25n = 1;
        @(posedge sys_clk25) begin
            di_valid = 1;
            data_in = 'h85;
        end
        wait(spi_busy == 1) di_valid = 0; // keep data valid high until spi_busy signal goes high, this indcates the input data has been received
    end

    always #20 sys_clk25 = ~sys_clk25; // 25MHz
    
    QSPI #(
        .G_CLK_FREQ(25000000),
        .G_DELAY(20),
        .G_SIM_MODE(1),
        .G_WORD_SIZE(8) // number of bits to send out
    ) QSPI_inst ( 
        .CLK(sys_clk25),
        .RESETN(sys_rst25n),
        .DATA_IN(data_in),
        .DI_VALID(di_valid),
        //.SPI_BUSY(spi_busy),
        .QUAD_MODE(0),
        .DQ(DQ),
        .SPI_CLK(SPI_CLK),
        .CE(CE)
    );
    
    
endmodule
