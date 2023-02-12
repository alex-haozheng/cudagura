#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <iostream>
#include <vector>
#include <fstream>
#include <random>
#include <algorithm>
#include <thrust/sort.h>
#include <thrust/copy.h>
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include "nvtx3/nvToolsExt.h"

using namespace std;

typedef struct block {
	// thrust::device_vector
	thrust::device_vector<int> offset;
	thrust::device_vector<int> indices;
	thrust::device_vector<int> unique;

	void clear(){
		offset.clear();
		indices.clear();
	}
} block;

typedef struct graphStruct {
	thrust::device_vector<int> indptr;
	thrust::device_vector<int> indices;
} graphStruct;


void remove_duplicates(thrust::device_vector<int>& nodes){
  if(nodes.size() == 0)return;
  if(nodes.size() > 1){
    nvtxRangePush("remove duplicates"); // built in timing?
    thrust::sort(nodes.begin(), nodes.end());
    auto it = thrust::unique(nodes.begin(), nodes.end());
    nodes.erase(it, nodes.end());
    nvtxRangePop();
  }
}

//probably not parallelized
__global__ void sample_layer(struct graphStruct* graph, struct block* t_block, thrust::device_vector<int> target) {
	int offset = 0;
	//parallelize this for loop
	for (int x: target) {
		t_block->offset.push_back(offset);
		for (int i = graph->indptr[x]; i < graph->indptr[x+1]; ++i, ++offset) {
			t_block->indices.push_back(graph->indices[i]);
		}
	} t_block->offset.push_back(offset);
	t_block->unique = t_block->indices;
}

int main() {
	// reading the file shouldn't be just move the data read into device
	fstream f("../data/graph", ios::in);
	int num_ptrs;
	int num_edges;
	int num_sample;
	f >> num_ptrs;
	f >> num_edges;
	f >> num_sample;

	// try these diff types
	// malloc
	// mallocmanaged
	// mallocHostAlloc

	fstream nodesf("../data/indptr", ios::in | ios::binary );
	if(!nodesf) {
		cout << "cannot open file!\n";
		return 0;
	}
	long *nodes_h = (long *)malloc (num_ptrs * sizeof(long));
	long *nodes_d;
	cudaMalloc((void**) &nodes_d, ((num_ptrs + 1) * sizeof(long)));
	nodesf.read((char *)nodes_h, (num_ptrs * sizeof(long)));
	cudaMemcpy(nodes_d, nodes_h, (num_ptrs + 1) * sizeof(long) , cudaMemcpyHostToDevice);

	fstream edgesf("../data/indices", ios::in | ios::binary );
	if(!edgesf) {
		cout << "cannot open file!\n";
		return 0;
	}
	long *edges_h = (long *)malloc (num_edges * sizeof(long));
	long *edges_d;
	cudaMalloc((void**) &edges_d, ((num_edges + 1) * sizeof(long)));
	edgesf.read((char *)edges_h, (num_edges * sizeof(long)));
	cudaMemcpy(edges_d, edges_h, (num_ptrs + 1) * sizeof(long) , cudaMemcpyHostToDevice);

	fstream samplef("../data/train", ios::in | ios::binary );
	if(!samplef) {
		cout << "cannot open file!\n";
		return 0;
	}
	long *sample_h = (long *)malloc (num_sample * sizeof(long));
	long *sample_d;
	cudaMalloc((void**) &sample_d, ((num_sample + 1) * sizeof(long)));
	samplef.read((char *)sample_h, (num_sample * sizeof(long)));
	cudaMemcpy(sample_d, sample_h, (num_ptrs + 1) * sizeof(long) , cudaMemcpyHostToDevice);

	// not sure how to convert batching to gpu
	vector<vector<int>> batches;

	for (int i = 0; i < num_sample - 1024; i += 1024) {
		vector<int> batch;
		for (int j = i; j < i + 1024; ++j) {
			batch.push_back(sample_h[j]);
		}
		batches.push_back(batch);
	}
	// end

	vector<int> a(nodes_h, nodes_h + num_ptrs);
	vector<int> b(edges_h, edges_h + num_edges);
	graphStruct h_graph = {a, b};
	graphStruct *d_graph;

	cudaMalloc((void **) &d_graph, sizeof(h_graph));
	cudaMemcpy(d_graph, &h_graph, sizeof(h_graph), cudaMemcpyHostToDevice);


	block arr[batches.size()];
	block *d_arr;

	cudaMalloc((void **) &d_arr, sizeof(arr));
	cudaMemcpy(d_arr, &arr, sizeof(arr), cudaMemcpyHostToDevice);

	random_device rd;
	mt19937 generator(rd());

	int epochs = 3;
	for(int j = 0; j < epochs; ++j) {
		shuffle(batches.begin(), batches.end(), generator);
		d_arr[0].unique = batches[0];
		cout << "epoch: " << j << '\n';
		for (int i = 0; i < batches.size(); ++i) {
			sample_layer<<<1,1>>>(d_graph, &d_arr[i+1], d_arr[i].unique);
			// sample_layer(&h_graph, &arr[i+1], d_arr[i].unique);
			remove_duplicates(d_arr[i+1].unique);
		}
	}
	cudaFree(edges_d);
	cudaFree(d_arr);
	cudaFree(nodes_d);
	cudaFree(sample_d);	
	cudaFree(d_graph);
}