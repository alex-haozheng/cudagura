from ogb.nodeproppred import DglNodePropPredDataset
import dgl
import torch
import numpy as np

dataset = DglNodePropPredDataset(name='ogbn-arxiv')
split_idx = dataset.get_idx_split()

# there is only one graph in Node Property Prediction datasets
g, labels = dataset[0]
# get edges a tensor tuple
print(g.edges())

csr = dgl.graph(g.edges()).adj_sparse('csr')
# csr contains (indptr, indices, edge_ids)
# i plan to write them on different lines
with open('sample.csv' , 'w') as f:
  # using numpy()
  # edges = tensor.numpy()
  csr[0].numpy().astype('int16').tofile(f)
  f.write('\n')
  csr[1].numpy().astype('int16').tofile(f)
  f.write('\n')
  csr[2].numpy().astype('int16').tofile(f)
# done?

train_label = dataset.labels[split_idx['train']]
valid_label = dataset.labels[split_idx['valid']]
test_label = dataset.labels[split_idx['test']]
