LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

LIBRARY WORK;
USE WORK.ALL;

--------------------------------------------------------------
--
--  This is a testbench you can use to test the win subblock in Modelsim.
--  The testbench repeatedly applies test vectors and checks the output to
--  make sure they match the expected values.  You can use this without
--  modification (unless you want to add more test vectors, which is not a
--  bad idea).  However, please be sure you understand it before trying to
--  use it in Modelsim.
--
---------------------------------------------------------------

ENTITY win_tb IS
  -- no inputs or outputs
END win_tb;

-- The architecture part decribes the behaviour of the test bench

ARCHITECTURE behavioural OF win_tb IS

   -- We will use an array of records to hold a list of test vectors and expected outputs.
   -- This simplifies adding more tests; we just have to add another line in the array.
   -- Each element of the array is a record that corresponds to one test vector.
   
   -- Define the record that describes one test vector
   
   TYPE test_case_record IS RECORD
      spin_result_latched : unsigned(5 downto 0); 
      bet_target : unsigned(5 downto 0); 
      bet_modifier: unsigned(3 downto 0);
      expected_win_straightup : std_logic;
      expected_win_split : std_logic;
      expected_win_corner : std_logic;
   END RECORD;

   -- Define a type that is an array of the record.

   TYPE test_case_array_type IS ARRAY (0 to 5+16+20-1) OF test_case_record;
     
   -- Define the array itself.  We will initialize it, one line per test vector.
   -- If we want to add more tests, or change the tests, we can do it here.
   -- Note that each line of the array is one record, and the 6 numbers in each
   -- line correspond to the 6 entries in the record.  Three of these entries 
   -- represent inputs to apply, and three represent the expected outputs.
    
   signal test_case_array : test_case_array_type := (
   
             -- test cases to test perfect match
             ("010011", "010011", "0000", '1', '0', '0'),
             ("000001", "000001", "0000", '1', '0', '0'),
             ("000001", "000010", "0000", '0', '0', '0'),
             ("100100", "100100", "0000", '1', '0', '0'),
             ("100100", "000000", "0000", '0', '0', '0'),
             
             -- test cases to test split bets
             ("010101", "010100", "1010", '0', '1', '0'),
             ("010111", "010100", "1100", '0', '1', '0'),       
             ("010011", "010100", "1110", '0', '1', '0'),  
             ("010001", "010100", "1000", '0', '1', '0'),
             ("010101", "010100", "1000", '0', '0', '0'),
             ("010111", "010100", "1010", '0', '0', '0'),       
             ("010011", "010100", "1100", '0', '0', '0'),  
             ("010001", "010100", "1110", '0', '0', '0'),
             ("001001", "000111", "1110", '0', '0', '0'),
             ("000111", "001001", "1010", '0', '0', '0'),
             ("100100", "000011", "1000", '0', '0', '0'),
             ("000000", "001001", "1000", '0', '0', '0'),             
             ("000001", "100100", "1100", '0', '0', '0'),
             ("000101", "000010", "1100", '0', '1', '0'),             
             ("000001", "000010", "1110", '0', '1', '0'),
             ("100001", "100100", "1000", '0', '1', '0'),
             
             -- test cases to test corner bets
             
             ("001111", "010001", "1001", '0', '0', '1'),
             ("010101", "010001", "1011", '0', '0', '1'),
             ("010011", "010001", "1101", '0', '0', '1'),
             ("001101", "010001", "1111", '0', '0', '1'),
             ("000000", "010001", "1001", '0', '0', '0'),
             ("100010", "010001", "1101", '0', '0', '0'),
             ("001111", "010001", "1111", '0', '0', '0'),
             ("010101", "010001", "1101", '0', '0', '0'),
             ("010011", "010001", "1011", '0', '0', '0'),
             ("001101", "010001", "1001", '0', '0', '0'),
             ("000011", "000111", "1111", '0', '0', '0'),
             ("000101", "000111", "1001", '0', '0', '1'),
             ("001011", "000111", "1011", '0', '0', '1'),
             ("001001", "000111", "1101", '0', '0', '0'),
             ("001011", "001111", "1111", '0', '0', '1'),
             ("001101", "001111", "1001", '0', '0', '0'),
             ("010011", "001111", "1011", '0', '0', '0'),
             ("010001", "001111", "1101", '0', '0', '1'),                                       
             ("100000", "100100", "1111", '0', '0', '1'),
             ("100000", "100010", "1001", '0', '0', '1')
                                                              
             );             

  -- Define the win subblock, which is the component we are testing

  COMPONENT win IS
	PORT(spin_result_latched : in unsigned(5 downto 0);  
             bet_target : in unsigned(5 downto 0); 
             bet_modifier : in unsigned(3 downto 0); 
             win_straightup : out std_logic;  
             win_split : out std_logic;  
             win_corner : out std_logic);
   END COMPONENT;

   -- local signals we will use in the testbench 

   SIGNAL spin_result_latched : unsigned(5 downto 0) := "000000";
   SIGNAL bet_target : unsigned(5 downto 0) := "000000";
   SIGNAL bet_modifier : unsigned(3 downto 0) := "0000";
   SIGNAL win_straightup : std_logic;
   SIGNAL win_split : std_logic;
   SIGNAL win_corner : std_logic;

