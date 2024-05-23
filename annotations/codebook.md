# Codebook for stance detection

## Stance

We define a stance as a textual expression which allows the reader to position the actor on an ideological dimension (cf. Du Bois). This can be an explicit expression of a preference (Biden is in favor of abortion access), but it can also be a more implicit expression of ideology, for example an evaluation of a policy or state of affairs (e.g. Johnson says Brexit deal 'does not take back control’); a legislative action or proposal (Labour proposes a new ombudsman for gambling industry); or even a symbolic action such as joining a protest or visiting a plant (e.g. MP joins protest at abortion clinic, or Biden says he'll wear mask in public). 

The guiding question to determine whether something is an issue position or not, is whether an average reader would be able to place that actor on an issue dimension based on the given text, e.g. without relying on external political knowledge. 

Coders can use the sentence before and after the target sentence as context for understanding references within the target text, e.g. if it explains what a particular plan or proposal means. However, the target sentence itself should contain the position. 

Some clarifications:
- If someone says X is important, or implicitly supports it by e.g. being present at a manifestation or with a specific group, we code it as 'in favour'
- If someone 'asks questions', 'investigates', or 'talks' about something without it being clear what their position is, we code it as 'neutral'
- If someone removes a barrier or reverses a decision to stop or limit something, we code it as 'in favour'
- If the sentence only introduces a person, and the next (context) sentence contains an issue position, we code it as 'no stance'

Note that in one sentence more issue positions can be mentioned (Both the Greens and Labour vote for abortion access).

## Issue dimensions

Issue dimensions are a fixed list of dimensions on which an actor can be placed. 
Each dimension allows an actor to be for or against it, i.e. for education you can propose to invest in public education or to cut the education budget. 

The dimensions we use are mostly based on the [Comparative Agenda Project (CAP)](https://www.comparativeagendas.net) list of topic codes, 
where each topic was interpreted along a dimension. 

See the [topic list](topics-en.md).

Changes w.r.t. the CAP topics: (apart from assigning a direction to each issue)
- Collapsed education, science, and technology into a single topic
- Collapsed energy into environment & climate (all position w.r.t. energy policy boil down to decisions that relate to climate)
- Add a category for Government finance (austerity, taxation, balancing the books)
