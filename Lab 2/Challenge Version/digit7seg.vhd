LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY WORK;
USE WORK.ALL;

ENTITY digit7seg IS
	PORT(
          digit : IN  UNSIGNED(3 DOWNTO 0);  -- number 0 to 0xF
          seg7 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)  -- one per segment
	);
END;

ARCHITECTURE behavioral OF digit7seg IS
BEGIN
	PROCESS(all)
		variable number : unsigned(3 downto 0);
	BEGIN
		number := digit mod to_unsigned(10, 4);

		if (number = to_unsigned(0, 4)) then
			seg7 <= "1000000";
		elsif (number = to_unsigned(1, 4)) then
			seg7 <= "1111001";
		elsif (number = to_unsigned(2, 4)) then
			seg7 <= "0100100";
		elsif (number = to_unsigned(3, 4)) then
			seg7 <= "0110000";
		elsif (number = to_unsigned(4, 4)) then
			seg7 <= "0011001";
		elsif (number = to_unsigned(5, 4)) then
			seg7 <= "0010010";
		elsif (number = to_unsigned(6, 4)) then
			seg7 <= "0000010";
		elsif (number = to_unsigned(7, 4)) then
			seg7 <= "1111000";
		elsif (number = to_unsigned(8, 4)) then
			seg7 <= "0000000";
		elsif (number = to_unsigned(9, 4)) then
			seg7 <= "0011000";
		else
			seg7 <= "1111111";
		end if;
	END PROCESS;
END;
