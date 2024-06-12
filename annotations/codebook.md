# Codebook for stance detection

## Stance

We define a stance as a textual expression which allows the reader to position the actor on an ideological dimension (cf. Du Bois). This can be an explicit expression of a preference (Biden is in favor of abortion access), but it can also be a more implicit expression of ideology, for example an evaluation of a policy or state of affairs (e.g. Johnson says Brexit deal 'does not take back control’); a legislative action or proposal (Labour proposes a new ombudsman for gambling industry); or even a symbolic action such as joining a protest or visiting a plant (e.g. MP joins protest at abortion clinic, or Biden says he'll wear mask in public). 

The guiding question to determine whether something is an issue position or not, is whether an average reader would be able to place that actor on an issue dimension based on the given text, e.g. without relying on external political knowledge. 

Coders can use the sentence before and after the target sentence as context for understanding references within the target text, e.g. if it explains what a particular plan or proposal means. 
Some clarifications:
- If someone says X is important, or implicitly supports it by e.g. being present at a manifestation or with a specific group, we code it as 'in favour'
- If someone 'asks questions', 'investigates', or 'talks' about something without it being clear what their position is, we code it as 'neutral'
- If someone removes a barrier or reverses a decision to stop or limit something, we code it as 'in favour'

Note that in one sentence more issue positions can be mentioned (Both the Greens and Labour vote for abortion access).

## Stance or no stance?
The first difficulty is to determine if a text actually contains a stance or not. Some decisions are made here. For example:
- If the sentence only introduces a person, and the next (context) sentence contains an issue position, we code it as 'no stance'
- If the topic is about calculating all the budgetarian consequences of political plans we code it as 'no stance'
- If a sentence states that a party is for 'expanding' but it is not clear what the topic is (from this sentence and the context given) we code it as 'no stance' (although we might know it will be the EU)
- If a topic is mentioned but it is not about the Netherlands we code is as 'no stance'.
- If a politician is asked (by another politician) te be accountable for policies without stating a specific topic, we code it as 'no stance'
- Statements about who wants to form a coalition with whom we code as 'no stance'
- A statement only mentioning Wilders being 'milder' or changing his opinions without explicitely mentioning these opinions, is coded as 'no stance'.
- Statements about what party is winning in the polls or what party gets votes from people in a certain village is coded as 'no stance'.
- Omtzigt stating he prefers not to be the prime minister we code as 'no stance', however if he states to be in favor of a Cabinet with experts as ministers, we do code it as 'Beter bestuur'.
- Statements about an alleged cleavage between the city and the country side we code as 'no stance'


## Issue dimensions

Issue dimensions are a fixed list of dimensions on which an actor can be placed. 
Each dimension allows an actor to be for or against it, i.e. for education you can propose to invest in public education or to cut the education budget. 


See the [topic list](topics-en.md).

Changes w.r.t. the CAP topics: (apart from assigning a direction to each issue)
- Collapsed education, science, and technology into a single topic
- Collapsed energy into environment & climate (all position w.r.t. energy policy boil down to decisions that relate to climate)
- Add a category for Government finance (austerity, taxation, balancing the books)
