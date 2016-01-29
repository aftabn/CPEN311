LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
 
LIBRARY WORK;
USE WORK.ALL;

ENTITY new_balance IS
  	PORT(slow_clock : in std_logic;
		resetb : in std_logic;
		bet_amount : in unsigned(2 downto 0);
		win_straightup : in std_logic;
		win_split : in std_logic;
		win_corner : in std_logic;
		new_money : out unsigned(15 downto 0));
END new_balance;

ARCHITECTURE behavioural OF new_balance IS

--signal initial_money: unsigned(15 downto 0):= "0000000000100000";
--signal money: unsigned(15 downto 0):= "0000000000100000"; 

BEGIN
	PROCESS(slow_clock)
		variable balance : unsigned(15 downto 0); 
		variable bet : unsigned(2 downto 0); 
	BEGIN
		bet := bet_amount;
		balance := money - bet;

		if (win_straightup = '1') then
			balance := balance + (to_unsigned(35, 13) * bet) + bet;
		elsif (win_split = '1') then
			balance := balance + (to_unsigned(17, 13) * bet) + bet;
		elsif (win_corner = '1') then
			balance := balance + (to_unsigned(8, 13) * bet) + bet;
		end if;

		new_money <= balance;

	END PROCESS;
END;
