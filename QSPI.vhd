library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity QSPI is
    generic(
        G_CLK_FREQ    : INTEGER := 25000000;        -- 25MHz PA3 system clk
        G_DELAY       : INTEGER := 20;              -- number of seconds to delay between instructions (this only to give us time to re trigger the oscilloscope)
        G_SIM_MODE    : BOOLEAN := FALSE;
        G_WORD_SIZE   : INTEGER := 8
    );
    port( 
        CLK         : in STD_LOGIC;
        RESETN      : in STD_LOGIC;
        DATA_IN     : in STD_LOGIC_VECTOR(G_WORD_SIZE - 1 downto 0);
        DI_VALID    : in STD_LOGIC; -- must be high for a single pulse so the data can be latched
        QUAD_MODE   : in STD_LOGIC; -- QPI mode. Standard SPI mode when this is low, DQ0 will be MOSI, DQ1 will be MOSI and DQ2 & DQ3 will be in high impedance state
        DQ          : inout STD_LOGIC_VECTOR(3 downto 0);
        SPI_CLK     : out STD_LOGIC;
        CE          : out STD_LOGIC
        );
end QSPI;

architecture Behavioral of QSPI is

    signal spi_data_out         : STD_LOGIC_VECTOR(G_WORD_SIZE - 1 downto 0);
    signal spi_clk_count        : INTEGER range 0 to 31;
    signal spi_busy             : STD_LOGIC;
    signal CE_reg               : STD_LOGIC;

    constant C_CLK_POLARITY     : STD_LOGIC := '0'; -- clk state when not in use. Refer to mode 0 versus mode 3 in IS25LP128 datasheet
    
begin

    CE <= CE_reg;
    SPI_CLK <= not(CLK) when CE_reg = '0' else C_CLK_POLARITY;

    p_clock_counter:  process(CLK) begin
        if(RESETN = '0') then
            spi_clk_count <= 0;
         elsif rising_edge(CLK) then
            if(CE_reg = '0') then
                spi_clk_count <= spi_clk_count + 1;
            else
                spi_clk_count <= 0;
            end if;
         end if;
    end process;

    p_spi_shift_reg : process(CLK) begin
        if(RESETN = '0') then
            DQ(0) <= 'Z';
            DQ(1) <= 'Z';
            DQ(2) <= 'Z';
            DQ(3) <= 'Z';
            spi_data_out <= (OTHERS => '0');
            CE_reg <= '1'; -- active low
            spi_busy <= '0';

         elsif rising_edge(CLK) then -- DQ0 data is loaded on the falling edge so QSPI can latch on the rising edge
            if(DI_VALID = '1' and spi_busy = '0') then -- latch the data
                spi_data_out <= DATA_IN;
                spi_busy <= '1';
            end if;
            if (spi_busy = '1') then
                if(QUAD_MODE = '0') then -- Standard SPI command
                    if(spi_clk_count < G_WORD_SIZE-1) then -- 8 bits to send out               
                        DQ(0) <= spi_data_out(spi_data_out'LEFT); -- MSB out first
                        spi_data_out <= spi_data_out(spi_data_out'LEFT - 1 downto 0) & '0'; -- SHIFT REGISTER
                        CE_reg <= '0';
                    else
                        DQ(0) <= '0';
                        DQ(1) <= 'Z';
                        DQ(2) <= 'Z';
                        DQ(3) <= 'Z';
                        CE_reg <= '1';
                        spi_busy <= '0'; -- done, ready for next byte
                    end if;           
                else -- QPI command
                    if(spi_clk_count <= G_WORD_SIZE/4) then -- 4 bits per clock              
                        DQ(3) <= spi_data_out(G_WORD_SIZE-1);
                        DQ(2) <= spi_data_out(G_WORD_SIZE-2);
                        DQ(1) <= spi_data_out(G_WORD_SIZE-3);
                        DQ(0) <= spi_data_out(G_WORD_SIZE-4);
                        spi_data_out <= spi_data_out(G_WORD_SIZE-5 downto 0) & x"0"; -- quad mode sends 4 bits out on each clock cyle
                    else 
                        DQ(0) <= '0';
                        DQ(1) <= 'Z';
                        DQ(2) <= 'Z';
                        DQ(3) <= 'Z';
                    end if; 
                end if;
            end if;
         end if;
    end process;
    
    
    
end Behavioral;
