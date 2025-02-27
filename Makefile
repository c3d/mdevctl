PREFIX=/usr
UDEVDIR=$(shell pkg-config --variable=udevdir udev)
UNITDIR=$(shell pkg-config --variable=systemdsystemunitdir systemd)
SBINDIR=$(PREFIX)/sbin
LIBEXECDIR=$(PREFIX)/libexec
CONFDIR=/etc/mdevctl.d
ETCDIR=/etc
NAME=mdevctl
VERSION=0.$(shell git rev-list --count HEAD)
COMMIT=$(shell git rev-list --max-count 1 HEAD)
NVFMT=$(NAME)-$(VERSION)-$(COMMIT)

files: mdevctl.sbin mdevctl.libexec mdevctl.conf mdev@.service \
	60-persistent-mdev.rules Makefile COPYING README mdevctl.spec.in

archive: files tag mdevctl.spec
	git archive --prefix=$(NVFMT)/ HEAD > $(NVFMT).tar
	gzip -f -9 $(NVFMT).tar

mdevctl.spec: mdevctl.spec.in files
	sed -e 's:#VERSION#:$(VERSION):g' \
	    -e 's:#COMMIT#:$(COMMIT):g'  < mdevctl.spec.in > mdevctl.spec
	git log --format="* %cd %aN <%ae>%n%B" --date=local mdevctl.spec.in | sed -r -e 's/%/%%/g' -e 's/[0-9]+:[0-9]+:[0-9]+ //' >> mdevctl.spec

srpm: mdevctl.spec archive
	rpmbuild -bs --define "_sourcedir $(PWD)" --define "_specdir $(PWD)" --define "_builddir $(PWD)" --define "_srcrpmdir $(PWD)" --define "_rpmdir $(PWD)" mdevctl.spec

rpm: mdevctl.spec archive
	rpmbuild -bb --define "_sourcedir $(PWD)" --define "_specdir $(PWD)" --define "_builddir $(PWD)" --define "_srcrpmdir $(PWD)" --define "_rpmdir $(PWD)" mdevctl.spec

install:
	mkdir -p $(DESTDIR)$(CONFDIR)
	install -m 644 mdevctl.conf $(DESTDIR)$(ETCDIR)/
	mkdir -p $(DESTDIR)$(UDEVDIR)/rules.d/
	install -m 644 60-persistent-mdev.rules $(DESTDIR)$(UDEVDIR)/rules.d/
	mkdir -p $(DESTDIR)$(UNITDIR)
	install -m 644 mdev@.service $(DESTDIR)$(UNITDIR)/
	mkdir -p $(DESTDIR)$(SBINDIR)
	install -m 755 mdevctl.sbin $(DESTDIR)$(SBINDIR)/mdevctl
	mkdir -p $(DESTDIR)$(LIBEXECDIR)
	install -m 755 mdevctl.libexec $(DESTDIR)$(LIBEXECDIR)/mdevctl

clean:
	rm -f mdevctl.spec *.src.rpm noarch/*.rpm *.tar.gz

tag:
	git tag -l $(VERSION) | grep -q $(VERSION) || git tag $(VERSION)
