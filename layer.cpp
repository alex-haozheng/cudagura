#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <iostream>
#include <vector>
#include <map>
#include <algorithm>
// #include <cub/cub.cuh>

using namespace std;

typedef struct block {
	vector<float> offset;
	vector<float> values;
	vector<float> unique;
} block;

//loop on offset as threshold
void to_graph(float offset[], float values[], int len) {	
	//	int edges[sizeof(values)/sizeof(*values)];
	for (int i = 0; i < len - 1; ++i) {
		for (int j = offset[i]; j < offset[i+1]; ++j) {
			printf("%d, %f\n", i, values[j]); 
		}
	}	
}

void to_csr(vector<vector<float>> graph) {
	// len(offset) == num_nodes + 1 (will hardcode this for now)
	float offset[5];
	int len = graph.size();
	float indices[len];
	int currN = -1;
	int ind = -1;
	// loop through to len
	for (int i = 0; i < len; ++i) {
		while (graph[i][0] != currN) {
			printf("graph value %f\n", graph[i][0]);
			currN = (int) graph[i][0];
			cout << "index: " << ind << "\n";
			offset[++ind] = i;
		}
		indices[i] = graph[i][1];
	}
	offset[++ind] = len;
	for (int i = 0; i < 5; ++i) {
		printf("offset %d: %f\n", i, offset[i]);
	}
	for (int i = 0; i < len; ++i) {
		printf("indices %d: %f\n", i, indices[i]);
	}
}


void sample_layer(vector<vector<float>> graph, struct block* t_block) {
	map<float, vector<float>> m;
	//loop for graph (tested)
	for (vector<float> vect : graph) {
		m[vect[0]].push_back(vect[1]);
  }
	t_block->values = {};
	for (float x : t_block->unique) {
		auto search = m.find(x);
		if (search != m.end()) {
			t_block->values.insert(t_block->values.end(), search->second.begin(), search->second.end());
		}
	}
	t_block->unique = t_block->values;
	// have all the values
	sort(t_block->unique.begin(), t_block->unique.end());
	cout << "size of next layer " << t_block->unique.size() << "\n";
	vector<float>::iterator ip = unique(t_block->unique.begin(), t_block->unique.begin() + t_block->unique.size());

	t_block->unique.resize(distance(t_block->unique.begin(), ip));

	for (ip = t_block->unique.begin(); ip != t_block->unique.end(); ++ip) {
    cout << *ip << " ";
  }
  // for(map<float, vector<float> >::const_iterator it = m.begin();
	// 	it != m.end(); ++it)
	// {
	// 		std::cout << it->first << "\n" << "values: ";

	// 		for (int i = 0; i < it->second.size(); ++i) {
	// 			cout << it->second[i] << ' ';
	// 		}
	// 		cout << endl;
	// }
}

int main() {

	float o[] = {0, 3, 5, 5, 6};
	float val[] = {1, 2, 3, 4, 7, 5};

	int l = sizeof(o)/sizeof(*o);
	//to_graph(o, val, l);

	printf("\n");

	vector<vector<float>> g = {{0, 1}, {0, 2}, {0, 3}, {1, 4}, {1, 7}, {3, 5}};
	struct block b = { {0, 3, 5, 5, 6}, {1, 2}, {1, 2}};

	// to_csr(g);
	sample_layer(g, &b);
}