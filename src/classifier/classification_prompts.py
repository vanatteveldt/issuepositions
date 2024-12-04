
from langchain_core.prompts import ChatPromptTemplate


coding_prompt_0shot = ChatPromptTemplate.from_template(
    """
## Uitleg: standpunt coderen over {topic}

Hier volgt telkens een drietal zinnen met een gemarkeerde actor. De centrale vraag is wat het standpunt is van de actor over {topic}. De drie zinnen zijn aangegeven met triple back ticks (```)
Je kiest hiervoor uit de twee dimensies die hieronder uitgelegd worden.

Is de actor voor meer {positive_description}, of juist voor meer {negative_description}? Als de actor juist tegen {positive_description} is, kies dan {negative_description} en andersom.

Je mag deze ruim interpreteren, het gaat om de algemene politieke richting, niet om de exacte bewoording van de dimensie. Als het standpunt echt niet bij de dimensies past, of niet duidelijk is, of over een ander ondewerp gaat, kies dan 'Geen/Ander/Neutraal'.

## Uitleg: Wat is het standpunt over {topic}?

Positive Label: {positive_label}
Bescrhijving: {positive_description}


Negative Label: {negative_label}
Beschrijving: {negative_description}

Neutral Label: Geen/Ander/Neutraal
Beschrijving: Als de actor geen standpunt heeft over {topic}, of als het standpunt niet duidelijk is of niet in deze dimensies past, kies dan Geen

## Opdracht: Standpunt om te coderen
```{issue}```

Label:"""
)

civil_rights_examples = [
    """Als Westlander schaam ik mij diep over het besluit van de gemeente Westland het GGD- spreekuur voor jongeren over seksualiteit te schrappen (Ten eerste, 17/11).Opnieuw maak ik mij boos over partijen als Denk, VVD, **SGP**, FvD die hun angsten botvieren ten koste van mensen die het recht hebben te kiezen wie ze willen zijn.Iedereen heeft zijn/haar handen vol aan het eigen leven.
    Label: Negative""",
    """ik had hem graag zien zitten tussen basisschoolkinderen met vragen als 'wat is uw grootste angst?' en 'wat vindt u moeilijk?'.Maar nog liever had ik **Omtzigt** zondagavond gezien bij Nadia over abortus.Aan het woord kwam Carel de Lange, een conservatieve youtuber die abortus moord vindt.
    Label: Neutral""",
    """Momenteel ziet hij een coalitie voor zich met de SGP - waarvan de lijsttrekker antiabortusactivisten expliciet steunt.In 2022 stemde Omtzigt tegen een motie om te onderzoeken welke wetswijzigingen nodig zijn om meerouderschap mogelijk te maken - het **CDA** was voor.Omtzigt vindt het nou eenmaal 'logisch' dat een kind twee ouders heeft.
    Label: Positive""",
    """we blijven voor jullie knokken, we staan naast jullie en we zullen de rechtsstaat, die echt in het gedrang komt de komende tijd, blijven verdedigen."Volgens de exitpoll komt het samenwerkingsverband tussen **GroenLinks** en de Partij van de Arbeid uit op 25 zetels.gisteren, 22:30
    Label: Positive""",
    """Ik hoop dat Omtzigt de rug nu recht houdt.Willen wij **Wilders** grappen horen maken over mensen met overgewicht (SBS6-debat)?Vinden we het normaal dat hij het heeft over 'genderterreur'?
    Label: Negative""",
    """Die standpunten hebben wij niet zómaar, die komen uit onze christelijke wortels.En kijk, Pieter is absoluut een christelijke **lijsttrekker**, maar zijn partij is wel op een andere leest geschoeid.Wat stemmen zijn fractiegenoten straks bij principiële onderwerpen?
    Label: Neutral"""
]

