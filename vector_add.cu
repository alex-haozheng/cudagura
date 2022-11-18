#include <stdlib.h>
#include <stdio.h>
#define N 10000000

__global__ void vector_add(float *out, float *a, float *b, int n) {
    for (int i = 0; i < n; i++) {
        out[i] = a[i] + b[i];
    }
}

int main() {
    float *a, *b, *out;
    float *d_a;

    // allocate device memory for a
    a   = (float*)malloc(sizeof(float) * N);
    b   = (float*)malloc(sizeof(float) * N);
    out = (float*)malloc(sizeof(float) * N);

    // Initialize array
    for(int i = 0; i < N; i++) {
        a[i] = 1.0f; b[i] = 2.0f;
    }

    // Main function
    vector_add<<<1,1>>>(out, a, b, N);

    for (int i = 0; i < 10; ++i) {
   	    printf("a: %f, b: %f, o: %f\n", a[i], b[i], out[i]);
    }
}

