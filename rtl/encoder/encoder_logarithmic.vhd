library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_misc.all;
	use ieee.numeric_std.all;

entity encoder_logarithmic is
	generic (
		n : natural range 2 to natural'high := 64
	);
	port (
		sign              : in    std_ulogic;
		logarithmic_value : in    std_ulogic_vector(n + 3 downto 0); -- 9 bits integer, n-5 bits fractional
		is_zero           : in    std_ulogic;
		is_nar            : in    std_ulogic;
		takum             : out   std_ulogic_vector(n - 1 downto 0)
	);
end entity encoder_logarithmic;

architecture rtl of encoder_logarithmic is
	-- signal characteristic                 : integer range -255 to 254;
	-- signal mantissa_bits                  : std_ulogic_vector(n - 6 downto 0);
	signal characteristic_mantissa_bits : std_ulogic_vector(n + 3 downto 0);
begin
	-- negate the logarithmic value depending on the sign to obtain the
	-- characteristic and mantissa bits
	characteristic_mantissa_bits <= logarithmic_value when sign = '0' else
	                                std_ulogic_vector(to_signed(-to_integer(signed(logarithmic_value)), n + 4));

	common_encoder : entity work.common_encoder(rtl)
		generic map (
			n => n
		)
		port map (
			sign           => sign,
			characteristic => to_integer(signed(characteristic_mantissa_bits(n + 3 downto n - 5))),
			mantissa_bits  => characteristic_mantissa_bits(n - 6 downto 0),
			is_zero        => is_zero,
			is_nar         => is_nar,
			takum          => takum
		);

end architecture rtl;
