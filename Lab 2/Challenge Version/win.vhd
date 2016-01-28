LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
 
LIBRARY WORK;
USE WORK.ALL;

ENTITY win IS
	PORT(spin_result_latched : in unsigned(5 downto 0);  -- result of the spin (the winning number)
			bet_target : in unsigned(5 downto 0); -- bet_target number for bet
			bet_modifier : in unsigned(3 downto 0); -- as described in the handout
			win_straightup : out std_logic;  -- whether it is a straight-up winner
			win_split : out std_logic;  -- whether it is a split bet winner
			win_corner : out std_logic); -- whether it is a corner bet winner
END win;

------------------------
-- Modifers 
-- 1111|1000|1001
-- 1110|"##"|1010
-- 1101|1100|1011

--Board 
--|		 0      |
--|  1 |  2 |  3 |
--|  4 |  5 |  6 |
--|  7 |  8 |  9 |
--| 10 | 11 | 12 |
--| 13 | 14 | 15 |
--| 16 | 17 | 18 |
--| 19 | 20 | 21 |
--| 22 | 23 | 24 |
--| 25 | 26 | 27 |
--| 28 | 29 | 30 |
--| 31 | 32 | 33 |
--| 34 | 35 | 36 |
------------------------

ARCHITECTURE behavioural OF win IS
BEGIN

	PROCESS(all)
	BEGIN
		win_straightup <= '0';
		win_split <= '0';
		win_corner <= '0';

		if (spin_result_latched = bet_target and bet_modifier = "0000") then -- Handle the straight up case
			win_straightup <= '1';
		elsif (spin_result_latched = to_unsigned(0, 6)) then	-- Handle every case involving 0 besides straight up
			case bet_modifier is
				when "1000" =>
					if (bet_target = to_unsigned(1, 6) or bet_target = to_unsigned(2, 6) or bet_target = to_unsigned(3, 6)) then
						win_split <= '1';
					end if;
				when "1001" =>
					if (bet_target = to_unsigned(1, 6) or bet_target = to_unsigned(2, 6)) then
						win_corner <= '1';
					end if;
				when "1111" =>
					if (bet_target = to_unsigned(2, 6) or bet_target = to_unsigned(3, 6)) then
						win_corner <= '1';
					end if;
				when others =>
					null;
			end case;
		elsif ((bet_target - to_unsigned(1, 6)) mod to_unsigned(3, 6) = to_unsigned(0, 6)) then -- Handle left column
			case bet_modifier is
				when "1000" =>
					if (spin_result_latched = bet_target or spin_result_latched = bet_target - to_unsigned(3, 6)) then
						win_split <= '1';
					end if;
				when "1001" =>
					if (spin_result_latched = bet_target - to_unsigned(3, 6) or spin_result_latched = bet_target - to_unsigned(2, 6) or spin_result_latched = bet_target + to_unsigned(1, 6) or spin_result_latched = bet_target) then
						win_corner <= '1';
					end if;
				when "1010" =>
					if (spin_result_latched = bet_target or spin_result_latched = bet_target + to_unsigned(1, 6)) then
						win_split <= '1';
					end if;
				when "1011" =>
					if (spin_result_latched = bet_target or spin_result_latched = bet_target + to_unsigned(1, 6) or spin_result_latched = bet_target + to_unsigned(3, 6) or spin_result_latched = bet_target + "0000100") then
						if (bet_target /= to_unsigned(34, 6)) then -- Handle the edge case 
							win_corner <= '1';
						end if;
					end if;
				when "1100" =>
					if (spin_result_latched = bet_target or spin_result_latched = bet_target + to_unsigned(3, 6)) then
						if (bet_target /= to_unsigned(34, 6)) then -- Handle the edge case 
							win_split <= '1';
						end if;
					end if;
				when others =>
					null;
			end case;
		elsif ((bet_target + to_unsigned(1, 6)) mod to_unsigned(3, 6) = to_unsigned(0, 6)) then -- Handle middle column
			case bet_modifier is
				when "1000" =>
					if (spin_result_latched = bet_target or spin_result_latched = bet_target - to_unsigned(3, 6)) then
						win_split <= '1';
					end if;
				when "1001" =>
					if (spin_result_latched = bet_target - to_unsigned(3, 6) or spin_result_latched = bet_target - to_unsigned(2, 6) or spin_result_latched = bet_target + to_unsigned(1, 6) or spin_result_latched = bet_target) then
						win_corner <= '1';
					end if;
				when "1010" =>
					if (spin_result_latched = bet_target or spin_result_latched = bet_target + to_unsigned(1, 6)) then
						win_split <= '1';
					end if;
				when "1011" =>
					if (spin_result_latched = bet_target or spin_result_latched = bet_target + to_unsigned(1, 6) or spin_result_latched = bet_target + to_unsigned(3, 6) or spin_result_latched = bet_target + "000100") then
						if (bet_target /= to_unsigned(35, 6)) then -- Handle the edge case 
							win_corner <= '1';
						end if;
					end if;
				when "1100" =>
					if (spin_result_latched = bet_target or spin_result_latched = bet_target + 3) then
						if (bet_target /= to_unsigned(35, 6)) then -- Handle the edge case 
							win_split <= '1';
						end if;
					end if;
				when "1101" =>
					if (spin_result_latched = bet_target or spin_result_latched = bet_target - to_unsigned(1, 6) or spin_result_latched = bet_target + to_unsigned(2, 6) or spin_result_latched = bet_target + to_unsigned(3, 6)) then
						if (bet_target /= to_unsigned(35, 6)) then -- Handle the edge case 
							win_corner <= '1';
						end if;
					end if;
				when "1110" =>
					if (spin_result_latched = bet_target or spin_result_latched = bet_target - to_unsigned(1, 6)) then
						win_split <= '1';
					end if;
				when "1111" =>
					if (spin_result_latched = bet_target or spin_result_latched = bet_target - to_unsigned(1, 6) or spin_result_latched = bet_target - to_unsigned(3, 6) or spin_result_latched = bet_target - "000100") then
						win_corner <= '1';
					end if;
				when others =>
					null;
			end case;
		elsif (bet_target mod to_unsigned(3, 6) = to_unsigned(0, 6)) then -- Handle right column
			case bet_modifier is
				when "1000" =>
					if (spin_result_latched = bet_target or spin_result_latched = bet_target - to_unsigned(3, 6)) then
						win_split <= '1';
					end if;
				when "1100" =>
					if (spin_result_latched = bet_target or spin_result_latched = bet_target + to_unsigned(3, 6)) then
						if (bet_target /= to_unsigned(36, 6)) then -- Handle the edge case 
							win_split <= '1';
						end if;
					end if;
				when "1101" =>
					if (spin_result_latched = bet_target or spin_result_latched = bet_target - to_unsigned(1, 6) or spin_result_latched = bet_target + to_unsigned(2, 6) or spin_result_latched = bet_target + to_unsigned(3, 6)) then
						if (bet_target /= to_unsigned(36, 6)) then -- Handle the edge case 
							win_corner <= '1';
							win_split <= '0';
						end if;
					end if;
				when "1110" =>
					if (spin_result_latched = bet_target or spin_result_latched = bet_target - to_unsigned(1, 6)) then
						win_split <= '1';
					end if;
				when "1111" =>
					if (spin_result_latched = bet_target or spin_result_latched = bet_target - to_unsigned(1, 6) or spin_result_latched = bet_target - to_unsigned(3, 6) or spin_result_latched = bet_target - "000100") then
						win_corner <= '1';
					end if;
				when others =>
					null;
			end case;
		end if;
	END PROCESS;
END; 
