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
        read_op_data : in std_logic_vector(INPUT_DATA_WIDTH-1 downto 0);

        reset   : in  std_logic;        
        clk     : in  std_logic
    );
end spi_control_if;

architecture Behavioral of spi_control_if is
    constant SPI_SR_LENGTH : integer := 32;
    constant ADDR_POS : integer :=  8; --read_write make up the first 8 bits
    constant WRITEDATA_POS : integer := 24; --when writing, start acting on the transaction after 24 bits in (leaving 8 clocks for CDC)
    constant READDATA_POS : integer := 8; --when reading, start acting on the transaction after 8 bits in (leaving 8 clocks for CDC)


    component handshake_synchronizer is
    generic (
        STAGES : natural := 2; --# Number of flip-flops in the synchronizer
        RESET_ACTIVE_LEVEL : std_ulogic := '1' --# Asynch. reset control level
    );
    port (
        -- {{clocks|}}
        Clock_tx : in std_ulogic; --# Transmitting domain clock
        Reset_tx : in std_ulogic; --# Asynchronous reset for Clock_tx

        Clock_rx : in std_ulogic; --# Receiving domain clock
        Reset_rx : in std_ulogic; --# Asynchronous reset for Clock_rx


        -- {{data|Send port}}
        Tx_data   : in std_ulogic_vector; --# Data to send
        Send_data : in std_ulogic;  --# Control signal to send new data
        Sending   : out std_ulogic; --# Active while TX is in process
        Data_sent : out std_ulogic; --# Flag to indicate TX completion

        -- {{Receive port}}
        Rx_data  : out std_ulogic_vector; --# Data received in clock_rx domain
        New_data : out std_ulogic   --# Flag to indicate new data
    );
    end component;

    signal spi_dom_write_msg : std_logic_vector(OUTPUT_DATA_WIDTH+ADDR_WIDTH downto 0); --upper bit has read/write
    signal sample_dom_write_msg : std_logic_vector(OUTPUT_DATA_WIDTH+ADDR_WIDTH downto 0); --upper bit has read/write

    signal spi_dom_read_msg : std_logic_vector(INPUT_DATA_WIDTH-1 downto 0);
    signal sample_dom_read_msg : std_logic_vector(INPUT_DATA_WIDTH-1 downto 0);

    signal spi_dom_send_strobe : std_logic;
    signal spi_dom_sending_status : std_logic;
    signal spi_dom_sent : std_logic;

    signal sample_dom_new_data : std_logic;

    signal sample_dom_send_strobe : std_logic;
    signal sample_dom_sending_status : std_logic;
    signal sample_dom_sent : std_logic;

    signal spi_dom_new_data : std_logic;

    signal spi_sr : std_logic_vector(SPI_SR_LENGTH-1 downto 0);
    signal spi_bit_counter : integer range 0 to SPI_SR_LENGTH-1;
    signal spi_write_op : std_logic;

begin

    spi_dom_to_sample_sync : handshake_synchronizer
        generic map(
            STAGES => 2,
            RESET_ACTIVE_LEVEL => '1'
        )
        port map(
            Clock_tx => spi_dom_clk,
            Reset_tx => spi_dom_csn,

            Clock_rx => clk,
            Reset_rx => reset,


            -- {{data|Send port}}
            Tx_data   => spi_dom_write_msg,
            Send_data => spi_dom_send_strobe,
            Sending   => spi_dom_sending_status,
            Data_sent => spi_dom_sent,

            -- {{Receive port}}
            Rx_data  => sample_dom_write_msg,
            New_data => sample_dom_new_data
        );

    sample_dom_to_spi_sync : handshake_synchronizer
        generic map(
            STAGES => 2,
            RESET_ACTIVE_LEVEL => '1'
        )
        port map(
            Clock_tx => clk,
            Reset_tx => reset,

            Clock_rx => spi_dom_clk,
            Reset_rx => spi_dom_csn,


            -- {{data|Send port}}
            Tx_data   => sample_dom_read_msg,
            Send_data => sample_dom_send_strobe,
            Sending   => sample_dom_sending_status,
            Data_sent => sample_dom_sent,

            -- {{Receive port}}
            Rx_data  => spi_dom_read_msg,
            New_data => spi_dom_new_data
        );

    op_addr <= sample_dom_write_msg(OUTPUT_DATA_WIDTH+ADDR_WIDTH-1 downto OUTPUT_DATA_WIDTH);
    write_op_data <= sample_dom_write_msg(OUTPUT_DATA_WIDTH-1 downto 0);
    write_op_strobe <= sample_dom_new_data and sample_dom_write_msg(OUTPUT_DATA_WIDTH+ADDR_WIDTH);
    read_op_req <= sample_dom_new_data and not sample_dom_write_msg(OUTPUT_DATA_WIDTH+ADDR_WIDTH);


    spi_dom_write_msg <= spi_sr(7) & spi_sr(ADDR_WIDTH-1 downto 0) & x"0000" when spi_write_op = '0' else
                         spi_sr(23) & spi_sr(OUTPUT_DATA_WIDTH+ADDR_WIDTH-1 downto OUTPUT_DATA_WIDTH) & spi_sr(OUTPUT_DATA_WIDTH-1 downto 0);

    --output data process
    process(spi_dom_clk, spi_dom_csn) is
    begin
        if(spi_dom_csn = '1') then
            spi_dom_miso <= '0';
        elsif(falling_edge(spi_dom_clk)) then
            --clock out the right bits
            --this is not right, but try to stop synthsis
            spi_dom_miso <= spi_dom_read_msg(0);
        end if;
    end process;
    --input clock process
    process(spi_dom_clk, spi_dom_csn) is
    begin
        if(spi_dom_csn = '1') then
            spi_sr <= (others => '0');
            spi_bit_counter <= 0;
            spi_dom_send_strobe <= '0';
            spi_write_op <= '0';
        elsif(rising_edge(spi_dom_clk)) then
            spi_dom_send_strobe <= '0';
            if(spi_bit_counter = 0) then
                if(spi_dom_mosi = '1') then
                    spi_write_op <= '1';
                else
                    spi_write_op <= '0';
                end if;
            end if;
            
            if(spi_bit_counter = 0 or (spi_write_op = '1' and spi_bit_counter <= WRITEDATA_POS-1) or (spi_write_op = '0' and spi_bit_counter <= READDATA_POS-1)) then
                spi_sr <= spi_sr(SPI_SR_LENGTH-2 downto 0) & spi_dom_mosi;
            end if;

            if(spi_bit_counter = READDATA_POS-1) then --we're at bit 8, start a read operation, so we have the data by bit 16 for clocking out
                if(spi_write_op = '0') then
                    spi_dom_send_strobe <= '1';
                end if;
            elsif(spi_bit_counter = WRITEDATA_POS-1) then --we're at bit 24 and have all we need for write operation, use 8 bits for actioning
                if(spi_write_op = '1') then
                    spi_dom_send_strobe <= '1';
                end if;
            end if;

            if(spi_bit_counter = SPI_SR_LENGTH-1) then --last bit
                spi_bit_counter <= 0;
            else
                spi_bit_counter <= spi_bit_counter + 1;
            end if;
        end if;
    end process;
end Behavioral;