# Code book for stance detection

We define a stance as a textual expression which allows the reader to position the actor on an ideological dimension (cf. Du Bois). This can be an explicit expression of a preference (Biden is in favor of abortion access), but it can also be a more implicit expression of ideology, for example an evaluation of a policy or state of affairs (e.g. Johnson says Brexit deal 'does not take back control’); a legislative action or proposal (Labour proposes a new ombudsman for gambling industry); or even a symbolic action such as joining a protest or visiting a plant (e.g. MP joins protest at abortion clinic, or Biden says he'll wear mask in public). 
The guiding question to determine whether something is an issue position or not, is whether an average reader would be able to place that actor on an issue dimension based on the given text, e.g. without relying on external political knowledge. The provided context can be used to understand references within the target text, e.g. if it explains what a particular plan or proposal means – see below for example sentences.

Note that in one sentence more issue positions can be mentioned (Both the Greens and Labour  vote for abortion access).

We have determined issues based on the Comparative Agenda Project (CAP; https://www.comparativeagendas.net) but rephrased in order to provide each issue with a dimension where it is clear what the actor is in favour of or opposing against. Underneath we discuss the topics from the CAP and what our labelling will be including the direction the stance can have. We also provide examples and when applicable include Dutch examples/issues.  

## **Defense**: Strong defense/NATO
Within this issue we oppose the actors in favor of more investment in Defense and the expense standard of 2% for the national gross product for Defense as NATO wants. Underneath a straight forward example:

*VVD in favor of defence expenditures of 2% of GDP*

| Holder | Expressed Polarity | Expressed Target | Polarity | Issue dimension|
|-|-|-|-|-|
|VVD | Positive | 2% defense expenditures | Positive | Defense |

## **Health care**: Better accesible health care
This topic deals with investments in health care and to make health care more accessible for everybody, e.g. by abandoning the deductible ('eigen risico'). Underneath an example in which the direction of the coding should be carefully considered.

*The prime minister said: "We previously announced to abandone the deductible in the years to come"*

| Holder | Expressed Polarity | Expressed Target | Polarity | Issue dimension|
|-|-|-|-|-|
| We (the cabinet) | Positive | abandon deductible | Positive | better health care|

## **Agriculture**: **In favor of intensive agriculture**
This topic deals with the farmers. In favor of the farmers means in favor of intensive argigulture and against nitrogen reduction (stikstofreductie). Underneath an example in which two issue opposite positions are given.

*BBB: the D66 proposal for nitrogen reduction is a disaster for our farmers*
| Holder | Expressed Polarity | Expressed Target | Polarity | Issue dimension|
|-|-|-|-|-|
|BBB| Negative | nitrogen reduction | Positive | Argiculture|
|D66| Positive | nitrogen reduction | Negative | Argiculture|


## **Energy**: **Investment in energy transition**
Within this topic we look at who is in favor of investments in the transition of energy from fossil fuels to renewable fuels.
Nuclear energy is within this issue coded as an investment in the transition to renewable fuels. An example that requires context is given underneath:

*Plans for a new nuclear power plant are the hottest question in Dutch politics. PvdA opposes it*

| Holder | Expressed Polarity | Expressed Target | Polarity | Issue dimension|
|-|-|-|-|-|
|PvdA| Negative | Nuclear power plant | Negative | Energy|

## **Government Operations**: improved governance through reforms
In the CAP this isssue is wider, but within our context we focus on an improved governance through different reforms, but also focusing on transparancy ('beter bestuur') and improving trust in governmental bodies. Underneath an example in which indirectly the position is given:

*NSC's hobbyhorse, a constitutional court, will be discussed in length among the coalition parties*
| Holder | Expressed Polarity | Expressed Target | Polarity | Issue dimension|
|-|-|-|-|-|
|NSC| Positive | constitutional court | positive | Beter governance|

## **Social welfare**: More social security
The topic social welfare is expecially focusing on social security for everybody for example by linking benefits to the minimum wages and indexing pensions. Underneath an example in which it is ambivilant to determine the direction of the stance, hence we code it neutral.

*Nothing is left of the former PvdA fight for better pensions*
| Holder | Expressed Polarity | Expressed Target | Polarity | Issue dimension|
|-|-|-|-|-|
|PvdA| Neutral | pensions | Neutral | Social welfare|

## **Labor**: More and better work
"Work should pay off" (Werken moet lonen) is the focus of this topic, hence parties that are in favor of work are in favor of a higher minium wage and better labor conditions for employees. Underneath an example in which context is needed, leading to several codings of one sentence.

*The coalition parties BBB, VVD, PVV and NSC had long discussions on numerous topics. They do agree on increasing the minimum wage.*
| Holder | Expressed Polarity | Expressed Target | Polarity | Issue dimension|
|-|-|-|-|-|
|BBB| Positive | increase minimum wage | Positive | Labor|
|VVD| Positive | increase minimum wage | Positive | Labor|
|PVV| Positive | increase minimum wage | Positive | Labor|
|NSC| Positive | increase minimum wage | Positive | Labor|

## **Transportation**: Investments in roads and public transport
When looking at transportation issues we look at investments for better roads or investments for public transport. Also an increase in highway speedlimmits means you are in favor of transport. Underneath an example in which an issue position is indirectly given.

*Last year's PvdA motion for free public transport was rejected by the minister.*
| Holder | Expressed Polarity | Expressed Target | Polarity | Issue dimension|
|-|-|-|-|-|
|PvdA| Positive | free public transport | Positive | Transportation|
|Minister| Negative | free public transport | Negative | Transportation|


## **Immigration**: More or less immigrants
This topic deals with the question if a party wants stricter immigartion policies or not. In this respect it is not only about refugees but also about labor immigrants or about foreign students. Underneath an example of indirect statements that do show issue positions.

*BBB: PVV rightly says the asylumseekers form a problem for our country*
| Holder | Expressed Polarity | Expressed Target | Polarity | Issue dimension|
|-|-|-|-|-|
|PVV| Negative | asylumseekers| Negative | Immigration|
|BBB| Negative | asylumseekers| Negative | Immigration|


## **International Affairs**: Human rights and international law 
When considering international affairs we focus on the distinction to be in favor of development aid and a focus on human rights and international law as a basis for foreign policy versus a focus on teh national interests as starting point for international relations. Underneath an example where an implicit issue position is expressed. 

*D66: This has nothing to do with the rightful protest to protect the people in Gaza.
| Holder | Expressed Polarity | Expressed Target | Polarity | Issue dimension|
|-|-|-|-|-|
|D66| Positive | protest protection Gaza | Positive | International law|


## **Education**: More investments in Education  and science (Technology)
The topic education focusses on more and better eduction. Measures to counter the shortage of teachers for example is an investment in education. The same is true for extra money with respect to science and technology. Underneath an example in which an issue position is indirectly given.

*The minister of education advises students to choose for intermediate vocational education*
| Holder | Expressed Polarity | Expressed Target | Polarity | Issue dimension|
|-|-|-|-|-|
|Minister of Eduction| Positive | vocational education | Positive | Education|

## **Culture**: More investments in Culture
An actor is in favor of more culture when investments are proposed, e.g. free entrance to museums for specific groups of people. One is not in favor of more Culture when in favor of a VAT increase for cultural events. Underneath an example of two positions on the same issue, resulting in a neutral overall position.

*PVV wants to increase the VAT for cultural events, with the exception of cinemas and amusement parks.*
| Holder | Expressed Polarity | Expressed Target | Polarity | Issue dimension|
|-|-|-|-|-|
|PVV| Positive | increase VAT cultural events | Negative | Culture|
|PVV| Negative | increase VAT cinema and amusement parks| Positive | Culture|

## **Civil rights**: In favor of civil rights (gay etc)
Civil rights are dealing with equal rights for all people in society, despite the color of their skin or their gender. In the example underneath a neutral issue position.

*BBB struggles with sexual education and gender for primary schools
| Holder | Expressed Polarity | Expressed Target | Polarity | Issue dimension|
|-|-|-|-|-|
|BBB| Neutral | Sexual education and gender | Neutral | Civil rights|

## **Government spending**: Less taxes, economy first
Government spending is an issue that is not mentioned in the CAP but is important within a Dutch political context, and probably also during other election campaigns. It deals with a focus on austerity measures in order to keep control on govermental spending versus more investments and a higher governmental deficit.

## **Environment**: Protecting the environment
In our coding we focus on the protection of the environment within this topic, while for example a focus on wind energy is covered within the topic energy. Here topics deal with investments in more nature, or policy in order to reduce trash, like deposit on cans.

## **Housing**: Affordable houses / more houses
When in favor of more houses, an actor want either to build more houses, or want houses to be affordable for everybody, for example with policies to discourage people to buy a house where they are not living themselves.

## **Law and Crime**: Fight crime, harsher penalties, counter-terrorism
This topics deals with law and order and in favor one wants repressive measures in order to fight crime, while more prevention is seen as opposed to more law and order. 

## **European Union**: Liberal world order including EU
The topic about the European order deals not only with the question if one is in favor of (more) EU but also if one is focusing on a liberal world order as a basis for trade and international relationships. 

