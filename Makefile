ifndef UID
	UID := "Elliot Alderson <ealderson@ecorp.com>"
endif

KEYID = $(shell gpg -K --with-colons $(UID) | grep "^sec" | cut -d: -f5)
FGRPR = $(shell gpg -K --with-colons $(UID) | grep "^fpr" | grep $(KEYID) | cut -d: -f10)

data:
	mkdir -p data

export: data
	gpg --export-secret-keys $(KEYID) > data/$(KEYID).gpg
	gpg --export-ownertrust > data/ownertrust.gpg

import: data
	gpg --import data/$(KEYID).gpg
	gpg --import-ownertrust data/ownertrust.gpg

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
	@echo "\033[0;31mKey revoked! You can now send your revoked key around.\033[0m"
	@echo "\033[0;31mgpg --keyserver pgp.mit.edu --send-keys $(KEYID)\033[0m"
	@echo "\033[0;31mgpg --keyserver hkp://keyring.debian.org --send-key $(KEYID)\033[0m"
	@echo "\033[0;31mgpg --keyserver hkp://pool.sks-keyservers.net --send-key $(KEYID)\033[0m"

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

cleanenv:
	rm -rf gnupg
	mkdir gnupg
	chmod 700 gnupg
	rm -rf data
