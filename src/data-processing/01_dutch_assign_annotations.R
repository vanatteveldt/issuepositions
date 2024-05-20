library(annotinder)
password = rstudioapi::askForPassword(prompt = 'Password: ')
annotinder::backend_connect("https://uva-climate.up.railway.app", username="nelruigrok@nieuwsmonitor.org", .password = password)

frame = question('frame', 'Wat is het frame van deze zin?', codes = c('Issue positie', 'Succes & falen', 'Conflict', "Anders"))
issueposition = question("issue position", 'Wordt er in deze zin een issuepositie weergegeven?', codes = c('Ja', 'Nee'))
conflict = question('conflict', 'Wordt er in deze zin een conflict weergegeven?', codes = c('Ja', 'Nee'))
succes = question("succes en falen",'Gaat het over succes en falen van een actor?', codes = c('Ja', 'Nee'))
codebook = create_codebook(issueposition=issueposition, conflict=conflict, succes=succes)

# Job uploaden naar de server
read_csv("~/Downloads/npo2023/coded_npo.csv")
sents = read_csv("~/Downloads/npo2023/sents_npo.csv")
table(artcodings$unit_id %in% sents$sent_id)
library(annotinder)
jobid = annotinder::upload_job("test", units, codebook)


# Coderen
url = glue::glue('https://uva-climate.netlify.app/?host=https%3A%2F%2Fuva-climate.up.railway.app&job_id={jobid}')
print(url)
browseURL(url)
