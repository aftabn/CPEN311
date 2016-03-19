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

ARCHITECTURE behavior OF lab5 IS

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

	COMPONENT noise IS
		PORT (
			CLOCK_50 : IN std_logic;
			magnitude : IN std_logic_vector(1 DOWNTO 0);
			stream_in : IN std_logic_vector(23 DOWNTO 0);
			stream_out : OUT std_logic_vector(23 DOWNTO 0)
		);
	END COMPONENT;

	COMPONENT fir8
		PORT (
			CLOCK_50, valid : IN std_logic;
			stream_in : IN std_logic_vector(23 DOWNTO 0);
			stream_out : OUT std_logic_vector(23 DOWNTO 0)
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
	TYPE write_state_type IS (WRITTEN, WAITING);

	CONSTANT MAX_AMPLITUDE : POSITIVE := 65535;
	CONSTANT C4 : POSITIVE := 92;
	CONSTANT D4 : POSITIVE := 82;
	CONSTANT E4 : POSITIVE := 73;
	CONSTANT F4 : POSITIVE := 69;
	CONSTANT G4 : POSITIVE := 61;
	CONSTANT A4 : POSITIVE := 55;
	CONSTANT B4 : POSITIVE := 49;
	CONSTANT NOTES : notes_array_type := (C4, D4, E4, F4, G4, A4, B4);

	SIGNAL max_note_count : INTEGER;
	SIGNAL current_note : INTEGER;
	SIGNAL next_note : INTEGER;

	SIGNAL read_ready, write_ready, read_s, write_s : STD_LOGIC;
	SIGNAL writedata_left, writedata_right : STD_LOGIC_VECTOR(23 DOWNTO 0);
	SIGNAL writedata_left_pure, writedata_right_pure : STD_LOGIC_VECTOR(23 DOWNTO 0);
	SIGNAL writedata_left_noise, writedata_right_noise : STD_LOGIC_VECTOR(23 DOWNTO 0);
	SIGNAL writedata_left_filtered, writedata_right_filtered : STD_LOGIC_VECTOR(23 DOWNTO 0);
	SIGNAL readdata_left, readdata_right : STD_LOGIC_VECTOR(23 DOWNTO 0);
	SIGNAL reset : STD_LOGIC;
	SIGNAL valid : STD_LOGIC;
 

BEGIN
	reset <= NOT(KEY(0));
	read_s <= '0';

	add_sample : PROCESS(CLOCK_50)
		VARIABLE note_count : INTEGER := 0;
		VARIABLE current_amplitude : INTEGER := MAX_AMPLITUDE;
		VARIABLE current_write_state : write_state_type := WAITING;
	BEGIN
		IF (rising_edge(CLOCK_50)) THEN
			IF (reset = '1') THEN
				note_count := 0;
				current_amplitude := MAX_AMPLITUDE;
				current_write_state := WAITING;
				write_s <= '0';
			ELSE
				-- Switch amplitude of square wave
				IF (note_count >= max_note_count) THEN
					note_count := 0;
					current_amplitude := 1 - current_amplitude;
				END IF;

				-- Produce new samples
				writedata_left_pure <= STD_LOGIC_VECTOR(to_signed(current_amplitude, 24));
				writedata_right_pure <= STD_LOGIC_VECTOR(to_signed(current_amplitude, 24));

				-- Updating writedata channels
				IF (current_write_state = WAITING) THEN
					IF (write_ready = '1') THEN
						if (SW(15 downto 14) = "00") THEN
							writedata_left <= writedata_left_pure;
							writedata_right <= writedata_right_pure;
						elsif (SW(15 downto 14) = "01") THEN
							writedata_left <= writedata_left_noise;
							writedata_right <= writedata_right_noise;
						elsif (SW(15 downto 14) = "11") THEN
							writedata_left <= writedata_left_filtered;
							writedata_right <= writedata_right_filtered;
						end if;

						valid <= '1';
						write_s <= '1';
						note_count := note_count + 1;
						current_write_state := WRITTEN;
					END IF;
				ELSE -- If already sent out new sample
					IF (write_ready = '0') THEN
						write_s <= '0';
						current_write_state := WAITING;
					else 
						valid <= '0';
					END IF;
				END IF;
			END IF;
		END IF; 

	END PROCESS;

	change_note : PROCESS(SW)
	BEGIN
		max_note_count <= NOTES(6);

		IF (SW(6) = '1') THEN
			max_note_count <= NOTES(6);
		ELSIF (SW(5) = '1') THEN
			max_note_count <= NOTES(5);
		ELSIF (SW(4) = '1') THEN
			max_note_count <= NOTES(4);
		ELSIF (SW(3) = '1') THEN
			max_note_count <= NOTES(3);
		ELSIF (SW(2) = '1') THEN
			max_note_count <= NOTES(2);
		ELSIF (SW(1) = '1') THEN
			max_note_count <= NOTES(1);
		ELSIF (SW(0) = '1') THEN
			max_note_count<= NOTES(0);
		END IF;
	END PROCESS;

	my_clock_gen : clock_generator PORT MAP(CLOCK_27, reset, AUD_XCK);
	cfg : audio_and_video_config PORT MAP(CLOCK_50, reset, I2C_SDAT, I2C_SCLK);
	left_noise : noise PORT MAP(CLOCK_50, SW(17 downto 16), writedata_left_pure, writedata_left_noise);
	right_noise : noise PORT MAP(CLOCK_50, SW(17 downto 16), writedata_right_pure, writedata_right_noise);
	left_filter : fir8 PORT MAP(CLOCK_50, valid, writedata_left_noise, writedata_left_filtered);
	right_filter : fir8 PORT MAP(CLOCK_50, valid, writedata_right_noise, writedata_right_filtered);
	codec : audio_codec PORT MAP(
		CLOCK_50, reset, read_s, write_s, writedata_left, writedata_right, 
		AUD_ADCDAT, AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, read_ready, write_ready, readdata_left, 
		readdata_right, AUD_DACDAT
	);

	-- rest of your code goes here
END behavior;