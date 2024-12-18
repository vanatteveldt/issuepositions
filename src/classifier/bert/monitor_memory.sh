#!/bin/bash

# Set GPU memory usage threshold in MiB
GPU_MEMORY_THRESHOLD=5000

while true; do
    # Get the GPU memory usage and free memory (in MiB) from nvidia-smi
    GPU_MEMORY_FREE=$(nvidia-smi --query-gpu=memory.free --format=csv,noheader,nounits | head -n 1)
    echo "Free GPU memory: $GPU_MEMORY_FREE MiB"

    if [ "$GPU_MEMORY_FREE" -ge "$GPU_MEMORY_THRESHOLD" ]; then
        echo "Sufficient GPU memory available. Starting next job..."
        python src/classifier/test.py
        nohup python src/classifier/train_bert_classifier.py > training_output.log 2>&1 &
        break
    fi

    sleep 600  # Check every 10 minutes
done