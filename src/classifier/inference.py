import torch
from transformers import BertTokenizer, BertForSequenceClassification

# Define paths
model_path = "src/classifier/bert_classifier.pth"

# Load tokenizer
tokenizer = BertTokenizer.from_pretrained("bert-base-uncased")  # Adjust to the specific BERT variant you used

# Load model architecture and weights
model = BertForSequenceClassification.from_pretrained("bert-base-uncased", num_labels=2)  # Adjust `num_labels` as needed
model.load_state_dict(torch.load(model_path))
model.eval()  # Set model to evaluation mode

# Inference function
def predict(text, model, tokenizer):
    # Tokenize and prepare input
    inputs = tokenizer(text, return_tensors="pt", truncation=True, padding=True, max_length=512)
    with torch.no_grad():
        outputs = model(**inputs)
        logits = outputs.logits
        probabilities = torch.softmax(logits, dim=1)
        predicted_class = torch.argmax(probabilities, dim=1).item()
    return predicted_class, probabilities

# Example usage
text = "This is an example sentence for classification."
predicted_class, probabilities = predict(text, model, tokenizer)

print(f"Predicted class: {predicted_class}")
print(f"Probabilities: {probabilities}")
