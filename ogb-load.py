# Load Graph Property Prediction datasets in OGB
#import dgl
import torch
#from ogb.graphproppred import DglGraphPropPredDataset
#from dgl.dataloading import GraphDataLoader
from ogb.linkproppred import DglNodePropPredDataset
import numpy as np
import csv

def _collate_fn(batch):
    # batch is a list of tuple (graph, label)
    graphs = [e[0] for e in batch]
    g = dgl.batch(graphs)
    labels = [e[1] for e in batch]
    labels = torch.stack(labels, 0)
    return g, labels

# load dataset
dataset = DglNodePropPredDataset(name='ogbn-arxiv')
#split_edge = dataset.get_edge_split()
# dataloader
graph, labels = dataset[0]
# graph.edges return two tensors now we call tf.stack
t1, t2 = graph.edges()
edges = torch.stack((t1, t2), axis=1)
print(edges)



#print(split_edge['train'].keys())
#print(split_edge['valid'].keys())
#print(split_edge['test'].keys())
#train_loader = GraphDataLoader(dataset[split_idx["train"]], batch_size=32, shuffle=True, collate_fn=_collate_fn)
#valid_loader = GraphDataLoader(dataset[split_idx["valid"]], batch_size=32, shuffle=False, collate_fn=_collate_fn)
#test_loader = GraphDataLoader(dataset[split_idx["test"]], batch_size=32, shuffle=False, collate_fn=_collate_fn)
