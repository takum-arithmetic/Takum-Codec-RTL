library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_misc.all;
	use ieee.numeric_std.all;

entity underflow_overflow_predictor is
	generic (
		n : natural range 2 to natural'high
	);
	port (
		characteristic        : in    integer range -255 to 254;
		mantissa_bits         : in    std_ulogic_vector(n - 6 downto 0);
		round_down_underflows : out   std_ulogic;
		round_up_overflows    : out   std_ulogic
	);
end entity underflow_overflow_predictor;

architecture rtl of underflow_overflow_predictor is
	signal   mantissa_bits_crop      : std_ulogic_vector(n - 12 downto 0);
	constant mantissa_bits_crop_zero : std_ulogic_vector(n - 12 downto 0) := (others => '0');
	constant mantissa_bits_crop_one  : std_ulogic_vector(n - 12 downto 0) := (others => '1');

	type characteristic_bound_type is array (2 to 11) of natural range 15 to 254;

	constant characteristic_bound : characteristic_bound_type :=
	(
	  15,
	  63,
	  127,
	  191,
	  223,
	  239,
	  247,
	  251,
	  253,
	  254
	);
begin

	check_characteristic : process (characteristic, mantissa_bits) is
	begin
		if (n <= 11) then
			if (characteristic < -characteristic_bound(n)) then
				round_down_underflows <= '1';
			else
				round_down_underflows <= '0';
			end if;

			if (characteristic >= characteristic_bound(n)) then
				round_up_overflows <= '1';
			else
				round_up_overflows <= '0';
			end if;
		else
			mantissa_bits_crop <= mantissa_bits(n - 6 downto 6);

			if (mantissa_bits_crop = mantissa_bits_crop_zero) then
				if (characteristic = -255) then
					round_down_underflows <= '1';
				else
					round_down_underflows <= '0';
				end if;
			else
				round_down_underflows <= '0';
			end if;

			if (mantissa_bits_crop = mantissa_bits_crop_one) then
				if (characteristic = 254) then
					round_up_overflows <= '1';
				else
					round_up_overflows <= '0';
				end if;
			else
				round_up_overflows <= '0';
			end if;
		end if;
	end process check_characteristic;

end architecture rtl;
