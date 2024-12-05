from dotenv import load_dotenv
from pathlib import Path
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.messages import AIMessage
from langchain_openai import ChatOpenAI
from pydantic import BaseModel, Field
from typing import TypedDict
from pprint import pprint

from classification_prompts import coding_prompt_6shot, coding_prompt_0shot, civil_rights_examples, coding_prompt_6shot_extended

load_dotenv()



class Classification(BaseModel):
    topic: str = Field(description="The most important topic in the text")
    label: str = Field(
        description="The stance taken by the highlighted actor on the described topic",
        enum=['Positive', 'Neutral', 'Negative']
    )


class TopicData(TypedDict):
    topic: str
    description: dict
    labels: dict
    issues: list
    predictions: list


def create_input(prompt:ChatPromptTemplate, data:dict, issue, examples=civil_rights_examples):

    input = prompt.format_messages(topic=data['topic'],
                               positive_description=data['descriptions']['positive'],
                               positive_label=data['labels']['positive'],
                               negative_description=data['descriptions']['negative'],
                               negative_label=data['labels']['negative'],
                               issue=issue,
                               examples=civil_rights_examples)
    
    return input


def create_llm(temperature, model_name, logprobs=False):

    if logprobs:
        llm = ChatOpenAI(temperature=temperature, model=model_name).bind(logprobs=True)

    else: 
        llm = ChatOpenAI(temperature=temperature, model=model_name).with_structured_output(
            Classification,
            include_raw=False
            )
    return llm
        

def generate_label(llm:ChatOpenAI, input, logprobs=False):
    output = llm.invoke(input)

    if logprobs:
        return output.response_metadata["logprobs"]["content"][:5], output.content

    else:
        return output.label


def generate_labels(prompt, data:TopicData, logprobs:bool):

    llm = create_llm(0, "gpt-4o-2024-08-06", logprobs)

    for issue in data["issues"]:
        input = create_input(prompt, data, issue)
        label = generate_label(llm, input, logprobs)
        data["predictions"].append(label)

    return data

