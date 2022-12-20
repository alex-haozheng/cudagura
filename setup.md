

0. Install 
	conda install nccl=2.10.3 -c nvidia

1. Use cuda 11.4 through 
	module load cuda/11.4

After loading cuda/11.4 I can also get everything installed 
conda create --name <env> --file <this file>
conda create --name uv-env --file cudagura/conda_requirements.txt -c nvidia -c pytorch -c dglteam


2. Install torch for cuda 11.3
3. Install dgl for cuda 11.3
4. Install ogb
5. Install cython