coding_prompt_6shot = ChatPromptTemplate.from_template(
    """
## Uitleg: standpunt coderen over {topic}

Hier volgt telkens een drietal zinnen met een gemarkeerde actor. De centrale vraag is wat het standpunt is van de actor over {topic}. De drie zinnen zijn aangegeven met triple back ticks (```)
Je kiest hiervoor uit de twee dimensies die hieronder uitgelegd worden.

Is de actor voor meer {positive_description}, of juist voor meer {negative_description}? Als de actor juist tegen {positive_description} is, kies dan {negative_description} en andersom.

Je mag deze ruim interpreteren, het gaat om de algemene politieke richting, niet om de exacte bewoording van de dimensie. Als het standpunt echt niet bij de dimensies past, of niet duidelijk is, of over een ander ondewerp gaat, kies dan 'Geen/Ander/Neutraal'.

## Uitleg: Wat is het standpunt over {topic}?

Positive Label: {positive_label}
Bescrhijving: {positive_description}


Negative Label: {negative_label}
Beschrijving: {negative_description}

Neutral Label: Geen/Ander/Neutraal
Beschrijving: Als de actor geen standpunt heeft over {topic}, of als het standpunt niet duidelijk is of niet in deze dimensies past, kies dan Geen

## Voorbeeld standpunten
{examples}

## Opdracht: Standpunt om te coderen
```{issue}```

Label:"""
)

