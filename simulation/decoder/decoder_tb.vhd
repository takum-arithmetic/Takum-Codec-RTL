library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity decoder_tb is
	generic (
		n : natural range 2 to natural'high := 16
	);
end entity decoder_tb;

architecture behave of decoder_tb is
	signal clock                       : std_ulogic;
	signal takum                       : std_ulogic_vector(n - 1 downto 0) := (others => '0');
	signal sign                        : std_ulogic;
	signal sign_reference              : std_ulogic;
	signal logarithmic_value           : std_ulogic_vector(n + 3 downto 0); -- 9 bits integer, n-5 bits fractional
	signal logarithmic_value_reference : std_ulogic_vector(n + 3 downto 0); -- 9 bits integer, n-5 bits fractional
	signal is_zero                     : std_ulogic;
	signal is_zero_reference           : std_ulogic;
	signal is_nar                      : std_ulogic;
	signal is_nar_reference            : std_ulogic;
	signal precision                   : natural range 0 to n - 5;
	signal precision_reference         : natural range 0 to n - 5;

	constant takum_end : std_ulogic_vector(n - 1 downto 0) := (others => '1');
	function ulogic_vector_to_string (
		input: std_ulogic_vector
	) return string is
		variable output       : string (1 to input'length) := (others => NUL);
		variable output_index : integer                    := 1;
	begin
		for i in input'range loop
			output(output_index) := std_ulogic'image(input((i)))(2);
			output_index         := output_index + 1;
		end loop;

		return output;
	end function;

begin

	-- UUT instantiation
	decoder : entity work.decoder(rtl)
		generic map (
			n => n
		)
		port map (
			takum             => takum,
			sign              => sign,
			logarithmic_value => logarithmic_value,
			precision         => precision,
			is_zero           => is_zero,
			is_nar            => is_nar
		);

	-- Reference unit instantiation
	decoder_reference : entity work.decoder(behave)
		generic map (
			n => n
		)
		port map (
			takum             => takum,
			sign              => sign_reference,
			logarithmic_value => logarithmic_value_reference,
			precision         => precision_reference,
			is_zero           => is_zero_reference,
			is_nar            => is_nar_reference
		);

	drive_clock : process is
	begin
		while takum /= takum_end loop
			clock <= '0';
			wait for 10 ns;
			clock <= '1';
			wait for 10 ns;
		end loop;

		wait;
	end process drive_clock;

	check_results_and_increment_takum : process (clock) is
	begin
		if rising_edge(clock) then
			assert sign = sign_reference
				report ulogic_vector_to_string(takum) &
				       ": sign mismatch (rtl sign=" &
				       std_ulogic'image(sign) &
				       ", behave sign=" &
				       std_ulogic'image(sign_reference) &
				       ")"
				severity error;
			assert logarithmic_value = logarithmic_value_reference
				report ulogic_vector_to_string(takum) &
				       ": logarithmic value mismatch (rtl logarithmic_value=" &
				       ulogic_vector_to_string(logarithmic_value) &
				       ", behave logarithmic_value=" &
				       ulogic_vector_to_string(logarithmic_value_reference) &
				       ")"
				severity error;
			assert is_zero = is_zero_reference
				report ulogic_vector_to_string(takum) &
				       ": is_zero mismatch (rtl is_zero=" &
				       std_ulogic'image(is_zero) &
				       ", behave is_zero=" &
				       std_ulogic'image(is_zero_reference) &
				       ")"
				severity error;
			assert is_nar = is_nar_reference
				report ulogic_vector_to_string(takum) &
				       ": is_nar mismatch (rtl is_nar=" &
				       std_ulogic'image(is_nar) &
				       ", behave is_nar=" &
				       std_ulogic'image(is_nar_reference) &
				       ")"
				severity error;
			assert precision = precision_reference
				report ulogic_vector_to_string(takum) &
				       ": precision mismatch (rtl precision=" &
				       natural'image(precision) &
				       ", behave precision=" &
				       natural'image(precision_reference) &
				       ")"
				severity error;

			takum <= std_ulogic_vector(unsigned(takum) + 1);
		end if;
	end process check_results_and_increment_takum;

end architecture behave;