ifndef UID
	UID := "Elliot Alderson <ealderson@ecorp.com>"
endif

ifdef GNUPGHOME
	CONF := ${GNUPGHOME}/gpg.conf
else
	CONF := ~/.gnupg/gpg.conf
endif

DEFAULTKEY = $(shell gpg -K --with-colons | grep "^sec" | cut -d: -f5 | tail -n1)
DEFAULTFPR = $(shell gpg -K --with-colons | grep "^fpr" | grep $(DEFAULTKEY) | rev | cut -d: -f2 | rev)

export:
	gpg --export-secret-keys > secret-keys.gpg
	gpg --export-ownertrust > ownertrust.gpg
	[ -f ${CONF} ] && cp ${CONF} gpg.conf || true

import:
	gpg --import secret-keys.gpg
	gpg --import-ownertrust ownertrust.gpg
	[ -f gpg.conf ] && cp gpg.conf ${CONF} || true

new-key:
	gpg --quick-gen-key $(UID) rsa4096 cert never

add-subkeys:
	gpg --quick-add-key $(DEFAULTFPR) rsa4096 encr 1m
	gpg --quick-add-key $(DEFAULTFPR) rsa4096 sign 1m
	gpg --quick-add-key $(DEFAULTFPR) rsa4096 auth 1m

rev-subkeys:
	./bin/revoke-all-subkeys $(DEFAULTKEY)

keytocard:
	./bin/transfer-subkeys-to-card $(DEFAULTKEY)

strip-master:
	gpg --output secret-subkeys.gpg --export-secret-subkeys $(DEFAULTKEY)
	gpg --yes --delete-secret-keys $(DEFAULTKEY)
	gpg --import secret-subkeys.gpg
	rm secret-subkeys.gpg

revoke:
	gpg --gen-revoke $(DEFAULTKEY) > revocation.txt
	gpg --import revocation.txt
	@echo "\033[0;31mKey revoked! You can now send your revoked key around.\033[0m"
	@echo "\033[0;31mgpg --keyserver pgp.mit.edu --send-keys $(DEFAULTKEY)\033[0m"
	@echo "\033[0;31mgpg --keyserver hkp://keyring.debian.org --send-key $(DEFAULTKEY)\033[0m"
	@echo "\033[0;31mgpg --keyserver hkp://pool.sks-keyservers.net --send-key $(DEFAULTKEY)\033[0m"

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