issues = [
    """hij ontdekte dat hij op jongens viel en was bang gepest te worden.**Timmermans** zei vurig dat het allerergste wat hem kan gebeuren, is dat zijn kinderen en kleinkinderen iets overkomt.Drie dagen eerder, in een interview bij Nieuwsuur, was Timmermans minder overtuigend, althans bij het onderwerp onderwijs.""",
    """Bikker feliciteert de PVV, maar "tegelijkertijd kijken we ook met zorg naar deze uitslag".**Bikker** vreest meer polarisatie door de winst van de PVV."Ons land is gebouwd op minderheden die elkaar heel houden en elkaar weten te vinden.""",
    """Winst PVV leidt bij veel mensen tot angst'De winst van Wilders is een bedreiging van de mensenrechten en de rechtsstaat, zegt Stephan van **Baarle** (**Denk**).Dat leidt volgens de 32-jarige lijsttrekker "bij heel veel mensen tot angst".""",
    """De winst van Wilders is een bedreiging van de mensenrechten en de rechtsstaat, zegt Stephan van Baarle (Denk).Dat leidt volgens de 32-jarige **lijsttrekker** "bij heel veel mensen tot angst".Hij wil de PVV-leider niet feliciteren met zijn winst.""",
    """Ik voel me niet veilig.We waren hier bang voor, maar hadden niet gedacht dat de **PVV** de grootste zou kunnen worden.Wij kunnen niets doen, alleen vasthouden aan de grondwet waarin gelijkheid en godsdienst als rechten wordt genoemd.""",
    """ik kan nu een nieuwe koers voor het land bepalen."In een poging die twijfelende burger te behouden, gooit de **ChristenUnie** het over een andere boeg:die van de 'bestaanszekerheid' van christelijke partijen.""",
    """Gingen e-mails naar leden tot nu toe vooral over 'zorgzame gemeenschappen' en 'grote uitdagingen' voor Nederland, inmiddels luidt de partij de alarmbel over 'het christelijke geluid' in de politiek.Want een stem op **Omtzigt** brengt dat geluid in gevaar, zei partijleider Bikker zaterdag op een campagnebijeenkomst in Veenendaal."Mensen weten waar wij staan rond onderwijsvrijheid, medische ethiek of het levenseinde.""",
    """Die standpunten hebben wij niet zómaar, die komen uit onze christelijke wortels.En kijk, Pieter is absoluut een christelijke **lijsttrekker**, maar zijn partij is wel op een andere leest geschoeid.Wat stemmen zijn fractiegenoten straks bij principiële onderwerpen?""",
    """Hun mening is eenduidig:**Wilders**' lot is zijn eigen keuze.Met de PVV in de regering zullen veel van onze landgenoten ervaren dat ze er van hun overheid eigenlijk niet mogen zijn.""",
    """Proces tegen de heer Wilders in 2026:**Wilders** zal spreken over een 'neprechtbank' die het vonnis van tevoren al klaar had liggen.Onbehoorlijk, vindt de rechtbank, want daarmee tornt Wilders aan de rechtsstaat.""",
    """Wilders zal spreken over een 'neprechtbank' die het vonnis van tevoren al klaar had liggen.Onbehoorlijk, vindt de rechtbank, want daarmee tornt **Wilders** aan de rechtsstaat.Wilders trekt zich daar overigens weinig van aan: vlak na het vonnis zet hij de drie rechters neer als 'PVV-haters'.""",
    """Ik hoop dat Omtzigt de rug nu recht houdt.Willen wij **Wilders** grappen horen maken over mensen met overgewicht (SBS6-debat)?Vinden we het normaal dat hij het heeft over 'genderterreur'?""",
    """Denk is volgens hem vaak een proteststem tegen de wijze waarop gevestigde partijen omgaan met migratie, armoede en discriminatie.Sylvana Simons (Bij1) verlaat de politiek.**Denk** heeft met Stephan van **Baarle** een nieuwe lijsttrekker.De partij zal vermoedelijk garen spinnen bij Van Baarles harde veroordeling van de Israëlische bombardementen op Gaza en de wijze waarop de Nederlandse regering daarop reageerde.""",
    """Denk is volgens hem vaak een proteststem tegen de wijze waarop gevestigde partijen omgaan met migratie, armoede en discriminatie.Sylvana Simons (Bij1) verlaat de politiek.Denk heeft met Stephan van Baarle een nieuwe **lijsttrekker**.De partij zal vermoedelijk garen spinnen bij Van Baarles harde veroordeling van de Israëlische bombardementen op Gaza en de wijze waarop de Nederlandse regering daarop reageerde.""",
    """Niet om de kloof tussen rijk en arm, wit en zwart, vrouw en man.Als **Omtzigt** het heeft over het toeslagenschandaal, heeft hij het opvallend genoeg vrijwel nooit over het feit dat de belastingdienst tot wel zestien keer vaker onderzoek deed naar gezinnen met een migratieachtergrond.Hij zwijgt nadrukkelijk over de menselijke kant van beleid - over de persoonlijke en sociaaleconomische gevolgen, bijvoorbeeld, die het bemoeilijken van zelfbeschikking voor vrouwen met zich meebrengt.""",
    """De jongeman sloeg hem twee keer met de onderkant van een bierfles.De selfies waren hem niet ontraden, aldus **Baudet**, 'maar de komende tijd maak ik ze niet meer'.Volgens Baudet maakt het incident andermaal duidelijk dat niet zijn partij een bedreiging voor de rechtsstaat is, maar dat het gevaar uit de tegenovergestelde hoek komt.""",
    """De selfies waren hem niet ontraden, aldus Baudet, 'maar de komende tijd maak ik ze niet meer'.Volgens **Baudet** maakt het incident andermaal duidelijk dat niet zijn partij een bedreiging voor de rechtsstaat is, maar dat het gevaar uit de tegenovergestelde hoek komt.'Daar wordt geweld gebruikt.'""",
    """Dit keer voelt Baudet zich goed genoeg om door te gaan, zei hij, 'ook omdat het belangrijk is te laten zien dat wij niet buigen'.**Baudet** sprak van 'een politieke aanslag vanwege de standpunten die wij voor het voetlicht brengen'.Voor het café stonden demonstranten van Antifa, die protesteren tegen fascisme, racisme en rechts-extremisme.""",
    """Van de Meeberg vliegt heen en weer om druk te vertellen over al zijn gasten:Brabanders die **PVV** stemmen en Jägermeister drinken, Amsterdamse vrienden die excuses willen aanbieden voor de slavernij aan Thijs zijn vriendin van kleur, een zus die in het onderwijs zit én antivaxer is.Het is een vermakelijke setting, waarin talloze twistpunten uit de Nederlandse samenleving zijn verwerkt.""",
    """Daarom vertrouw ik hem niet helemaal, terwijl hij wel veel kennis en ervaring heeft.'Misschien kies ik dan toch voor **Jetten**, omdat hij redelijk integer is.D66 past, met het standpunt over bijvoorbeeld euthanasie ook wel bij mij.""",
    """Misschien kies ik dan toch voor Jetten, omdat hij redelijk integer is.**D66** past, met het standpunt over bijvoorbeeld euthanasie ook wel bij mij.Maar ik weet het gewoon nog niet.'""",
    """Zijn kinderen vinden pittig eten inmiddels ook best lekker.Het is dat Klaver deze verkiezingen niet meedoet als **lijsttrekker**, anders zou hij misschien wel te horen hebben gekregen dat dit optreden niet 'mannelijk' genoeg was.Want 'vrouwelijk' mag dan tegenwoordig een compliment zijn voor mannen in machtsposities, zowel 'mannelijk' als 'vrouwelijk' kan een scheldwoord zijn voor mensen van welk ander gender dan ook.""",
    """Kijk met zorg naar uitslag'**ChristenUnie-leider** Mirjam **Bikker** wil "juist nu in een gepolariseerde tijd" blijven staan voor de overtuigingen van haar partij: "christelijke, sociale politiek, geworteld in hoop, zoekend naar vrede, pal voor de rechtstaat".Haar partij haalt in de exitpoll 3 zetels, en heeft momenteel 5 zetels in de Kamer."""
]

data:TopicData = {
    "topic": "Burgerrechten",
    "descriptions": {
        "positive": (
            "Vrijheid van meningsuiting, individuele rechten en vrijheden; "
            "privacy; gelijke rechten voor alle mensen, ethnische minderheden, "
            "seksualiteit inc homorechten, transgender, LHBTQI+ rechten; "
            "weerstand tegen discriminatie of anti-semitisme; zelfbeschikking in "
            "gezondheidszorg, waaronder abortus en euthanasie"
        ),
        "negative": (
            "Traditionele / Christelijke / conservatieve normen en waarden; "
            "belang van gezin en gemeenschap; bescherming van het (ongeboren) "
            "leven en het gezin, weerstand tegen abortus / euthanasie, anti-woke"
        )
    },
    "labels": {
        "positive": "Burgerrechten, vrijheid en minderheidsrechten",
        "negative": "Traditionele waarden"
    },
    "issues": issues,
    "predictions": []
}

data = generate_labels(coding_prompt_6shot_extended, data, False)


pprint(data["predictions"])

