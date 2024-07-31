library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity common_encoder_tb is
	generic (
		n : natural range 2 to natural'high := 16
	);
end entity common_encoder_tb;

architecture behave of common_encoder_tb is
	signal clock                    : std_ulogic;
	signal takum                    : std_ulogic_vector(n - 1 downto 0) := (others => '0');
	signal takum_output             : std_ulogic_vector(n - 1 downto 0);
	signal sign                     : std_ulogic;
	signal characteristic           : integer range -255 to 254;
	signal mantissa_bits            : std_ulogic_vector(n - 6 downto 0);
	signal is_zero                  : std_ulogic;
	signal is_nar                   : std_ulogic;
	signal precision                : natural range 0 to n - 5;

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

	-- decoder instantiation, which we test separately and can assume
	-- here to be correct
	decoder : entity work.common_decoder(rtl)
		generic map (
			n => n
		)
		port map (
			takum          => takum,
			sign           => sign,
			characteristic => characteristic,
			mantissa_bits  => mantissa_bits,
			precision      => precision,
			is_zero        => is_zero,
			is_nar         => is_nar
		);

	-- UUT instantiation
	encoder : entity work.common_encoder(rtl)
		generic map (
			n => n
		)
		port map (
			sign           => sign,
			characteristic => characteristic,
			mantissa_bits  => mantissa_bits,
			is_zero        => is_zero,
			is_nar         => is_nar,
			takum          => takum_output
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
			assert takum = takum_output
				report ulogic_vector_to_string(takum) &
				       "!=" &
				       ulogic_vector_to_string(takum_output)
				       severity error;

			takum <= std_ulogic_vector(unsigned(takum) + 1);
		end if;
	end process check_results_and_increment_takum;

end architecture behave;
