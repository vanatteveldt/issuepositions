#!/bin/bash

# Define your sets of arguments
models=("xlm-roberta-base" "GroNLP/bert-base-dutch-cased")
topics=("CivilRights" "Environment" "Immigration" "Economic" "Agriculture")

# Loop over all combinations of arguments
for model in "${models[@]}"; do
  for topic in "${topics[@]}"; do
    echo "Running script.py with arguments $model and $topic"
    python script.py "$model" "$topic"
  done
done