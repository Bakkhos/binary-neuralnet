use work.neuralnets.all;
--xor topology
package topology is
	constant N : Integer := 5;		
	constant D : Integer := 3;	
							
	constant Adj : ADJACENCY_MATRIX := ((false, false, true, true, false),(false, false, true, true, false),(false, false, false, false, true),(false, false, false, false, true),(false, false, false, false, false));
end topology;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.neuralnets.all;
use work.topology.all;
entity lutnet_tb is
END lutnet_tb;

ARCHITECTURE behavior OF lutnet_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
	component neuralnet is generic (N : integer; D : integer; Adjacent : ADJACENCY_MATRIX);
		port (
		Input : In STD_LOGIC_VECTOR (N-1 downto 0);
		Output : Out STD_LOGIC_VECTOR (N-1 downto 0);

		NeuronIdx: In Integer range 0 to N-1;
		Function_In: In STD_LOGIC;
		Write_Function: In STD_LOGIC;
		
		Clk: In STD_LOGIC;
		Reset: In STD_LOGIC
	);
	end component;

   --Inputs
   signal Inputs : STD_LOGIC_VECTOR (N-1 downto 0);
   signal NeuronIdx: Integer range 0 to N-1;

   signal Function_In: STD_LOGIC;
   signal Write_Function: STD_LOGIC;

   signal Clk : std_logic := '0';
   signal Reset : std_Logic := '1';

   --Outputs
   signal Outputs : STD_LOGIC_VECTOR (N-1 downto 0);
  
   -- Clock period definitions
   constant Clk_period : time := 10 ns;
 
BEGIN
 
   -- Instantiate the Unit Under Test (UUT)
   uut: neuralnet generic map (N, D, Adj) port map (Inputs, Outputs, NeuronIdx, Function_In, Write_Function, Clk, Reset);

   -- Clock process definitions
   Clk_process :process
   begin
		Clk <= '0';
		wait for Clk_period/2;
		Clk <= '1';
		wait for Clk_period/2;
   end process;
 
   -- Stimulus process
   stim_proc: process
      variable i_vec : STD_LOGIC_VECTOR(D-1 downto 0);
   begin
      Reset <= '1';
      wait for 100 ns;	

      --Set up XOR weights
     wait until rising_edge(Clk);
     wait for Clk_period/2;

     --Initialize all luts to zero
	for n in 0 to N-1 loop
	  for i in 0 to 2**D - 1 loop
		NeuronIdx <= n;
		Function_In <= '0';
		Write_Function <='1';
		wait until rising_edge(Clk);
	 end loop;
	end loop;
     Write_Function <='0';

   --Neurons 0 and 1 pass through what they get on input line 0
   --i.e. pass through lowest order bit of input
	for k in 0 to 1 loop
		NeuronIdx <= k;

		for i in 0 to 2**D - 1 loop
			i_vec := std_logic_vector(to_unsigned(i,D));

			Function_In <= i_vec(0);
			Write_Function <= '1';
			wait until rising_edge(Clk);
		end loop;
	end loop;

   --Neuron 2 tests, if (x0 OR x1) (which are at input lines 1, 2)
	NeuronIdx <= 2;

	for i in 0 to 2**D - 1 loop
		i_vec := std_logic_vector(to_unsigned(i,D));

		if ((i_vec(1) = '1') or (i_vec(2) = '1')) then
			Function_In <= '1';
		else
			Function_In <= '0';
		end if;
		Write_Function <= '1';
		wait until rising_edge(Clk);
	end loop;
 
   --Neuron 3 tests if NOT (x0 AND x1) (which are at input lines 1, 2)
	NeuronIdx <= 3;

	for i in 0 to 2**D - 1 loop
		i_vec := std_logic_vector(to_unsigned(i,D));

		if (not ((i_vec(1) = '1') and (i_vec(2) = '1'))) then
			Function_In <= '1';
		else
			Function_In <= '0';
		end if;
		Write_Function <= '1';
		wait until rising_edge(Clk);
	end loop;

  --Neuron 4 computes AND of outputs of 2 and 3
	NeuronIdx <= 4;

	for i in 0 to 2**D - 1 loop
		i_vec := std_logic_vector(to_unsigned(i,D));

		if ((i_vec(1) = '1') and (i_vec(2) = '1')) then
			Function_In <= '1';
		else
			Function_In <= '0';
		end if;
		Write_Function <= '1';
		wait until rising_edge(Clk);
	end loop;

        --Done setting up XOR weights
	Write_Function <= '0';

        --Test Input->Output function
	--Output should be XOR
	wait for Clk_Period/2;

	for I in 0 to 2**N-1 loop
		Reset <= '0';
		Inputs <= std_logic_vector(to_unsigned(I, Inputs'length));
		wait until rising_edge(Clk);
		wait for Clk_Period/5;
		assert Outputs(0) = Inputs(0) report "Xor test failed - neuron 0" severity error;
		assert Outputs(1) = Inputs(1) report "Xor test failed - neuron 1" severity error;		

		wait until rising_edge(Clk);
		wait for Clk_Period/5;
		assert Outputs(2) = (Inputs(0) OR Inputs(1)) report "Xor test failed - neuron 2" severity error;
		assert Outputs(3) = NOT (Inputs(0) AND Inputs(1)) report "Xor test failed - neuron 3" severity error;

		wait until rising_edge(Clk);
		wait for Clk_Period/5;
		assert Outputs(4) = (Inputs(0) XOR Inputs(1)) report "Xor test failed" severity error;
	end loop;

      wait;
   end process;
END;
