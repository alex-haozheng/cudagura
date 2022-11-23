Graph Datastructure in CSR Format

Indptr (i.e offset array)
Indices (i.e Value array)

len(indptr) = num_nodes + 1
len(indices) = num_edges

edges[i] = values[indptr[i]:indptr[i+1]]

Either create a toy graph or use a graph a from ogbn-benchmark

One layer sample of nodes in a list
creates a block with edges for the sampled nodes in the block
I call this data structure

Block with indptr and indices.

Step1.

3 Hop Sampling given a set of nodes and Graph will result in 3 blocks
and fan out 10, write this c code

function sample_layer(training nodes) returns (offsets and indices sampled from graph)
repeat this function 3 times.

layer 0 unique nodes = input nodes
for i in num_layers:
  sample(previous layer unique nodes)
  append offsets and indices recieved

To remove duplicates use any library such as boost or vector sort
The unique nodes of the previous layer are the input nodes for the next layer.

Step 2
Put this on the GPU and sample.
Once you do the previous step, its easy to visualize the kernels.

Create a kernel version of
function sample_layer()

===============
Step 3 .
Using Managed Malloc.
Put a portion of the graph on GPU and a portion on the CPU
