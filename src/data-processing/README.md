Scripts for preparing the data for annotation

Process:

1. [00_politics_get_sentences.R](00_politics_get_sentences.R): Download the sentences from AmCAT and use a simply dictionary to identify political actors
2. [11_gpt_code_issues.py](11_gpt_code_issues.py): Code the sentences using GPT to identify which issue the statements are about.
   + This is evaluated using [10_write_gold.R](10_write_gold.R) and [12_gpt_issues_evaluate.R](12_gpt_issues_evaluate.R)
  
Note: This is for coding political actors, the code for coding other actors is still WIP
