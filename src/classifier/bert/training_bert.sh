#!/bin/bash

# Define your sets of arguments
models=("GroNLP/bert-base-dutch-cased" "xlm-roberta-base")
topics=("CivilRights" "Environment" "Immigration" "Economic" "Agriculture")

# Loop over all combinations of arguments
for model in "${models[@]}"; do
  for topic in "${topics[@]}"; do
    echo "Running train_bert_classfier.py with arguments $model and $topic"
    python src/classifier/train_bert_classifier.py "$model" "$topic"
  done
done