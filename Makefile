# John McLevey
# October 28, 2015

# This is a very minimal make file that you can use to knit your
# Rmarkdown files into pandoc markdown files, which can then be
# converted into PDF, html, or docx using pandoc. You will need to
# edit the file paths at the start of the file.

# While it is possible to write a more abstract Makefile that
# can easily be dropped into different projects, this one
# references specific files that might be in your directory.
# That means you will also have to edit file names for each project
# that you use this Makefile for.

# You might want to read [this post](http://bost.ocks.org/mike/make/) by Mike Babstock on Make
# and [this post](http://kbroman.org/minimal_make/) by Karl Broman on Make

# You can reference the output file with: $@
# You can reference the input file with : $<

## Location of Pandoc support files.
SUPPORT = /Users/yanish/Documents/latex_writing/pandoc_templates

## Location of your working bibliography file
BIB = /Users/yanish/Documents/latex_writing/bibliography/references.bib

## Location of CSL stylesheet
CSL = /Users/yanish/Documents/latex_writing/bibliography/apsa.csl

# make works backwards, so put your final targets first,
# and work your way back to the start

all: article.md article.pdf article.html article.docx

article.pdf: article.md
	pandoc -r markdown+simple_tables+table_captions+yaml_metadata_block -s -S --latex-engine=pdflatex --template=$(SUPPORT)/article.tex --filter pandoc-citeproc --csl=$(CSL) --bibliography=$(BIB) -o $@ $<

article.docx: article.md
	pandoc -r markdown+simple_tables+table_captions+yaml_metadata_block -s -S --latex-engine=pdflatex --filter pandoc-citeproc --csl=$(CSL) --bibliography=$(BIB) -o $@ $<

article.html: article.md
	pandoc -r markdown+simple_tables+table_captions+yaml_metadata_block -s -S --latex-engine=pdflatex --template=$(SUPPORT)/html.template --filter pandoc-citeproc --csl=$(CSL) --bibliography=$(BIB) -o $@ $<

article.md: article.Rmd
	Rscript -e "require(knitr); knit('$<', '$@')"

# CAREFUL: This rule will remove all html, pdf, tex, and docx
# files in the directory. Note that regular markdown files are not
# included.

clean:
	rm -f *.html *.pdf *.tex *.docx
