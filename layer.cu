#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <iostream>
#include <vector>
#include <fstream>
// #include <map>
// #include <algorithm>
#include <thrust/sort.h>
#include <thrust/copy.h>
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
// #include <thrust/host_vector.h>
// #include <thrust/device_vector.h>
// #include <thrust/generate.h>
// #include <thrust/sort.h>
// #include <thrust/copy.h>
// #include <thrust/random.h>
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
//almost done
void sample_layer(struct graphStruct* graph, struct block* t_block, vector<int> target) {
	int offset = 0;
	for (int x: target) {
		t_block->offset.push_back(offset);
		for (int i = graph->indptr[x]; i < graph->indptr[x+1]; ++i, ++offset) {
			t_block->values.push_back(graph->indices[i]);
		}
	} t_block->offset.push_back(offset);

	thrust::host_vector<int> h_vec(t_block->values);
	//transfer data to the device
	thrust::device_vector<int> d_vec = h_vec;
	//sort data on the device
	thrust::sort(d_vec.begin(), d_vec.end());
	// unique only
	thrust::device_vector<int>::iterator newLast = thrust::unique(d_vec.begin(), d_vec.end());
	// transfer data back to host
	thrust::copy(d_vec.begin(), newLast, h_vec.begin());

	for (thrust::host_vector<int>::iterator hit = h_vec.begin(); dit != h_vec.end(); ++hit) {
			// cout << *it << " ";
			t_block->unique.push_back(*hit);
	}
	for (int i = 0; i < t_block->unique.size(); ++i) {
    std::cout << t_block->unique[i] << '\n';
  }

	// t_block->unique = t_block->values;
	// sort(t_block->unique.begin(), t_block->unique.end());
	cout << "number of unique in block: " << t_block->unique.size() << '\n';
	// vector<int>::iterator ip = unique(t_block->unique.begin(), t_block->unique.begin() + t_block->unique.size());

	// t_block->unique.resize(distance(t_block->unique.begin(), ip));

	// for (ip = t_block->unique.begin(); ip != t_block->unique.end(); ++ip) {
  //   cout << *ip << '\n';
  // }
}

int main() {

	fstream f("../data/graph", ios::in);
	int num_ptrs;
	int num_edges;
	int num_sample;
	f >> num_ptrs;
	f >> num_edges;
	f >> num_sample;

	// confirmed that these are read in as ints

	fstream nodesf("../data/indptr", ios::in | ios::binary );
	if(!nodesf) {
		cout << "cannot open file!\n";
		return 0;
	}
	long *nodes_b = (long *)malloc (num_ptrs * sizeof(long));
	nodesf.read((char *)nodes_b, (num_ptrs * sizeof(long)));

	fstream edgesf("../data/indices", ios::in | ios::binary );
	if(!edgesf) {
		cout << "cannot open file!\n";
		return 0;
	}
	long *edges_b = (long *)malloc (num_edges * sizeof(long));
	edgesf.read((char *)edges_b, (num_edges * sizeof(long)));

	fstream samplef("../data/train", ios::in | ios::binary );
	if(!samplef) {
		cout << "cannot open file!\n";
		return 0;
	}
	long *sample_b = (long *)malloc (num_sample * sizeof(long));
	samplef.read((char *)sample_b, (num_sample * sizeof(long)));

	// finally done with loading the files
	// for (int i = 0; i < 10; i++) {
	// 	cout << sample_b[i] << '\n';
	// }

	// try without thrust first
	vector<vector<int>> batches;

	for (int i = 0; i < num_sample - 1024; i += 1024) {
		vector<int> batch;
		for (int j = i; j < i + 1024; ++j) {
			batch.push_back(sample_b[j]);
		}
		batches.push_back(batch);
	}
	//checking correctness
	// for (int i = 0; i < batches.size(); ++i) {
	// 	for (int j = 0; j < batches[i].size(); ++j) {
	// 		cout << batches[i][j] << '\n';
	// 		cout << sample_b[i*1024 + j] << '\n';
	// 	}
	// }

	// // b = (long *)malloc (l)
	// printf("\nsampling has started :) \n");
	vector<int> a(nodes_b, nodes_b + num_ptrs);
	vector<int> b(edges_b, edges_b + num_edges);
	graphStruct sample_graph = {a, b};

	block arr[batches.size()];
	arr[0].unique = batches[0];
	// the first unique is not unique (not sure why sample_b has duplicates)
	// for (int i = 0; i < arr[0].unique.size(); ++i) {
	// 	cout << arr[0].unique[i] << '\n';
	// }
	for (int i = 0; i < 3; ++i) {
		sample_layer(&sample_graph, &arr[i+1], arr[i].unique);
	}
	// vector<int> targetNodes();
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