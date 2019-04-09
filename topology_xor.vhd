library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.neuralnets.all;
package topology is
	constant N : Integer := 5;			--nr of neurons (must be consistent with Adj)
	constant N_Bits : Integer := 3;

	constant D : Integer := 3;			--maximal degree of neurons (must be consistent with Adj)
	constant S_Bits : Integer := 2;

	--the topology is defined here
	constant Adj : ADJACENCY_MATRIX := ((false, false, true, true, false),(false, false, true, true, false),(false, false, false, false, true),(false, false, false, false, true),(false, false, false, false, false));
end topology;
