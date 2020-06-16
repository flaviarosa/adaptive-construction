# Global variables {{{1
# ================
# Where make should look for things
VPATH = lib
vpath %.csl styles
vpath %.html .:_includes:_layouts:_site
vpath %.xml _site
vpath %.yaml .:spec
vpath default.% lib/templates:lib/pandoc-templates

# Branch-specific targets and recipes {{{1
# ===================================

# Jekyll {{{2
# ------
SRC   = $(filter-out README.md,$(wildcard *.md))
DOCS := $(patsubst %.md,tmp/%.md, $(SRC))

pandoc : $(DOCS)
	rm -rf styles

tmp/%.md : %.md spec/jekyll.yaml default.jekyll biblio.bib
	@test -e tmp || mkdir tmp
	@test -e styles || git clone https://github.com/citation-style-language/styles.git
	docker run --rm --volume "`pwd`:/data" --user `id -u`:`id -g` \
		palazzo/pandoc-xnos:2.9.2.1 -o $@ -d spec/jekyll.yaml $<

serve :
	docker run --rm -p 4000:4000 -h 127.0.0.1 \
		-v "`pwd`:/srv/jekyll" -it jekyll/jekyll:3.8.5 \
		jekyll serve
