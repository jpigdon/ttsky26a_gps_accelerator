library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity acq_and_track_subsystem is
    generic(
        ACCU_WIDTH : integer := 16;
        ACCU_OUTPUT_WIDTH : integer := 8;
        MASTER_COUNT_WIDTH_INT : integer := 10;
        MASTER_COUNT_WIDTH_FRAC : integer := 2;
        GPS_GOLD_TAPS_WIDTH : integer := 10;
        PHASE_ACCU_WIDTH : integer := 12;
        PHASE_COUNT_WIDTH : integer := 8;
        PHASE_INC_WIDTH : integer := 8
    );
    port (
        i_chan : in std_logic;
        q_chan : in std_logic;

        acq_begin : in std_logic;

        phase_inc_start : in std_logic_vector(PHASE_INC_WIDTH-1 downto 0);
        phase_inc_step : in std_logic_vector(PHASE_INC_WIDTH-1 downto 0);
        phase_inc_count : in std_logic_vector(PHASE_COUNT_WIDTH-1 downto 0);
        sv_test_taps: in std_logic_vector(GPS_GOLD_TAPS_WIDTH-1 downto 0);

        acq_busy : out std_logic;
        curr_time_offset_test : out std_logic_vector(GPS_GOLD_TAPS_WIDTH-1 downto 0);
        curr_ph_inc_test : out std_logic_vector(PHASE_INC_WIDTH-1 downto 0);

        i_accu_val : out std_logic_vector(ACCU_OUTPUT_WIDTH-1 downto 0);
        q_accu_val : out std_logic_vector(ACCU_OUTPUT_WIDTH-1 downto 0);

        reset   : in  std_logic;        
        clk     : in  std_logic
    );
end acq_and_track_subsystem;

architecture Behavioral of acq_and_track_subsystem is
    component acquisition_mgmt_sm is
    generic(
        ACCU_WIDTH : integer := 16;
        ACCU_OUTPUT_WIDTH : integer := 8;
        MASTER_COUNT_WIDTH_INT : integer := 10;
        MASTER_COUNT_WIDTH_FRAC : integer := 2;
        GPS_GOLD_TAPS_WIDTH : integer := 10;
        PHASE_ACCU_WIDTH : integer := 12;
        PHASE_COUNT_WIDTH : integer := 8;
        PHASE_INC_WIDTH : integer := 8
    );
    port (
        i_chan : in std_logic;
        q_chan : in std_logic;

        acq_begin : in std_logic;
        timing_period_strobe : in std_logic;

        master_timing_slv : in std_logic_vector(MASTER_COUNT_WIDTH_INT+MASTER_COUNT_WIDTH_FRAC-1 downto 0); --other 

        phase_inc_start : in std_logic_vector(PHASE_INC_WIDTH-1 downto 0);
        phase_inc_step : in std_logic_vector(PHASE_INC_WIDTH-1 downto 0);
        phase_inc_count : in std_logic_vector(PHASE_COUNT_WIDTH-1 downto 0);

        sv_test_taps: in std_logic_vector(GPS_GOLD_TAPS_WIDTH-1 downto 0);

        acq_busy : out std_logic;
        curr_time_offset_test : out std_logic_vector(GPS_GOLD_TAPS_WIDTH-1 downto 0);
        curr_ph_inc_test : out std_logic_vector(PHASE_INC_WIDTH-1 downto 0);

        i_accu_val : out std_logic_vector(ACCU_OUTPUT_WIDTH-1 downto 0);
        q_accu_val : out std_logic_vector(ACCU_OUTPUT_WIDTH-1 downto 0);

        reset   : in  std_logic;        
        clk     : in  std_logic
    );
    end component;

    component master_timing is
    generic(
        OSAMP_RATIO : integer := 4;
        MASTER_COUNT_WIDTH_INT : integer := 10;
        MASTER_COUNT_WIDTH_FRAC : integer := 2;
        MAX_COUNT_INT : integer := 1023
    );
    port (
        master_clock_count : out std_logic_vector(MASTER_COUNT_WIDTH_INT+MASTER_COUNT_WIDTH_FRAC-1 downto 0);
        timing_sof  : out std_logic;
        ena     : in  std_logic;
        clk     : in  std_logic;
        reset   : in  std_logic
    );
    end component; 

    signal timing_period_strobe : std_logic;
    signal master_timing_slv : std_logic_vector(MASTER_COUNT_WIDTH_INT+MASTER_COUNT_WIDTH_FRAC-1 downto 0); --other 

begin

    master_clock : master_timing
        generic map (
            OSAMP_RATIO => 4,
            MASTER_COUNT_WIDTH_INT => MASTER_COUNT_WIDTH_INT,
            MASTER_COUNT_WIDTH_FRAC => MASTER_COUNT_WIDTH_FRAC,
            MAX_COUNT_INT => 1023
        )
        port map(
            master_clock_count => master_timing_slv,
            timing_sof => timing_period_strobe,
            ena => '1',
            clk => clk,
            reset => reset
        );

    
    acq_channel :  acquisition_mgmt_sm
        generic map(
            ACCU_WIDTH => ACCU_WIDTH,
            ACCU_OUTPUT_WIDTH => ACCU_OUTPUT_WIDTH,
            MASTER_COUNT_WIDTH_INT => MASTER_COUNT_WIDTH_INT,
            MASTER_COUNT_WIDTH_FRAC => MASTER_COUNT_WIDTH_FRAC,
            GPS_GOLD_TAPS_WIDTH => GPS_GOLD_TAPS_WIDTH,
            PHASE_ACCU_WIDTH => PHASE_ACCU_WIDTH,
            PHASE_COUNT_WIDTH => PHASE_COUNT_WIDTH,
            PHASE_INC_WIDTH => PHASE_COUNT_WIDTH
        )
        port map(
            i_chan => i_chan,
            q_chan => q_chan,
            acq_begin => acq_begin,
            timing_period_strobe => timing_period_strobe,
            master_timing_slv => master_timing_slv,

            phase_inc_start => phase_inc_start,
            phase_inc_step => phase_inc_step,
            phase_inc_count => phase_inc_step,
            sv_test_taps => sv_test_taps,
            acq_busy => acq_busy,
            curr_time_offset_test => curr_time_offset_test,
            curr_ph_inc_test => curr_ph_inc_test,

            i_accu_val => i_accu_val,
            q_accu_val => q_accu_val,

            reset   => reset,     
            clk     => clk
        );

end Behavioral;