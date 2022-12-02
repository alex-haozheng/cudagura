#include <stdlib.h>
#include <stdio.h>

int main() {
	// example of CSR
	// edges: (0, 1) (0, 2) (0, 3) (1, 7) (1, 4) (3, 5)
	// offset arr: [0, 3, 5, 5, 6]
	// value arr: [1, 2, 3, 7, 4, 5]

	// todo: generate edges from offset arr & value arr
	int offset[] = {0, 3, 5, 5, 6};
	int values[] = {1, 2, 3, 4, 7, 5};
	int edges[sizeof(values)/sizeof(*values)];
	int len = sizeof(offset)/sizeof(*offset);
	for (int i = 0; i < len; ++i) {
		if (i + 1 < len) {
			for (int j = offset[i]; j < offset[i+1]; ++j) {
				printf("%d, %d\n", i, values[j]); 
			}
		} else {
			for (int j = offset[i]; j < len; ++j) {	
				printf("%d, %d\n", i, values[j]); 
			}
		}
	}	
	
}