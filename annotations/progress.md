# Step 1: Does the sentence contain a political actor?

For step 1, we selected sentences mentioning a political actor from the newspaper articles covering the 2023 election using a simple keyword search (party name or party leader name). 
This yielded @ sentences. 

# Step 2: Does the actor express an issue position?

From these, we coded 1295 sentences for whether or not it expresses an issue position. @ sentences were coded twice (by Nel and Jessica), giving an intercoder reliability of @. 
Based on these codings, we trained several BERT and BERT-NLI models to automate this coding step. Multilingual BERT-NLI results for the positive category: Precision 80%, recall 83%, F-score .82..
