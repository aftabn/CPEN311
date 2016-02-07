-- ******************************
-- Name: lab3.vhdl
-- Created: February 7, 2016
-- Author: Aftab
-- ******************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lab3 is
  port(CLOCK_50         : in  std_logic;
    KEY                 : in  std_logic_vector(3 downto 0);
    HEX0                : out std_logic_vector(6 downto 0) := (others => '1');
    HEX1                : out std_logic_vector(6 downto 0) := (others => '1'); 
    HEX2                : out std_logic_vector(6 downto 0) := (others => '1'); 
    HEX3                : out std_logic_vector(6 downto 0) := (others => '1');
    HEX4                : out std_logic_vector(6 downto 0) := (others => '1');
    HEX5                : out std_logic_vector(6 downto 0) := (others => '1'); 
    HEX6                : out std_logic_vector(6 downto 0) := (others => '1'); 
    HEX7                : out std_logic_vector(6 downto 0) := (others => '1');
    VGA_R, VGA_G, VGA_B : out std_logic_vector(9 downto 0);  -- The outs go to VGA controller
    VGA_HS              : out std_logic;
    VGA_VS              : out std_logic;
    VGA_BLANK           : out std_logic;
    VGA_SYNC            : out std_logic;
    VGA_CLK             : out std_logic);
end lab3;

architecture rtl of lab3 is

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

    -- Pixel colours in gray code
    constant BLACK  : std_logic_vector(2 downto 0) := "000";
    constant BLUE   : std_logic_vector(2 downto 0) := "001";
    constant GREEN  : std_logic_vector(2 downto 0) := "010";
    constant CYAN   : std_logic_vector(2 downto 0) := "011";
    constant RED    : std_logic_vector(2 downto 0) := "100";
    constant PURPLE : std_logic_vector(2 downto 0) := "101";
    constant YELLOW : std_logic_vector(2 downto 0) := "110";
    constant WHITE  : std_logic_vector(2 downto 0) := "111";

    function GRAY_COLOR(X : integer) 
                return std_logic_vector is
    begin 
        if (X = 0) then
            return BLACK;
        elsif (X = 1) then
            return BLUE;
        elsif (X = 2) then
            return CYAN;
        elsif (X = 3) then
            return GREEN;
        elsif (X = 4) then
            return YELLOW;
        elsif (X = 5) then
            return WHITE;
        elsif (X = 6) then
            return PURPLE;
        elsif (X = 7) then
            return RED;
        else 
            return BLACK;
        end if;
    end GRAY_COLOR;


    -- Defining the states needed for drawing
    type state_type is (INIT, CLEAR_SCREEN, START, OCTANT1, OCTANT2, 
        OCTANT3, OCTANT4, OCTANT5, OCTANT6, OCTANT7, OCTANT8, UPDATE, IDLE);

    -- Bottom right corner of the screen
    constant X_MAX : integer := 159;
    constant Y_MAX : integer := 119;

    -- Constants for Bresenham Circle algorithm
    constant STARTING_RADIUS : integer := 30;
    constant CENTER_X : integer := 60;
    constant CENTER_Y : integer := 60;



    signal x : std_logic_vector(7 downto 0) := (others => '0');
    signal y : std_logic_vector(6 downto 0) := (others => '0');
    signal colour : std_logic_vector(2 downto 0);
    signal plot : std_logic;

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

    process (CLOCK_50, KEY(3))  
        variable state : state_type := IDLE;
        variable circleCount : integer := 1;
        variable x_int : integer;
        variable y_int : integer;
        variable radius : integer := STARTING_RADIUS;
        variable offset_x : integer;
        variable offset_y : integer;
        variable crit : integer;
    BEGIN
        if KEY(3) = '0' then
            state := INIT;

        elsif rising_edge (CLOCK_50) THEN
            x_int := to_integer(unsigned(x));
            y_int := to_integer(unsigned(y));

            case state is
                when INIT => 
                    colour <= BLACK;
                    plot <= '1';
                    state := CLEAR_SCREEN;

                when CLEAR_SCREEN =>
                    if (y_int < Y_MAX) then
                        y_int := y_int + 1;
                    elsif (x_int < X_MAX) then
                        x_int := x_int + 1;
                        y_int := 0;
                    else
                        state := START;
                    end if;

                when START =>
                    offset_x := radius;
                    offset_y := 0;
                    crit := 1 - offset_x;
                    colour <= GRAY_COLOR(circleCount);
                    state := OCTANT1;

                when OCTANT1 =>
                    x_int := CENTER_X + offset_x;
                    y_int := CENTER_Y + offset_y;
                    state := OCTANT2;

                when OCTANT2 =>
                    x_int := CENTER_X + offset_y;
                    y_int := CENTER_Y + offset_x;
                    state := OCTANT3;

                when OCTANT3 =>
                    x_int := CENTER_X - offset_y;
                    y_int := CENTER_Y + offset_x;
                    state := OCTANT4;

                when OCTANT4 =>
                    x_int := CENTER_X - offset_x;
                    y_int := CENTER_Y + offset_y;
                    state := OCTANT5;

                when OCTANT5 =>
                    x_int := CENTER_X - offset_x;
                    y_int := CENTER_Y - offset_y;
                    state := OCTANT6;

                when OCTANT6 =>
                    x_int := CENTER_X - offset_y;
                    y_int := CENTER_Y - offset_x;
                    state := OCTANT7;

                when OCTANT7 =>
                    x_int := CENTER_X + offset_x;
                    y_int := CENTER_Y - offset_y;
                    state := OCTANT8;

                when OCTANT8 =>
                    x_int := CENTER_X + offset_y;
                    y_int := CENTER_Y - offset_x;
                    state := UPDATE;

                when UPDATE =>
                    -- Apply Bresenham algorithm updates
                    offset_y := offset_y + 1;

                    if (crit <= 0) then
                        crit := crit + (2 * offset_y) + 1;
                    else
                        offset_x := offset_x - 1;
                        crit := crit + (2 * (offset_y - offset_x)) + 1;
                    end if;

                    if (offset_y <= offset_x) then
                        state := OCTANT1;
                    else
                        -- Check if done drawing circles
                        if (circleCount < 7) then
                            circleCount := circleCount + 1;
                            radius := 30 - (2 * circleCount);
                            state := START;
                        else 
                            state := IDLE;
                        end if;
                    end if;
                
                when IDLE =>
                    plot <= '0';

                when others =>
                    state := IDLE;
            end case;

            x <= std_logic_vector(to_unsigned(x_int, x'length));
            y <= std_logic_vector(to_unsigned(y_int, y'length));

        end if;
    END process;
end rtl;


