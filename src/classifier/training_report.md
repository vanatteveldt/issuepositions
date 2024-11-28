# BERT Finetuning for topic: CivilRights
*Date 28/11/2024*
Best model can be found on [Huggingface](https://huggingface.co/n-Taco/issuepositions-environment-v1/tree/main).

## Grid search variables for hyperparameter optimization
    learning_rates = [2e-5]
    batch_sizes = [8]
    num_epochs_list = [1]
    dropout_rates = [0.1]
    max_lengths = [128]

> Adding higher batch_size results in running out of GPU memory
>
> Adding longer max_length results in running out of GPU memory
> 
> Trainig time: 0.75  mins (test run)

## Results
### Validation Score
Validation Accuracy: 0.5663

### Best Hyperparameters
    learning_rate: 2e-5
    batch_size: 8
    num_epochs: 1
    dropout_rate: 0.1
    max_length: 128

### Test Scores
| Class    | Precision | Recall | F1-Score | Support (instances of class)|
| -------- | :-------: | :-------: | :-------: | :-------: |
| L | 0.55 | 0.56 | 0.80 | 203 | 
| N | 0.64 | 0.46 | 0.53 | 261 |    
| R | 0.53 | 0.68 | 0.60 | 267 |
| ____________________ |
| Accuracy | - | - | 0.57 | 731 |
| Macro average | 0.58 | 0.57 | 0.56 | 731 |
| Weighted average | 0.58 | 0.57 | 0.56 | 731 |

