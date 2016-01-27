library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lab1_challenge is
   port (KEY: in std_logic_vector(3 downto 0);  -- push-button switches
         SW : in std_logic_vector(17 downto 0);  -- slider switches
         CLOCK_50: in std_logic;            -- 50MHz clock input     
         HEX0 : out std_logic_vector(6 downto 0);
         HEX1 : out std_logic_vector(6 downto 0); 
         HEX2 : out std_logic_vector(6 downto 0) := (others => '1'); 
         HEX3 : out std_logic_vector(6 downto 0) := (others => '1');
         HEX4 : out std_logic_vector(6 downto 0) := (others => '1');
         HEX5 : out std_logic_vector(6 downto 0) := (others => '1'); 
         HEX6 : out std_logic_vector(6 downto 0) := (others => '1'); 
         HEX7 : out std_logic_vector(6 downto 0) := (others => '1') 
   );     
end lab1_challenge; 

architecture structural of lab1_challenge is

   component state_machine
      port (clk : in std_logic;   -- clock input
         resetb : in std_logic;   -- active-low reset input
         skip : in std_logic;      -- skip switch value
         hex0 : out std_logic_vector(6 downto 0)  -- drive digit 0
      );
   end component;

   signal prescaler_min : unsigned(27 downto 0) := "0000011001101111111100110000"; -- 6,750,000 (4Hz)
   signal prescaler_max : unsigned(27 downto 0) := "1110111001101011001010000000"; -- 250,000,000 (0.1Hz)
   signal prescaler_bit_value : unsigned(19 downto 0) := "11100111111110110011"; -- 950195 (1/256th between max and min) 
   signal prescaler_counter0 : unsigned(27 downto 0) := (others => '0');
   signal prescaler_counter1 : unsigned(27 downto 0) := (others => '0');
   signal clock0 : std_logic := '0';
   signal clock1 : std_logic := '0';

begin

   PROCESS (CLOCK_50)	
   BEGIN
      if rising_edge (CLOCK_50) THEN 
         prescaler_counter0 <= prescaler_counter0 + 1;
         prescaler_counter1 <= prescaler_counter1 + 1;
         
         if(prescaler_counter0 > (prescaler_max - unsigned(SW(9 downto 2)) * prescaler_bit_value)) THEN
            clock0 <= not clock0;
            prescaler_counter0 <= (others => '0');
         end if;

         if(prescaler_counter1 > (prescaler_max - unsigned(SW(17 downto 10)) * prescaler_bit_value)) THEN
            clock1 <= not clock1;
            prescaler_counter1 <= (others => '0');
         end if;
      end if;
   END process;

    u0: state_machine port map(clock0, KEY(0), SW(0), HEX0);
    u1: state_machine port map(clock1, KEY(0), SW(1), HEX1);
end structural;
