import sys
import csv
import itertools
import torch
import time
from pathlib import Path
from torch import nn
from torch.utils.data import DataLoader, Dataset
from transformers import BertTokenizer, BertModel, AdamW, get_linear_schedule_with_warmup, AutoModel, AutoTokenizer
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report

from load_data import list_data


class TextClassificationDataset(Dataset):
    def __init__(self, texts, labels, tokenizer, max_length):
            self.texts = texts
            self.labels = labels
            self.tokenizer = tokenizer
            self.max_length = max_length

    def __len__(self):
        return len(self.texts)
    
    def __getitem__(self, idx):
        text = self.texts[idx]
        label = self.labels[idx]
        encoding = self.tokenizer(text, return_tensors='pt', max_length=self.max_length, padding='max_length', truncation=True)
        return {'input_ids': encoding['input_ids'].flatten(), 'attention_mask': encoding['attention_mask'].flatten(), 'label': torch.tensor(label)}


class BERTClassifier(nn.Module):
    def __init__(self, bert_model_name, num_classes):
        super(BERTClassifier, self).__init__()
        self.bert = AutoModel.from_pretrained(bert_model_name)
        self.dropout = nn.Dropout(0.1)
        self.fc = nn.Linear(self.bert.config.hidden_size, num_classes)

    def forward(self, input_ids, attention_mask):
        outputs = self.bert(input_ids=input_ids, attention_mask=attention_mask)
        pooled_output = outputs.pooler_output
        x = self.dropout(pooled_output)
        logits = self.fc(x)
        return logits


def train(model:AutoModel, data_loader, optimizer, scheduler, device):
    model.train()
    for batch in data_loader:
        optimizer.zero_grad()
        input_ids = batch['input_ids'].to(device)
        attention_mask = batch['attention_mask'].to(device)
        labels = batch['label'].to(device)
        outputs = model(input_ids=input_ids, attention_mask=attention_mask)
        loss = nn.CrossEntropyLoss()(outputs, labels)
        loss.backward()
        optimizer.step()
        scheduler.step()


def evaluate(model, data_loader, device):
    model.eval()
    predictions = []
    actual_labels = []
    with torch.no_grad():
        for batch in data_loader:
            input_ids = batch['input_ids'].to(device)
            attention_mask = batch['attention_mask'].to(device)
            labels = batch['label'].to(device)
            outputs = model(input_ids=input_ids, attention_mask=attention_mask)
            _, preds = torch.max(outputs, dim=1)
            predictions.extend(preds.cpu().tolist())
            actual_labels.extend(labels.cpu().tolist())

    return accuracy_score(actual_labels, predictions), classification_report(actual_labels, predictions, target_names= ['L', 'N', 'R'], output_dict=True, zero_division=0.0)


def write_classification_row(classification_report:dict, writer:csv.DictWriter):
    for key, value in classification_report.items():
        if key == 'accuracy':
             writer.writerow({'accuracy': value})
             continue
        writer.writerow({'class_name': key,
                         'precision': value['precision'],
                         'recall': value['recall'],
                         'f1-score': value['f1-score'],
                         'support': value['support']})
            
if __name__ == "__main__":

    start_time = time.time()
    
    # load training data data and basemodel
    data_file = Path("data/intermediate/stances.csv")
    topic = sys.argv[2]
    texts, labels = list_data(data_file, topic)
    bert_model_name = sys.argv[1]
    num_classes = 3

    # grid search for hyperparameter optimization
    learning_rates = [2e-5, 3e-5, 5e-5]
    batch_sizes = [8, 16]
    num_epochs_list = [1, 2, 3, 4]
    dropout_rates = [0.1, 0.3]
    max_lengths = [128, 256]

    hyperparameter_combinations = list(itertools.product(learning_rates, batch_sizes, num_epochs_list, dropout_rates, max_lengths))

    best_accuracy = 0
    best_hyperparams = None
    best_model_state = None
    
    results_file = Path(f"results_{bert_model_name}_{topic}.csv")

    with open(results_file, mode='w', newline='') as csvfile:
        fieldnames = ['epoch', 'learning_rate', 'batch_size', 'num_epochs', 'dropout_rate', 'max_length', 'accuracy', 'class_name', 'precision', 'recall', 'f1-score', 'support', 'time']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()

        for learning_rate, batch_size, num_epochs, dropout_rate, max_length in hyperparameter_combinations:
            print("______________________________________________________________________________")
            print(f"Training with lr={learning_rate}, batch_size={batch_size}, num_epochs={num_epochs}, dropout_rate={dropout_rate}, max_length={max_length}\n")

            # create test and validation split
            train_texts, val_texts, train_labels, val_labels = train_test_split(texts, labels, test_size=0.2, random_state=42)

            tokenizer = AutoTokenizer.from_pretrained(bert_model_name)
            train_dataset = TextClassificationDataset(train_texts, train_labels, tokenizer, max_length)
            val_dataset = TextClassificationDataset(val_texts, val_labels, tokenizer, max_length)
            train_dataloader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)
            val_dataloader = DataLoader(val_dataset, batch_size=batch_size)


            # initialize model
            device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
            model = BERTClassifier(bert_model_name, num_classes).to(device)

            # initialize optimizer and scheduler
            optimizer = AdamW(model.parameters(), lr=learning_rate, no_deprecation_warning=True)
            total_steps = len(train_dataloader) * num_epochs
            scheduler = get_linear_schedule_with_warmup(optimizer, num_warmup_steps=0, num_training_steps=total_steps)

            # train and evaluate
            for epoch in range(num_epochs):
                    print(f"Epoch {epoch + 1}/{num_epochs}\n")
                    train(model, train_dataloader, optimizer, scheduler, device)
                    accuracy, report = evaluate(model, val_dataloader, device)
                    print(f"Validation Accuracy: {accuracy:.4f}")
                    writer.writerow({
                            'epoch': epoch + 1,
                            'learning_rate': learning_rate,
                            'batch_size': batch_size,
                            'num_epochs': num_epochs,
                            'dropout_rate': dropout_rate,
                            'max_length': max_length,
                            'accuracy': accuracy
                        })

                    write_classification_row(report, writer)
                    csvfile.flush()

            # check if this is the best model (currently only checking for accuracy)
            if accuracy > best_accuracy:
                    best_accuracy = accuracy
                    best_hyperparams = (learning_rate, batch_size, num_epochs, dropout_rate, max_length)
                    best_model_state = model.state_dict()

            print(f"""Best Hyperparameters: 
                Learning Rate={best_hyperparams[0]} 
                Batch Size={best_hyperparams[1]}
                Num Epochs={best_hyperparams[2]}
                Dropout Rate={best_hyperparams[3]}
                Max Length={best_hyperparams[4]}\n""")

        # save best model state
        print("Saving best performing model...")
        torch.save(best_model_state, Path(f"src/classifier/models/bert_{bert_model_name}_{topic}_classifier.pth"))
        
        end_time = time.time()
        
        elapsed_time = (end_time-start_time)/60
        writer.writerow({'time': f"Total training time: {elapsed_time:.2f} minutes"})
    

