LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

-- This is a FIR filter, as described in the lab handout.
-- It is written as an 8-tap filter, although it can easily be changed
-- for more taps.

ENTITY fir8 IS
	PORT (
		CLOCK_50, valid : IN std_logic;
		stream_in : IN std_logic_vector(23 DOWNTO 0);
		stream_out : OUT std_logic_vector(23 DOWNTO 0)
	);
END fir8;

ARCHITECTURE behaviour OF fir8 IS
	
	TYPE state_type IS (IDLE, FILTERING);
	TYPE int_array IS ARRAY (0 to 7) of integer;

BEGIN

	take_sample : process(CLOCK_50)
		VARIABLE state : state_type := IDLE;
		VARIABLE samples : int_array := (others => 0);
		VARIABLE sample_count : natural := 0;
		VARIABLE sampled_sum : integer := 0;
		VARIABLE oldest_value : integer := 0;
	BEGIN
		if (rising_edge(CLOCK_50)) THEN
			if (valid = '1') THEN
				if (sample_count < samples'length - 1) THEN
					samples(sample_count) := to_integer(signed(stream_in));
					sampled_sum := sampled_sum + samples(sample_count);
					sample_count := sample_count + 1;
					stream_out <= stream_in;

				else
					oldest_value := samples(0);
					samples(0) := samples(1);
					samples(1) := samples(2);
					samples(2) := samples(3);
					samples(3) := samples(4);
					samples(4) := samples(5);
					samples(5) := samples(6);
					samples(6) := samples(7);
					samples(7) := to_integer(signed(stream_in));
					sampled_sum := sampled_sum - oldest_value + samples(7);
					stream_out <= STD_LOGIC_VECTOR(to_signed(sampled_sum / samples'length, 24));
				end if;
			end if;
		end if;

	END PROCESS;

END behaviour;