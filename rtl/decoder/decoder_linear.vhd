library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_misc.all;
	use ieee.numeric_std.all;

entity decoder_linear is
	generic (
		n : natural range 2 to natural'high := 16
	);
	port (
		takum         : in    std_ulogic_vector(n - 1 downto 0);
		sign          : out   std_ulogic;
		exponent      : out   integer range -255 to 254;
		fraction_bits : out   std_ulogic_vector(n - 6 downto 0);
		precision     : out   natural range 0 to n - 5;
		is_zero       : out   std_ulogic;
		is_nar        : out   std_ulogic
	);
end entity decoder_linear;

architecture rtl of decoder_linear is
	signal logarithmic_value : std_ulogic_vector(n + 3 downto 0); -- 9 bits integer, n-5 bits fractional
begin

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

	exponent      <= to_integer(signed(logarithmic_value(n + 3 downto n - 5)));
	fraction_bits <= logarithmic_value(n - 6 downto 0);
end architecture rtl;
