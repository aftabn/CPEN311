LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY task2 IS
	PORT (
		CLOCK_50, AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK, AUD_ADCDAT : IN STD_LOGIC;
		CLOCK_27 : IN STD_LOGIC;
		KEY : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
		SW : IN STD_LOGIC_VECTOR(17 DOWNTO 0);

		I2C_SDAT : INOUT STD_LOGIC;
		I2C_SCLK, AUD_DACDAT, AUD_XCK : OUT STD_LOGIC
	);
END task2;

ARCHITECTURE Behavior OF task2 IS

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

	TYPE write_state IS (WRITTEN, WAITING);

	--CONSTANT HALF_SECOND_COUNT : positive := 50000000 * 2; -- 50Mhz / 0.5 Hz
	CONSTANT MAX_AMPLITUDE : POSITIVE := 65535;
	CONSTANT MIDDLE_C : POSITIVE := 262;
	CONSTANT MIDDLE_C_COUNT : POSITIVE := 48000 / 262 / 2;

	SIGNAL read_ready, write_ready, read_s, write_s : STD_LOGIC;
	SIGNAL writedata_left, writedata_right : STD_LOGIC_VECTOR(23 DOWNTO 0);
	SIGNAL readdata_left, readdata_right : STD_LOGIC_VECTOR(23 DOWNTO 0);
	SIGNAL reset : STD_LOGIC;
 

BEGIN
	reset <= NOT(KEY(0));
	read_s <= '0';

	add_sample : PROCESS(CLOCK_50)
		--VARIABLE current_state : note_state := MIDDLE_C;
		VARIABLE note_count : INTEGER := 0;
		VARIABLE current_amplitude : INTEGER := MAX_AMPLITUDE;
		VARIABLE current_write_state : write_state := WAITING;
	BEGIN
		IF (rising_edge(CLOCK_50)) THEN
			IF (note_count >= MIDDLE_C_COUNT) THEN
				note_count := 0;
				current_amplitude := 1 - current_amplitude;
			END IF;

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

	END PROCESS;

	my_clock_gen : clock_generator PORT MAP(CLOCK_27, reset, AUD_XCK);
	cfg : audio_and_video_config PORT MAP(CLOCK_50, reset, I2C_SDAT, I2C_SCLK);
	codec : audio_codec PORT MAP(
		CLOCK_50, reset, read_s, write_s, writedata_left, writedata_right, 
		AUD_ADCDAT, AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, read_ready, write_ready, readdata_left, 
		readdata_right, AUD_DACDAT
	);

	-- rest of your code goes here
END Behavior;