import torch

print(torch.__version__)
my_tensor = torch.tensor([[1, 2, 3], [4, 5, 6]], dtype=torch.float32, device="cuda")
print(my_tensor)
torch.cuda.is_available()