
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

ENTITY tb_LED_LMDPL_d1 IS
END tb_LED_LMDPL_d1;
 
ARCHITECTURE behavior OF tb_LED_LMDPL_d1 IS 
 
	constant fresh_size   : integer := 64;

   --Inputs
	constant fresh_byte_size : integer := integer(ceil(real(fresh_size)/real(8)));

   signal Po_rst : std_logic;
   signal clk : std_logic := '0';
   signal IN_reset : std_logic := '0';
   signal IN_plaintext_s0 : std_logic_vector(63 downto 0) := (others => '0');
   signal IN_plaintext_s1 : std_logic_vector(63 downto 0) := (others => '0');
   signal IN_key_s0 : std_logic_vector(127 downto 0) := (others => '0');
   signal IN_key_s1 : std_logic_vector(127 downto 0) := (others => '0');
	
   signal IN_plaintext : std_logic_vector(63 downto 0) := (others => '0');
   signal IN_key : std_logic_vector(127 downto 0) := (others => '0');

 	--Outputs
   signal OUT_ciphertext_s0 : std_logic_vector(63 downto 0);
   signal OUT_ciphertext_s1 : std_logic_vector(63 downto 0);
   signal Fresh     : std_logic_vector(8*fresh_byte_size-1 downto 0) := (others => '0');

   signal Mask_P : std_logic_vector(63 downto 0) := (others => '0');
   signal Mask_K : std_logic_vector(127 downto 0) := (others => '0');


   signal OUT_ciphertext : std_logic_vector(63 downto 0);
   signal OUT_done : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;

    constant mask_byte_size : integer := fresh_byte_size+8+16;
 
    type INT_ARRAY  is array (integer range <>) of integer;
    type REAL_ARRAY is array (integer range <>) of real;
    type BYTE_ARRAY is array (integer range <>) of std_logic_vector(7 downto 0);
    
    signal rr: INT_ARRAY (mask_byte_size-1 downto 0);
    signal mm: BYTE_ARRAY(mask_byte_size-1 downto 0);
    
BEGIN
 
    maskgen: process
         variable seed1, seed2: positive;        -- seed values for random generator
         variable rand: REAL_ARRAY(mask_byte_size-1 downto 0); -- random real-number value in range 0 to 1.0  
         variable range_of_rand : real := 256.0; -- the range of random values created will be 0 to +1600.
    begin
        
        FOR i in 0 to mask_byte_size-1 loop
            uniform(seed1, seed2, rand(i));   -- generate random number
            rr(i) <= integer(trunc(rand(i)*range_of_rand));  -- rescale to 0..1000, convert integer part 
            mm(i) <= std_logic_vector(to_unsigned(rr(i), mm(i)'length));
        end loop;
		  
        wait for clk_period;
        wait for clk_period;
    end process;

    ---------

	 gen_1:
    FOR i in 0 to fresh_byte_size-1 GENERATE
        Fresh(8*(i+1)-1 downto 8*i) <= mm(i);
    end GENERATE;
    
	 gen_2:
    for i in 0 to 7 GENERATE
        Mask_P(8*(i+1)-1 downto 8*i) <= mm(fresh_byte_size+i);
    end GENERATE;

	 gen_3:
    for i in 0 to 15 GENERATE
        Mask_K(8*(i+1)-1 downto 8*i) <= mm(fresh_byte_size+8+i);
    end GENERATE;



   uut: entity work.LED_LMDPL_Pipeline_d1 PORT MAP (
          Po_rst  => Po_rst,
          clk => clk,
          IN_reset => IN_reset,
          IN_plaintext_s0 => IN_plaintext_s0,
          IN_plaintext_s1 => IN_plaintext_s1,
          IN_key_s0 => IN_key_s0,
          IN_key_s1 => IN_key_s1,
			 Fresh  => Fresh(fresh_size-1 downto 0),
          OUT_ciphertext_s0 => OUT_ciphertext_s0,
          OUT_ciphertext_s1 => OUT_ciphertext_s1,
          OUT_done => OUT_done
        );

	IN_plaintext_s0 <= IN_plaintext XOR Mask_P;
	IN_plaintext_s1 <= Mask_P;
	
	IN_key_s0 <= IN_key XOR Mask_K;
	IN_key_s1 <= Mask_K;

   OUT_ciphertext <= OUT_ciphertext_s0 XOR OUT_ciphertext_s1;

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      Po_rst <= '1';
		
      wait for clk_period*20;

      Po_rst <= '0';

		IN_reset	<= '1';
		IN_plaintext 	<= x"B9B11902E6C14E39";
		IN_key 		<= x"F589DA3F6BB38D23E776CDE49EC7CB62";
		wait for clk_period*2;

		IN_reset	<= '0';
		wait for clk_period*2;

		wait until falling_edge(clk) and (OUT_done = '1'); 
		wait for clk_period*1;

		if (OUT_ciphertext = x"C4DF3176EF3059C8") then
			report "---------- Passed ----------";
		else
			report "---------- Failed ----------";
		end if;	

		wait until falling_edge(clk); 
		wait for clk_period*1;

		IN_reset	<= '1';
		IN_plaintext 	<= x"0000000000000000";
		IN_key 		<= x"F589DA3F6BB38D23E776CDE49EC7CB62";
		wait for clk_period*2;

		IN_reset	<= '0';
		wait for clk_period*2;

		wait until falling_edge(clk) and (OUT_done = '1'); 
		wait for clk_period*1;

		if (OUT_ciphertext = x"334c89d55c59c617") then
			report "---------- Passed ----------";
		else
			report "---------- Failed ----------";
		end if;	

      wait;
   end process;


END;
