library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_misc.all;
	use ieee.numeric_std.all;

entity common_decoder is
	generic (
		n : natural range 2 to natural'high := 16
	);
	port (
		takum          : in    std_ulogic_vector(n - 1 downto 0);
		sign_bit       : out   std_ulogic;
		characteristic : out   integer range -255 to 254;
		mantissa_bits  : out   std_ulogic_vector(n - 6 downto 0);
		precision      : out   natural range 0 to n - 5;
		is_zero        : out   std_ulogic;
		is_nar         : out   std_ulogic
	);
end entity common_decoder;

architecture behave of common_decoder is
	signal prefix                  : std_ulogic_vector(10 downto 0);
	signal direction_bit           : std_ulogic;
	signal regime_bits             : std_ulogic_vector(2 downto 0);
	signal regime                  : natural range 0 to 7;
	signal characteristic_explicit : natural range 0 to 127;
	signal precision_internal      : natural range 0 to n - 5;

	constant zeros      : std_ulogic_vector(6 downto 0)     := (others => '0');
	constant takum_zero : std_ulogic_vector(n - 1 downto 0) := (others => '0');
	constant takum_nar  : std_ulogic_vector(n - 1 downto 0) := (n - 1 => '1', others => '0');
begin
	-- Directly output the sign bit
	sign_bit <= takum(n - 1);

	-- Get 11-bit prefix consisting of the direction bit, 3 regime
	-- bits and 7 subsequent bits for all possible characteristic
	-- lengths 0-7
	prefix        <= takum(n - 2 downto n - 12) when n >= 12 else
	                 takum(n - 2 downto 0) & ((12 - n - 1) downto 0 => '0');
	direction_bit <= prefix(10);
	regime_bits   <= prefix(9 downto 7);

	-- determine regime as per definition
	regime <= 7 - to_integer(unsigned(regime_bits)) when direction_bit = '0' else
	          to_integer(unsigned(regime_bits));

	-- determine characteristic as per definition
	characteristic_explicit <= to_integer(unsigned(prefix(6 downto 7 - regime)));
	characteristic          <= -2 ** (regime + 1) + 1 + characteristic_explicit when direction_bit = '0' else
	                           2 ** regime - 1 + characteristic_explicit;

	-- determine precision as per definition
	precision_internal <= 0 when regime >= n - 5 else
	                      n - regime - 5;
	precision          <= precision_internal;

	-- determine mantissa bits as per definition
	mantissa_bits <= (others => '0') when precision_internal = 0 else
	                 std_ulogic_vector'(takum(precision_internal - 1 downto 0) & zeros(regime - 1 downto 0));

	-- determine special cases as per definition
	is_zero <= '1' when takum = takum_zero else
	           '0';
	is_nar  <= '1' when takum = takum_nar else
	           '0';
end architecture behave;

architecture rtl of common_decoder is
	signal direction_bit                 : std_ulogic;
	signal regime_characteristic_segment : std_ulogic_vector(9 downto 0);
	signal regime_bits                   : std_ulogic_vector(2 downto 0);
	signal regime                        : natural range 0 to 7;
	signal antiregime                    : natural range 0 to 7;
	signal characteristic_raw_bits       : std_ulogic_vector(6 downto 0);
begin
	sign_bit      <= takum(n - 1);
	direction_bit <= takum(n - 2);

	regime_characteristic_segment <= takum(n - 3 downto n - 12) when n >= 12 else
	                                 std_ulogic_vector'(takum(n - 3 downto 0) & (11 - n downto 0 => '0'));

	regime_bits <= regime_characteristic_segment(9 downto 7);

	determine_regime_antiregime : process (direction_bit, regime_bits) is
	begin
		if (direction_bit = '0') then
			regime     <= to_integer(unsigned(not regime_bits));
			antiregime <= to_integer(unsigned(regime_bits));
		else
			regime     <= to_integer(unsigned(regime_bits));
			antiregime <= to_integer(unsigned(not regime_bits));
		end if;
	end process determine_regime_antiregime;

	characteristic_raw_bits <= regime_characteristic_segment(6 downto 0);

	characteristic_determinator : entity work.characteristic_determinator(rtl)
		port map (
			characteristic_raw_bits => characteristic_raw_bits,
			antiregime              => antiregime,
			direction_bit           => direction_bit,
			characteristic          => characteristic
		);

	mantissa_bits <= std_ulogic_vector(shift_left(unsigned(takum(n - 6 downto 0)), regime));
	precision     <= (n - 5) - regime when regime < n - 5 else
	                 0;

	detect_special_cases : process (takum) is
	begin
		if (or_reduce(takum(n - 2 downto 0)) = '0') then
			is_zero <= not takum(n - 1);
			is_nar  <= takum(n - 1);
		else
			is_zero <= '0';
			is_nar  <= '0';
		end if;
	end process detect_special_cases;

end architecture rtl;
