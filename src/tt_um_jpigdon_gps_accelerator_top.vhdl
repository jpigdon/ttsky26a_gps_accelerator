library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tt_um_jpigdon_gps_accelerator_top is
    port (
        ui_in   : in  std_logic_vector(7 downto 0);
        uo_out  : out std_logic_vector(7 downto 0);
        uio_in  : in  std_logic_vector(7 downto 0);
        uio_out : out std_logic_vector(7 downto 0);
        uio_oe  : out std_logic_vector(7 downto 0);
        ena     : in  std_logic;
        clk     : in  std_logic;
        rst_n   : in  std_logic
    );
end tt_um_jpigdon_gps_accelerator_top;

architecture Behavioral of tt_um_jpigdon_gps_accelerator_top is
    component single_complex_correlator_channel is
    generic(
        ACCU_WIDTH : integer := 16;
        ACCU_OUTPUT_WIDTH : integer := 8;
        GPS_GOLD_TAPS_WIDTH : integer := 10;
        PHASE_ACCU_WIDTH : integer := 12;
        PHASE_INC_WIDTH : integer := 8
    );
    port (
        i_chan : in std_logic;
        q_chan : in std_logic;

        gold_taps_slv : in std_logic_vector(GPS_GOLD_TAPS_WIDTH-1 downto 0);
        gold_load : in std_logic;
        gold_sync : in std_logic;
        gold_ena : in std_logic;

        ph_inc_slv : in  std_logic_vector(PHASE_INC_WIDTH-1 downto 0);
        ph_inc_load : in std_logic;
        nco_reset : in std_logic;
        nco_ena : in std_logic;

        accu_sync : in std_logic;
        accu_ena     : in  std_logic; --general channel enable

        i_accu_val : out std_logic_vector(ACCU_OUTPUT_WIDTH-1 downto 0);
        q_accu_val : out std_logic_vector(ACCU_OUTPUT_WIDTH-1 downto 0);


        reset   : in  std_logic;
        
        clk     : in  std_logic
    );
    end component;
    signal reset_pos_logic : std_logic;
    signal accu_val_i_part : std_logic_vector(7 downto 0);
    signal accu_val_q_part : std_logic_vector(7 downto 0);
    signal output_reg : std_logic_vector(31 downto 0);
    signal input_reg : std_logic_vector(31 downto 0);

    signal input_i_chan : std_logic;
    signal input_q_chan : std_logic;

    signal input_gold_taps_slv : std_logic_vector(9 downto 0);
    signal input_gold_load :  std_logic;
    signal input_gold_sync :  std_logic;
    signal input_gold_ena :  std_logic;

    signal input_ph_inc_slv :  std_logic_vector(7 downto 0);
    signal input_ph_inc_load :  std_logic;
    signal input_nco_reset :  std_logic;
    signal input_nco_enable :  std_logic;

    signal input_accu_sync :  std_logic;
    signal input_accu_ena     :   std_logic; --general channel enable

begin
    reset_pos_logic <= not rst_n;

    input_i_chan <= ui_in(0); -- these are real pins, connect them here
    input_q_chan <= ui_in(0);
    uio_out(7 downto 1) <= (others=> '0');
    uo_out <= (others => '0');
    uio_oe <= (others => '0');

    --shift register based configuration loading
    --this is just fake to stop everything being synthesisted out
    --pins as as follows, clk to shift everything
    --uio_in(0) for sr data input
    --uin_in(1) to latch output data
    --uio_out(0) for outputdata

    process(clk) is
    begin
        if(rising_edge(clk)) then
            if(reset_pos_logic = '0') then
                input_reg <= (others => '0');
            else
                input_reg <= input_reg(30 downto 0) & uio_in(0);
            end if;
        end if;
    end process;

    process(clk) is
    begin
        if(rising_edge(clk)) then
            if(reset_pos_logic = '0') then
                output_reg <= (others => '0');
            else
                if(uio_in(1) = '1') then
                    output_reg <= x"0000" & accu_val_i_part & accu_val_q_part;
                else
                    output_reg <= output_reg(30 downto 0) & '0';
                end if;
            end if;
        end if;
    end process;

    uio_out(0) <= output_reg(0);

    input_gold_taps_slv <= input_reg(9 downto 0);
    input_gold_load  <= input_reg(10);
    input_gold_sync  <= input_reg(11);
    input_gold_ena  <= input_reg(12);
    input_ph_inc_slv <= input_reg(31 downto 24);
    input_ph_inc_load  <= input_reg(12);
    input_nco_reset  <= input_reg(13);
    input_nco_enable  <= input_reg(14);
    input_accu_sync <= input_reg(15);
    input_accu_ena  <= input_reg(16);


    
    corl_inst : single_complex_correlator_channel
        generic map(
            ACCU_WIDTH => 16,
            GPS_GOLD_TAPS_WIDTH => 10,
            PHASE_ACCU_WIDTH => 12,
            PHASE_INC_WIDTH => 8
        )
        port map(
            i_chan => input_i_chan,
            q_chan => input_q_chan,

            gold_taps_slv => input_gold_taps_slv,
            gold_load => input_gold_load,
            gold_sync => input_gold_sync,
            gold_ena => input_gold_ena,

            ph_inc_slv => input_ph_inc_slv,
            ph_inc_load => input_ph_inc_load,
            nco_reset => input_nco_reset,
            nco_ena => input_nco_enable,

            accu_sync => input_accu_sync,
            accu_ena  => input_accu_ena,

            i_accu_val => accu_val_i_part,
            q_accu_val => accu_val_q_part,

            reset => reset_pos_logic,
            clk => clk
        );


end Behavioral;