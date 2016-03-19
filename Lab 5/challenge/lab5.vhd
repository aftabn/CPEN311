LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY lab5 IS
	PORT (
		CLOCK_50, AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK, AUD_ADCDAT : IN STD_LOGIC;
		CLOCK_27 : IN STD_LOGIC;
		KEY : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
		SW : IN STD_LOGIC_VECTOR(17 DOWNTO 0);

		I2C_SDAT : INOUT STD_LOGIC;
		I2C_SCLK, AUD_DACDAT, AUD_XCK : OUT STD_LOGIC
	);
END lab5;

ARCHITECTURE Behavior OF lab5 IS

	-- CODEC Cores

	COMPONENT clock_generator
		PORT (
			CLOCK_27 : IN STD_LOGIC;
			reset : IN STD_LOGIC;
			AUD_XCK : OUT STD_LOGIC
		);
	END COMPONENT;

	COMPONENT audio_and_video_config
		PORT ( 
			CLOCK_50, reset : IN STD_LOGIC;
			I2C_SDAT : INOUT STD_LOGIC;
			I2C_SCLK : OUT STD_LOGIC
		);
	END COMPONENT;

	COMPONENT audio_codec  
		PORT (
			CLOCK_50, reset, read_s, write_s : IN STD_LOGIC;
			writedata_left, writedata_right : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
			AUD_ADCDAT, AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK : IN STD_LOGIC;
			read_ready, write_ready : OUT STD_LOGIC;
			readdata_left, readdata_right : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
			AUD_DACDAT : OUT STD_LOGIC
		);
	END COMPONENT;

	COMPONENT rom1_p
		PORT
		(
			address		: IN STD_LOGIC_VECTOR (4 DOWNTO 0);
			clock		: IN STD_LOGIC  := '1';
			q		: OUT STD_LOGIC_VECTOR (3 DOWNTO 0)
		);
	END COMPONENT;

	TYPE notes_array_type IS ARRAY (6 downto 0) of INTEGER;
	TYPE write_state IS (WRITTEN, WAITING);

	CONSTANT MAX_AMPLITUDE : POSITIVE := 65535;
	CONSTANT C4 : POSITIVE := 92;
	CONSTANT D4 : POSITIVE := 82;
	CONSTANT E4 : POSITIVE := 73;
	CONSTANT F4 : POSITIVE := 69;
	CONSTANT G4 : POSITIVE := 61;
	CONSTANT A4 : POSITIVE := 55;
	CONSTANT B4 : POSITIVE := 49;
	CONSTANT NOTES : notes_array_type := (C4, D4, E4, F4, G4, A4, B4);
	CONSTANT HALF_SECOND_COUNT : positive := 50000000 / 2; -- 50Mhz / 0.5 Hz

	SIGNAL max_note_count : INTEGER;
	SIGNAL current_address : STD_LOGIC_VECTOR (4 downto 0) := "00000";
	SIGNAL rom_out : STD_LOGIC_VECTOR (3 downto 0);

	SIGNAL read_ready, write_ready, read_s, write_s : STD_LOGIC;
	SIGNAL writedata_left, writedata_right : STD_LOGIC_VECTOR(23 DOWNTO 0);
	SIGNAL readdata_left, readdata_right : STD_LOGIC_VECTOR(23 DOWNTO 0);
	SIGNAL reset : STD_LOGIC;
 

BEGIN
	reset <= NOT(KEY(0));
	read_s <= '0';

	add_sample : PROCESS(CLOCK_50)
		VARIABLE note_count : INTEGER := 0;
		VARIABLE clock_counter : INTEGER := 0;
		VARIABLE current_amplitude : INTEGER := MAX_AMPLITUDE;
		VARIABLE current_write_state : write_state := WAITING;
	BEGIN
		IF (rising_edge(CLOCK_50)) THEN
			IF (reset = '1') THEN
				note_count := 0;
				current_amplitude := MAX_AMPLITUDE;
				current_write_state := WAITING;
				clock_counter := 0;
				write_s <= '0';
			ELSE
				-- Trigger note change every 0.5s
				IF (clock_counter >= HALF_SECOND_COUNT) then
					clock_counter := 0;
					
					if (current_address = "00110") then
						current_address <= "00000";
					else
						current_address <= std_logic_vector(unsigned(current_address) + "00001");
					end if;
				ELSE	
					clock_counter := clock_counter + 1;
				end if;

				-- Oscillate wave based on frequency
				IF (note_count >= max_note_count) THEN
					note_count := 0;
					current_amplitude := 1 - current_amplitude;
				END IF;

				-- Write the amplitude to audio codec or wait for new FIFO sample to empty
				IF (current_write_state = WAITING) THEN
					IF (write_ready = '1') THEN
						writedata_left <= STD_LOGIC_VECTOR(to_signed(current_amplitude, 24));
						writedata_right <= STD_LOGIC_VECTOR(to_signed(current_amplitude, 24));
						write_s <= '1';
						note_count := note_count + 1;
						current_write_state := WRITTEN;
					END IF;
				ELSE
					IF (write_ready = '0') THEN
						write_s <= '0';
						current_write_state := WAITING;
					END IF;
				END IF;
			END IF;
		END IF;
	END PROCESS;

	change_note : PROCESS(current_address)
		VARIABLE address : unsigned(4 downto 0) := unsigned(current_address);
	BEGIN
		if (current_address >= "00000" and current_address < "00111") then
			max_note_count <= NOTES(to_integer(signed(rom_out)));
		else
			max_note_count <= 1000000;
		end if;
	END PROCESS;

	my_clock_gen : clock_generator PORT MAP(CLOCK_27, reset, AUD_XCK);
	cfg : audio_and_video_config PORT MAP(CLOCK_50, reset, I2C_SDAT, I2C_SCLK);
	codec : audio_codec PORT MAP(
		CLOCK_50, reset, read_s, write_s, writedata_left, writedata_right, 
		AUD_ADCDAT, AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, read_ready, write_ready, readdata_left, 
		readdata_right, AUD_DACDAT
	);
	rom : rom1_p PORT MAP (current_address, CLOCK_50, rom_out);

	-- rest of your code goes here
END Behavior;