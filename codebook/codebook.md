# Codebook for stance detection

## Stance

We define a stance as a textual expression which allows the reader to position the actor on an ideological dimension (cf. Du Bois). 
This can be an explicit expression of a preference (Biden is in favor of abortion access), 
but it can also be a more implicit expression of ideology, for example an evaluation of a policy or state of affairs (e.g. Johnson says Brexit deal 'does not take back control’); 
a legislative action or proposal (Labour proposes a new ombudsman for gambling industry); 
or even a symbolic action such as joining a protest or visiting a plant (e.g. MP joins protest at abortion clinic, or Biden says he'll wear mask in public). 

The guiding question to determine whether something is an issue position or not, is whether an average reader would be able to place that actor on an issue dimension based on the given text, e.g. without relying on external political knowledge. 

Coders can use the sentence before and after the target sentence as context for understanding references within the target text, e.g. if it explains what a particular plan or proposal means. 
Some clarifications:
- If someone says X is important, or implicitly supports it by e.g. being present at a manifestation or with a specific group, we code it as 'in favour'
- If someone 'asks questions', 'investigates', or 'talks' about something without it being clear what their position is, we code it as 'neutral'
- If someone removes a barrier or reverses a decision to stop or limit something, we code it as 'in favour'

Note that in one sentence more issue positions can be mentioned (Both the Greens and Labour vote for abortion access).

## Context

Each coding unit consists of a main sentence anchored on a (highlighted) actor. 
This is accompanied by the sentences immediately before and after this main sentence. 
For the purposes of coding the stance, all information in these three sentences may be used.
So, the question is "What do these sentences tell us about the position of [Actor]", optionally "about [issue]".

## Stance or no stance?
The first difficulty is to determine if a text actually contains a stance or not. Some decisions are made here. For example:

- If the sentence introduces a person, or involves a person being appointed, we code it as 'no stance' even if the person has a function related to a dimension (police commissioner etc).
- A statement about how a specific party should behave, e.g. by alculating budgetary consequences or being more transparent, we code it as 'no stance'
- Statements about who wants to form a coalition with whom, or who wants to be prime minister, we code as 'no stance'
- If you need a substantial amount of existing knowledge about politics to understand the dimension, we code as 'no stance'. For example, being in favour of 'expansion' without making clear that this is expansion of EU. 
- If a topic is mentioned but it is clearly talking about the situation in a foreign country, we code is as 'no stance'.
- If a politician is asked (by another politician) te be accountable for policies without stating a specific topic, we code it as 'no stance'
- A statement only mentioning a politician changing his opinions, without explicitely mentioning on what issue or what these opinions were, is coded as 'neutral' (if the topic  is known) or 'no stance'.
- Statements about what party is winning in the polls or what party gets votes from people in a certain village is coded as 'no stance'.

## Neutral or no stance

We code a neutral stance if the sentence makes it clear that the actor has an opinion about a topic or finds the topic important, but it is unclear what their position is. 
For example, if a party mentions a topic in the manifesto, talks about it in a debate, or explicitly states that it is important (without making their position clear).

We code 'no stance' if no topic is mentioned that matches one of the dimensions from the codebool, or if it is not clear that the actor actually has a position about it.
For example, if the prime minister 'is asked about their plans abour immigrations', this does not imply that they actually have a position about immigration. 

## Issue dimensions

Issue dimensions are a fixed list of dimensions on which an actor can be placed. 
For each dimension, there are two pre-defined positions (sides, poles) that an actor can be placed on.
For example, on the topic of 'immigration' the two positions are 'restrictive immigration' and 'multicultural society'.

See the [topic list](topics-en.md) (or [in Dutch](topics-nl.md) (WIP))

