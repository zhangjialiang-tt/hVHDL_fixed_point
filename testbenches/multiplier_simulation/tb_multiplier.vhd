LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
    context vunit_lib.vunit_context;

    use work.multiplier_pkg.all;

entity tb_multiplier is
  generic (runner_cfg : string);
end;

architecture sim of tb_multiplier is

    signal simulator_clock : std_logic;
    signal clocked_reset : std_logic;
    constant clock_per : time := 1 ns;
    constant simtime_in_clocks : integer := 50;

    signal simulation_counter : natural := 0;
    signal multiplier_output : signed(35 downto 0);
    signal multiplier_is_ready_when_1 : std_logic;
    signal int18_multiplier_output : integer := 0;
    signal multiplier_result : integer := 0;

    signal hw_multiplier : multiplier_record := multiplier_init_values;

    type int_array is array (integer range <>) of integer;
    signal input_a_array : int_array(0 to 7) :=(-5  , 16899 , -6589 , 32768 , -32768 , 58295 , -65536, 55555);
    signal output_counter : natural := 0;
    signal result : integer := 0;

    signal output_needs_to_be_checked : boolean := false;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_per;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_per/2.0;

------------------------------------------------------------------------
    clocked_reset_generator : process(simulator_clock)

    begin
        if rising_edge(simulator_clock) then
            create_multiplier(hw_multiplier);

            simulation_counter <= simulation_counter + 1;
            CASE simulation_counter is
                WHEN 0 => multiply(hw_multiplier , input_a_array(0) , 65536);
                WHEN 1 => multiply(hw_multiplier , input_a_array(1) , 65536);
                WHEN 2 => multiply(hw_multiplier , input_a_array(2) , 65536);
                WHEN 3 => multiply(hw_multiplier , input_a_array(3) , 65536);
                WHEN 4 => multiply(hw_multiplier , input_a_array(4) , 65536);
                WHEN 5 => multiply(hw_multiplier , input_a_array(5) , 65536);
                WHEN 6 => multiply(hw_multiplier , input_a_array(6) , 65536);
                WHEN 7 =>
                    simulation_counter <= 7;
                    sequential_multiply(hw_multiplier, input_a_array(7), 65536);
                    if multiplier_is_not_busy(hw_multiplier) then
                        simulation_counter <= 10;
                    end if;

                WHEN others => -- do nothing
            end CASE;
            multiplier_result <= get_multiplier_result(hw_multiplier, 16);
            output_needs_to_be_checked <= false;
            if multiplier_is_ready(hw_multiplier) then
                output_counter <= output_counter + 1;
                int18_multiplier_output <= get_multiplier_result(hw_multiplier,16);
                result <= input_a_array(output_counter) - get_multiplier_result(hw_multiplier,16);
                output_needs_to_be_checked <= true;
            end if; 

            if output_needs_to_be_checked then
                assert abs(result) <= 5 report "got " & integer'image(result);
            end if;

        end if; -- rstn
    end process clocked_reset_generator;	
------------------------------------------------------------------------
end sim;
