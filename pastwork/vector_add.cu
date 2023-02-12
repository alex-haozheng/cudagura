#include <stdlib.h>
#include <stdio.h>
#include <iostream>
#include <cuda_runtime.h>
#define N 100000


using namespace std;

__global__ void vector_add(float *out, float *a, float *b, int n) {
    for (int i = 0; i < n; i++) {
        out[i] = a[i] + b[i];
    }
}

int main() {
    float *a, *b, *out;
    float *d_a, *d_b, *d_out;
    cudaEvent_t start, stop;
    float elapsed_time;
    // allocate host memory
    a   = (float*)malloc(sizeof(float) * N);
    b   = (float*)malloc(sizeof(float) * N);
    out = (float*)malloc(sizeof(float) * N);

    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    // initialize array on host
    for(int i = 0; i < N; i++) {
        a[i] = i; b[i] = i;
    }
    // allocate device memory
    cudaMalloc((void**)&d_a, sizeof(float) * N);
    cudaMalloc((void**)&d_b, sizeof(float) * N);
    cudaMalloc((void**)&d_out, sizeof(float) * N);

    cudaMemcpy(d_a, a, sizeof(float) * N, cudaMemcpyHostToDevice);
    cudaMemcpy(d_b, b, sizeof(float) * N, cudaMemcpyHostToDevice);

    cudaEventRecord(start, 0);
    // Main function
    vector_add<<<1,1>>>(d_out, d_a, d_b, N);
    cudaEventRecord(stop, 0);
    cudaEventSynchronize(stop);
    cudaEventElapsedTime(&elapsed_time, start, stop);

    cout << elapsed_time << '\n';
    cudaMemcpy(out, d_out, sizeof(float) * N, cudaMemcpyDeviceToHost);
    
    // for (int i = 0; i < N; ++i) {
   	//     printf("a: %f, b: %f, o: %f\n", a[i], b[i], out[i]);
    // }
    cudaEventDestroy(start);
    cudaEventDestroy(stop);
    cudaFree(d_a);
    cudaFree(d_b);
    cudaFree(d_out);
}