#include <vector>
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include <thrust/generate.h>
#include <thrust/sort.h>
#include <thrust/copy.h>
#include <thrust/random.h>
#include <stdio.h>
#include <thrust/execution_policy.h>


int main() {
  // Generate 32M random numbers serially.
  // thrust::default_random_engine rng(1337);
  // thrust::uniform_int_distribution<int> dist;
  // thrust::host_vector<int> h_vec(32 << 20);
  // thrust::generate(h_vec.begin(), h_vec.end(), [&] { return dist(rng); });


  std::vector<int> vect{5,5,5,7,7,7,9,10,11};
  thrust::host_vector<int> h_vec(vect);
  // Transfer data to the device.
  thrust::device_vector<int> d_vec = h_vec;

  // Sort data on the device.
  thrust::sort(d_vec.begin(), d_vec.end());

  thrust::device_vector<int>::iterator newLast = thrust::unique(d_vec.begin(), d_vec.end());
  // Transfer data back to host.
  thrust::copy(d_vec.begin(), newLast, h_vec.begin());

  std::vector<int> newV;
  thrust::device_vector<int>::iterator dit = d_vec.begin();
	// for (thrust::host_vector<int>::iterator hit = h_vec.begin(); dit != newLast; ++hit, ++dit) {
	// 	std::cout << *hit << " ";
	// 		// t_block->unique.push_back(*hit);
	// }
  // std::cout << '\n';

  for (thrust::host_vector<int>::iterator hit = h_vec.begin(); hit != h_vec.end(); ++hit) {
		std::cout << *hit << " ";
	}
  std::cout << '\n';

  // for (int i = 0; i < ; i++) {
  //   newV.push_back(h_vec[i]);
  // }

  for (int i = 0; i < newV.size(); ++i) {
    std::cout << newV[i] << '\n';
  }
}