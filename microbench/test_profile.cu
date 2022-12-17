#include<iostream>



__global__ void add(float *a){
	
	a[0] = 998.8;
	
}

int main(){
	 float *x;
 	 cudaMallocManaged(&x, sizeof(float));	
	 add<<<1,1>>>(x);
	 cudaDeviceSynchronize();
	 std::cout << x[0] <<"\n";
	 std::cout << "Hello world\n";
}
