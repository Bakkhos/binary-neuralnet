Die hardware stellt ein künstliches neuronales netz dar. Jedes 'Neuron' n hat eine anzahl (in(n)) Eingänge und einen Ausgang, der der Eingang im prinzip beliebig vieler anderer Neuronen sein kann.
Im mathematischen modell transportieren die ein- und ausgänge reelle zahlen, und jedes Neuron hat ein reelles gewicht für jeden eingang. Die neuronen summieren die gewichteten eingänge und wenden darauf eine funktion an (üblicherweise die sigmoidfunktion oder die 0-1 stufe mit sprung bei x=0) und geben dies aus.

Im gegensatz zum mathematischen Modell sind hier der einfachheit halber alle Ein- und ausgänge boolsche werte. Das sollte keine sehr große einschränkung sein, da aufgrund der sigmoidfunktion sowieso alle internen signale fast 0 oder fast 1 wären. Jedoch kann man dieses system evtl. nicht ohne weiteres zum training künstlicher NN benutzen da dort üblicherweise die differenzierbarkeit der ausgangsfunktionen vorausgesetzt wird.

Die Neuronen der hardware sind synchron getaktet und neue Werte erscheint zur steigenden Taktflanke am Ausgang. (Jedes Neuron hat ein FF zum speichern des werts) Man kann das Netz also als Pipeline mit rückführungen auffassen.

Die topologie (d.h. der vernetzungsgraph) wird zur compilezeit festgelegt, die gewichte sind zur Laufzeit einstellbar. Beliebige topologien sind möglich, sofern genug ressourcen vorhanden sind.

Es sind zwei Varianten implementiert:

Bei Variante 1 hat jedes Neuron in(n)+1 8 bit register in denen die in(n) Gewichte, plus ein bias, als signed integer gespeichert sind. Ein baum aus addierern (D+1 pro neuron) summiert die gewichte und die summe wird auf >0 getestet (0-1 stufenfunktion)
Die benötigte Fläche ist etwa O(N*D). Pro taktschritt kann ein beliebiges Gewicht im Netz verändert werden. 

Bei Variante 2 sind die Neuronen nichts anderes als eine lookup table (genauer: SLR) und ein nachgeschalteter flipflop. Die gewichtsabhängige, boolsche Funktion jedes neurons wird also nicht explizit berechnet sondern deren wertetabelle abgespeichert. Um gewichte zu schreiben, kann man zur lafuzeit die wertetabellen umschreiben. Es dauert dann 2**D takte, die gewichte eines neurons zu schreiben.
Variante 2 ist eigentlich ein glorifiziertes interface zur low level programmierung des fpga... die topologie gibt an wie LUTs miteinander zu verdrahten sind und die software schreibt explizit in die LUTs

Anleitung zum ausführen / Dokumentation der Schnittstellen:
-----
Var 1:

Neues ISE 14.6 projekt (Spartan6 / XC6SLX45 / CSG324 / -3 / VHDL93) anlegen mit den sourcen
	nn2.vhd 		neuronales netz (generic)
	nn2_wrapper.vhd 	wrapper (nicht generic, 32 bit input/output)
	<topology.vhd>		legt graph des neuronalen netzes fest (adjazenzmatrix). Hier entweder topology_xor.vhd benutzen oder mit dem skript maketopology.py einen zufallsgraphen erzeugen.

Testbench (für Simulation):
	net2_tb.vhd		Testet automatisch funktion des Netzes. Erfordert topology_xor.vhd

Ports des Wrappers sind: 
	In Input(31..0):  Neuronen 0...31 bekommen dies als zusätzlichen input
	Out Output(31..0): Hier ist der output von neuron N-31...N zu beobachten

	In NeuronIdx(log(N)..0):	Neuronenadresse (fortlaufende nummer ab 0)
	In SynapseIdx(log(D+1)..0):  	Synapsenadresse, bezeichnet einen eingang an einem neuron. 0... input, 1...D: eingänge von anderen neuronen (sortiert nach neuron nummer), D+1...bias

	In Weight(7..0): Zu schreibendes neues Synapsen-Gewicht als 8 bit zweierkomplement zahl
	In Write_Weight: Liegt hier eine 1 an, wird das gewicht geschrieben (zur nächsten steigenden taktflanke)

	In Clk:		 Takt
	In Reset:	 Liegt hier an 1, wird am ausgang jedes neurons 0 ausgegeben, nicht der gespeicherte wert (synchroner reset)

Es existiert ein C programm (nn.c) mit funktionen um vom microblaze prozessor aus Gewichte einzustellen, und inputs zu übergeben und outputs zu lesen.
Falls das Netz rückführungen enthält (dies bestimmt topology.vhd) ist es jedoch mit der dzt. hardware nicht möglich den gesamten vom neuronalen netz erzeugten ausgabe-bitstream am prozessor einzulesen. Dazu müsste man dem neuronalen netz noch einen eingabe/ausgabepuffer vor bzw nachschalten, oder man betreibt das NN mit einem vgl. zum prozessor sehr niedrigen takt.

Var 2:
	lutrons2.vhd 	
	lutnn2_wrapper.vhd
	<topology.vhd>		

Testbench (für Simulation):
	lutnet2_tb.vhd

Signale im Wrapper: 
	In Input(31..0): 
	Out Output(31..0):
	In NeuronIdx(log(N)..0):	
	In Clk:		 
	In Reset:	 	Wie bei v1

	In Function_In:	   Jedes Neuron realisiert durch seine LUT eine boolsche Funktion f(b_(D-1), ..., b_0), wobei b_0 ist der Wert des Eingangs vom Input, b_1...b_(D-1) die Werte der Eingänge von den anderen Neuronen bezeichnet. (Sortiert nach neuron ID). f(b_(D-1), ..., f(0)) steht an Stelle i=b_(D-1) * 2^(D-1) + ... + b_0 * 2^0 im schieberegister. 
	In Write_Function: Liegt hier '1' an, wird zur nächsten taktflanke die LUT des Neurons rightshifted und Function_In wird 'von oben' in die LUT hineingeschoben. So kann innerhalb von 2**D takten die LUT erstetzt werden. 
    			   Insbesondere können beliebige boolsche funktionen in das 'neuron' gepackt werden, auch solche die in neuronalen netzen mehrere neuronen benötigen würden, wie XOR.
			   Eine etwaige umrechnung zwischen den Gewichten und der boolschen Funktion eines einzelnen Neurons muss in Software erfolgen



Skalierungsexperimente:
---
Siehe scaling.txt
