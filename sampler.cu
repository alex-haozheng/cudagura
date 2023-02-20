#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <iostream>
#include <vector>
#include <fstream>
#include <random>
#include <chrono>
#include <algorithm>
#include <thrust/sort.h>
#include <thrust/copy.h>
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include "nvtx3/nvToolsExt.h"
#include <curand.h>
#include <cuda_runtime.h>
#include <curand_kernel.h>

#define gpuErrchk(ans) { gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t code, const char *file, int line, bool abort=true)
{
   if (code != cudaSuccess)
   {
      fprintf(stderr,"GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
      if (abort) exit(code);
   }
}

using namespace std;

typedef struct block {
	// thrust::device_vector
	thrust::device_vector<long> offset;
	thrust::device_vector<long> indices;
	thrust::device_vector<long> unique;
	// thrust::device_vector<long> in_degrees;

	void clear(){
		offset.clear();
		indices.clear();
	}
} block;

// typedef struct graphStruct {
// 	thrust::device_vector<long> indptr;
// 	thrust::device_vector<long> indices;
// } graphStruct;


const int THREAD_SIZE = 256;
const int MAX_BLOCKS = 1024;
int BLOCK_SIZE(size_t t){
	if(t > MAX_BLOCKS) return MAX_BLOCKS;
	return (t-1)/THREAD_SIZE + 1;
}

__global__ void init_random_states(curandState *states, size_t num,
                                   unsigned long seed) {
  size_t threadId = threadIdx.x + blockIdx.x * blockDim.x;
  assert(num == blockDim.x * gridDim.x);
  if (threadId < num) {
    // Copied from GNNLAB
    /** Using different seed & constant sequence 0 can reduce memory
      * consumption by 800M
      * https://docs.nvidia.com/cuda/curand/device-api-overview.html#performance-notes
      */
    curand_init(seed+threadId, 0, 0, &states[threadId]);
  }
}

void remove_duplicates(thrust::device_vector<long>& nodes){
  if(nodes.size() == 0)return;
  if(nodes.size() > 1){
    nvtxRangePush("remove duplicates"); // built in timing?
    thrust::sort(nodes.begin(), nodes.end());
    auto it = thrust::unique(nodes.begin(), nodes.end());
    nodes.erase(it, nodes.end());
    nvtxRangePop();
  }
}

__global__
void printing(long* indptr_g) {
	for (int i = 0; i < 10; ++i){
		printf("index: %d value: %ld \n", i, indptr_g[i]);
	}
}

__global__
void sample_offsets(long *in, size_t in_size, long *offsets_s, 
	long *indptr_g, long num_nodes, int fanout){
      int id = blockIdx.x * blockDim.x + threadIdx.x;
  while(id < in_size){
      int nd = in[id];
			// get # of neighbors
      int nbs_size = indptr_g[nd+1] - indptr_g[nd];
			
			// stabilize nbs_size
			if(fanout < nbs_size){
					nbs_size = fanout;
			}
      
      offsets_s[id+1] = nbs_size;
      id = id + (blockDim.x * gridDim.x);
  }
}

__global__
void neigh_sample(long * in, long size, long * offsets, long * indices,\
      long * graph_indptr, long * graph_indices, long num_nodes, int fanout, curandState *random_states) {
      int threadId =  blockIdx.x * blockDim.x + threadIdx.x;
      int id = threadId;
      while(id < size){
          int nd = in[id];
          int nbs_size = graph_indptr[nd+1] - graph_indptr[nd];
					// sets the starting position to start reading in indices (graph standpoint)
          long *read = &graph_indices[graph_indptr[nd]];
					// where to start writing (from indices standpoint)
          long *write = &indices[offsets[id]];
          if(nbs_size > fanout){
						for(int j = 0; j < fanout; j++){
							int sid = (int) (curand_uniform(&random_states[threadId]) * nbs_size);
            	write[j] = read[sid];
						}
          }else{
						for(int j = 0; j < nbs_size; j++){
							write[j] = read[j];
						}
          }
          id = id + (blockDim.x * gridDim.x);
      }
  }

// todo: update the variables witin the functions 
void sample_layer(long *g_indptr, long *g_indices, thrust::device_vector<long> &target, 
	thrust::device_vector<long> &offsets, thrust::device_vector<long> &indices, long fanout, long num_nodes, curandState *random_states) {
		offsets.clear();
		indices.clear();
		offsets.resize(target.size() + 1);
		// appending for inclusive scan
		// cout << "before offset sampling\n";
		offsets[0] = 0;
		sample_offsets<<<BLOCK_SIZE(target.size()), THREAD_SIZE>>>
			(thrust::raw_pointer_cast(target.data()), target.size(), \
    		thrust::raw_pointer_cast(offsets.data()), \
      		g_indptr, num_nodes, fanout);
		// cout << "after sample offset\n";
		thrust::inclusive_scan(thrust::device, offsets.begin(), 
			offsets.end(), offsets.begin()); 
		indices.resize(offsets[offsets.size() - 1]);
		// cout << "segfault in sample layer\n";
		neigh_sample<<<BLOCK_SIZE(target.size()), THREAD_SIZE>>>
			(thrust::raw_pointer_cast(target.data()), target.size(),
            thrust::raw_pointer_cast(offsets.data()),
             thrust::raw_pointer_cast(indices.data()),
              g_indptr, g_indices, num_nodes, fanout, random_states);
	}

int main() {
	// reading the file shouldn't be just move the data read into device
	fstream f("../data/graph", ios::in);
	long num_ptrs;
	long num_edges;
	long num_sample;
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
	nodesf.read((char *)nodes_h, (num_ptrs * sizeof(long)));

	// for (int i = 0; i < 10; ++i){
	// 	printf("index: %d cpu value: %ld \n", i, nodes_h[i]);
	// }

	fstream edgesf("../data/indices", ios::in | ios::binary );
	if(!edgesf) {
		cout << "cannot open file!\n";
		return 0;
	}

	long *edges_h = (long *)malloc (num_edges * sizeof(long));
	edgesf.read((char *)edges_h, (num_edges * sizeof(long)));

	fstream samplef("../data/train", ios::in | ios::binary );
	if(!samplef) {
		cout << "cannot open file!\n";
		return 0;
	}
	long *sample_h = (long *)malloc (num_sample * sizeof(long));
	samplef.read((char *)sample_h, (num_sample * sizeof(long)));

	vector<vector<long>> batches;

	for (int i = 0; i < num_sample - 1024; i += 1024) {
		vector<long> batch;
		for (int j = i; j < i + 1024; ++j) {
			batch.push_back(sample_h[j]);
		}
		batches.push_back(batch);
	}
	// end
	vector<long> a(nodes_h, nodes_h + num_ptrs);
	vector<long> b(edges_h, edges_h + num_edges);	
	long *nodes_g;
	long *edges_g;
	// malloc
	// mallocmanaged
	// mallocHostAlloc
	// gpuErrchk(cudaMalloc((void**)&nodes_g, (num_ptrs - 1) * sizeof(long)));
	// gpuErrchk(cudaMemcpy(nodes_g, nodes_h, (num_ptrs - 1) * sizeof(long), cudaMemcpyHostToDevice));
	// gpuErrchk(cudaMalloc((void**)&edges_g, (num_edges - 1) * sizeof(long)));
	// gpuErrchk(cudaMemcpy(edges_g, edges_h, (num_edges - 1) * sizeof(long), cudaMemcpyHostToDevice));
	cudaMallocManaged(&nodes_g, (num_ptrs - 1) * sizeof(long));
	cudaMallocManaged(&edges_g, (num_edges - 1) * sizeof(long));
	// cudaMallocHost((void**)&nodes_g, (num_ptrs - 1) * sizeof(long));
	// cudaMallocHost((void**)&edges_g, (num_edges - 1) * sizeof(long));

	
	const int TOTAL_RAND_STATES = 1024 * 256;
	curandState* dev_curand_states;
	unsigned long seed = std::chrono::system_clock::now().time_since_epoch().count();
	gpuErrchk(cudaMalloc(&dev_curand_states, TOTAL_RAND_STATES * sizeof(curandState)));
	init_random_states<<<MAX_BLOCKS, THREAD_SIZE>>>(dev_curand_states, TOTAL_RAND_STATES, seed);
	
	
	block **d_arr = (block **) malloc(sizeof(block) * 3);
	for (int i=0;i<3;++i) {
		d_arr[i] = new block();
	}

	// gpuErrchk(cudaMalloc((void **) &d_arr, sizeof(arr)));
	// gpuErrchk(cudaMemcpy(d_arr, &arr, sizeof(arr), cudaMemcpyHostToDevice));

	random_device rd;
	mt19937 generator(rd());
	float elapsed_time;

	cudaEvent_t start, stop;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);

	int epochs = 3;
	cudaEventRecord(start, 0);
	for(int j = 0; j < epochs; ++j) {
		shuffle(batches.begin(), batches.end(), generator);
		for (int k = 0; k < batches.size(); ++k) {
			thrust::device_vector<long> b(batches[k].begin(), batches[k].end());
			d_arr[0]->unique = b;
			for (int i = 1; i <= 3; ++i) {
				// still passing in wrong pointer
				sample_layer(nodes_g, edges_g, d_arr[i-1]->unique, d_arr[i]->offset, d_arr[i]->indices, 20, num_ptrs, dev_curand_states);
				// for (int c = 0; c < d_arr[i]->indices.size(); ++c) {
				// 	cout << d_arr[i]->indices[c] << '\n';
				// }
				d_arr[i]->unique.resize(d_arr[i]->indices.size());
				thrust::copy(thrust::device, d_arr[i]->indices.begin(), d_arr[i]->indices.end(), d_arr[i]->unique.begin());
				remove_duplicates(d_arr[i]->unique);
				for (int i=0;i<=3;++i) {
					d_arr[i] = new block();
				}
			}
		}
	}
	cudaEventRecord(stop, 0);
	cudaEventSynchronize(stop);
	cudaEventElapsedTime(&elapsed_time, start, stop);
	cout << elapsed_time << '\n';	
	cudaEventDestroy(start);
  cudaEventDestroy(stop);
	free(d_arr);
}