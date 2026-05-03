library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity control_system is
    generic(
        OUTPUT_DATA_WIDTH : integer := 16;
        INPUT_DATA_WIDTH : integer := 16;
        ADDR_WIDTH : integer := 5;

        OVERSAMPLE_RATIO : integer := 4;
        ACCU_WIDTH : integer := 16;
        ACCU_OUTPUT_WIDTH : integer := 16;
        MASTER_COUNT_WIDTH_INT : integer := 10;
        MASTER_COUNT_WIDTH_FRAC : integer := 2;
        GPS_GOLD_TAPS_WIDTH : integer := 10;
        PHASE_ACCU_WIDTH : integer := 12;
        PHASE_COUNT_WIDTH : integer := 8;
        PHASE_INC_WIDTH : integer := 8
    );
    port (

        spi_dom_csn : in std_logic;
        spi_dom_miso : out std_logic;
        spi_dom_mosi : in std_logic;
        spi_dom_clk : in std_logic;

        time_interrupt : out std_logic;
        time_pulse : in std_logic;
        
        acq_begin : out std_logic;
        acq_phase_inc_start : out std_logic_vector(PHASE_INC_WIDTH-1 downto 0);
        acq_phase_inc_step : out std_logic_vector(PHASE_INC_WIDTH-1 downto 0);
        acq_phase_inc_count : out std_logic_vector(PHASE_COUNT_WIDTH-1 downto 0);
        acq_sv_test_taps: out std_logic_vector(GPS_GOLD_TAPS_WIDTH-1 downto 0);

        acq_busy : in std_logic;
        acq_curr_time_offset_test : in std_logic_vector(GPS_GOLD_TAPS_WIDTH-1 downto 0);
        acq_curr_ph_inc_test : in std_logic_vector(PHASE_INC_WIDTH-1 downto 0);

        acq_i_accu_val : in std_logic_vector(ACCU_OUTPUT_WIDTH-1 downto 0);
        acq_q_accu_val : in std_logic_vector(ACCU_OUTPUT_WIDTH-1 downto 0);

        reset   : in  std_logic;        
        clk     : in  std_logic
    );
end control_system;

architecture Behavioral of control_system is
    constant COMMAND_ADDR : integer := 0;
    constant ACQ_SV_ADDR : integer := 1;
    constant ACQ_PH_START_ADDR : integer := 2;
    constant ACQ_PH_INC_ADDR : integer := 3;
    constant ACQ_PH_COUNT_ADDR : integer := 4;
    constant ACQ_I_VAL_ADDR : integer := 5;
    constant ACQ_Q_VAL_ADDR : integer := 6;
    constant ACQ_CURR_PINC_ADDR : integer := 7;
    constant ACQ_CURR_TIME_ADDR : integer := 8;

    constant COMMAND_ADDR_ACQ_BEGIN_POS : integer := 1;
    constant COMMAND_ADDR_INT_CLR_POS : integer := 0;

    component spi_control_if is
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
    end component;

    signal spi_read_op_req :  std_logic;
    signal spi_read_update_strobe :  std_logic;
    signal spi_write_op_strobe : std_logic;
    signal spi_op_addr :  std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal spi_op_addr_reg :  std_logic_vector(ADDR_WIDTH-1 downto 0);

    signal spi_write_op_data : std_logic_vector(OUTPUT_DATA_WIDTH-1 downto 0);
    signal spi_read_op_data : std_logic_vector(OUTPUT_DATA_WIDTH-1 downto 0);

    signal acq_phase_inc_start_reg :  std_logic_vector(PHASE_INC_WIDTH-1 downto 0);
    signal acq_phase_inc_step_reg : std_logic_vector(PHASE_INC_WIDTH-1 downto 0);
    signal acq_phase_inc_count_reg : std_logic_vector(PHASE_COUNT_WIDTH-1 downto 0);
    signal acq_sv_test_taps_reg:  std_logic_vector(GPS_GOLD_TAPS_WIDTH-1 downto 0);
    signal interrupt_flag_int : std_logic;
    
