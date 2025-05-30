Scripts for managing the annotation process. See the [intercoder reliability report](irr_politics.md) for intercoder reliability [[source](irr_politics.qmd)]

Note: Many of these scripts use a [google sheets file](https://docs.google.com/spreadsheets/d/1CKxjOn-x3Fbk2TVopi1K7WhswcELxbzcyx_o-9l_2oI/edit?usp=sharing) to keep track of coding jobs.
This file is world-readable and contains a list of jobs, coder assignments, and the coding decisions for the jobs that were discussed in groups. 

### Assigning annotations:

- [assign_annotations_stance.R]([assign_annotations_stance.R]) is the main R script for assigning annotations. It will download the units and assign them to annotinder. 
- [assign_annotations_disagreements.R]([assign_annotations_stance.R]) assigns annotations on which there was disagreement.
- [assign_annotations_withtraining.R]([assign_annotations_withtraining.R]) is a variant that also includes instruction and training units (for coder training). 

### Downloading annotations:

The script [download_stances.R](download_stances.R) downloads the annotations for all jobs and saves them in the [stances.csv](/data/intermediate/stances.csv) file.

### Intercoder reliablity

