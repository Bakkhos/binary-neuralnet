library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
package neuralnets is
	type ADJACENCY_MATRIX is array (natural range <>, natural range <>) of Boolean;
	function bit_reverse(X : STD_LOGIC_VECTOR) return STD_LOGIC_VECTOR;
end neuralnets;

package body neuralnets is
	function bit_reverse(X: STD_LOGIC_VECTOR) return STD_LOGIC_VECTOR is
		variable result: STD_LOGIC_VECTOR(X'REVERSE_RANGE);
	begin
		for i in X'RANGE loop
			result(i) := X(i);
		end loop;
		return result;
	end function;
end neuralnets;

--Entities
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.neuralnets.all;
entity neuralnet is generic (N : integer; D : integer; Adjacent : ADJACENCY_MATRIX); --N: Number of neurons. D: the greatest indegree of a neuron, including a single bit connection from Input to each neuron. N and D must be consistent with Adjacent, i.e. Adjacent must be NxN and have at most (D-1) ones per row.
	port (
		Input : In STD_LOGIC_VECTOR (N-1 downto 0);
		Output : Out STD_LOGIC_VECTOR (N-1 downto 0);

		NeuronIdx: In Integer range 0 to N-1;
		Function_In: In STD_LOGIC;
		Write_Function: In STD_LOGIC;
		
		Clk: In STD_LOGIC;
		Reset: In STD_LOGIC					--if '1', then on next clock tick, all neurons will output 0 regardless of inputs and weights. Does not affect weights.
	);
end neuralnet;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.neuralnets.all;
entity neuron is generic (Degree : integer; id: integer);
	port (
		Input : In STD_LOGIC_VECTOR(0 to Degree-1);
		Output : Out STD_LOGIC;

		Function_In: In STD_LOGIC;
		Write_Function: In STD_LOGIC;
		
		Clk: In STD_LOGIC;
		Reset: In STD_LOGIC
	);
end neuron;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.neuralnets.all;
entity demux is generic(Num : integer);
	port (
		i : In STD_LOGIC;
		o : Out STD_LOGIC_VECTOR(0 to Num-1);
		which: In Integer range 0 to Num-1
	);
end demux;

--Architectures
architecture BEHAVIOUR of demux is
begin
	switch : process(i, which) 
	begin
		for k in 0 to Num-1 loop
			if (k = which) then
				o(k) <= i;
			else
				o(k) <= '0';
			end if;
		end loop;
	end process;
end BEHAVIOUR;

--this is a clocked version of the neuron
architecture RTL of neuron is
	constant lutbits : Integer := 2**Degree;
	signal lut : STD_LOGIC_VECTOR(lutbits-1 downto 0);
	signal New_Output : STD_LOGIC;
begin
	clock_process : process(Clk)
	begin
		if rising_edge(Clk) then
			--Store change to lookup table
			--Currently user is advised to reset the net after every change of a weight (or to really know what he is doing with the changing lookup table)
			--A better version could use the 'old' lookup table until the writing of the new lookup table finishes (use 1 'backup site' LUT per neural net and relay lookups to the backup site while this table is being written)
			if (Write_Function = '1') then
				lut <= std_logic_vector(unsigned(lut) srl 1);
				lut(lutbits-1) <= Function_In;
			end if;
			
			--Store Output in Flipflop
			if (Reset = '1') then 
				Output <= '0';
			else 
				Output <= New_Output;
			end if;
		end if;

	end process;

	--Funktion auswerten
	compute : process(Input, lut)
	variable index : Integer range 0 to (lutbits-1);
	begin
		index := to_integer(unsigned(bit_reverse(Input)));
		New_Output <= lut(index);
	end process;

end RTL;

architecture GEN of neuralnet is
	type SVArray is array (natural range <>) of STD_LOGIC_VECTOR(0 to D-1);
	type intarray is array (natural range <>) of integer range 0 to D;		

	signal Inputs : SVArray (0 to N-1);
	signal Outputs : STD_LOGIC_VECTOR(0 to N-1);
	signal wvec : STD_LOGIC_VECTOR(0 to N-1);
	
begin
	net_demux : entity work.demux generic map (N) port map (Write_Function, wvec, NeuronIdx);

	make_connections : process(Input, Outputs)									--note that connections are fixed at compile time according to the generic parameter Adjacent which specifies the adjacency matrix. Adjacent(i,j) means the output of i is connected to the input of j, specifically to the (Adjacent(0,j)+...+Adjacent(i,j)-1) th input line of j. In other words the matrix is read column by column, and inputs of neurons are filled up in the order in which ones are found in the matrix. Each neuron can have up to D-1 inputs from other neurons, Adjacent must conform to this, it is not checked.
		variable connections_made : intarray(0 to N-1);							--connections_made(j) = index of next unused input slot for neuron j
		begin	
			--All neurons receive an input from the neural net's input as input zero
			for j in 0 to N-1 loop
				Inputs(j)(0) <= Input(j);	
				connections_made(j) := 1;
			end loop;
		
			--This sets up the other inputs (connections between neurons)
			for i in 0 to N-1 loop
				for j in 0 to N-1 loop
					if Adjacent(i,j) then											--i is row and source; j is column and destination
						Inputs(j)(connections_made(j)) <= Outputs(i);
						connections_made(j) := connections_made(j) + 1;
					end if;
				end loop;
			end loop;
		
			--This sets leftover input lines, if any, to 0 (first test this with indegree of exactly D for each neuron!)
			for j in 0 to N-1 loop
				while (connections_made(j) < D) loop
					Inputs(j)(connections_made(j)) <= '0';
					connections_made(j) := connections_made(j) +1;
				end loop;
			end loop;
		
			--All neurons are monitored at the exit of the NN
			for j in 0 to N-1 loop
				Output(j) <= Outputs(j);
			end loop;
		
		end process;
	
	make_neurons: for j in 0 to N-1 generate 
		neuron : entity work.neuron generic map (D, j) port map (Inputs(j), Outputs(j), Function_In, wvec(j), Clk, Reset);
	end generate make_neurons;
	
end GEN;
	

