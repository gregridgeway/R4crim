# Run this script once to create the two pre-made lookup files that students
# need alongside 05_Working_with_NIBRS_data.qmd:
#   nibrs_format.csv         -- column specs for every NIBRS segment
#   nibrs_offense_lookup.csv -- UCR code -> crime category -> crime description
#
# Requires: NIBRS Records Description updated.xlsx in the working directory

library(readxl)
library(dplyr)
library(readr)

# ---- Main format table (INCIDENT RECORD sheet) ----

fmtXL <- read_excel("NIBRS/NIBRS Records Description updated.xlsx",
                    sheet = "INCIDENT RECORD",
                    range = "A5:D819") |>
  rename(DataField  = `Data Field Number`,
         TypeLength = `Type/ Length`)

clean_fmt <- function(rows, exclude_pos = NULL) {
  fmt <- fmtXL |>
    slice(rows) |>
    filter(!is.na(Position))
  if (!is.null(exclude_pos))
    fmt <- fmt |> filter(!(Position %in% exclude_pos))
  data.frame(
    col_name  = fmt$Description |>
      strsplit(split = " - ", fixed = TRUE) |>
      sapply(head, n = 1) |>
      gsub("[^A-Za-z0-9]+", "_", x = _) |>
      gsub("_+$", "", x = _) |>
      tolower(),
    col_type  = recode_values(substring(fmt$TypeLength, 1, 1), from=c("A","N"), to=c("c","n")),
    col_width = fmt$TypeLength |>
      substring(2) |>
      as.numeric()
  )
}

i02 <- grep('LEVEL "02"', fmtXL$DataField)
i03 <- grep('LEVEL "03"', fmtXL$DataField)
i04 <- grep('LEVEL "04"', fmtXL$DataField)
i05 <- grep('LEVEL "05"', fmtXL$DataField)
i06 <- grep('LEVEL "06"', fmtXL$DataField)
i07 <- grep('LEVEL "07"', fmtXL$DataField)

nibrs_format <- bind_rows(
  clean_fmt(3:(i02 - 3),       "59-88")                                    |> mutate(segment = "01"),
  clean_fmt((i02 + 1):(i03 - 3), c("38-40", "46-48", "49-57"))            |> mutate(segment = "02"),
  clean_fmt((i03 + 2):(i04 - 3), c("14-22","20-22","58-102","58-72","103-132")) |> mutate(segment = "03"),
  clean_fmt((i04 + 1):(i05 - 3), c("37-66","74-77","79-83","84-123"))     |> mutate(segment = "04"),
  clean_fmt((i05 + 1):(i06 - 3))                                           |> mutate(segment = "05"),
  clean_fmt((i06 + 2):(i07 - 3), c("61-66", "75-104"))                    |> mutate(segment = "06"),
  clean_fmt(-(1:i07),            "44-49")                                  |> mutate(segment = "07")
)

# Property segment has two ESTIMATED.QUANTITY columns; rename the second
nibrs_format <- nibrs_format |>
  mutate(col_name = if_else(
    segment == "03" &
      col_name == "estimated_quantity" &
      duplicated(paste(segment, col_name)),
    "estimated_quantity_1000ths",
    col_name))

# Shorten the unwieldy type_property_loss_etc name
nibrs_format <- nibrs_format |>
  mutate(col_name = if_else(col_name == "type_property_loss_etc",
                            "type_property_loss",
                            col_name))

# ---- Batch header (first sheet) ----

fmtBH <- read_excel("NIBRS/NIBRS Records Description updated.xlsx", skip = 4) |>
  data.frame() |>
  filter(!is.na(Position) &
         !(Position %in% c("106-225", "234-269", "234", "235", "236", "270-284")))

nibrs_format <- bind_rows(
  nibrs_format,
  data.frame(
    col_name  = fmtBH$Description |>
      strsplit(split = " - ", fixed = TRUE) |>
      sapply(head, n = 1) |>
      gsub("[^A-Za-z0-9]+", "_", x = _) |>
      gsub("_+$", "", x = _) |>
      tolower(),
    col_type  = recode_values(substring(fmtBH$Type..Length, 1, 1), from=c("A","N"), to=c("c","n")),
    col_width = fmtBH$Type..Length |>
      substring(2) |>
      as.numeric(),
    segment   = "BH"
  )
)

write_csv(nibrs_format, "NIBRS/nibrs_format.csv")
message("Written: nibrs_format.csv  (", nrow(nibrs_format), " rows)")

# ---- Offense lookup table ----

i_start <- which(fmtXL$Description == "720 - Animal Cruelty Offenses - Animal Cruelty")
i_end   <- which(fmtXL$Description == "90Z - All Other Offenses - All Other Offenses")

offense_lookup <- strsplit(fmtXL$Description[i_start:i_end], " - ") |>
  do.call(rbind, args = _) |>
  data.frame() |>
  rename(ucr_code = X1, crime_cat = X2, crime = X3) |>
  filter(ucr_code != "Group B Offenses")

write_csv(offense_lookup, "NIBRS/nibrs_offense_lookup.csv")
message("Written: nibrs_offense_lookup.csv  (", nrow(offense_lookup), " rows)")
