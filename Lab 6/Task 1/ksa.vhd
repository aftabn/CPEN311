library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Entity part of the description.  Describes inputs and outputs

entity ksa is
  port(CLOCK_50 : in  std_logic;  -- Clock pin
       KEY : in  std_logic_vector(3 downto 0);  -- push button switches
       SW : in  std_logic_vector(15 downto 0);  -- slider switches
		 LEDG : out std_logic_vector(7 downto 0);  -- green lights
		 LEDR : out std_logic_vector(17 downto 0));  -- red lights
end ksa;

-- Architecture part of the description

architecture rtl of ksa is

   -- Declare the component for the ram.  This should match the entity description 
	-- in the entity created by the megawizard. If you followed the instructions in the 
	-- handout exactly, it should match.  If not, look at s_memory.vhd and make the
	-- changes to the component below
	
   COMPONENT s_memory IS
	   PORT (
		   address		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		   clock		: IN STD_LOGIC  := '1';
		   data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		   wren		: IN STD_LOGIC ;
		   q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0));
   END component;

	-- Enumerated type for the state variable.  You will likely be adding extra
	-- state names here as you complete your design
	
	type state_type is (state_init, 
                       state_fill,						
   	 					  state_done);
								
    -- These are signals that are used to connect to the memory													 
	 signal address : STD_LOGIC_VECTOR (7 DOWNTO 0);	 
	 signal data : STD_LOGIC_VECTOR (7 DOWNTO 0);
	 signal wren : STD_LOGIC;
	 signal q : STD_LOGIC_VECTOR (7 DOWNTO 0);	

	 begin
	    -- Include the S memory structurally
	
       u0: s_memory port map (
	        address, CLOCK_50, data, wren, q);
			  
  	process(CLOCK_50, KEY(3))
  		variable state : state_type := state_init;
  		variable i : integer := 0;
	begin
		if (KEY(3) = '0') then
			i := 0; 
			state := state_init;

		elsif (rising_edge(CLOCK_50)) then

			case state is
				when state_init =>
					i := 0; 
					state := state_fill;
					wren <= '1';

				when state_fill => 
					address <= std_logic_vector(to_unsigned(i, 8));
					data <= std_logic_vector(to_unsigned(i, 8));
					wren <= '1';
					i := i + 1;
					if (i = 256) then
						state := state_done;
					end if;

				 when others =>
				 	state := state_done;

		 	end case;
 		end if;
	end process;
end rtl;


