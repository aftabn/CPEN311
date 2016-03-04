library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.lab4_pkg.all; -- types and constants

entity lab4 is
  port(CLOCK_50            : in  std_logic;  -- Clock pin
       KEY                 : in  std_logic_vector(3 downto 0);  -- push button switches
       SW                  : in  std_logic_vector(17 downto 0);  -- slider switches
       VGA_R, VGA_G, VGA_B : out std_logic_vector(9 downto 0);  -- The outs go to VGA controller
       VGA_HS              : out std_logic;
       VGA_VS              : out std_logic;
       VGA_BLANK           : out std_logic;
       VGA_SYNC            : out std_logic;
       VGA_CLK             : out std_logic);
end lab4;

-- Architecture part of the description
architecture rtl of lab4 is

	-- These are signals that will be connected to the VGA adapater.
	-- The VGA adapater was described in the Lab 3 handout.
	signal resetn : std_logic;
	signal x      : std_logic_vector(7 downto 0);
	signal y      : std_logic_vector(6 downto 0);
	signal colour : std_logic_vector(2 downto 0);
	signal plot   : std_logic;
	signal draw   : point;

	

begin

	vga_u0 : vga_adapter
	generic map(RESOLUTION => "160x120") 
	port map(resetn    => KEY(3),
	         clock     => CLOCK_50,
	         colour    => colour,
	         x         => x,
	         y         => y,
	         plot      => plot,
	         VGA_R     => VGA_R,
	         VGA_G     => VGA_G,
	         VGA_B     => VGA_B,
	         VGA_HS    => VGA_HS,
	         VGA_VS    => VGA_VS,
	         VGA_BLANK => VGA_BLANK,
	         VGA_SYNC  => VGA_SYNC,
	         VGA_CLK   => VGA_CLK);

	-- the x and y lines of the VGA controller will be always
	-- driven by draw.x and draw.y.   The process below will update
	-- signals draw.x and draw.y.
	x <= std_logic_vector(draw.x(x'range));
	y <= std_logic_vector(draw.y(y'range));


	controller_state : process(CLOCK_50, KEY)	 

		variable state : draw_state_type := START; 
		variable turn : turn_state_type := TURN_GREEN;

		-- This variable will store the x position of the paddle (left-most pixel of the paddle)
		variable paddle_green_x : unsigned(draw.x'range);
		variable paddle_red_x : unsigned(draw.x'range);

		-- These variables will store the puck and the puck velocity.
		-- In this implementation, the puck velocity has two components: an x component
		-- and a y component.  Each component is always +1 or -1.
		variable puck : fractional_point;
		variable puck_velocity : fractional_velocity;

		-- Counter used in the IDLE state
		variable clock_counter : natural := 0;

		variable paddle_width : natural := PADDLE_MAX_WIDTH;
		variable shrink_counter : natural := 0;
		
	begin
	    if KEY(3) = '0' then
				draw <= (x => to_unsigned(0, draw.x'length), 
						y => to_unsigned(0, draw.y'length));			  
				paddle_green_x := to_unsigned(PADDLE_X_START, paddle_green_x'length);
				paddle_red_x := to_unsigned(PADDLE_X_START, paddle_red_x'length);
		     	paddle_width := PADDLE_MAX_WIDTH;
				puck.x := to_unsigned(FACEOFF_X, 8 ) & "00000000";
				puck.y := to_unsigned(FACEOFF_Y, 8 ) & "00000000";
				puck_velocity.x := "00000000" & "11110101";
				puck_velocity.y := "11111111" & "01000000";
				colour <= BLACK;
			  	turn := TURN_GREEN;
			  	plot <= '1';
		     	state := INIT;
		     	shrink_counter := 0;
		
	    elsif rising_edge(CLOCK_50) then
				
	      	case state is

			  	when INIT =>
	           		draw <= (x => to_unsigned(0, draw.x'length), 
						y => to_unsigned(0, draw.y'length));			  
					paddle_green_x := to_unsigned(PADDLE_X_START, paddle_green_x'length);
					paddle_red_x := to_unsigned(PADDLE_X_START, paddle_red_x'length);
			     	paddle_width := PADDLE_MAX_WIDTH;
					puck.x := to_unsigned(FACEOFF_X, 8 ) & "00000000";
					puck.y := to_unsigned(FACEOFF_Y, 8 ) & "00000000";
					puck_velocity.x := "00000000" & "11110101";
					puck_velocity.y := "11111111" & "01000000";
					colour <= BLACK;
				  	turn := TURN_GREEN;
				  	plot <= '1';
			     	state := START;
			     	shrink_counter := 0;

			  	-- Erases the screen and then moves on to drawing the game
		        when START =>	
		          	if draw.x = SCREEN_WIDTH-1 then
			            if draw.y = SCREEN_HEIGHT-1 then
			              	state := DRAW_TOP_ENTER;	
			            else
			              	draw.y <= draw.y + to_unsigned(1, draw.y'length);
			   			  	draw.x <= to_unsigned(0, draw.x'length);				  
			            end if;
		          	else	
		            	draw.x <= draw.x + to_unsigned(1, draw.x'length);
		          	end if;

	          	-- Starts drawing the first pixel of the top line
			  	when DRAW_TOP_ENTER =>				
			     	draw.x <= to_unsigned(LEFT_LINE, draw.x'length);
				  	draw.y <= to_unsigned(TOP_LINE, draw.y'length);
				  	colour <= WHITE;
				  	state := DRAW_TOP_LOOP;
				 
				-- Finishes drawing the top line 
		        when DRAW_TOP_LOOP =>	
					if draw.x = RIGHT_LINE then
						state := DRAW_RIGHT_ENTER; -- next state is DRAW_RIGHT
					else
						draw.y <= to_unsigned(TOP_LINE, draw.y'length);
						draw.x <= draw.x + to_unsigned(1, draw.x'length);
					end if;

	          	-- Starts drawing the first pixel of the right line
			  	when DRAW_RIGHT_ENTER =>				
					draw.y <= to_unsigned(TOP_LINE, draw.x'length);
					draw.x <= to_unsigned(RIGHT_LINE, draw.x'length);	
					state := DRAW_RIGHT_LOOP;
	   		  
				-- Finishes drawing the right line 
			  	when DRAW_RIGHT_LOOP =>	
					if draw.y = SCREEN_HEIGHT-1 then
						state := DRAW_LEFT_ENTER;	-- next state is DRAW_LEFT
					else
						draw.x <= to_unsigned(RIGHT_LINE,draw.x'length);
						draw.y <= draw.y + to_unsigned(1, draw.y'length);
					end if;	

	          	-- Starts drawing the first pixel of the left line
			  	when DRAW_LEFT_ENTER =>				
					draw.y <= to_unsigned(TOP_LINE, draw.x'length);
					draw.x <= to_unsigned(LEFT_LINE, draw.x'length);	
					state := DRAW_LEFT_LOOP;
	   		  
				-- Finishes drawing the left line 
				when DRAW_LEFT_LOOP =>
					if draw.y = SCREEN_HEIGHT-1 then
						state := IDLE;  -- next state is IDLE
						clock_counter := 0;  -- initialize counter we will use in IDLE  
						shrink_counter := 0;  -- initialize counter we will use in IDLE  
					else
						draw.x <= to_unsigned(LEFT_LINE, draw.x'length);
						draw.y <= draw.y + to_unsigned(1, draw.y'length);
					end if;	
					  
				-- Delays the game until the clock_counter reaches loop speed (default is 8Hz)
				when IDLE =>  
					plot <= '0';  -- nothing to draw while we are in this state
					if clock_counter < LOOP_SPEED then
						clock_counter := clock_counter + 1;
					else 
						shrink_counter := shrink_counter + 1;

						if(shrink_counter > SHRINK_PERIOD) THEN
							shrink_counter := 0;	

							if (paddle_width > PADDLE_MIN_WIDTH) then
								paddle_width := paddle_width - 1;
							end if;
						end if;

						clock_counter := 0;
						state := ERASE_PADDLE_GREEN_ENTER;  -- next state

					end if;

				-- Starts erasing the first pixel of the paddle
				when ERASE_PADDLE_GREEN_ENTER =>		  
					draw.y <= to_unsigned(PADDLE_GREEN_ROW, draw.y'length);
					draw.x <= paddle_green_x;	
					colour <= BLACK;
					plot <= '1';			
					state := ERASE_PADDLE_GREEN_LOOP;				 

				-- Finishes erasing the paddle
				when ERASE_PADDLE_GREEN_LOOP =>
					--if draw.x = paddle_green_x + paddle_width then	
					if draw.x = RIGHT_LINE - 1 then		
						state := ERASE_PADDLE_RED_ENTER; 
					else
						draw.y <= to_unsigned(PADDLE_GREEN_ROW, draw.y'length);
						draw.x <= draw.x + to_unsigned(1, draw.x'length);
					end if;

				-- Starts erasing the first pixel of the paddle
				when ERASE_PADDLE_RED_ENTER =>		  
					draw.y <= to_unsigned(PADDLE_RED_ROW, draw.y'length);
					draw.x <= paddle_red_x;	
					colour <= BLACK;
					plot <= '1';			
					state := ERASE_PADDLE_RED_LOOP;				 

				-- Finishes erasing the paddle
				when ERASE_PADDLE_RED_LOOP =>
					--if draw.x = paddle_red_x + paddle_width then		
					if draw.x = RIGHT_LINE - 1 then	
						state := DRAW_PADDLE_GREEN_ENTER;  -- next state is DRAW_PADDLE 
					else
						draw.y <= to_unsigned(PADDLE_RED_ROW, draw.y'length);
						draw.x <= draw.x + to_unsigned(1, draw.x'length);
					end if;

				-- Starts drawing the first pixel of the paddle
				when DRAW_PADDLE_GREEN_ENTER =>
					if (SW(0) = '1') then 
						if paddle_green_x < to_unsigned(RIGHT_LINE - paddle_width - 2, paddle_green_x'length) then 				 
							paddle_green_x := paddle_green_x + to_unsigned(2, paddle_green_x'length);						
						elsif paddle_green_x = to_unsigned(RIGHT_LINE - paddle_width - 2, paddle_green_x'length) then
							paddle_green_x := paddle_green_x + to_unsigned(1, paddle_green_x'length);
						end if;
					else
						if paddle_green_x > to_unsigned(LEFT_LINE + 2, paddle_green_x'length) then 				 
							paddle_green_x := paddle_green_x - to_unsigned(2, paddle_green_x'length);						
						elsif paddle_green_x = to_unsigned(LEFT_LINE + 2, paddle_green_x'length)  then
							paddle_green_x := paddle_green_x - to_unsigned(1, paddle_green_x'length);
						end if;
					end if;

					draw.y <= to_unsigned(PADDLE_GREEN_ROW, draw.y'length);				  
					draw.x <= paddle_green_x;  -- get ready for next state			  
					colour <= GREEN; -- when we draw the paddle, the colour will be GREEN		  
					state := DRAW_PADDLE_GREEN_LOOP;

				-- Finishes drawing the paddle
				when DRAW_PADDLE_GREEN_LOOP =>
					if draw.x = paddle_green_x + paddle_width then
						plot  <= '1';  
						state := DRAW_PADDLE_RED_ENTER;	-- next state is ERASE_PUCK
					else		
						draw.y <= to_unsigned(PADDLE_GREEN_ROW, draw.y'length);
						draw.x <= draw.x + to_unsigned(1, draw.x'length);
					end if;
	
				-- Starts drawing the first pixel of the paddle
				when DRAW_PADDLE_RED_ENTER =>
					if (SW(17) = '1') then 
						if paddle_red_x < to_unsigned(RIGHT_LINE - paddle_width - 2, paddle_red_x'length) then 				 
							paddle_red_x := paddle_red_x + to_unsigned(2, paddle_red_x'length);						
						elsif paddle_red_x = to_unsigned(RIGHT_LINE - paddle_width - 2, paddle_red_x'length) then
							paddle_red_x := paddle_red_x + to_unsigned(1, paddle_red_x'length);
						end if;
					else
						if paddle_red_x > to_unsigned(LEFT_LINE + 2, paddle_red_x'length) then 				 
							paddle_red_x := paddle_red_x - to_unsigned(2, paddle_red_x'length) ;						
						elsif paddle_red_x = to_unsigned(LEFT_LINE + 2, paddle_red_x'length) then 				 
							paddle_red_x := paddle_red_x - to_unsigned(1, paddle_red_x'length) ;						
						end if;
					end if;

					draw.y <= to_unsigned(PADDLE_RED_ROW, draw.y'length);				  
					draw.x <= paddle_red_x;  -- get ready for next state			  
					colour <= RED; -- when we draw the paddle, the colour will be GREEN		  
					state := DRAW_PADDLE_RED_LOOP;

				-- Finishes drawing the paddle
				when DRAW_PADDLE_RED_LOOP =>
					if draw.x = paddle_red_x + paddle_width then
						plot  <= '0';  
						state := ERASE_PUCK;	-- next state is ERASE_PUCK
					else		
						draw.y <= to_unsigned(PADDLE_RED_ROW, draw.y'length);
						draw.x <= draw.x + to_unsigned(1, draw.x'length);
					end if;

				when ERASE_PUCK =>
					colour <= BLACK;  -- erase by setting colour to black
					plot <= '1';
					draw.x <= puck.x(15 downto 8);
					draw.y <= puck.y(15 downto 8);
					state := DRAW_PUCK;  -- next state is DRAW_PUCK.

					-- Factor in acceleration from gravity
					puck_velocity.y := puck_velocity.y + signed(GRAVITY);

					puck.x := unsigned( signed(puck.x) + puck_velocity.x);
					puck.y := unsigned( signed(puck.y) + puck_velocity.y);	

					-- Correct for updated position being past the boundaries
					if puck.x(15 downto 8) <= LEFT_LINE then
						puck.x := to_unsigned(LEFT_LINE + 1, 8) & "00000000";
					end if;
					if puck.x(15 downto 8) >= RIGHT_LINE then
						puck.x := to_unsigned(RIGHT_LINE - 1, 8) & "00000000";
					end if;
					if puck.y(15 downto 8) <= TOP_LINE then
						puck.y := to_unsigned(TOP_LINE + 1, 8) & "00000000";
					end if;
					if puck.y(15 downto 8) >= PADDLE_GREEN_ROW then
						puck.y := to_unsigned(PADDLE_GREEN_ROW - 1, 8) & "00000000";
					end if;

					-- Check if we've hit the top wall
					if puck.y(15 downto 8) = TOP_LINE + 1 then
						puck_velocity.y := 0 - puck_velocity.y;
					end if;

					-- Check if we've hit the left or right walls 
					if puck.x(15 downto 8) = LEFT_LINE + 1 or puck.x(15 downto 8) = RIGHT_LINE - 1 then
						puck_velocity.x := 0 - puck_velocity.x;
					end if;			

					-- TODO: Add accidental collision detection from red as puck leaves green
					if turn = TURN_GREEN then
						-- Check for accidental red collision first
						if puck.y(15 downto 8) = PADDLE_RED_ROW - 1 or puck.y(15 downto 8) = PADDLE_RED_ROW then 
							if puck.x(15 downto 8) >= paddle_red_x and puck.x(15 downto 8) <= paddle_red_x + paddle_width then
								state := INIT;
							end if;
						-- Check if green hit it
						elsif puck.y(15 downto 8) = PADDLE_GREEN_ROW - 1 then
							if puck.x(15 downto 8) >= paddle_green_x and puck.x(15 downto 8) <= paddle_green_x + paddle_width then
								puck_velocity.y := 0 - puck_velocity.y;
								turn := TURN_RED;
							else
								state := INIT;
							end if;	  
						end if;


					else -- RED's turn
						if puck_velocity.y > 0 then
							if puck.y(15 downto 8) = PADDLE_RED_ROW - 1 then
								if puck.x(15 downto 8) >= paddle_red_x and puck.x(15 downto 8) <= paddle_red_x + paddle_width then
									puck_velocity.y := 0 - puck_velocity.y;
									turn := TURN_GREEN;
								else
									state := INIT;
								end if;	  
							end if;
						end if;
					end if;

				when DRAW_PUCK =>
					if turn = TURN_GREEN then
						colour <= GREEN;
					else 
						colour <= RED;
					end if;

					plot <= '1';
					draw.x <= puck.x(15 downto 8);
				  	draw.y <= puck.y(15 downto 8);
					state := IDLE;	  -- next state is IDLE (which is the delay state)			  

				-- We'll never get here, but good practice to include it anyway
				when others =>
					state := START;

	      	end case;
	 	end if;
   end process;
end rtl;


