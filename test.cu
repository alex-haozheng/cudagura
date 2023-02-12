#include <cuda_runtime.h>
#include <iostream>

struct my_struct {
  int x;
  int y;
};

__global__ void process_struct(struct my_struct *d_struct) {
  // Access data in the struct on the GPU
  int x = d_struct->x;
  int y = d_struct->y;

  // Do something with the data...

  // Update the struct data on the GPU
  d_struct->x = x + 1;
  d_struct->y = y + 2;
}

int main() {
  struct my_struct h_struct;
  struct my_struct *d_struct;

  // Initialize data on the CPU
  h_struct.x = 1;
  h_struct.y = 2;

  // Allocate memory on the device
  cudaMalloc((void**)&d_struct, sizeof(struct my_struct));

  // Transfer data from host to device
  cudaMemcpy(d_struct, &h_struct, sizeof(struct my_struct), cudaMemcpyHostToDevice);

  // Launch a kernel to process the struct on the GPU
  process_struct<<<1, 1>>>(d_struct);

  // Transfer data from device to host
  cudaMemcpy(&h_struct, d_struct, sizeof(struct my_struct), cudaMemcpyDeviceToHost);

  // Verify the data on the host
  std::cout << h_struct.x << " " << h_struct.y << std::endl;

  // Free memory on the device
  cudaFree(d_struct);

  return 0;
}
