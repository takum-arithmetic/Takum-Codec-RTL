library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_misc.all;
	use ieee.numeric_std.all;

entity encoder_linear is
	generic (
		n : natural range 2 to natural'high := 16
	);
	port (
		sign          : in    std_ulogic;
		exponent      : in    integer range -255 to 254;
		fraction_bits : in    std_ulogic_vector(n - 6 downto 0);
		is_zero       : in    std_ulogic;
		is_nar        : in    std_ulogic;
		takum         : out   std_ulogic_vector(n - 1 downto 0)
	);
end entity encoder_linear;

architecture rtl of encoder_linear is
	signal logarithmic_value : std_ulogic_vector(n + 3 downto 0); -- 9 bits integer, n-5 bits fractional
begin
	logarithmic_value <= std_ulogic_vector(to_signed(exponent, 9)) & fraction_bits;

	encoder : entity work.encoder(rtl)
		generic map (
			n => n
		)
		port map (
			sign              => sign,
			logarithmic_value => logarithmic_value,
			is_zero           => is_zero,
			is_nar            => is_nar,
			takum             => takum
		);

end architecture rtl;
