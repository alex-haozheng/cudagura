#include <stdlib.h>
#include <stdio.h>
#include <chrono>
#include <iostream>

#define N 10000000

using namespace std;

void vector_add(float *out, float *a, float *b, int n) {
    for(int i = 0; i < n; i++){
        out[i] = a[i] + b[i];
    }
}

int main(){
    float *a, *b, *out; 

    // Allocate memory
    a   = (float*)malloc(sizeof(float) * N);
    b   = (float*)malloc(sizeof(float) * N);
    out = (float*)malloc(sizeof(float) * N);

    // Initialize array
    for(int i = 0; i < N; i++){
        a[i] = i; b[i] = i;
    }

    auto start = std::chrono::high_resolution_clock::now();
    vector_add(out, a, b, N);
    auto stop = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::microseconds>(stop - start);

    cout << duration.count()/10 << '\n';
    // for (int i = 0; i < 10; ++i) {	
   	//     printf("a: %f, b: %f, o: %f\n", a[i], b[i], out[i]);
    // }
}
