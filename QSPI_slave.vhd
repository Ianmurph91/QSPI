library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity QSPI_slave is
    generic(
        G_CLK_FREQ    : INTEGER := 25000000;        -- 25MHz PA3 system clk
        G_DELAY       : INTEGER := 20;              -- number of seconds to delay between instructions (this only to give us time to re trigger the oscilloscope)
        G_SIM_MODE    : BOOLEAN := FALSE;
        G_WORD_SIZE   : INTEGER := 8
    );
    port( 
        RESETN      : in STD_LOGIC;
        DATA_IN     : in STD_LOGIC_VECTOR(G_WORD_SIZE - 1 downto 0);
        DI_VALID    : in STD_LOGIC; -- must be high for a single pulse so the data can be latched
        DATA_OUT    : out STD_LOGIC_VECTOR(G_WORD_SIZE - 1 downto 0);
        DO_VALID    : out STD_LOGIC;
        SPI_BUSY    : out STD_LOGIC;
        QUAD_MODE   : in STD_LOGIC; -- QPI mode. Standard SPI mode when this is low, DQ0 will be MOSI, DQ1 will be MOSI and DQ2 & DQ3 will be in high impedance state
        DQ          : inout STD_LOGIC_VECTOR(3 downto 0);
        SPI_CLK     : in STD_LOGIC;
        CE          : in STD_LOGIC
        );
end QSPI_slave;

architecture Behavioral of QSPI_slave is

    signal spi_data_out         : STD_LOGIC_VECTOR(G_WORD_SIZE - 1 downto 0);
    signal spi_data_in          : STD_LOGIC_VECTOR(G_WORD_SIZE - 1 downto 0);
    signal spi_clk_count        : INTEGER range 0 to 31;
    signal data_latched         : STD_LOGIC;
    
begin
    
    SPI_BUSY <= data_latched;
    DATA_OUT <= spi_data_in;

    p_clock_counter:  process(SPI_CLK) begin
        if(RESETN = '0') then
            spi_clk_count <= 0;
         elsif rising_edge(SPI_CLK) then
            if(CE = '0') then
                spi_clk_count <= spi_clk_count + 1;
            else
                spi_clk_count <= 0;
            end if;
         end if;
    end process;

    p_spi_input:  process(SPI_CLK) begin
        if(RESETN = '0') then
            spi_data_in <= (OTHERS => '0');
            DO_VALID <= '0';
         elsif rising_edge(SPI_CLK) then
            if(CE = '0') then
                spi_data_in <= spi_data_in(6 downto 0) & DQ(0); -- Shift left register - DQ0 = MOSI
            end if;
            if(spi_clk_count = G_WORD_SIZE-1) then
                DO_VALID <= '1';
            else
                DO_VALID <= '0';
            end if;
         end if;
    end process;

    p_spi_outout : process(SPI_CLK) begin
        if(RESETN = '0') then
            DQ(0) <= 'Z';
            DQ(1) <= 'Z';
            DQ(2) <= 'Z';
            DQ(3) <= 'Z';
            spi_data_out <= (OTHERS => '0');
            data_latched <= '0';

         elsif rising_edge(SPI_CLK) then
            if(DI_VALID = '1' and data_latched = '0') then -- latch the data
                spi_data_out <= DATA_IN;
                data_latched <= '1';
            end if;
            if (data_latched = '1') then
                if(QUAD_MODE = '0') then -- Standard SPI command
                    if(spi_clk_count < G_WORD_SIZE-1) then -- 8 bits to send out               
                        DQ(1) <= spi_data_out(spi_data_out'LEFT); -- MSB out first - DQ1 = MISO
                        spi_data_out <= spi_data_out(spi_data_out'LEFT - 1 downto 0) & '0'; -- Shift left register
                    else
                        DQ(0) <= '0';
                        DQ(1) <= 'Z';
                        DQ(2) <= 'Z';
                        DQ(3) <= 'Z';
                        data_latched <= '0'; -- done, ready for next byte
                    end if;           
                else -- QPI command
                    if(spi_clk_count < G_WORD_SIZE/4 - 1) then -- 4 bits per clock              
                        DQ(3) <= spi_data_out(G_WORD_SIZE-1);
                        DQ(2) <= spi_data_out(G_WORD_SIZE-2);
                        DQ(1) <= spi_data_out(G_WORD_SIZE-3);
                        DQ(0) <= spi_data_out(G_WORD_SIZE-4);
                        spi_data_out <= spi_data_out(G_WORD_SIZE-5 downto 0) & x"0"; -- quad mode sends 4 bits out on each clock cyle
                    else 
                        DQ(0) <= 'Z';
                        DQ(1) <= 'Z';
                        DQ(2) <= 'Z';
                        DQ(3) <= 'Z';
                        data_latched <= '0'; -- done, ready for next byte
                    end if; 
                end if;
            end if;
         end if;
    end process;
    
end Behavioral;
