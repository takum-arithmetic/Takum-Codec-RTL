library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_misc.all;
	use ieee.numeric_std.all;

entity decoder_logarithmic is
	generic (
		n : natural range 2 to natural'high := 16
	);
	port (
		takum             : in    std_ulogic_vector(n - 1 downto 0);
		sign              : out   std_ulogic;
		logarithmic_value : out   std_ulogic_vector(n + 3 downto 0); -- 9 bits integer, n-5 bits fractional
		precision         : out   natural range 0 to n - 5;
		is_zero           : out   std_ulogic;
		is_nar            : out   std_ulogic
	);
end entity decoder_logarithmic;

architecture rtl of decoder_logarithmic is
	signal sign_internal                : std_ulogic;
	signal characteristic               : integer range -255 to 254;
	signal mantissa_bits                : std_ulogic_vector(n - 6 downto 0);
	signal characteristic_mantissa_bits : std_ulogic_vector(n + 3 downto 0);
begin

	common_decoder : entity work.common_decoder(rtl)
		generic map (
			n => n
		)
		port map (
			takum          => takum,
			sign           => sign_internal,
			characteristic => characteristic,
			mantissa_bits  => mantissa_bits,
			precision      => precision,
			is_zero        => is_zero,
			is_nar         => is_nar
		);

	-- output sign
	sign <= sign_internal;

	-- negate the concatenated characteristic and mantissa bits depending on the sign to obtain the
	-- logarithmic value
	characteristic_mantissa_bits <= std_ulogic_vector(to_signed(characteristic, 9)) & mantissa_bits;
	logarithmic_value            <= characteristic_mantissa_bits when sign_internal = '0' else
	                                std_ulogic_vector(to_signed(-to_integer(signed(characteristic_mantissa_bits)), n + 4));
end architecture rtl;
