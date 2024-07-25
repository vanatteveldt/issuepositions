library(googlesheets4)
library(tidyverse)
library(glue)
library(gistr)
googlesheets4::gs4_auth()
d = googlesheets4::read_sheet("https://docs.google.com/spreadsheets/d/1CKxjOn-x3Fbk2TVopi1K7WhswcELxbzcyx_o-9l_2oI/edit?gid=871520840#gid=871520840", sheet = "Coding round 4") |>
  filter(!is.na(unit_id))

parse_unit <- function(unit_id, before, text_hl, after, decision, comment, ...) {
  text <- glue("<div style='border:1px solid black'><b>Text</b>:")
  if (!(is.na(before) || is.null(before))) text <- glue("{text} <span style='color:#505050'>{before}</span> ")
  text <- glue("{text} {text_hl}")
  if (!(is.na(after) || is.null(after))) text <- glue("{text} <span style='color:#505050'>{after}</span>")
  text <- glue("{text}</div>\n\n**Coding**: {decision}")
  if (!is.na(comment)) text = glue("{text}<br/> **Uitleg**: <em>{comment}</em>")
  text
}


d3[1:20, ] |> select(unit_id) |> left_join(d) |> purrr::pmap_chr(parse_unit) |>
  writeLines(file("/tmp/uitleg1.md"))
d3[21:60, ] |> select(unit_id) |> left_join(d) |> purrr::pmap_chr(parse_unit) |>
  writeLines(file("/tmp/uitleg2.md"))
d3[61:100, ] |> select(unit_id) |> left_join(d) |> purrr::pmap_chr(parse_unit) |>
  writeLines(file("/tmp/uitleg3.md"))

gistr::gist_auth(reauth = T)
gist_create("/tmp/uitleg1.md", description='Uitleg')

d3[1:20, ] |> select(unit_id) |> left_join(d) |> 
  purrr::pmap_chr(parse_unit) |>
  markdown::mark(format='html', output="/tmp/uitleg1.html", template=T, meta=list(title="Uitleg eerste 20"))

d3[21:60, ] |> select(unit_id) |> left_join(d) |> 
  purrr::pmap_chr(parse_unit) |>
  markdown::mark(format='html', output="/tmp/uitleg2.html", template=T, meta=list(title="Uitleg tweede set (21-60)"))
d3[61:100, ] |> select(unit_id) |> left_join(d) |> 
  purrr::pmap_chr(parse_unit) |>
  markdown::mark(format='html', output="/tmp/uitleg3.html", template=T, meta=list(title="Uitleg derde set (61-100)"))

rstudioapi::viewer(tmpfile)

