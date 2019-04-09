LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use work.neuralnets.all; 
use IEEE.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
entity net_tb is
constant N : Integer := 5;
constant D : Integer := 3;
constant Adj : ADJACENCY_MATRIX := ((false, false, true, true, false), (false, false, true, true, false), (false, false, false, false, true), (false, false, false, false, true), (false, false, false, false, false));
END net_tb;

ARCHITECTURE behavior OF net_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
	component neuralnet is generic (N : integer; D : integer; Adjacent : ADJACENCY_MATRIX);
	port (
		Input : In STD_LOGIC_VECTOR (N-1 downto 0);
		Output : Out STD_LOGIC_VECTOR (N-1 downto 0);

		NeuronIdx: In Integer range 0 to N-1;
		SynapseIdx: In Integer range 0 to D;
		Weight: In WEIGHT_T;
		Write_Weight: In STD_LOGIC;
		
		Clk: In STD_LOGIC;
		Reset: In STD_LOGIC
	);
	end component;

   --Inputs
   signal Input : STD_LOGIC_VECTOR(N-1 downto 0);
  
   signal NeuronIdx: Integer range 0 to N-1;
   signal SynapseIdx: Integer range 0 to D;
   signal Weight : WEIGHT_T;
   signal Write_Weight :  std_logic;

   signal Clk : std_logic := '0';
   signal Reset : std_logic := '1';

   --Outputs
   signal Output :  STD_LOGIC_VECTOR (N-1 downto 0);

   -- Clock period definitions
   constant Clk_period : time := 20 ns;
 
BEGIN
 
   -- Instantiate the Unit Under Test (UUT)
   uut: neuralnet generic map (N,D,Adj) port map (Input, Output, NeuronIdx, SynapseIdx, Weight, Write_Weight, Clk, Reset);

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
   begin		
      -- hold reset state for 100 ns.
	Reset <= '1';
	wait for 100 ns;	

	--Set up XOR weights
	wait until rising_edge(Clk);
	wait for Clk_period/2;

	--Initialize all weights and biases to zero
	for n in 0 to N-1 loop
	  for s in 0 to D loop
		NeuronIdx <= n;
		SynapseIdx <= s;

		Weight <= 0;
		Write_Weight <= '1';
		wait until rising_edge(Clk);
 		Write_Weight <= '0';
	  end loop;
	end loop;

	--First input neuron
	--weight from input to 1
	NeuronIdx <= 0;
	SynapseIdx <= 0;	--input
	Weight <= 1;

	Write_Weight <= '1';
	wait until rising_edge(Clk);
	Write_Weight <= '0';

	--Second input neuron
	NeuronIdx <= 1;
	SynapseIdx <= 0;
	Weight <= 1;

	Write_Weight <= '1';
	wait until rising_edge(Clk);
	Write_Weight <= '0';

	--Neuron 2 computes (x0 OR x1)
	
	--weight from x0 to 1
	NeuronIdx <= 2;
	SynapseIdx <= 1; --x0
	Weight <= 1;

	Write_Weight <= '1';
	wait until rising_edge(Clk);
	Write_Weight <= '0';

	--weight from x1 to 1
	SynapseIdx <= 2; --x1
	Weight <= 1;

	Write_Weight <= '1';
	wait until rising_edge(Clk);
	Write_Weight <= '0';

	--Neuron 3 computes NOT (x0 AND x1)
	--weight from x0 to -1
	NeuronIdx <= 3;

	SynapseIdx <= 1;	--x0
	Weight <= -1;

	Write_Weight <= '1';
	wait until rising_edge(Clk);
	Write_Weight <= '0';

	--weight from x1 to -1

	SynapseIdx <= 2;	--x1
	Weight <= -1;

	Write_Weight <= '1';
	wait until rising_edge(Clk);
	Write_Weight <= '0';

	--bias to +2

	SynapseIdx <= D;
	Weight <= 2;

	Write_Weight <= '1';
	wait until rising_edge(Clk);
	Write_Weight <= '0';

	--Neuron 4 computes AND of outputs of 2 and 3
	NeuronIdx <= 4;

	SynapseIdx <= 1; --z2
	Weight <= 1;

	Write_Weight <= '1';
	wait until rising_edge(Clk);
	Write_Weight <= '0';

	SynapseIdx <= 2; --z3
	Weight <= 1;

	Write_Weight <= '1';
	wait until rising_edge(Clk);
	Write_Weight <= '0';

	--bias to -1
	SynapseIdx <= D;
	Weight <= -1;

	Write_Weight <= '1';
	wait until rising_edge(Clk);
	Write_Weight <= '0';

	--Done setting up XOR weights (disgusting!) (TODO: can you use a procedure?)

	--Test Input->Output function
	--Output should be XOR
	wait for Clk_Period/2;

	for I in 0 to (2**N)-1 loop
		Reset <= '0';
		Input <= std_logic_vector(to_unsigned(I, Input'length));
		wait until rising_edge(Clk);
		wait for Clk_Period/5;
		assert Output(0) = Input(0) report "Xor test failed - neuron 0" severity error;
		assert Output(1) = Input(1) report "Xor test failed - neuron 1" severity error;		

		wait until rising_edge(Clk);
		wait for Clk_Period/5;
		assert Output(2) = (Input(0) OR Input(1)) report "Xor test failed - neuron 2" severity error;
		assert Output(3) = NOT (Input(0) AND Input(1)) report "Xor test failed - neuron 3" severity error;

		wait until rising_edge(Clk);
		wait for Clk_Period/5;
		assert Output(4) = (Input(0) XOR Input(1)) report "Xor test failed" severity error;
	end loop;

	wait;
	end process;

END;