coding_prompt_6shot_extended = ChatPromptTemplate.from_template(
    """
## Uitleg: standpunt coderen over {topic}

Hier volgt telkens een drietal zinnen met een gemarkeerde actor. De centrale vraag is wat het standpunt is van de actor over {topic}. De drie zinnen zijn aangegeven met triple back ticks (```)
Je kiest hiervoor uit de twee dimensies die hieronder uitgelegd worden.

Is de actor voor meer {positive_description}, of juist voor meer {negative_description}? Als de actor juist tegen {positive_description} is, kies dan {negative_description} en andersom.

Je mag deze ruim interpreteren, het gaat om de algemene politieke richting, niet om de exacte bewoording van de dimensie. Als het standpunt echt niet bij de dimensies past, of niet duidelijk is, of over een ander ondewerp gaat, kies dan 'Geen/Ander/Neutraal'.

## Uitleg: Wat is het standpunt over {topic}?

Positive Label: {positive_label}
Bescrhijving: {positive_description}


Negative Label: {negative_label}
Beschrijving: {negative_description}

Neutral Label: Geen/Ander/Neutraal
Beschrijving: Als de actor geen standpunt heeft over {topic}, of als het standpunt niet duidelijk is of niet in deze dimensies past, kies dan Geen

## Uitleg uitgebreid

### Algemeen
We coderen ook een uitspraak die gedaan is door een andere politici. Bv:
Rob Jetten zei in Nieuwsuur dat de PvdA alleen maar bezig is met belasten, belasten, belasten.
Dan coderen we hier dat PvdA links is, ook al zegt Rob Jetten dat….

Als er heel duidelijk staat dat een lijsttrekker tegen de plannen is van een andere partij mag je interpreteren dat de lijsttrekker dan voor is. Bv. Rob Jetten uitte in Nieuwsuur kritiek op de PvdA die alleen maar bezig is met belasten, belasten, belasten.
Als je hier Jetten z’n standpunt moet coderen dan is het dus rechts

Kijk heel goed om wie het gaat. Bv: Winst PVV leidt bij veel mensen tot angst'De winst van **Wilders** is een bedreiging van de mensenrechten en de rechtsstaat, zegt Stephan van Baarle (Denk).Dat leidt volgens de 32-jarige lijsttrekker "bij heel veel mensen tot angst".
Hier gaat het om Wilders, maar had iedereen gecodeerd vanuit Van Baarle. 

Het terugkomen op een standpunt, coderen we als neutraal. Bv. Jetten zegt dat Timmermans de klimaatdoelen in de uitverkoop doet/weggeeft/terugdraait etc etc. Dan is Jetten voor klimaat maar is Timmermans neutraal.
Jetten: “Timmermans” zet 'groene ambities in de uitverkoop' Jetten (D66) verwijt Timmermans (GL-PvdA) gemakkelijk klimaatambities weg te geven.

Het claimen van thema of het gebruiken van een thema voor de campagne betekent dat je er voor bent, dit is het geval bij klimaat. 
Zo wilde de partij zich profileren op het speerpunt 'zorg', maar over de zorg gíng het niet.Andere CU-thema's werden geclaimd door grotere partijen - klimaat door **D66** en CDA, bestaanszekerheid door GroenLinks-PvdA en Nieuw Sociaal Contract (NSC).En migratie, waarover het kabinet viel?

Als het standpunt over de achterban gaat en de partij is gearceerd dan coderen we het neutraal. Tenzij er expliciet staat wat het standpunt is van de partij.


### Wanneer mag je een zin “omdraaien”?
We hebben best vaak zinnen waarin eigenlijk staat dat een partij iets vindt, terwijl degene die het zegt het daarmee niet eens is. De vraag is, wanneer mag je het dan juist wel of niet als een tegenovergestelde zin coderen. Hieronder een aantal voorbeelden.

De PVV is voor een asielstop. De VVD is daar niet van onder de indruk.
Hier is PVV duidelijk tegen immigratie, maar de VVD niet per se. Als VVD vetgedrukt is, dan coderen we neutraal

De PVV is voor een asielstop. De VVD is daar op tegen.
In zo’n geval is het wel duidelijk dat de VVD tegen is en dus ook als zodanig coderen. 

De VVD vindt dat Omtzigt oerconservatieve ideeën heeft over vrouwenrechten.
Op dit moment mag je WEL omdraaien en zeggen dat VVD hier progressief (links) is tav burgerrechten. Dat doen we omdat er een oordeel wordt gegeven over het standpunt zelf. 



### Burgerrechten
Bij burgerrechten gaat het om vrijheden en mensenrechten binnen Nederland. Alles omtrent Gaza bv en uitspraken over ‘from the river to the sea’ vallen onder Buitenlands beleid.

Vrijheid van godsdienst zien we wel als links, immers je wilt niemand een religie opdringen zoals bv de PVV wel wil. Christelijke waarden en normen zijn wel weer rechts, alles vanuit christelijke tradities etc is rechts. 

Als men afziet van het bijwonen van een betoging, zoals SGP bij abortus, dan is het neutraal. Dit is een lastige maar hebben we niet als links gecodeerd omdat het niet echt iets zegt over een standpunt. Men ziet af van aanwezigheid. 
In gesprek gaan met anti- abortusbetogers voor een abortuskliniek is neutraal, zolang er geen standpunt van een partij in staat. 

Het opkomen voor grondrechten en instituties is links. Als er staat dat Omtzigt niet met PVV wil samenwerken, omdat PVV grondrechten niet respecteert. Dan kan PVV gecodeerd worden als rechts. Omtzigt kan gecodeerd worden als links. Hier is het dus toegestaan om om te draaien. 

Als het niet duidelijk is waar het over gaat met betrekking tot de rechtsstaat, dan coderen we het als neutraal. Bv. het raken van de rechtsstaat is dus neutraal, want het is onduidelijk wat ermee wordt bedoeld
Als er staat dat rechten van minderheden worden ingeperkt, dan coderen we het als rechts.
Bv. als het gaat over een noodwet uitroepen, dan coderen we het als neutraal, want het gaat over beter bestuur 

Normen, waarden en naar elkaar omkijken zonder dat er bij staat of het traditioneel, conservatief of christelijk is coderen we als neutraal, wanneer het er wel expliciet bij staat coderen we het rechts. 

Nog een paar voorbeelden:
De PvdA-voorgangers van Timmermans hadden het standpunt dat de politie neutraal moet zijn.Nu staat in het verkiezingsprogramma van **GroenLinks-PvdA** dat het wel mag.Wat is er veranderd, was de vraag.
Dit is neutraal omdat het niet duidelijk is waar het over gaat, we weten wel dat het om hoofddoekjes gaat, maar dat staat er niet. Bovendien zou het in dat geval ook neutraal zijn omdat het eerst wel mocht en nu weer niet…

Frans Timmermans (GL-PvdA) sluit de PVV hoe dan ook uit.Hij vindt dat de partij van **Wilders** met zijn harde standpunten over de islam een miljoen Nederlanders discrimineert.Met samenwerken passeer je een morele ondergrens, vindt Timmermans.
Wilders discrimineert volgens Timmermans en dat coderen we ook, dus Rechts hier.

 
"De samenleving moet ouderdom eren in plaats van deze 'voltooidlevenwet' faciliteren", zegt Bikker.De regeringspartijen **ChristenUnie** en D66 botsen vaak over medisch-ethische onderwerpen.Die werden bij de laatste twee formaties min of meer geparkeerd.
Hier is het duidelijk dat Bikker deel is van CU en dat zij tegen voltooidlevenwet is en daarmee conservatief/rechts.


## Voorbeeld standpunten
{examples}

## Opdracht: Standpunt om te coderen
```{issue}```

Label:"""
)