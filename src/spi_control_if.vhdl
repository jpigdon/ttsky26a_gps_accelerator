library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi_control_if is
    generic(
        OUTPUT_DATA_WIDTH : integer := 16;
        INPUT_DATA_WIDTH : integer := 16;
        ADDR_WIDTH : integer := 5
    );
    port (

        spi_dom_csn : in std_logic;
        spi_dom_miso : out std_logic;
        spi_dom_mosi : in std_logic;
        spi_dom_clk : in std_logic;
        
        read_op_req : out std_logic;
        read_update_strobe : in std_logic;
        write_op_strobe : out std_logic;

        op_addr : out std_logic_vector(ADDR_WIDTH-1 downto 0);

        write_op_data : out std_logic_vector(OUTPUT_DATA_WIDTH-1 downto 0);
        read_op_data : in std_logic_vector(OUTPUT_DATA_WIDTH-1 downto 0);

        reset   : in  std_logic;        
        clk     : in  std_logic
    );
end spi_control_if;

architecture Behavioral of spi_control_if is


begin


end Behavioral;