#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <iostream>
#include <vector>
#include <fstream>
#include <map>
#include <algorithm>
// #include <cub/cub.cuh>

using namespace std;

typedef struct block {
	vector<int> offset;
	vector<int> values;
	vector<int> unique;
} block;

typedef struct graphStruct {
	vector<int> indptr;
	vector<int> indices;
} graphStruct;

//loop on offset as threshold
void to_graph(int offset[], int values[], int len) {	
	//	int edges[sizeof(values)/sizeof(*values)];
	for (int i = 0; i < len - 1; ++i) {
		for (int j = offset[i]; j < offset[i+1]; ++j) {
			printf("%d, %d\n", i, values[j]); 
		}
	}	
}

void to_csr(vector<vector<int>> graph) {
	// len(offset) == num_nodes + 1 (will hardcode this for now)
	int offset[5];
	int len = graph.size();
	int indices[len];
	int currN = -1;
	int ind = -1;
	// loop through to len
	for (int i = 0; i < len; ++i) {
		while (graph[i][0] != currN) {
			printf("graph value %d\n", graph[i][0]);
			currN = (int) graph[i][0];
			cout << "index: " << ind << "\n";
			offset[++ind] = i;
		}
		indices[i] = graph[i][1];
	}
	offset[++ind] = len;
	for (int i = 0; i < 5; ++i) {
		printf("offset %d: %d\n", i, offset[i]);
	}
	for (int i = 0; i < len; ++i) {
		printf("indices %d: %d\n", i, indices[i]);
	}
}

// todo: add one more parameter: vector<int> targetNodes
void sample_layer(struct graphStruct* graph, struct block* t_block, vector<int> target) {
	int offset = 0;
	for (int x: target) {
		t_block->offset.push_back(offset);
		for (int i = graph->indptr[x]; i < graph->indptr[x+1]; ++i, ++offset) {
			t_block->values.push_back(graph->indices[i]);
		}
	} t_block->offset.push_back(offset);

	t_block->unique = t_block->values;
	sort(t_block->unique.begin(), t_block->unique.end());
	cout << "number of unique in block: " << t_block->unique.size() << '\n';
	vector<int>::iterator ip = unique(t_block->unique.begin(), t_block->unique.begin() + t_block->unique.size());

	t_block->unique.resize(distance(t_block->unique.begin(), ip));

	for (ip = t_block->unique.begin(); ip != t_block->unique.end(); ++ip) {
    cout << *ip << " ";
  }
}

int main() {

	fstream f("../data/graph", ios::in);
	int num_nodes;
	int num_edges;
	int num_sample;
	f >> num_nodes;
	f >> num_edges;
	f >> num_sample;

	fstream nodesf("../data/indptr", ios::in | ios::binary );
	if(!nodesf) {
		cout << "cannot open file!\n";
		return
	}
	long *nodes_b = (long *)malloc (num_nodes * sizeof(long));
	nodesf.read((char *)nodes_b, (num_nodes * sizeof(long)));

	fstream edgesf("../data/indices", ios::in | ios::binary );
	if(!edgesf) {
		cout << "cannot open file!\n";
		return
	}
	long *edges_b = (long *)malloc (num_edges * sizeof(long));
	edgesf.read((char *)edges_b, (num_edges * sizeof(long)));

	fstream samplef("../data/train", ios::in | ios::binary );
	if(!samplef) {
		cout << "cannot open file!\n";
		return
	}
	long *sample_b = (long *)malloc (num_sample * sizeof(long));
	samplef.read((char *)sample_b, (num_sample * sizeof(long)));

	// b = (long *)malloc (l)
	// printf("\nsampling has started :) \n");
	// graphStruct sample_graph = {{0,3,6,7,9,10,11,11,12}, {1,2,3,0,4,7,0,0,5,1,3,1}};

	// block arr[4];
	// vector<int> targetNodes = {1,2};
	// arr[0].unique = targetNodes;
	// // 1024 - 4096 batch size
	// // to_csr(g);
	// // todo: fill graphStruct while reading binary
	// // what to do with graph characteristic file (for output?)
	// for (int i = 0; i < 3; ++i) {
	// 	sample_layer(&sample_graph, &arr[i+1], arr[i].unique);
	// // cout << arr[1].unique; # why cant i print this out?
	// }
}