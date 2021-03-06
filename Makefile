PROJECT  := psm
# turns the git-describe output of v0.3-$NCOMMITS-$SHA1 into
# the more deb friendly 0.3.$NCOMMITS
VERSION  := $(shell git describe --long --match 'v*' | sed 's/v\([0-9]*\)\.\([0-9]*\)-\([0-9]*\).*/\1.\2.\3/')

DEBUILD_OPTS = -S -sa

prefix   := /usr
bindir   := $(prefix)/bin
sharedir := $(prefix)/share
mandir   := $(sharedir)/man
man1dir  := $(mandir)/man1

all: build

build:
	go test
	go build

psm: *.go
	go build
	if [ $(shell basename $(PWD)) != psm ]; then mv $(shell basename $(PWD)) psm; fi

clean:
	rm -rf psm build psm.1 psm.xml psm.html *~

psm.html: psm.txt
	asciidoc -b xhtml11 -d manpage -f asciidoc.conf -o $@ $<

psm.xml: psm.txt
	asciidoc -b docbook -d manpage -f asciidoc.conf -o $@ $<

psm.1: psm.xml
	xmlto man $<
	cat $@ | sed -e 's/\[FIXME: source\]/psm/' -e 's/\[FIXME: manual\]/User Commands/' >$@.tmp
	mv $@.tmp $@

install: psm psm.1
	install -D -m 4755 -o root psm $(DESTDIR)$(bindir)/psm
	install -D -m 0644 psm.1 $(DESTDIR)$(man1dir)/psm.1

deb: builddeb

builddeb:
	mkdir -p build
	git archive --prefix="$(PROJECT)-$(VERSION)/" HEAD | bzip2 -z9 >build/$(PROJECT)_$(VERSION).orig.tar.bz2
	git archive --prefix="$(PROJECT)-$(VERSION)/" HEAD | tar -xC build
	echo $(VERSION) >build/$(PROJECT)-$(VERSION)/version.txt
	(cd build/$(PROJECT)-$(VERSION) && dch --newversion $(VERSION)-1 -b "Last Commit: $(shell git log -1 --pretty=format:'(%ai) %H %cn <%ce>')")
	(cd build/$(PROJECT)-$(VERSION) && dch --release  "new upstream")
	(cd build/$(PROJECT)-$(VERSION) && debuild $(DEBUILD_OPTS) -v$(VERSION)-1)
	@echo "Package is at build/$(PROJECT)_$(VERSION)-1_all.deb"

version:

.PHONY: all build install deb builddeb version clean
