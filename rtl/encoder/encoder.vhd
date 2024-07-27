library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_misc.all;
	use ieee.numeric_std.all;

entity encoder is
	generic (
		n : natural range 2 to natural'high := 16
	);
	port (
		sign              : in    std_ulogic;
		logarithmic_value : in    std_ulogic_vector(n + 3 downto 0); -- 9 bits integer, n-5 bits fractional
		is_zero           : in    std_ulogic;
		is_nar            : in    std_ulogic;
		takum             : out   std_ulogic_vector(n - 1 downto 0)
	);
end entity encoder;

architecture rtl of encoder is
	signal direction_bit                : std_ulogic;
	signal characteristic_mantissa_bits : std_ulogic_vector(n + 3 downto 0);
	signal characteristic               : integer range -255 to 254;
	signal mantissa_bits                : std_ulogic_vector(n - 6 downto 0);
	signal characteristic_precursor     : std_ulogic_vector(7 downto 0);
	signal regime                       : natural range 0 to 7;
	signal takum_with_rounding_bit      : std_ulogic_vector(n downto 0);
	signal takum_rounded                : std_ulogic_vector(n - 1 downto 0);
	signal round_up_overflows           : std_ulogic;
	signal round_down_underflows        : std_ulogic;
begin
	-- direction bit is 1 when characteristic >= 0 holds
	direction_bit <= not to_signed(characteristic, 9)(8);

	-- negate the logarithmic value depending on the sign to obtain the
	-- characteristic and mantissa bits
	characteristic_mantissa_bits <= logarithmic_value when sign = '0' else
	                                std_ulogic_vector(to_signed(-to_integer(signed(logarithmic_value)), n + 4));
	characteristic               <= to_integer(signed(characteristic_mantissa_bits(n + 3 downto n - 5)));
	mantissa_bits                <= characteristic_mantissa_bits(n - 6 downto 0);

	underflow_overflow_predictor : entity work.underflow_overflow_predictor(rtl)
		generic map (
			n => n
		)
		port map (
			characteristic        => characteristic,
			mantissa_bits         => mantissa_bits,
			round_down_underflows => round_down_underflows,
			round_up_overflows    => round_up_overflows
		);

	determine_characteristic_precursor : block is
		signal characteristic_bits   : std_ulogic_vector(8 downto 0);
		signal characteristic_normal : std_ulogic_vector(7 downto 0);
	begin
		characteristic_bits      <= std_ulogic_vector(to_signed(characteristic, 9));
		characteristic_normal    <= characteristic_bits(7 downto 0) when direction_bit = '1' else
	                            not characteristic_bits(7 downto 0);
		characteristic_precursor <= std_ulogic_vector(to_unsigned(to_integer(unsigned(characteristic_normal)) + 1, 8));
	end block determine_characteristic_precursor;

	leading_zero_counter_8 : entity work.leading_zero_counter_8(rtl)
		port map (
			input  => characteristic_precursor,
			offset => regime
		);

	generate_takum_with_rounding_bit : block is
		signal regime_bits                  : std_ulogic_vector(2 downto 0);
		signal characteristic_bits          : std_ulogic_vector(6 downto 0);
		signal characteristic_mantissa_bits : std_ulogic_vector(n + 1 downto 0);
	begin

		set_regime_and_characteristic_raw_bits : process (direction_bit, regime, characteristic_precursor) is
		begin
			if (direction_bit = '0') then
				regime_bits         <= not std_ulogic_vector(to_unsigned(regime, 3));
				characteristic_bits <= not characteristic_precursor(6 downto 0);
			else
				regime_bits         <= std_ulogic_vector(to_unsigned(regime, 3));
				characteristic_bits <= characteristic_precursor(6 downto 0);
			end if;
		end process set_regime_and_characteristic_raw_bits;

		characteristic_mantissa_bits <= std_ulogic_vector(shift_left(unsigned(std_ulogic_vector'(characteristic_bits & mantissa_bits)),
	                                                             to_integer(unsigned(not std_ulogic_vector(to_unsigned(regime, 3))))));
		takum_with_rounding_bit      <= sign & direction_bit & regime_bits & characteristic_mantissa_bits(n + 1 downto 6);
	end block generate_takum_with_rounding_bit;

	rounder : entity work.rounder(rtl)
		generic map (
			n => n
		)
		port map (
			takum_with_rounding_bit => takum_with_rounding_bit,
			round_up_overflows      => round_up_overflows,
			round_down_underflows   => round_down_underflows,
			takum_rounded           => takum_rounded
		);

	drive_output : process (is_zero, is_nar, takum_rounded) is
	begin
		if (is_zero = '1' or is_nar = '1') then
			takum <= (n - 1 => is_nar, others => '0');
		else
			takum <= takum_rounded;
		end if;
	end process drive_output;

end architecture rtl;
