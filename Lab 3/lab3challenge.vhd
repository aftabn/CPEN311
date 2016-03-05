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

    -- Defining the states needed for drawing
    type state_type is (INIT, CLEAR_SCREEN, OCTANT1, OCTANT2, OCTANT3,  
        OCTANT4, OCTANT5, OCTANT6, OCTANT7, OCTANT8, UPDATE, IDLE);

    -- Pixel colours in gray code
    constant BLACK  : std_logic_vector(2 downto 0) := "000";
    constant BLUE   : std_logic_vector(2 downto 0) := "001";
    constant GREEN  : std_logic_vector(2 downto 0) := "010";
    constant CYAN   : std_logic_vector(2 downto 0) := "011";
    constant RED    : std_logic_vector(2 downto 0) := "100";
    constant PURPLE : std_logic_vector(2 downto 0) := "101";
    constant YELLOW : std_logic_vector(2 downto 0) := "110";
    constant WHITE  : std_logic_vector(2 downto 0) := "111";

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
        variable prevState : state_type := IDLE;
        variable x0 : integer;
        variable y0 : integer;
        variable x1 : integer;
        variable y1 : integer;

        -- For Bresenham Line Algorithm
        variable dx : integer;
        variable dy : integer;
        variable sx : integer;
        variable sy : integer;
        variable err : integer;
        variable e2 : integer;

        -- For Bresenham Circle Algorithm
        variable offset_x : integer := STARTING_RADIUS;
        variable offset_y : integer := 0;
        variable crit : integer := 1 - offset_x;
    BEGIN
        if KEY(3) = '0' then
            state := INIT;

        elsif rising_edge (CLOCK_50) THEN
            x0 := to_integer(unsigned(x));
            y0 := to_integer(unsigned(y));

            case state is
                when INIT => 
                    colour <= BLACK;
                    plot <= '1';
                    state := CLEAR_SCREEN;
                    x0 := 0;
                    y0 := 0;

                when CLEAR_SCREEN =>
                    if (y0 < Y_MAX) then
                        y0 := y0 + 1;
                    elsif (x0 < X_MAX) then
                        x0 := x0 + 1;
                        y0 := 0;
                    else
                        colour <= BLUE;
                        state := OCTANT1_5;
                        prevState := OCTANT1_5;
                    end if;

                when OCTANT1_5 =>
                    x0 := CENTER_X + offset_x;
                    y0 := CENTER_Y + offset_y;

                    x1 := CENTER_X - offset_x;
                    y1 := CENTER_Y - offset_y;

                    state := DRAW_LINE;

                when OCTANT2_6 =>
                    x0 := CENTER_X + offset_y;
                    y0 := CENTER_Y + offset_x;

                    x1 := CENTER_X - offset_y;
                    y1 := CENTER_Y - offset_x;

                    state := DRAW_LINE;

                when OCTANT3_7 =>
                    x0 := CENTER_X - offset_y;
                    y0 := CENTER_Y + offset_x;

                    x1 := CENTER_X + offset_x;
                    y1 := CENTER_Y - offset_y;

                    state := DRAW_LINE;

                when OCTANT4_8 =>
                    x0 := CENTER_X - offset_x;
                    y0 := CENTER_Y + offset_y;

                    x1 := CENTER_X + offset_y;
                    y1 := CENTER_Y - offset_x;

                    state := DRAW_LINE;

                when START_LINE =>
                    dx := abs(x1 - x0);
                    dy := abs(y1 - y0);

                    if (x0 < x1) then
                        sx := 1;
                    else 
                        sx := -1;
                    end if;

                    if (y0 < y1) then
                        sy := 1;
                    else 
                        sy := -1;
                    end if;

                    err := dx - dy;

                when DRAW_LINE =>
                    if (x0 = x1 and y0 = y1) then
                        case prevState is
                            when OCTANT1_5 => state := OCTANT2_6;
                            when OCTANT2_6 => state := OCTANT3_7;
                            when OCTANT3_7 => state := OCTANT4_8;
                            when OCTANT4_8 => state := UPDATE_CIRCLE;
                        state := <INSERT NEXT STATE>

                    x1 := CENTER_X + offset_y;
                    y1 := CENTER_Y - offset_x;

                    state := DRAW_LINE;

                when UPDATE_LINE =>


                when UPDATE_CIRCLE =>
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
                        state := IDLE;
                    end if;
                
                when IDLE =>
                    plot <= '0';

                when others =>
                    state := IDLE;
            end case;

            x <= std_logic_vector(to_unsigned(x0, x'length));
            y <= std_logic_vector(to_unsigned(y0, y'length));

        end if;
    END process;
end rtl;


