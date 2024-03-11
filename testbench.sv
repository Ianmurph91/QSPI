`timescale 1ns / 1ps

module tb();
    logic sys_clk25;
    logic sys_rst25n;
    wire [3:0] DQ; // inout ports need to be connected to wires
    wire SPI_CLK;
    wire CE;
    logic [7:0] data_in, spi_data;
    integer spi_bit_count;
    logic di_valid;
    logic tx_spi_busy, rx_spi_busy;

    initial begin
        sys_clk25 = 0;
        sys_rst25n = 0;
        data_in = 0;
        di_valid = 0;
        spi_data = 0;
        spi_bit_count = 0;
        #200;
        sys_rst25n = 1;
    end

    initial begin
        wait(sys_rst25n == 1);
        @(posedge sys_clk25) begin
            data_in = 'h85;
            di_valid = 1;
        end
        wait(tx_spi_busy == 1); // IMPORTANT! keep data valid high until spi_busy signal goes high, this indcates the input data has been received, then this signal should go low
        @(posedge sys_clk25) begin
            di_valid = 0;
            data_in = 'h00; // dont care the value here
        end

        #500; // wait 500ns then send another byte
        @(posedge sys_clk25) begin
            data_in = 'hA1;
            di_valid = 1;
        end
        wait(tx_spi_busy == 1); // IMPORTANT! keep data valid high until spi_busy signal goes high, this indcates the input data has been received, then this signal should go low
        @(posedge sys_clk25) begin
            di_valid = 0;
            data_in = 'h00; // dont care the value here
        end
    end

    always #20 sys_clk25 = ~sys_clk25; // 25MHz

    QSPI_master #(
        .G_CLK_FREQ(25000000),
        .G_DELAY(20),
        .G_SIM_MODE(1),
        .G_WORD_SIZE(8) // number of bits to send out
    ) QSPI_master_inst ( 
        .CLK(sys_clk25),
        .RESETN(sys_rst25n),
        .DATA_IN(data_in),
        .DI_VALID(di_valid),
        .DO_VALID(),
        .SPI_BUSY(tx_spi_busy),
        .QUAD_MODE(0),
        .DQ(DQ),
        .SPI_CLK(SPI_CLK),
        .CE(CE)
    );

    QSPI_slave #(
        .G_CLK_FREQ(25000000),
        .G_DELAY(20),
        .G_SIM_MODE(1),
        .G_WORD_SIZE(8) // number of bits to send out
    ) QSPI_slave_inst ( 
        .RESETN(sys_rst25n),
        .DATA_IN(data_in),
        .DI_VALID(di_valid),
        .DO_VALID(),
        .SPI_BUSY(rx_spi_busy),
        .QUAD_MODE(0),
        .DQ(DQ),
        .SPI_CLK(SPI_CLK),
        .CE(CE)
    );

    always @(posedge SPI_CLK) begin
        if(CE == 0) begin
            spi_data = {spi_data[6:0], DQ[0]};
        end

    end



endmodule
