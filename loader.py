from ogb.nodeproppred import DglNodePropPredDataset
import dgl
import torch
import numpy as np

dataset = DglNodePropPredDataset(name='ogbn-arxiv', root='../data')
split_idx = dataset.get_idx_split()

# there is only one graph in Node Property Prediction datasets
g, labels = dataset[0]
# # get edges a tensor tuple

csr = dgl.graph(g.edges()).adj_sparse('csr')

# csr contains (indptr, indices, edge_ids)
# i plan to write them on different lines
print(csr[1].size())

with open('../data/indptr' , 'wb') as f:
  # using numpy()
  # edges = tensor.numpy()
  csr[0].numpy().astype('int64').tofile(f)

with open('../data/indices', 'wb') as f:
  csr[1].numpy().astype('int64').tofile(f)

train_label = dataset.labels[split_idx['train']]
print(torch.flatten(train_label).numpy())
#write this to file
with open('../data/train', 'wb') as f:
  torch.flatten(train_label).numpy().astype('int64').tofile(f)

# todo: number of nodes edges and seperate into 3 files
# with open('../data/graph', 'w') as f:
#   f.write(f'{g.num_nodes()} {g.num_edges()} {list(train_label.size())[0]}')

valid_label = dataset.labels[split_idx['valid']]
test_label = dataset.labels[split_idx['test']]
