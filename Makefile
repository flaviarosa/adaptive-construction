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

deploy : pandoc build

pandoc : $(DOCS)

build : sitemap.xml
	docker run --rm -v "`pwd`:/srv/jekyll" jekyll/jekyll:4.1.0 \
		/bin/bash -c "chmod 777 /srv/jekyll && jekyll build"

build-local : build
	mv -rf tmp/* _site/
	-rm -rf styles

tmp/%.md : %.md spec/jekyll.yaml default.jekyll biblio.bib
	@test -e tmp || mkdir tmp
	@test -e styles || git clone https://github.com/citation-style-language/styles.git
	docker run --rm --volume "`pwd`:/data" --user `id -u`:`id -g` \
		palazzo/pandoc-xnos:2.9.2.1 -o $@ -d spec/jekyll.yaml $<

serve :
	docker run --rm -v "`pwd`:/srv/jekyll" \
		-h 127.0.0.1 -p 4000:4000 -it jekyll/jekyll:4.1.0 \
		jekyll serve --skip-initial-build --no-watch

# Install and cleanup {{{1
# ===================
# `make install` copies various config files and hooks to the .git
# directory and sets up standard empty directories:
# - link-template: sets up the template repo in a branch named `template`, for
#   when you want to update local boilerplates across different projects.
# - makedirs: creates standard folders for output (_book), received files
#   (_share), and figures (fig).
# - submodule: initializes the submodules for the CSL styles and for the
#   Reveal.js framework.
# - virtualenv: sets up a virtual environment (but you still need to activate
#   it from the command line).
.PHONY : install template submodule virtualenv clean
install : template submodule csl virtualenv license
	bundle install

makedirs :
	-mkdir _share && mkdir _book && mkdir fig

csl : .install/git/modules/lib/styles/info/sparse-checkout
	rsync -aq .install/git/ .git/
	cd lib/styles && git config core.sparsecheckout true && \
		git checkout master && git pull && \
		git read-tree -m -u HEAD

submodule :
	# Generating a repo from a GitHub template breaks the submodules.
	# As a workaround, we init the submodules after cloning the template repo
	# instead of including them in the source template.
	git submodule add https://github.com/hakimel/reveal.js.git docs/reveal.js
	git submodule add https://github.com/citation-style-language/styles.git lib/styles
	git submodule add https://github.com/jgm/pandoc-templates.git lib/pandoc-templates

template :
	-git remote add template git@github.com:p3palazzo/research_template.git
	git fetch template
	git checkout -B template --track template/master
	git checkout -

virtualenv :
	python -m venv .venv && source .venv/bin/activate && \
		pip install -r .install/requirements.txt
	-rm -rf src

bundle :
	bundle update

license :
	source .venv/bin/activate && \
		lice --header cc_by_sa >> README.md && \
		lice cc_by_sa -f LICENSE

# `make clean` will clear out a few standard folders where only compiled
# files should be. Anything you might have placed manually in them will
# also be deleted!
clean :
	-rm -r _book/* _site/*

# vim: set foldmethod=marker shiftwidth=2 tabstop=2 :
