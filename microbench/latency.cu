#include<iostream>
#include <cuda_runtime.h>
#define CHECK_CUDA_ERROR(val) check((val), #val, __FILE__, __LINE__)
template <typename T>
void check(T err, const char* const func, const char* const file,
           const int line)
{
    if (err != cudaSuccess)
    {
        std::cerr << "CUDA Runtime Error at: " << file << ":" << line
                  << std::endl;
        std::cerr << cudaGetErrorString(err) << " " << func << std::endl;
        // We don't exit when we encounter CUDA errors in this example.
        // std::exit(EXIT_FAILURE);
    }
}

__global__ void add(float *a, int size){
        for(int i=0;i<size;i++){
		int j = (i )%size;
		a[j] = 1;
	}

}

__global__ void add_not_zero(float *a, int size){
	for(int i=0;i<size;i++){
		int j = (i )%size;
		a[j] = 10;
	}
}

__global__ void add_trad(float *a, int size){
        for(int i=0;i<size;i++){
                int j = (i )%size;
                a[j] = 10;
        }
}


int main(){
         float *x, * y, *z;
	 int GB = 1024 * 1024 * 1024/4;
	 //Note malloc managed results in a single memcpy
         cudaHostAlloc(&x, sizeof(float) * GB, 0);
	 cudaMallocManaged(&y, sizeof(float) * GB);
         CHECK_CUDA_ERROR(cudaMalloc(&z, sizeof(float) * GB));
	 cudaEvent_t start, stop;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);
	 cudaEventRecord(start);
	 for(int i=0;i<10;i++){
	 		add<<<1,1>>>(x,GB);
		//	add_not_zero<<<1,1>>>(y, GB);
	 	//	add_trad<<<1,1>>>(z, GB);
	 }
	 CHECK_CUDA_ERROR(cudaEventRecord(stop));
         CHECK_CUDA_ERROR(cudaEventSynchronize(stop));
	 float milliseconds = 0;
	 cudaEventElapsedTime(&milliseconds, start, stop);
	 std::cout << GB << " ";
	 std::cout << "time :" << milliseconds <<"\n";
         std::cout << "Hello world\n";
}

