library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_misc.all;
	use ieee.numeric_std.all;

entity leading_zero_counter_8 is
	port (
		input  : in    std_ulogic_vector(7 downto 0);
		offset : out   natural range 0 to 7
	);
end entity leading_zero_counter_8;

architecture rtl of leading_zero_counter_8 is
	signal log_low  : natural range 0 to 3;
	signal log_high : natural range 0 to 3;

	type log_lut_type is array (0 to 15) of natural range 0 to 3;

	constant log_lut : log_lut_type :=
	(
	  0, -- 0000
	  0, -- 0001
	  1, -- 0010
	  1, -- 0011
	  2, -- 0100
	  2, -- 0101
	  2, -- 0110
	  2, -- 0111
	  3, -- 1000
	  3, -- 1001
	  3, -- 1010
	  3, -- 1011
	  3, -- 1100
	  3, -- 1101
	  3, -- 1110
	  3  -- 1111
	);
begin
	log_low  <= log_lut(to_integer(unsigned(input(3 downto 0))));
	log_high <= log_lut(to_integer(unsigned(input(7 downto 4))));
	offset   <= log_low when input(7 downto 4) = "0000" else
	            to_integer(unsigned('1' & std_ulogic_vector(to_unsigned(log_high, 2))));
end architecture rtl;
