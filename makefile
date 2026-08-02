QMD_FILES = \
  01_Intro_to_R_protests.qmd \
  02_Dates_and_times.qmd \
  03_Regular_expressions.qmd \
  04_Working_with_NCVS_data.qmd \
  05_Working_with_NIBRS_data.qmd \
  06_Mapping_Crime_Hotspots.qmd \
  09_Webscraping_and_Parallel_Processing.qmd \
  10_PPD_shootings_extracting_from_text_geocoding.qmd \
  11_Working_with_geographic_data.qmd


HTML_FILES := $(QMD_FILES:.qmd=.html)
PDF_FILES  := $(QMD_FILES:.qmd=.pdf)

# Build both formats unless user specifies a target
all: $(HTML_FILES) $(PDF_FILES)

%.html %.pdf: %.qmd
	quarto render $<

clean:
	rm -f $(HTML_FILES) $(PDF_FILES)