begin

    spi_if : spi_control_if
        generic map(
            OUTPUT_DATA_WIDTH => OUTPUT_DATA_WIDTH,
            INPUT_DATA_WIDTH => INPUT_DATA_WIDTH,
            ADDR_WIDTH => ADDR_WIDTH
        )
        port map(
            spi_dom_csn => spi_dom_csn,
            spi_dom_miso => spi_dom_miso,
            spi_dom_mosi => spi_dom_mosi,
            spi_dom_clk => spi_dom_clk,
        
            read_op_req => spi_read_op_req,
            read_update_strobe => spi_read_update_strobe,
            write_op_strobe => spi_write_op_strobe,
            op_addr => spi_op_addr,
            write_op_data => spi_write_op_data,
            read_op_data => spi_read_op_data,
            reset   => reset,
            clk     => clk
        );

    acq_phase_inc_start <= acq_phase_inc_start_reg;
    acq_phase_inc_step <= acq_phase_inc_step_reg;
    acq_phase_inc_count <= acq_phase_inc_count_reg;
    acq_sv_test_taps <= acq_sv_test_taps_reg;
    time_interrupt <= interrupt_flag_int;

    spi_read_op_data <= x"0000" when to_integer(signed(spi_op_addr_reg)) = COMMAND_ADDR else
                        "000000" & acq_sv_test_taps_reg when to_integer(signed(spi_op_addr_reg)) = ACQ_SV_ADDR else
                        x"00" & acq_phase_inc_start_reg when to_integer(signed(spi_op_addr_reg)) = ACQ_PH_START_ADDR else
                        x"00" & acq_phase_inc_step_reg when to_integer(signed(spi_op_addr_reg)) = ACQ_PH_INC_ADDR else
                        x"00" & acq_phase_inc_count_reg when to_integer(signed(spi_op_addr_reg)) = ACQ_PH_COUNT_ADDR else
                        acq_i_accu_val when to_integer(signed(spi_op_addr_reg)) = ACQ_I_VAL_ADDR else
                        acq_q_accu_val when to_integer(signed(spi_op_addr_reg)) = ACQ_Q_VAL_ADDR else
                        x"00" & acq_curr_ph_inc_test when to_integer(signed(spi_op_addr_reg)) = ACQ_CURR_PINC_ADDR else
                        "000000" & acq_curr_time_offset_test when to_integer(signed(spi_op_addr_reg)) = ACQ_CURR_TIME_ADDR else
                        x"0000";

    process(clk, reset) is
    begin
        if(reset = '1') then
            acq_phase_inc_start_reg <= (others => '0');
            acq_phase_inc_step_reg <= (others => '0');
            acq_phase_inc_count_reg <= (others => '0');
            acq_sv_test_taps_reg <= (others => '0');
            spi_op_addr_reg <= (others => '0');
            interrupt_flag_int <= '0';
            spi_read_update_strobe <= '0';
            acq_begin <= '0';
        elsif(rising_edge(clk)) then
            acq_begin <= '0';
            spi_read_update_strobe <= '0';
            if(time_pulse = '1') then
                interrupt_flag_int <= '1';
            end if;

            if(spi_write_op_strobe = '1') then
                --update correct register
                if(to_integer(signed(spi_op_addr)) = COMMAND_ADDR)then
                    if(spi_write_op_data(COMMAND_ADDR_ACQ_BEGIN_POS) = '1') then
                        acq_begin <= '1';
                    end if;
                    if(spi_write_op_data(COMMAND_ADDR_INT_CLR_POS) = '1') then
                        interrupt_flag_int <= '0';
                    end if;
                elsif(to_integer(signed(spi_op_addr)) = ACQ_SV_ADDR) then
                    acq_sv_test_taps_reg <= spi_write_op_data(GPS_GOLD_TAPS_WIDTH-1 downto 0);
                elsif(to_integer(signed(spi_op_addr)) = ACQ_PH_START_ADDR) then
                    acq_phase_inc_start_reg <= spi_write_op_data(PHASE_INC_WIDTH-1 downto 0);
                elsif(to_integer(signed(spi_op_addr)) = ACQ_PH_INC_ADDR) then
                    acq_phase_inc_step_reg <= spi_write_op_data(PHASE_INC_WIDTH-1 downto 0);
                elsif(to_integer(signed(spi_op_addr)) = ACQ_PH_COUNT_ADDR) then
                    acq_phase_inc_count_reg <= spi_write_op_data(PHASE_COUNT_WIDTH-1 downto 0);
                end if;
            elsif(spi_read_op_req = '1') then --address will select the data to be passed back, just needs to stay stable
                spi_op_addr_reg <= spi_op_addr;
                spi_read_update_strobe <= '1';
            end if;
        end if;
    end process;

end Behavioral;
