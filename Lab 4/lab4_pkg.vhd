library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--
-- This is a package that provides useful constants and types for Lab 4.
-- 

package lab4_pkg is
    constant SCREEN_WIDTH  : positive := 160;
    constant SCREEN_HEIGHT : positive := 120;
    constant FRAC_BITS : natural := 8;
    constant INT_BITS : natural := 8;
    constant GRAVITY : unsigned(15 downto 0) := "00000000" & "00000110";

    -- Use the same precision for x and y as it simplifies life
    -- A new type that describes a pixel location on the screen
    type point is record
        x : unsigned(7 downto 0);
        y : unsigned(7 downto 0);
    end record;

    type fractional_point is record
        x : unsigned(FRAC_BITS + INT_BITS - 1 downto 0);
        y : unsigned(FRAC_BITS + INT_BITS - 1 downto 0);
    end record;

    -- A new type that describes a velocity.  Each component of the
    -- velocity can be either + or -, so use signed type
    type fractional_velocity is record
        x : signed(FRAC_BITS + INT_BITS - 1 downto 0);
        y : signed(FRAC_BITS + INT_BITS - 1 downto 0);
    end record;

    --Colours.  
    constant BLACK : std_logic_vector(2 downto 0) := "000";
    constant BLUE  : std_logic_vector(2 downto 0) := "001";
    constant GREEN : std_logic_vector(2 downto 0) := "010";
    constant CYAN : std_logic_vector(2 downto 0) := "011";
    constant RED   : std_logic_vector(2 downto 0) := "100";
    constant PURPLE : std_logic_vector(2 downto 0) := "101";
    constant YELLOW   : std_logic_vector(2 downto 0) := "110";
    constant WHITE : std_logic_vector(2 downto 0) := "111";

    -- We are going to write this as a state machine.  The following
    -- is a list of states that the state machine can be in.

    type turn_state_type is (TURN_GREEN, TURN_RED);

    type draw_state_type is (INIT, START, DRAW_TOP_ENTER, DRAW_TOP_LOOP, 
		DRAW_RIGHT_ENTER, DRAW_RIGHT_LOOP, DRAW_LEFT_ENTER,  DRAW_LEFT_LOOP, IDLE, 
        ERASE_PADDLE_GREEN_ENTER, ERASE_PADDLE_GREEN_LOOP, ERASE_PADDLE_RED_ENTER, ERASE_PADDLE_RED_LOOP, 
        DRAW_PADDLE_GREEN_ENTER, DRAW_PADDLE_GREEN_LOOP, DRAW_PADDLE_RED_ENTER, DRAW_PADDLE_RED_LOOP, 
        ERASE_PUCK, DRAW_PUCK);

    -- These constants contain information about the paddle 
    constant PADDLE_MAX_WIDTH : natural := 10;  -- width, in pixels, of the paddle
    constant PADDLE_MIN_WIDTH : natural := 4;  -- width, in pixels, of the paddle
    constant PADDLE_GREEN_ROW : natural := SCREEN_HEIGHT - 2;  -- row to draw the paddle 
    constant PADDLE_RED_ROW : natural := SCREEN_HEIGHT - 4;  -- row to draw the paddle 
    constant PADDLE_X_START : natural := SCREEN_WIDTH / 2;  -- starting x position of the paddle

    -- These constants describe the lines that are drawn around the  
    -- border of the screen  
    constant TOP_LINE : natural := 4;
    constant RIGHT_LINE : natural := SCREEN_WIDTH - 5;
    constant LEFT_LINE : natural := 5;

    -- These constants describe the starting location for the puck 
    constant FACEOFF_X : natural := SCREEN_WIDTH/2;
    constant FACEOFF_Y : natural := (SCREEN_HEIGHT/2);

    -- This constant indicates how many times the counter should count in the
    -- START state between each invocation of the main loop of the program.
    -- A larger value will result in a slower game.  The current setting will    
    -- cause the machine to wait in the start state for 1/8 of a second between 
    -- each invocation of the main loop.  The 50000000 is because we are
    -- clocking our circuit with  a 50Mhz clock.
    constant LOOP_FREQUENCY : natural := 20; 
    constant SHRINK_SECONDS : natural := 10;
    constant LOOP_SPEED : natural := 50000000/LOOP_FREQUENCY;  -- LOOP_FREQUENCY Hz
    constant SHRINK_PERIOD : natural := LOOP_FREQUENCY * SHRINK_SECONDS;

    --Component from the Verilog file: vga_adapter.v
    component vga_adapter
    generic(RESOLUTION : string);
    port (resetn                                       : in  std_logic;
          clock                                        : in  std_logic;
          colour                                       : in  std_logic_vector(2 downto 0);
          x                                            : in  std_logic_vector(7 downto 0);
          y                                            : in  std_logic_vector(6 downto 0);
          plot                                         : in  std_logic;
          VGA_R, VGA_G, VGA_B                          : out std_logic_vector(9 downto 0);
          VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC, VGA_CLK : out std_logic);
    end component;
end;

package body lab4_pkg is
end package body;
