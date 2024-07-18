library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_misc.all;
	use ieee.numeric_std.all;

entity rounder is
	generic (
		n : natural range 2 to natural'high
	);
	port (
		takum_with_rounding_bit : in    std_ulogic_vector(n downto 0);
		round_up_overflows      : in    std_ulogic;
		round_down_underflows   : in    std_ulogic;
		takum_rounded           : out   std_ulogic_vector(n - 1 downto 0)
	);
end entity rounder;

architecture rtl of rounder is
	signal takum_rounded_up   : std_ulogic_vector(n - 1 downto 0);
	signal takum_rounded_down : std_ulogic_vector(n - 1 downto 0);
begin
	takum_rounded_up   <= std_ulogic_vector(to_unsigned(to_integer(unsigned(takum_with_rounding_bit(n downto 1))) + 1, n));
	takum_rounded_down <= takum_with_rounding_bit(n downto 1);

	takum_rounded <= takum_rounded_up when (round_up_overflows = '0' and (takum_with_rounding_bit(0) = '1' or round_down_underflows = '1')) else
	                 takum_rounded_down;
end architecture rtl;