begin

   -- instantiate the design-under-test

   dut : win PORT MAP(
            spin_result_latched => spin_result_latched,
            bet_target => bet_target,
            bet_modifier => bet_modifier,
            win_straightup => win_straightup,
            win_split => win_split,
            win_corner => win_corner);

   -- Code to drive inputs and check outputs.  This is written by one process.
   -- Note there is nothing in the sensitivity list here; this means the process is
   -- executed at time 0.  It would also be restarted immediately after the process
   -- finishes, however, in this case, the process will never finish (because there is
   -- a wait statement at the end of the process).

   process
   begin   
       
      -- starting values for simulation.  Not really necessary, since we initialize
      -- them above anyway

      spin_result_latched <= to_unsigned(0, spin_result_latched'length);
      bet_target <= to_unsigned(0, bet_target'length);
      bet_modifier <= to_unsigned(0, bet_modifier'length);

      -- Loop through each element in our test case array.  Each element represents
      -- one test case (along with expected outputs).
      
      for i in test_case_array'low to test_case_array'high loop
        
        -- Print information about the testcase to the transcript window (make sure when
        -- you run this, your transcript window is large enough to see what is happening)
        
        report "-------------------------------------------";
        
        report "Test case " & integer'image(i) & ":" &
                 " spin_result=" & integer'image(to_integer(test_case_array(i).spin_result_latched)) & 
                 " bet_target=" & integer'image(to_integer(test_case_array(i).bet_target)) &
                 " bet_modifier=" & std_logic'image(test_case_array(i).bet_modifier(3)) &
                                    std_logic'image(test_case_array(i).bet_modifier(2)) &
                                    std_logic'image(test_case_array(i).bet_modifier(1)) &
                                    std_logic'image(test_case_array(i).bet_modifier(0));
                
        -- assign the values to the inputs of the DUT (design under test)
        
        spin_result_latched <= test_case_array(i).spin_result_latched;
        bet_target <= test_case_array(i).bet_target;
        bet_modifier <= test_case_array(i).bet_modifier;               

        -- wait for some time, to give the DUT circuit time to respond (1ns is arbitrary)                

        wait for 1 ns;
        
        -- now print the results along with the expected results
      
        report "Expected result: win_straightup=" & std_logic'image(test_case_array(i).expected_win_straightup) &
                              "  win_split=" & std_logic'image(test_case_array(i).expected_win_split) &
                              "  win_corner=" & std_logic'image(test_case_array(i).expected_win_corner);
        report "Observed result: win_straightup=" & std_logic'image(win_straightup) &
                              "  win_split=" & std_logic'image(win_split) &
                              "  win_corner=" & std_logic'image(win_corner);

        -- This assert statement causes a fatal error if there is a mismatch
                                                                    
        assert (win_straightup = test_case_array(i).expected_win_straightup AND
                win_corner = test_case_array(i).expected_win_corner AND
                win_split = test_case_array(i).expected_win_split)
            report "MISMATCH.  THERE IS A PROBLEM IN YOUR DESIGN THAT YOU NEED TO FIX"
            severity failure;
      end loop;
                                           
      report "================== ALL TESTS PASSED =============================";
                                                                              
      wait; --- we are done.  Wait for ever
    end process;
end behavioural;