library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Entity part of the description.  Describes inputs and outputs

entity ksa is
  port(CLOCK_50 : in  std_logic;  -- Clock pin
       KEY : in  std_logic_vector(3 downto 0);  -- push button switches
       SW : in  std_logic_vector(17 downto 0);  -- slider switches
		 LEDG : out std_logic_vector(7 downto 0);  -- green lights
		 LEDR : out std_logic_vector(17 downto 0);  -- red lights
		HEX7 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0) := (others => '1');
		HEX6 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX5 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);  -- Turn off unused HEX display
		HEX4 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX3 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX2 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX1 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX0 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0));
end ksa;

-- Architecture part of the description

architecture rtl of ksa is

   -- Declare the component for the ram.  This should match the entity description 
	-- in the entity created by the megawizard. If you followed the instructions in the 
	-- handout exactly, it should match.  If not, look at s_memory.vhd and make the
	-- changes to the component below
	
   COMPONENT s_memory IS
	   PORT (
		   address	: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		   clock	: IN STD_LOGIC  := '1';
		   data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		   wren		: IN STD_LOGIC ;
		   q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0));
   END component;

	COMPONENT d_memory IS
	   PORT (
		   address	: IN STD_LOGIC_VECTOR (4 DOWNTO 0);
		   clock	: IN STD_LOGIC  := '1';
		   data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		   wren		: IN STD_LOGIC ;
		   q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0));
   END component;
	
	COMPONENT m_memory IS
		PORT
		(
			address	: IN STD_LOGIC_VECTOR (4 DOWNTO 0);
			clock	: IN STD_LOGIC  := '1';
			q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
		);
	END COMPONENT;
	
	component digit7seg
		port(digit : IN  UNSIGNED(3 DOWNTO 0);
	        seg7 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0));
	end component;

	-- Enumerated type for the state variable.  You will likely be adding extra
	-- state names here as you complete your design
	
	type state_type is (INIT, FIRST_LOOP, 
						READ_I_2, READ_J_2, WRITE_I_2, WRITE_J_2,
						READ_I_3, READ_J_3, WRITE_I_3, WRITE_J_3, 
						READ_F, READ_ENCRYPTED, WRITE_DECRYPTED,
						DONE);
								
    -- S_MEMORY (RAM) signals												 
	 signal address : STD_LOGIC_VECTOR (7 DOWNTO 0);	 
	 signal data : STD_LOGIC_VECTOR (7 DOWNTO 0);
	 signal wren : STD_LOGIC;
	 signal q : STD_LOGIC_VECTOR (7 DOWNTO 0);	

	 -- M_MEMORY (ROM) signals
	 signal address_m : STD_LOGIC_VECTOR (4 downto 0);
	 signal q_m : STD_LOGIC_VECTOR (7 DOWNTO 0);

	-- S_MEMORY (RAM) signals												 
	 signal address_d : STD_LOGIC_VECTOR (4 DOWNTO 0);	 
	 signal data_d : STD_LOGIC_VECTOR (7 DOWNTO 0);
	 signal wren_d : STD_LOGIC;
	 signal q_d : STD_LOGIC_VECTOR (7 DOWNTO 0);	

	 type byteArray is array (0 to 2) of std_logic_vector(7 downto 0);
 	signal secret_key: byteArray;
 	signal full_secret_key : STD_LOGIC_VECTOR (23 downto 0);

	signal digit0 : unsigned(3 downto 0);
	signal digit1 : unsigned(3 downto 0);
	signal digit2 : unsigned(3 downto 0);
	signal digit3 : unsigned(3 downto 0);
	signal digit4 : unsigned(3 downto 0);
	signal digit5 : unsigned(3 downto 0);
	signal digit6 : unsigned(3 downto 0);

	 begin
	    -- Include the S memory structurally
	
	u0: s_memory port map (address, CLOCK_50, data, wren, q);
	u1: d_memory port map (address_d, CLOCK_50, data_d, wren_d, q_d);
	u2: m_memory port map (address_m, CLOCK_50, q_m);
	u3: digit7seg port map(digit6, HEX6);
	u4: digit7seg port map(digit5, HEX5);
	u5: digit7seg port map(digit4, HEX4);
	u6: digit7seg port map(digit3, HEX3);
	u7: digit7seg port map(digit2, HEX2);
	u8: digit7seg port map(digit1, HEX1);
	u9: digit7seg port map(digit0, HEX0);

      secret_key(0) <= full_secret_key(23 downto 16);
		secret_key(1) <= full_secret_key(15 downto 8);
		secret_key(2) <= full_secret_key(7 downto 0);

  	process(CLOCK_50, KEY(3))
  		variable state : state_type := INIT;
  		variable s_i, s_j, dec_out, enc_in, f : integer;
  		variable temp : integer;
  		variable waitCount : integer := 0;
		variable i : integer := 0;
		variable j : integer := 0;
		variable k : integer := 0;

	begin
		if (KEY(3) = '0') then
			i := 0; 
			j := 0;
			k := 0;
			waitCount := 0;
			full_secret_key <= "000000000000000000000000";
			state := INIT;

		elsif (rising_edge(CLOCK_50)) then

			case state is
				when INIT =>
					i := 0; 
					j := 0;
					k := 0;
					waitCount := 0;
					state := FIRST_LOOP;

					full_secret_key <= std_logic_vector(unsigned(full_secret_key) + "000000000000000000000001");
					if (full_secret_key = "001111111111111111111111") then
						state := DONE;
					end if;

				when FIRST_LOOP => 
					address <= std_logic_vector(to_unsigned(i, 8));
					data <= std_logic_vector(to_unsigned(i, 8));
					wren <= '1';
					i := i + 1;
					if (i = 256) then
						i := 0;
						wren <= '0';
						state := READ_I_2;
					end if;

				when READ_I_2 => 
					if (waitCount = 0) then
						wren <= '0';
						address <= std_logic_vector(to_unsigned(i, 8));
						waitCount := waitCount + 1;
					elsif (waitCount = 1) then
						waitCount := waitCount + 1;
					else
						s_i := to_integer(unsigned(q));
						j := (j + s_i + to_integer(unsigned(secret_key(i mod 3)))) mod 256;
						waitCount := 0;
						state := READ_J_2;
					end if;

				when READ_J_2 => 
					if (waitCount = 0) then
						address <= std_logic_vector(to_unsigned(j, 8));
						waitCount := waitCount + 1;
					elsif (waitCount = 1) then
						waitCount := waitCount + 1;
					else
						s_j := to_integer(unsigned(q));
						waitCount := 0;
						state := WRITE_I_2;
					end if;

				when WRITE_I_2 => 
					if (waitCount = 0) then
						address <= std_logic_vector(to_unsigned(i, 8));
						data <= std_logic_vector(to_unsigned(s_j, 8));
						wren <= '1';
						waitCount := waitCount + 1;
					elsif (waitCount = 1) then
						waitCount := waitCount + 1;
					else
						waitCount := 0;
						state := WRITE_J_2;
					end if;

				when WRITE_J_2 => 
					if (waitCount = 0) then
						address <= std_logic_vector(to_unsigned(j, 8));
						data <= std_logic_vector(to_unsigned(s_i, 8));
						wren <= '1';
						waitCount := waitCount + 1;
					elsif (waitCount = 1) then
						waitCount := waitCount + 1;
					else
						i := i + 1;
						if (i = 256) then
							i := 0;
							j := 0;
							state := READ_I_3;
						else
							state := READ_I_2;
						end if;

						waitCount := 0;
					end if;

				when READ_I_3 => 
					if (waitCount = 0) then
						i := (i + 1) mod 256;
						wren <= '0';
						address <= std_logic_vector(to_unsigned(i, 8));
						waitCount := waitCount + 1;
					elsif (waitCount = 1) then
						waitCount := waitCount + 1;
					else
						s_i := to_integer(unsigned(q));
						j := (j + s_i) mod 256;
						waitCount := 0;
						state := READ_J_3;
					end if;

				when READ_J_3 => 
					if (waitCount = 0) then
						address <= std_logic_vector(to_unsigned(j, 8));
						waitCount := waitCount + 1;
					elsif (waitCount = 1) then
						waitCount := waitCount + 1;
					else
						s_j := to_integer(unsigned(q));
						waitCount := 0;
						state := WRITE_I_3;
					end if;

				when WRITE_I_3 => 
					if (waitCount = 0) then
						address <= std_logic_vector(to_unsigned(i, 8));
						data <= std_logic_vector(to_unsigned(s_j, 8));
						wren <= '1';
						waitCount := waitCount + 1;
					elsif (waitCount = 1) then
						waitCount := waitCount + 1;
					else
						waitCount := 0;
						state := WRITE_J_3;
					end if;

				when WRITE_J_3 => 
					if (waitCount = 0) then
						address <= std_logic_vector(to_unsigned(j, 8));
						data <= std_logic_vector(to_unsigned(s_i, 8));
						wren <= '1';
						waitCount := waitCount + 1;
					elsif (waitCount = 1) then
						waitCount := waitCount + 1;
					else
						waitCount := 0;
						state := READ_F;
					end if;

				when READ_F => 
					if (waitCount = 0) then
						wren <= '0';
						address <= std_logic_vector(to_unsigned((s_i + s_j) mod 256, 8));
						waitCount := waitCount + 1;
					elsif (waitCount = 1) then
						waitCount := waitCount + 1;
					else
						f := to_integer(unsigned(q));
						waitCount := 0;
						state := READ_ENCRYPTED;
					end if;

				when READ_ENCRYPTED => 
					if (waitCount = 0) then
						address_m <= std_logic_vector(to_unsigned(k, 5));
						waitCount := waitCount + 1;
					elsif (waitCount = 1) then
						waitCount := waitCount + 1;
					else
						enc_in := to_integer(unsigned(q_m));
						waitCount := 0;
						state := WRITE_DECRYPTED;
					end if;

				when WRITE_DECRYPTED => 
					if (waitCount = 0) then
						address_d <= std_logic_vector(to_unsigned(k, 5));
						dec_out := to_integer(unsigned(std_logic_vector(to_unsigned(f, 8)) xor std_logic_vector(to_unsigned(enc_in, 8))));
						if ((dec_out <= 122 and dec_out >= 97) or dec_out = 32) then
							data_d <= std_logic_vector(to_unsigned(dec_out, 8));
							wren_d <= '1';
							waitCount := waitCount + 1;
						else
							state := INIT;
						end if;
					elsif (waitCount = 1) then
						waitCount := waitCount + 1;
					else
						k := k + 1;
						if (k = 32) then
							state := DONE;
						else
							state := READ_I_3;
						end if;

						waitCount := 0;
					end if;

				 when others =>
				 	state := DONE;

		 	end case;
 		end if;
	end process;

	DISPLAY_KEY: process(full_secret_key)
		variable result : integer;
		variable digit : integer;
	BEGIN
		result := to_integer(unsigned(full_secret_key));
		digit := (result) mod 10;
		digit0 <= to_unsigned(digit, 4);
		digit := (result / 10) mod 10;
		digit1 <= to_unsigned(digit, 4);
		digit := (result / 100) mod 10;
		digit2 <= to_unsigned(digit, 4);
		digit := (result / 1000) mod 10;
		digit3 <= to_unsigned(digit, 4);
		digit := (result / 10000) mod 10;
		digit4 <= to_unsigned(digit, 4);
		digit := (result / 100000) mod 10;
		digit5 <= to_unsigned(digit, 4);
		digit := (result / 1000000) mod 10;
		digit6 <= to_unsigned(digit, 4);
	end process;
end rtl;


