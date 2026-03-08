import torch
from transformers import AutoModelForCausalLM


def load_hf_model(model_name):

    model = AutoModelForCausalLM.from_pretrained(model_name)

    return model.state_dict()