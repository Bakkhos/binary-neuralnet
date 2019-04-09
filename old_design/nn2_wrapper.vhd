library IEEE;
use work.neuralnets.all;
use work.topology.all;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity nn_wrapper is
	port (
		Input : In STD_LOGIC_VECTOR (31 downto 0);	--used to be N-1 downto 0
		Output : Out STD_LOGIC_VECTOR (31 downto 0);

		NeuronIdx: In STD_LOGIC_VECTOR(N_Bits-1 downto 0);
		SynapseIdx: In STD_LOGIC_VECTOR(S_Bits-1 downto 0);
		Weight: In STD_LOGIC_VECTOR(WEIGHT_BITS -1 downto 0);
		Write_Weight: In STD_LOGIC;
		
		Clk: In STD_LOGIC;
		Reset: In STD_LOGIC					--if '1', then on next clock tick, all neurons will output 0 regardless of inputs and weights. Does not affect weights (use reset button on FPGA for those)				
	);
end nn_wrapper;

architecture STRUCT of nn_wrapper is

signal NeuronIdx_sig: Integer range 0 to N-1;
signal SynapseIdx_sig: Integer range 0 to D;
signal Weight_sig: WEIGHT_T;
signal Input_sig: STD_LOGIC_VECTOR(N-1 downto 0);
signal Output_sig: STD_LOGIC_VECTOR(N-1 downto 0);

begin
	typecasts : process(Input, Output_sig, NeuronIdx, SynapseIdx, Weight) 
	begin
		NeuronIdx_sig <= to_integer(unsigned(NeuronIdx));
		SynapseIdx_sig <= to_integer(unsigned(SynapseIdx));
		Weight_sig <= to_integer(signed(Weight));

		for i in 0 to N-1 loop
			if i < 32 then
				Input_sig(i) <= Input(i);
			else
				Input_sig(i) <= '0';
			end if;
		end loop;
		
		if N < 33 then
			for i in 0 to 31 loop
				if i < N then
					Output(i) <= Output_sig(i);			
				else
					Output(i) <= '0';
				end if;
			end loop;
		else
			for i in 0 to 31 loop
				Output(i) <= Output_sig(N-32+i);
			end loop;
		end if;

	end process;
	
	--neural net is included here
	net : entity work.neuralnet generic map(N, D, Adj) port map (Input_sig, Output_sig, NeuronIdx_sig, SynapseIdx_sig, Weight_sig, Write_Weight, Clk, Reset);
end STRUCT;
