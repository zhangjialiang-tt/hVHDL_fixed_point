package body division_pkg is

    constant nr_radix : integer := int_word_length-2;

------------------------------------------------------------------------
    procedure create_division
    (
        signal hw_multiplier : inout multiplier_record;
        signal division : inout division_record
    ) is
    --------------------------------------------------
        alias m is division;
    --------------------------------------------------
    begin
        
            CASE m.division_process_counter is
                WHEN 0 =>
                    multiply(hw_multiplier, m.x, m.number_to_be_reciprocated);
                    m.division_process_counter <= m.division_process_counter + 1;
                WHEN 1 =>
                    increment_counter_when_ready(hw_multiplier,m.division_process_counter);
                    if multiplier_is_ready(hw_multiplier) then
                        multiply(hw_multiplier, m.x, invert_bits(get_multiplier_result(hw_multiplier, nr_radix)));
                    end if;
                WHEN 2 =>
                    if multiplier_is_ready(hw_multiplier) then
                        m.x <= get_multiplier_result(hw_multiplier, nr_radix);
                        if m.number_of_newton_raphson_iteration /= 0 then
                            m.number_of_newton_raphson_iteration <= m.number_of_newton_raphson_iteration - 1;
                            m.division_process_counter <= 0;
                        else
                            m.division_process_counter <= m.division_process_counter + 1;
                            multiply(hw_multiplier, get_multiplier_result(hw_multiplier, nr_radix), m.dividend);
                            m.check_division_to_be_ready <= true;
                        end if;
                    end if;
                WHEN others => -- wait for start
                    if multiplier_is_ready(hw_multiplier) then
                        m.check_division_to_be_ready <= false;
                    end if;
            end CASE;
    end create_division;

------------------------------------------------------------------------
    procedure request_division
    (
        signal division : out division_record;
        number_to_be_divided : int;
        number_to_be_reciprocated : int;
        iterations : range_of_nr_iteration
    ) is
    begin
        division.x                                  <= get_initial_value_for_division(remove_leading_zeros(number_to_be_reciprocated));
        division.number_to_be_reciprocated          <= remove_leading_zeros(number_to_be_reciprocated);
        division.dividend                           <= number_to_be_divided;
        division.divisor                            <= number_to_be_reciprocated;
        division.division_process_counter           <= 0;
        division.number_of_newton_raphson_iteration <= iterations - 1;
    end request_division;
------------------------------------------------------------------------
    procedure request_division
    (
        signal division : out division_record;
        number_to_be_divided : int;
        number_to_be_reciprocated : int
    ) is
    begin
        request_division(division, number_to_be_divided, number_to_be_reciprocated, 1);
    end request_division;
------------------------------------------------------------------------
    function division_is_ready
    (
        division_multiplier : multiplier_record;
        division : division_record
    )
    return boolean
    is
        variable returned_value : boolean;
    begin
        if division.check_division_to_be_ready then
            returned_value := multiplier_is_ready(division_multiplier);
        else
            returned_value := false;
        end if;
        
        return returned_value;

    end division_is_ready;
------------------------------------------------------------------------ 

    function division_is_busy
    (
        division : in division_record
    )
    return boolean
    is
    begin
        return division.division_process_counter /= 3;
    end division_is_busy;
------------------------------
    function division_is_not_busy
    (
        division : in division_record
    )
    return boolean
    is
    begin
        return not division_is_busy(division);
    end division_is_not_busy;

------------------------------------------------------------------------
    function get_division_result
    (
        multiplier : multiplier_record;
        divisor : natural;
        radix : natural
    )
    return integer
    is
        variable multiplier_result : integer;
        variable multiplier_result2 : integer;
        variable used_radix : integer;

        variable uint_number : unsigned(int_word_length-2 downto 0);
        variable zeroes : natural;

        variable returned_value : integer;
    begin

        used_radix := nr_radix + nr_radix-radix;
        multiplier_result  := get_multiplier_result(multiplier,used_radix);

        for i in integer range int_word_length-2 downto 0 loop
            if divisor < 2**i then
                returned_value := multiplier_result*2**((int_word_length-2)-i);
            end if;
        end loop;

        return returned_value;
        
    end get_division_result;

------------------------------------------------------------------------
    function get_division_result
    (
        multiplier : multiplier_record;
        hw_divider : division_record;
        radix : natural
    )
    return integer
    is
        variable multiplier_result : integer;
        variable returned_value : integer;
    begin
            multiplier_result := get_multiplier_result(multiplier,radix); 
            returned_value := get_division_result(multiplier, abs(hw_divider.divisor), radix);
            if hw_divider.divisor < 0 then
                returned_value := -returned_value;
            end if;

            return returned_value;
        
    end get_division_result;

------------------------------------------------------------------------ 
end package body division_pkg;
