library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity phase4 is
   port (KEY: in std_logic_vector(3 downto 0);  -- push-button switches
         SW : in std_logic_vector(17 downto 0);  -- slider switches
         CLOCK_50: in std_logic;            -- 50MHz clock input     
         CLOCK_27: in std_logic;          -- 27MHz clock input
         HEX0 : out std_logic_vector(6 downto 0); -- output to drive digit 0
         HEX1 : out std_logic_vector(6 downto 0) -- output to drive digit 0
   );     
end phase4;

------------------------------------------------------------
--
-- This is the architecture part of the top level file for Phase 3.
-- This file includes your lower level state machine, and wires up the
-- input and output pins to your state machine.
--
-------------------------------------------------------------

architecture structural of phase4 is

   component state_machine
      port (clk : in std_logic;   -- clock input
         resetb : in std_logic;   -- active-low reset input
         skip : in std_logic;      -- skip switch value
         hex0 : out std_logic_vector(6 downto 0)  -- drive digit 0
      );
   end component;

   -- These two signals are used in the clock divider (see below).
   -- slow_clock is the output of the clock divider, and count50 is
   -- an internal signal used within the clock divider.
	
   signal slow_clock50 : std_logic;
   signal count50 : unsigned(25 downto 0) := (others => '0');
   
   signal slow_clock27 : std_logic;
   signal count27 : unsigned(25 downto 0) := (others => '0');

   -- Note: the above syntax (others=>'0') is a short cut for initializing
   -- all bits in this 26 bit wide bus to 0. 

begin

   PROCESS (CLOCK_50)	
   BEGIN
      if rising_edge (CLOCK_50) THEN 
         count50 <= count50 + 1;
      end if;
   END process;

    slow_clock50 <= count50(25); 

   PROCESS (CLOCK_27)   
   BEGIN
      if rising_edge (CLOCK_27) THEN 
         count27 <= count27 + 1;
     end if;
   END process;

    slow_clock27 <= count27(25); 
    -- instantiate the state machine component, which is defined in 
    -- state_machine.vhd (which you will write).    

    u0: state_machine port map(slow_clock50, KEY(0), SW(0), HEX0);
    u1: state_machine port map(slow_clock27, KEY(0), SW(1), HEX1);
end structural;
