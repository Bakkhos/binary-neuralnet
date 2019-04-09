#include <stdio.h>
#include "platform.h"
#include "xparameters.h"
#include <stdlib.h>
#include <time.h>

const unsigned int N = 8;	//Number of neurons
const unsigned int D = 3;	//Maximal degree (counting the one connection from the input to each neuron)

//get memory locations allowing access to state of wires to/from nn
//note usually only the lowest few bits are significant
volatile unsigned int* NN_NeuronIdx = (unsigned int *) (XPAR_GPIO_NEURONIDX_BASEADDR);		//ceil(2log(N)) bit unsigned int
volatile unsigned int* NN_SynapseIdx = (unsigned int *) (XPAR_GPIO_SYNAPSEIDX_BASEADDR);	//ceil(2log(D)) bit unsigned int
volatile unsigned int* NN_In = (unsigned int *) (XPAR_GPIO_INPUT_BASEADDR);					//N bit unsigned int
volatile unsigned int* NN_Out = (unsigned int *) XPAR_GPIO_OUTPUT_BASEADDR;					//N bit unsigned int
volatile signed char* NN_Weight = (signed char *) (XPAR_GPIO_WEIGHT_BASEADDR);				//8 bit signed int
volatile unsigned int* NN_SetWeight = (unsigned int *) (XPAR_GPIO_WRITE_WEIGHT_BASEADDR); 	//boolean
volatile unsigned int* NN_Reset = (unsigned int *) (XPAR_GPIO_RESET_BASEADDR); 	//boolean

void print(char *str);

void set_weight(unsigned int neuron, unsigned int synapse, signed char weight){
	*NN_SetWeight = 0;
	*NN_NeuronIdx=neuron;
	*NN_SynapseIdx=synapse;
	*NN_Weight=weight;
	*NN_SetWeight = 1;
	//wait one clock cycle now
	//xil_printf("Setting weight of (%d, %d) Synapse from %d to %d.\n\r", neuron, layer, synapse, weight);

	*NN_SetWeight = 0;
	return;
}

unsigned int nn_compute(unsigned int input){

	*NN_Reset = 1;
	*NN_In = input;
	*NN_Reset = 0;
	//wait for 3 clock ticks now (net takes 3 clock ticks to propagate the output)
	return *NN_Out;
}

void waitFor (unsigned int n) {
	int i;
	for (i=0; i<n*10; i++)
		xil_printf(".");
	xil_printf("\n");
}

void xor_test(){
	//Initialize weights and biases to 0
	int n, synapse;
	for(n=0; n<N; n++)
		for(synapse=0; synapse<=D; synapse++)
			set_weight(n, synapse, 0);	//initialize all weights to 0

	/*Write weights for XOR function
	 * Note that neuron i has as synapse 0 the net's input(i), and as synapse D the bias
	 * The synapses in between connect neurons to each other, see adjacency matrix in wrapper's .vhd file*/
	xil_printf("Setting weights for XOR net...");

	//neurons 0 and 1 simply pass through their input bits
	set_weight(0,0,1);
	set_weight(1,0,1);

	//Neuron 2 computes z0 OR z1
	set_weight(2,1,1);
	set_weight(2,2,1);

	//Neuron 3 computes NOT (Z0 AND Z1)
	set_weight(3,1,-1);
	set_weight(3,2,-1);
	set_weight(3,D,2);

	//Neuron 4 computes Z2 AND Z3
	set_weight(4,1,1);
	set_weight(4,2,1);
	set_weight(4,D,-1);

	xil_printf("done\n");
	xil_printf("Testing nn\n");
	/*
	 * Input:		Expected:
	 * 0...00		0...01000
	 * 0...01		0...11101
	 * 0...10		0...11110
	 * 0...11		0...00111
	 */
	int i;
	for (i=0; i<(1<<N); i = (i + 1) % (1<<N)){
		xil_printf("Input: %X \t Output (after >3 ticks): %X\n\r", i, nn_compute(i));
		waitFor(12);	//to allow watching the LEDs
	}
}

void feedback_test(){
	//Initialize weights to 0
	int n, synapse;
	for(n=0; n<N; n++)
		for(synapse=0; synapse<=D; synapse++)
			set_weight(n, synapse, 0);	//initialize all weights to 0

	//0: passes thru (or sets to 1 if input is given)
	set_weight(0,0,1);
	set_weight(0,1,1);

	//1: passes thru
	set_weight(1,1,1);

	//2+3+4 perform modulo addition of output of 0 and 1 (taking 2 cycles)
	//output goes to 0
	set_weight(2,1,1);
	set_weight(2,2,1);

	set_weight(3,1,-1);
	set_weight(3,2,-1);
	set_weight(3,D,2);

	set_weight(4,1,1);
	set_weight(4,2,1);
	set_weight(4,D,-1);

	//the appropriate adjacency matrix for the neurons must be set up in nn2_wrapper.vhd
	//Adj(i,j) = ((0,1,1,1,0), (0,0,1,1,0), (0,0,0,1,0), (0,0,0,1,0), (1,0,0,0,0))

	*NN_Reset = 1;
	*NN_In = 1;
	*NN_Reset = 0;
	*NN_In = 0;
}

int main()
{
    init_platform();
    xor_test();
    return 0;
}

