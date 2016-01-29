LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY WORK;
USE WORK.ALL;

ENTITY spinwheel IS
	PORT(
		fast_clock : IN  STD_LOGIC;  -- This will be a 27 Mhz Clock
		resetb : IN  STD_LOGIC;      -- asynchronous reset
		spin_result  : OUT UNSIGNED(5 downto 0));  -- current value of the wheel
END;

ARCHITECTURE behavioral OF spinwheel IS

	SIGNAL	wheel_internal : INTEGER;
	
BEGIN
	-- The wheel is always spinning
	PROCESS( fast_clock, resetb )
	BEGIN
	
        -- Asynchronous reset
		IF resetb='0' THEN
			wheel_internal <= 0;
        
        -- If not reset, check for a rising clock edge
		ELSIF RISING_EDGE(fast_clock) THEN
			IF wheel_internal = 36 THEN
				wheel_internal <= 0;
			ELSE
				wheel_internal <= wheel_internal + 1;
			END IF;
		END IF;
	END PROCESS;

	spin_result <= to_unsigned(wheel_internal, spin_result'length);
END;