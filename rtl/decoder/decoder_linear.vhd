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
		sign_bit      : out   std_ulogic;
		exponent      : out   integer range -255 to 254;
		fraction_bits : out   std_ulogic_vector(n - 6 downto 0);
		precision     : out   natural range 0 to n - 5;
		is_zero       : out   std_ulogic;
		is_nar        : out   std_ulogic
	);
end entity decoder_linear;

architecture rtl of decoder_linear is
	signal sign_bit_internal : std_ulogic;
	signal characteristic    : integer range -255 to 254;
begin

	predecoder : entity work.predecoder(rtl)
		generic map (
			n => n
		)
		port map (
			takum          => takum,
			sign_bit       => sign_bit_internal,
			characteristic => characteristic,
			mantissa_bits  => fraction_bits,
			precision      => precision,
			is_zero        => is_zero,
			is_nar         => is_nar
		);

	-- output sign
	sign_bit <= sign_bit_internal;

	-- the exponent is defined as (-1)^sign_bit * (characteristic + sign_bit),
	-- which means that it's characteristic for sign_bit=0 and
	-- (-characteristic - 1). However, the latter is just the result
	-- of the bitwise negation of the corresponding two's complement
	-- signed integer.
	exponent <= characteristic when sign_bit_internal = '0' else
	            to_integer(signed(not(std_ulogic_vector(to_signed(characteristic, 9)))));
end architecture rtl;
