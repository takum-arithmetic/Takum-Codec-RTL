library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_misc.all;
	use ieee.numeric_std.all;

entity characteristic_determinator is
	port (
		characteristic_raw_bits : in    std_ulogic_vector(6 downto 0);
		antiregime              : in    natural range 0 to 7;
		direction_bit           : in    std_ulogic;
		characteristic          : out   integer range -255 to 254
	);
end entity characteristic_determinator;

architecture rtl of characteristic_determinator is
	signal characteristic_raw_normal_bits : std_ulogic_vector(6 downto 0);
	signal characteristic_precursor       : std_ulogic_vector(8 downto 0);
	signal characteristic_normal          : std_ulogic_vector(8 downto 0);
begin
	characteristic_raw_normal_bits <= characteristic_raw_bits when direction_bit = '0' else
	                                  not characteristic_raw_bits;
	characteristic_precursor       <= std_ulogic_vector(shift_right(signed(std_ulogic_vector'("10" & characteristic_raw_normal_bits)), antiregime));
	characteristic_normal          <= std_ulogic_vector'("1" & std_ulogic_vector(unsigned(characteristic_precursor(7 downto 0)) + 1));
	characteristic                 <= to_integer(signed(characteristic_normal)) when direction_bit = '0' else
	                                  to_integer(signed(not characteristic_normal));
end architecture rtl;
