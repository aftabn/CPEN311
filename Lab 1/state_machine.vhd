library ieee;
use ieee.std_logic_1164.all;

entity state_machine is
   port (clk : in std_logic;  -- clock input to state machine
         resetb : in std_logic;  -- active-low reset input
         skip : in std_logic;     -- skip input
         hex0 : out std_logic_vector(6 downto 0) -- output of state machine
   ); 
end state_machine;

architecture behavioural of state_machine is

type state is (A_UPPER, F, T, A_LOWER, B);
signal next_state, current_state : state;	

begin

   process (all)

   begin

      case current_state is
         when A_UPPER =>
            if (skip = '0') then 
               next_state <= F;
            else 
               next_state <= T;
            end if;
         when F =>
            if (skip = '0') then 
               next_state <= T;
            else 
               next_state <= A_LOWER;
            end if;		
         when T =>
            if (skip = '0') then 
               next_state <= A_LOWER;
            else 
               next_state <= B;
            end if;
         when A_LOWER =>
            if (skip = '0') then 
               next_state <= B;
            else 
               next_state <= A_UPPER;
            end if;
         when B =>
            if (skip = '0') then 
               next_state <= A_UPPER;
            else 
               next_state <= F;
            end if;
         when others => next_state <= A_UPPER;
      end case;

      if (resetb = '0') then  
          next_state <= A_UPPER;
      end if;
   end process;

   process(all) 
   begin
         if (current_state = A_UPPER) then -- A
            hex0(6 downto 0) <= "0001000";
         elsif (current_state = F) then -- f
            hex0(6 downto 0) <= "0001110";
         elsif (current_state = T) then -- t
            hex0(6 downto 0) <= "0000111";
         elsif (current_state = A_LOWER) then -- a
            hex0(6 downto 0) <= "0100000";
         elsif (current_state = B) then -- b
            hex0(6 downto 0) <= "0000011";
         end if;
   end process;
	
   process(clk)
   begin 
      if rising_edge(clk) then 
         current_state <= next_state;
      end if;
   end process;
	
end behavioural;
