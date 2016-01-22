--------------------------------------------------------
--
--  This is the skeleton file for Lab 1 Phase 3.  You should
--  start with this file when you describe your state machine.  
--  
--------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

--------------------------------------------------------
--
--  This is the entity part of the top level file for Phase 3.
--  The entity part declares the inputs and outputs of the
--  module as well as their types.  For now, a signal of
--  “std_logic” type can take on the value ‘0’ or ‘1’ (it
--  can actually do more than this).  A signal of type
--  std_logic_vector can be thought of as an array of 
--  std_logic, and is used to describe a bus (a parallel 
--  collection of wires).
--
--  Note: you don't have to change the entity part.
--  
----------------------------------------------------------

entity state_machine is
   port (clk : in std_logic;  -- clock input to state machine
         resetb : in std_logic;  -- active-low reset input
         skip : in std_logic;     -- skip input
         hex0 : out std_logic_vector(6 downto 0) -- output of state machine
            -- Note that in the above, hex0 is a 7-bit wide bus
            -- indexed using indices 6, 5, 4 ... down to 0.  The
            -- most-significant bit is hex(6) and the least significant
            -- bit is hex(0)

   ); 
end state_machine;

----------------------------------------------------------------
--
-- The following is the architecture part of the state machine.  It 
-- describes the behaviour of the state machine using synthesizable
-- VHDL.  
--
----------------------------------------------------------------- 

architecture behavioural of state_machine is

signal next_state, current_state : std_logic_vector(2 downto 0);	
begin

   process (all)
   begin

      case current_state is
         when "000" =>
            if (skip = '0') then 
               next_state <= "001";
            else 
               next_state <= "010";
            end if;
         when "001" =>
            if (skip = '0') then 
               next_state <= "010";
            else 
               next_state <= "011";
            end if;		
         when "010" =>
            if (skip = '0') then 
               next_state <= "011";
            else 
               next_state <= "100";
            end if;
         when "011" =>
            if (skip = '0') then 
               next_state <= "100";
            else 
               next_state <= "000";
            end if;
         when "100" =>
            if (skip = '0') then 
               next_state <= "000";
            else 
               next_state <= "001";
            end if;
         when others => next_state <= "000";
      end case;

      -- if the reset signal is high, then the next state is 00 regardless
      -- of the other inputs.

      if (resetb = '0') then  
          next_state <= "000";
      end if;
   end process;

   -- This process is another combinational block.  It computes the value of
   -- the alert output based on the current state.  It is written using an “if”
   -- construct; a more complex block might be written using a case statement as in
   -- the previous process.  Note again this is written using VHDL 2008 features.
	
   process(all) 
   begin
         if (current_state = "000" or current_state = "011") then -- A
            hex0(0) <= '0';
            hex0(1) <= '0';
            hex0(2) <= '0';
            hex0(3) <= '1';
            hex0(4) <= '0';
            hex0(5) <= '0';
            hex0(6) <= '0';
         elsif (current_state = "001") then -- F
            hex0(0) <= '0';
            hex0(1) <= '1';
            hex0(2) <= '1';
            hex0(3) <= '1';
            hex0(4) <= '0';
            hex0(5) <= '0';
            hex0(6) <= '0';
         elsif (current_state = "010") then -- t
            hex0(0) <= '1';
            hex0(1) <= '1';
            hex0(2) <= '1';
            hex0(3) <= '0';
            hex0(4) <= '0';
            hex0(5) <= '0';
            hex0(6) <= '0';
         elsif (current_state = "100") then -- B
            hex0(0) <= '0';
            hex0(1) <= '0';
            hex0(2) <= '0';
            hex0(3) <= '0';
            hex0(4) <= '0';
            hex0(5) <= '0';
            hex0(6) <= '0';
         end if;
   end process;
	
   -- The following process describes the behaviour of the two bit state machine.
   -- This is a sequential process; the current state is updated only on the rising 
   -- edge of the clock.  Note that clk is in the sensitivity list (this is different
   -- than the combinational blocks described above).  

   process(clk)
   begin 
      if rising_edge(clk) then 
         current_state <= next_state;
      end if;
   end process;
	
end behavioural;
