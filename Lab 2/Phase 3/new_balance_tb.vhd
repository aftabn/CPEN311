LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

LIBRARY WORK;
USE WORK.ALL;

--------------------------------------------------------------
--
--  This is a testbench you can use to test the new_balance subblock in Modelsim.
--  The testbench repeatedly applies test vectors and checks the output to
--  make sure they match the expected values.  You can use this without
--  modification (unless you want to add more test vectors, which is not a
--  bad idea).  However, please be sure you understand it before trying to
--  use it in Modelsim.
--
---------------------------------------------------------------

ENTITY new_balance_tb IS
  -- no inputs or outputs
END new_balance_tb;

-- The architecture part decribes the behaviour of the test bench

ARCHITECTURE behavioural OF new_balance_tb IS

   -- We will use an array of records to hold a list of test vectors and expected outputs.
   -- This simplifies adding more tests; we just have to add another line in the array.
   -- Each element of the array is a record that corresponds to one test vector.
   
   -- Define the record that describes one test vector
   
   TYPE test_case_record IS RECORD
       money : unsigned(15 downto 0);
       bet_amount : unsigned(2 downto 0);
       win_straightup : std_logic;
       win_split : std_logic;
       win_corner : std_logic;
       expected_new_money : unsigned(15 downto 0);
   END RECORD;

   -- Define a type that is an array of the record.

   TYPE test_case_array_type IS ARRAY (0 to 8) OF test_case_record;
     
   -- Define the array itself.  We will initialize it, one line per test vector.
   -- If we want to add more tests, or change the tests, we can do it here.
   -- Note that each line of the array is one record, and the 8 numbers in each
   -- line correspond to the 8 entries in the record.  Seven of these entries 
   -- represent inputs to apply, and one represents the expected output.
    
   signal test_case_array : test_case_array_type := (
        (to_unsigned(16,16), "000", '1', '0', '0', to_unsigned(16,16)),
        (to_unsigned(16,16), "010", '1', '0', '0', to_unsigned(86,16)),
        (to_unsigned(16,16), "010", '0', '1', '0', to_unsigned(50,16)),
        (to_unsigned(16,16), "010", '0', '0', '1', to_unsigned(32,16)),
        (to_unsigned(8,16), "110", '1', '0', '0', to_unsigned(218,16)),
        (to_unsigned(8,16), "110", '0', '1', '0', to_unsigned(110,16)),
        (to_unsigned(8,16), "110", '0', '0', '1', to_unsigned(56,16)),
        (to_unsigned(16,16), "010", '0', '0', '0', to_unsigned(14,16)),
        (to_unsigned(32,16), "100", '0', '0', '0', to_unsigned(28,16))
             );             

  -- Define the new_balance subblock, which is the component we are testing

  COMPONENT new_balance IS
     PORT(money : in unsigned(15 downto 0);
       bet_amount : in unsigned(2 downto 0);
       win_straightup : in std_logic;
       win_split : in std_logic;
       win_corner : in std_logic;
       new_money : out unsigned(15 downto 0));
   END COMPONENT;

   -- local signals we will use in the testbench 

   SIGNAL money : unsigned(15 downto 0) := x"0000"; 
   SIGNAL bet_amount : unsigned(2 downto 0) := "000";
   SIGNAL win_straightup : std_logic := '0';
   SIGNAL win_split : std_logic := '0';
   SIGNAL win_corner : std_logic := '0';
   SIGNAL new_money : unsigned(15 downto 0); 

begin

   -- instantiate the design-under-test

   dut : new_balance PORT MAP(
          money => money,
          bet_amount => bet_amount,
          win_straightup => win_straightup,
          win_split => win_split,
          win_corner => win_corner,
          new_money => new_money);


   -- Code to drive inputs and check outputs.  This is written by one process.
   -- Note there is nothing in the sensitivity list here; this means the process is
   -- executed at time 0.  It would also be restarted immediately after the process
   -- finishes, however, in this case, the process will never finish (because there is
   -- a wait statement at the end of the process).

   process
   begin   
       
      -- starting values for simulation.  Not really necessary, since we initialize
      -- them above anyway

      money <= x"0000"; 
      bet_amount <= "000";
      win_straightup <= '0';
      win_split <= '0';
      win_corner <= '0';
    
      -- Loop through each element in our test case array.  Each element represents
      -- one test case (along with expected outputs).
      
      for i in test_case_array'low to test_case_array'high loop
        
        -- Print information about the testcase to the transcript window (make sure when
        -- you run this, your transcript window is large enough to see what is happening)
        
        report "-------------------------------------------";
        report "Test case " & integer'image(i) & ":" &
                 " money=" & integer'image(to_integer(test_case_array(i).money)) &
                 " bet_amount=" & integer'image(to_integer(test_case_array(i).bet_amount)) & 
                 " win_straightup=" & std_logic'image(test_case_array(i).win_straightup) & 
                 " win_split=" & std_logic'image(test_case_array(i).win_split) & 
                 " win_corner=" & std_logic'image(test_case_array(i).win_corner) ;

        -- assign the values to the inputs of the DUT (design under test)

        money <= test_case_array(i).money; 
        bet_amount <= test_case_array(i).bet_amount;
        win_straightup <= test_case_array(i).win_straightup;
        win_split <= test_case_array(i).win_split;
        win_corner <= test_case_array(i).win_corner;      

        -- wait for some time, to give the DUT circuit time to respond (1ns is arbitrary)                

        wait for 1 ns;
        
        -- now print the results along with the expected results
        
        report "Expected result= " &  
                    integer'image(to_integer(test_case_array(i).expected_new_money)) &
               "  Actual result= " &  
                    integer'image(to_integer(new_money));

        -- This assert statement causes a fatal error if there is a mismatch
                                                                    
        assert (test_case_array(i).expected_new_money = new_money )
            report "MISMATCH.  THERE IS A PROBLEM IN YOUR DESIGN THAT YOU NEED TO FIX"
            severity failure;
      end loop;
                                           
      report "================== ALL TESTS PASSED =============================";
                                                                              
      wait; --- we are done.  Wait for ever
    end process;
end behavioural;