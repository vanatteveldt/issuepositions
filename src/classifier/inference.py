import torch
from transformers import BertTokenizer
from train_bert_classifier import BERTClassifier

# Define model variables
model_path = "src/classifier/models/bert_CivilRights_classifier.pth"
bert_model_name = 'bert-base-uncased'
num_classes = 3
device = 'cuda' if torch.cuda.is_available() else 'cpu'

# Define reverse category mapping
reverse_category_mapping = {0: 'L', 1: 'N', 2: 'R'}

# Initialize the tokenizer with a pretrained model
tokenizer = BertTokenizer.from_pretrained('bert-base-uncased')

# Load model architecture and weights
model = BERTClassifier(bert_model_name, num_classes)
model.load_state_dict(torch.load(model_path, map_location=torch.device(device), weights_only=True))
model.to(device)
model.eval()


def predict_stance(text, model, tokenizer, device, max_length=128):
    encoding = tokenizer(text, return_tensors='pt', max_length=max_length, padding='max_length', truncation=True)
    input_ids = encoding['input_ids'].to(device)
    attention_mask = encoding['attention_mask'].to(device)

    with torch.no_grad():
            outputs = model(input_ids=input_ids, attention_mask=attention_mask)
            probabilities = torch.nn.functional.softmax(outputs, dim=1)
            _, preds = torch.max(outputs, dim=1)

            # Map predictions to labels
            predicted_label = reverse_category_mapping[preds.item()]
            
            # Map probabilities to their corresponding labels
            probability_mapping = {reverse_category_mapping[i]: prob for i, prob in enumerate(probabilities.squeeze().tolist())}
            
            return predicted_label, probability_mapping

if __name__ == "__main__":
    predicted_stance, probabilities = predict_stance("*test sentence*", model, tokenizer, device)

    print(f"Predicted stance: {predicted_stance}")
    print(f"Probablilities: {probabilities}")
