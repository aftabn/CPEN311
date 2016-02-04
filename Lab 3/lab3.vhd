library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lab3 is
  port(CLOCK_50            : in  std_logic;
    KEY                 : in  std_logic_vector(3 downto 0);
    HEX0 : out std_logic_vector(6 downto 0) := (others => '1');
    HEX1 : out std_logic_vector(6 downto 0) := (others => '1'); 
    HEX2 : out std_logic_vector(6 downto 0) := (others => '1'); 
    HEX3 : out std_logic_vector(6 downto 0) := (others => '1');
    HEX4 : out std_logic_vector(6 downto 0) := (others => '1');
    HEX5 : out std_logic_vector(6 downto 0) := (others => '1'); 
    HEX6 : out std_logic_vector(6 downto 0) := (others => '1'); 
    HEX7 : out std_logic_vector(6 downto 0) := (others => '1');
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

    signal slow_clock : std_logic;
    signal x : std_logic_vector(7 downto 0) := (others => '0');
    signal y : std_logic_vector(6 downto 0) := (others => '0');
    signal colour : std_logic_vector(2 downto 0);
    signal prescaler_counter : unsigned(27 downto 0) := (others => '0');

begin

    process(slow_clock)
        variable x_int : integer;
        variable y_int : integer;
        variable color_int : integer;
    begin
        if (rising_edge(slow_clock)) then
            x_int := to_integer(unsigned(x));
            y_int := to_integer(unsigned(y));

            if (y_int < 119) then
                y_int := y_int + 1;
                color_int := x_int mod 8;
            elsif (x_int < 159) then
                x_int := x_int + 1;
                y_int := 0;
                color_int := x_int mod 8;
            else
                null;
            end if;

            x <= std_logic_vector(to_unsigned(x_int, x'length));
            y <= std_logic_vector(to_unsigned(y_int, y'length));
            colour <= std_logic_vector(to_unsigned(color_int, colour'length));

        end if;
    end process;

    process (CLOCK_50)  
    BEGIN
      if rising_edge (CLOCK_50) THEN 
         prescaler_counter <= prescaler_counter + 1;
         
         if(prescaler_counter > "0000000000000000001111101000") THEN
            slow_clock <= not slow_clock;
            prescaler_counter <= (others => '0');
         end if;

      end if;
    END process;

    vga_u0 : vga_adapter
    generic map(RESOLUTION => "320x240") 
    port map(resetn    => KEY(3),
             clock     => CLOCK_50,
             colour    => colour,
             x         => x,
             y         => y,
             plot      => slow_clock,
             VGA_R     => VGA_R,
             VGA_G     => VGA_G,
             VGA_B     => VGA_B,
             VGA_HS    => VGA_HS,
             VGA_VS    => VGA_VS,
             VGA_BLANK => VGA_BLANK,
             VGA_SYNC  => VGA_SYNC,
             VGA_CLK   => VGA_CLK);


end rtl;


