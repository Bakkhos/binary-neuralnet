-- neuronales netz mit feedback, takt und frei (zur kompilierzeit) konfigurierbarer topologie (Generic Parameter Adjazenz-Matrix)
-- Gewichte sind zur Laufzeit einstellbar
--  Wärenett-features:
--		LTP: Nachdem neuron 1 ausgibt, erhöhe leicht gewicht aller inputs wo 1 reinkommt
--		Oder biologisch realistischeres modell
--
-- Tips: 
--	- Gewichte fest zu machen spart viel hardware
--		-> wirklich?

--Package
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
package neuralnets is
	subtype WEIGHT_T is Integer range -128 to 127; --oder Real
	constant WEIGHT_BITS : Integer := 8;	     --breite des weight in bits (sicher schlechter stil)
	type WEIGHT_VECTOR_T is array (natural range <>) of WEIGHT_T;
	type ADJACENCY_MATRIX is array (natural range <>, natural range <>) of Boolean;
	--function degree(i:integer, M: ADJACENCY_MATRIX) of integer;	--degree of node i according to adjacency matrix M
	--function sl2int (x: std_logic) return integer;
end neuralnets;

package body neuralnets is
end neuralnets;

--Entities
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.neuralnets.all;
entity neuralnet is generic (N : integer; D : integer; Adjacent : ADJACENCY_MATRIX); --N: Number of neurons. D: the greatest indegree of a neuron, including a single bit connection from Input to each neuron. Both must be consistent with Adjacent.
	port (
		Input : In STD_LOGIC_VECTOR (N-1 downto 0);
		Output : Out STD_LOGIC_VECTOR (N-1 downto 0);

		NeuronIdx: In Integer range 0 to N-1;
		SynapseIdx: In Integer range 0 to D;
		Weight: In WEIGHT_T;
		Write_Weight: In STD_LOGIC;
		
		Clk: In STD_LOGIC;
		Reset: In STD_LOGIC					--if '1', then on next clock tick, all neurons will output 0 regardless of inputs and weights. Does not affect weights (use reset button on FPGA for those)				
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

		SynapseIdx: In Integer range 0 to Degree;
		Weight: In WEIGHT_T;
		Write_Weight: In STD_LOGIC;
		
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
architecture BEHAVIOUR of neuron is
	signal w : WEIGHT_VECTOR_T(0 to Degree);	--Speicher, für D+1 gewichte. Letztes gewicht ist der bias.
	signal New_Output : STD_LOGIC;
begin
	--gewichte speichern
	clock_process : process(Clk)
	begin
		if rising_edge(Clk) then
			if (Reset = '1') then 
				Output <= '0';
			else 
				Output <= New_Output;		--FF to store output. Acts as pipeline register when neuron is used in layers.
			end if;
			
			if (Write_Weight = '1') then
				w(SynapseIdx) <= Weight;
			end if;
		end if;		
	end process;

	--Inputs gewichtet aufsummieren (eigentlich 'skalarprodukt' Weight*Input berechnen)
	compute : process(Input, w)
		variable Sum : Integer;
		variable bias : WEIGHT_T;
	begin
		--Tree for weighted sum 
		bias := w(Degree);
		Sum := 0;
		for i in 0 to Degree-1 loop
			if (Input(i) = '1') then
				Sum := Sum + w(i);
			end if;
		end loop;
		Sum := Sum + bias;	

		--Threshold
		if (Sum > 0) then
			New_Output <= '1';
		else
			New_Output <= '0';
		end if;

	end process;

end BEHAVIOUR;

architecture GEN of neuralnet is
	type SVArray is array (natural range <>) of STD_LOGIC_VECTOR(0 to D-1);
	type intarray is array (natural range <>) of integer range 0 to D;		

	signal Inputs : SVArray (0 to N-1);
	signal Outputs : STD_LOGIC_VECTOR(0 to N-1);
	signal wvec : STD_LOGIC_VECTOR(0 to N-1);
	
begin
	net_demux : entity work.demux generic map (N) port map (Write_Weight, wvec, NeuronIdx);

	make_connections : process(Input, Outputs)									--note that connections are fixed at compile time according to the generic parameter Adjacent which specifies the adjacency matrix. Adjacent(i,j) means the output of i is connected to the input of j, specifically to the (Adjacent(0,j)+...+Adjacent(i,j)-1) th input line of j. In other words the matrix is read column by column from left to right, and inputs of neurons are filled up in the order in which ones are found in the matrix. Each neuron can have up to D inputs, Adjacent must conform to this, it is not checked.
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
		neuron : entity work.neuron generic map (D, j) port map (Inputs(j), Outputs(j), SynapseIdx, Weight, wvec(j), Clk, Reset);
	end generate make_neurons;
	
end GEN;
	

