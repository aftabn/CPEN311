LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
 
LIBRARY WORK;
USE WORK.ALL;

ENTITY roulette IS
	PORT(CLOCK_27 : IN STD_LOGIC; -- the fast clock for spinning wheel
		KEY : IN STD_LOGIC_VECTOR(3 downto 0);  -- includes slow_clock and reset
		SW : IN STD_LOGIC_VECTOR(17 downto 0); -- switches for betting parameters
		LEDG : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		HEX7 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX6 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX5 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0) := (others => '1');  -- Turn off unused HEX display
		HEX4 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX3 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX2 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX1 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX0 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0));
END roulette;


ARCHITECTURE structural OF roulette IS
	
	component spinwheel
		port (fast_clock : in std_logic;
			resetb : in std_logic;
			spin_result : OUT UNSIGNED(5 downto 0));
   end component;

	component win
		port(spin_result_latched : in unsigned(5 downto 0);
			bet_target : in unsigned(5 downto 0);
			bet_modifier : in unsigned(3 downto 0);
			win_straightup : out std_logic;
			win_split : out std_logic;
			win_corner : out std_logic);
	end component;

	component new_balance
	  	port(money : in unsigned(15 downto 0);
			bet_amount : in unsigned(2 downto 0);
			win_straightup : in std_logic;
			win_split : in std_logic;
			win_corner : in std_logic;
			new_money : out unsigned(15 downto 0));
	end component;

	component digit7seg
		port(digit : IN  UNSIGNED(3 DOWNTO 0);
	        seg7 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0));
	end component;

	signal slow_clock : STD_LOGIC := KEY(0);
	signal resetb : STD_LOGIC := KEY(1);

	signal spin_result : unsigned(5 downto 0);
	signal spin_result_latched : unsigned(5 downto 0);
	signal bet_target : unsigned(5 downto 0);
	signal bet_modifier : unsigned(3 downto 0);
	signal bet_amount : unsigned(2 downto 0);

	signal win_straightup : STD_LOGIC;
	signal win_split : STD_LOGIC;
	signal win_corner : STD_LOGIC;

	signal money : unsigned(15 downto 0);
	signal new_money : unsigned(15 downto 0);

	signal spin_result_digit0 : unsigned(3 downto 0);
	signal spin_result_digit1 : unsigned(3 downto 0);

	signal money_digit0 : unsigned(3 downto 0);
	signal money_digit1 : unsigned(3 downto 0);
	signal money_digit2 : unsigned(3 downto 0);
	signal money_digit3 : unsigned(3 downto 0);
	signal money_digit4 : unsigned(3 downto 0);

BEGIN
	LEDG(0) <= win_straightup;
	LEDG(1) <= win_split;
	LEDG(2) <= win_corner;

	DISPLAY_MONEY: process(new_money)
		variable result : integer;
		variable digit : integer;
	BEGIN
		result := to_integer(new_money);
		digit := (result) mod 10;
		money_digit0 <= to_unsigned(digit, 4);
		digit := (result / 10) mod 10;
		money_digit1 <= to_unsigned(digit, 4);
		digit := (result / 100) mod 10;
		money_digit2 <= to_unsigned(digit, 4);
		digit := (result / 1000) mod 10;
		money_digit3 <= to_unsigned(digit, 4);
		digit := (result / 10000) mod 10;
		money_digit4 <= to_unsigned(digit, 4);
	end process;

	DISPLAY_SPIN_RESULT: process(spin_result_latched)
		variable result : integer;
		variable digit : integer;
	BEGIN
		result := to_integer(spin_result_latched);
		digit := result mod 10;
		spin_result_digit0 <= to_unsigned(digit, 4);
		digit := (result / 10) mod 10; 
		spin_result_digit1 <= to_unsigned(digit, 4);
	end process;

	CLOCK_OR_RESET: process (slow_clock, resetb)
	BEGIN
		if (resetb = '0') then
			spin_result_latched <= (others => '0');
			bet_target <= (others => '0');
			bet_modifier <= (others => '0');
			bet_amount <= (others => '0');
			money <= to_unsigned(32, 16);
		elsif (rising_edge(slow_clock)) then
			spin_result_latched <= spin_result;
			bet_target <= unsigned(SW(5 downto 0));
			bet_modifier <= unsigned(SW(9 downto 6));
			bet_amount <= unsigned(SW(12 downto 10));
			money <= new_money;
		end if;
	end process;

	u0: spinwheel port map(CLOCK_27, resetb, spin_result);
	u1: win port map(spin_result_latched, bet_target, bet_modifier, win_straightup, win_split, win_corner);
	u2: new_balance port map(money, bet_amount, win_straightup, win_split, win_corner, new_money);
	u3: digit7seg port map(spin_result_digit1, HEX7);
	u4: digit7seg port map(spin_result_digit0, HEX6);
	u5: digit7seg port map(money_digit4, HEX4);
	u6: digit7seg port map(money_digit3, HEX3);
	u7: digit7seg port map(money_digit2, HEX2);
	u8: digit7seg port map(money_digit1, HEX1);
	u9: digit7seg port map(money_digit0, HEX0);

END;