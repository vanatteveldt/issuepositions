# BERT Finetuning for topic: CivilRights
*Date 28/11/2024*
Best model can be found on [Huggingface](https://huggingface.co/n-Taco/issuepositions-environment-v1/tree/main).

### Modelname: bert-base-uncased

## Grid search variables for hyperparameter optimization
    learning_rates = [2e-5, 3e-5, 5e-5]
    batch_sizes = [8, 16]
    num_epochs_list = [2, 3, 4]
    dropout_rates = [0.1, 0.3]
    max_lengths = [128, 256]

> Adding batch_size > 16 results in running out of GPU memory
>
> Adding max_length > 256 results in running out of GPU memory
> 
> Trainig time: not completed (> 1,5h)
>
> Training run up to: lr=3e-5, batch_size=8, num_epochs=3, dropout=0.3, max_length=128
> 

## Results
### Validation Score
Validation Accuracy: 0.7893

### Optimal Hyperparameters
    learning_rate: 2e-5
    batch_size: 8
    num_epochs: 4
    dropout_rate: 0.1
    max_length: 128

### Test Scores
| Class    | Precision | Recall | F1-Score | Support (instances of class)|
| -------- | :-------: | :-------: | :-------: | :-------: |
| L | 0.87 | 0.79 | 0.83 | 203 | 
| N | 0.73 | 0.75 | 0.74 | 261 |    
| R | 0.79 | 0.83 | 0.81 | 267 |
| ____________________ |
| Accuracy | - | - | 0.79 | 731 |
| Macro average | 0.80 | 0.79 | 0.79 | 731 |
| Weighted average | 0.79 | 0.79 | 0.79 | 731 |

# Multilingual BERT Finetuning for topic: CivilRights
*Date 16/12/2024*
Best model can be found on [Huggingface](https://huggingface.co/n-Taco/issuepositions-environment-v1/tree/main).

#### Modelname: https://huggingface.co/google-bert/bert-base-multilingual-cased

## Grid search variables for hyperparameter optimization
    learning_rates = [2e-5, 3e-5, 5e-5]
    batch_sizes = [8, 16]
    num_epochs_list = [2, 3, 4]
    dropout_rates = [0.1, 0.3]
    max_lengths = [128, 256]

> Trainig time: 292.73 minutes
>
> Training run up to: Completed
> 

## Results
### Validation Score
Validation Accuracy: 0.821

### Optimal Hyperparameters
    learning_rate: 2e-5
    batch_size: 8
    num_epochs: 4
    dropout_rate: 0.1
    max_length: 128

### Test Scores (update after training)
| Class    | Precision | Recall | F1-Score | Support (instances of class)|
| -------- | :-------: | :-------: | :-------: | :-------: |
| L | 0.87 | 0.79 | 0.83 | 203 | 
| N | 0.73 | 0.75 | 0.74 | 261 |    
| R | 0.79 | 0.83 | 0.81 | 267 |
| ____________________ |
| Accuracy | - | - | 0.79 | 731 |
| Macro average | 0.80 | 0.79 | 0.79 | 731 |
| Weighted average | 0.79 | 0.79 | 0.79 | 731 |

