library(googlesheets4)
library(tidyverse)
library(glue)
googlesheets4::gs4_auth()
d = googlesheets4::read_sheet("https://docs.google.com/spreadsheets/d/1CKxjOn-x3Fbk2TVopi1K7WhswcELxbzcyx_o-9l_2oI/edit?gid=871520840#gid=871520840", sheet = "Coding round 4")

parse_unit <- function(unit_id, before, text_hl, after, decision, comment, ...) {
  text <- glue("<div style='border:1px solid black'><b>Text</b>:")
  if (!(is.na(before) || is.null(before))) text <- glue("{text} <span style='color:#505050'>{before}</span> ")
  text <- glue("{text} {text_hl}")
  if (!(is.na(after) || is.null(after))) text <- glue("{text} <span style='color:#505050'>{after}</span>")
  text <- glue("{text}</div>\n\n**Coding**: {decision}")
  if (!is.na(comment)) text = glue("{text}<br/> **Uitleg**: <em>{comment}</em>")
  text
}
texts <- d |> filter(!is.na(unit_id)) |> purrr::pmap_chr(parse_unit)

tmpfile <- tempfile(fileext = ".html")
html <- markdown::mark(texts, format='html', output=tmpfile, template=T, meta=list(title="Coding round 4"))

rstudioapi::viewer(tmpfile)

