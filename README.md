# Issue Positions

The goal of this project is to create a dataset of expressed issue positionsin Dutch and English news. 

An expressed issue position is a piece of text from which a reader can deduce where an actor can be placed along an issue dimension, that is, what is the preference of that actor regarding that issue? 

Thus, the primary goal of this project is to create a dataset containing:
- A sentence/phrase with metadata and a limited context
- Zero or more ‘stances’ anchored on a political actor:
   - **Stance holder**: who is the political actor  
   - **Target issue dimension**: What is the issue dimension at stake? This is selected from a closed list of directed issues, i.e. things you can be in favour of or against, e.g. “lower taxes”, “cheaper housing”, “lower immigration” rather than just “housing” or “immigration”.
   - **Stance polarity**: Are they against or in favour of the issue? Do they want more or less of the policy goal?

Note that optionally, the *expressed target*, the actual text referencing the issue dimension could be coded as well, in which case it should also be indicated whether the polarity is the same or opposite w.r.t. the concept expressed in the text. Example: “Greens want to abolish fossil subsidies” would express a stance against fossil subsidies (expressed target), but in favour of climate mitigation (issue position). 

The secondary goal of the project would be to train an SML model (or combination of models) to automatically extract such stance triples from text. 

A possible extension of the project could be to add two more relevant polarity/sentiment codings: (1) does a political actor receive support or criticism, and if so, from whom? (actor / polarity / political actor); and (2) is a political actor displayed as successful or failing, do they have positive or negative momentum? (polarity / political actor). Note that we need to be careful to delimit the latter to include only the horse race, i.e. the ‘fortuna’ and not the ‘virtù’, so it should not include doing well in a the debate or being attacked or sued (which are probably all conflict statements), only explicit mentions of these events affecting how a party is doing in the race.

# Repository structure

+ [literature.md](literature.md) is a (WIP!) document describing the conceptualisation of issue positions and a brief overview of existing work
+ The [annotations](annotations) folder contains and overview of the [annotation procedure](annotations/README.md], [codebook](annotations/codebook.md), and reliability and progress
+ The [data](data) folder contains the relevant data, i.e. selected sentences from news media and annotations
+ The [src](src) folder contains the scripts for gathering, (pre)processing and selecting the data as well as SML experiments
