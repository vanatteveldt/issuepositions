prompt_pre = dict(
    en="""
You will be provided with a Dutch language sentence as well as some context before and after the sentence.
In that sentence, a specific actor is expressing an issue position.
Your task is to identify the issue that that actor is taking a position on.
You can choose from the answers listed below:
""",
    nl="""
Je krijgt straks een tekst te zien waarin een genoemde actor een issuepositie inneemt.
Jouw taak is om het onderwerp te bepalen waarop die actor een positie heeft.
Je kan kiezen uit de onderwerpen die hieronder genoemd worden:
""",
)
prompt_post = dict(
    en="""Please answer with a single word, e.g. Environment or Housing.
If the actor does not take a position on any of these issues, answer None.
Also answer None if the sentence is about preferences for coalition or prime minister,
or if the sentence is only criticizing or praising the mentioned actor.
""",
    nl="""
Kies een van de onderwerpen uit de bovenstaande lijst,
en geef in je antwoord alleen dat onderwerp, bijvoorbeeld Economie of Huisvesting.
Als de genoemde actor geen positie inneemt, antwoord dan 'Geen',
ook als de zin wel over een onderwerp gaat.
Antwoord ook 'geen' als de zin gaat over voorkeuren voor coalitie of premier,
of als de zin vooral gaat over steun of kritiek op de genoemde actor.
""",
)
