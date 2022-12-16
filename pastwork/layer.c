#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>

typedef struct block {
	size_t n_offsets;
	size_t n_values;
	size_t* offsets;
	size_t* values;
} block;


void to_graph(float offset[], float values[], int len) {	
	//	int edges[sizeof(values)/sizeof(*values)];
	for (int i = 0; i < len - 1; ++i) {
		for (int j = offset[i]; j < offset[i+1]; ++j) {
			printf("%d, %f\n", i, values[j]); 
		}
	}	
}

void to_csr(float graph[][2], int len) {
	// len(offset) == num_nodes + 1 (will hardcode this for now)
	float offset[5];
	float indices[len];	
	int currN = -1;
	// loop through to len
	for (int i = 0; i < len; ++i) {
		while (graph[i][0] != currN) {			
			printf("graph value %f\n", graph[i][0]);
			offset[++currN] = i;
		}
		indices[i] = graph[i][1];
	}
	offset[++currN] = len;
	for (int i = 0; i < 5; ++i) {
		printf("offset %d: %f\n", i, offset[i]);
	}
	for (int i = 0; i < len; ++i) {
		printf("indices %d: %f\n", i, indices[i]);
	}
}


void sample_layer(int training[]) {
	// given as [a,b]
}


int main() {
	// example of CSR
	// edges: (0, 1) (0, 2) (0, 3) (1, 7) (1, 4) (3, 5)
	// offset arr: [0, 3, 5, 5, 6]
	// value arr: [1, 2, 3, 7, 4, 5]

	// todo: generate edges from offset arr & value arr
	float o[] = {0, 3, 5, 5, 6};
	float val[] = {1, 2, 3, 4, 7, 5};
	
	int l = sizeof(o)/sizeof(*o);
	//to_graph(o, val, l);

	printf("\n");

	float g[6][2] = {{0, 1}, {0, 2}, {0, 3}, {1, 4}, {1, 7}, {3, 5}};

	to_csr(g, 6);


}
