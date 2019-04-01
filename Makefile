include config.mk

ifndef UID
$(error "UID not defined.")
endif

ifndef BACKUPDIR
$(error "BACKUPDIR not defined.")
endif

KEYID = $(shell gpg -K --with-colons $(UID) | grep "^sec" | cut -d: -f5)
FGRPR = $(shell gpg -K --with-colons $(UID) | grep "^fpr" | grep $(KEYID) | cut -d: -f10)

backupdir:
	test -d $(BACKUPDIR)

export: backupdir
	gpg --export-secret-keys $(KEYID) > $(BACKUPDIR)/$(KEYID).gpg
	gpg --export-ownertrust > $(BACKUPDIR)/ownertrust.gpg

import: backupdir
	gpg --import $(BACKUPDIR)/$(KEYID).gpg
	gpg --import-ownertrust $(BACKUPDIR)/ownertrust.gpg

new-key:
	gpg --quick-gen-key $(UID) rsa4096 cert never

add-subkeys:
	gpg --quick-add-key $(FGRPR) rsa4096 encr 1m
	gpg --quick-add-key $(FGRPR) rsa4096 sign 1m
	gpg --quick-add-key $(FGRPR) rsa4096 auth 1m

rev-subkeys:
	./bin/revoke-all-subkeys $(KEYID)

keytocard:
	./bin/transfer-subkeys-to-card $(KEYID)

strip-master:
	gpg --output secret-subkeys.gpg --export-secret-subkeys $(KEYID)
	gpg --yes --delete-secret-keys $(KEYID)
	gpg --import secret-subkeys.gpg
	rm secret-subkeys.gpg

revoke:
	gpg --gen-revoke $(KEYID) > revocation.txt
	gpg --import revocation.txt
	@echo "\033[0;31mKey revoked! Use 'make publish' to send it around.\033[0m"

publish:
	keybase pgp update
	#gpg --keyserver pgp.mit.edu --send-keys $(KEYID)
	#gpg --keyserver hkp://keyring.debian.org --send-key $(KEYID)
	#gpg --keyserver hkp://pool.sks-keyservers.net --send-key $(KEYID)

test:
	./bin/test

new:
	$(MAKE) new-key
	$(MAKE) add-subkeys
	$(MAKE) export
	$(MAKE) strip-master

renew:
	$(MAKE) import
	$(MAKE) rev-subkeys
	$(MAKE) add-subkeys
	$(MAKE) export
	$(MAKE) strip-master
