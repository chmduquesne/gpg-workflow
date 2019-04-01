include config.mk

ifndef GNUPGHOME
GNUPGHOME := ${HOME}/.gnupg
endif

ifndef UID
$(error "UID not defined. Please create config.mk and adapt it to your needs.")
endif

ifndef BACKUPDIR
$(error "BACKUPDIR not defined. Please create config.mk and adapt it to your needs.")
endif

KEYID = $(shell gpg -K --with-colons $(UID) | grep "^sec" | cut -d: -f5)
FGRPR = $(shell gpg -K --with-colons $(UID) | grep "^fpr" | grep $(KEYID) | cut -d: -f10)
KGRIP = $(shell gpg -K --with-colons $(UID) | sed -n 3p | cut -d: -f10)

backupdir:
	@echo -e "\033[0;32mMaking sure the backup path is a git directory\033[0m"
	test -d $(BACKUPDIR) || mkdir -p $(BACKUPDIR)
	test -d $(BACKUPDIR)/.git || git init $(BACKUPDIR)

export: backupdir
	@echo -e "\033[0;32mCreating a backup of the complete key\033[0m"
	gpg --export-secret-keys $(KEYID) > $(BACKUPDIR)/$(KEYID).gpg
	gpg --export-ownertrust > $(BACKUPDIR)/ownertrust.gpg
	GIT_DIR=$(BACKUPDIR)/.git GIT_WORK_TREE=$(BACKUPDIR) git add '.'
	GIT_DIR=$(BACKUPDIR)/.git GIT_WORK_TREE=$(BACKUPDIR) git commit -m "Updating secrets"

import: backupdir
	@echo -e "\033[0;32mImporting a backup of the complete key\033[0m"
	gpg --import $(BACKUPDIR)/$(KEYID).gpg
	gpg --import-ownertrust $(BACKUPDIR)/ownertrust.gpg

new-key:
	@echo -e "\033[0;32mGenerating a new key\033[0m"
	gpg --quick-gen-key $(UID) rsa4096 cert never

add-subkeys:
	@echo -e "\033[0;32mGenerating subkeys for encr, sign and auth\033[0m"
	gpg --quick-add-key $(FGRPR) rsa4096 encr 1m
	gpg --quick-add-key $(FGRPR) rsa4096 sign 1m
	gpg --quick-add-key $(FGRPR) rsa4096 auth 1m

rev-subkeys:
	@echo -e "\033[0;32mRevoking all subkeys\033[0m"
	./bin/revoke-all-subkeys $(KEYID)

keystocard:
	@echo -e "\033[0;32mTransferring all valid subkeys to the card\033[0m"
	./bin/transfer-subkeys-to-card $(KEYID)

strip-master:
	@echo -e "\033[0;32mRemoving the master secret\033[0m"
	rm -f ${GNUPGHOME}/private-keys-v1.d/$(KGRIP).key

revoke:
	@echo -e "\033[0;32mRevoking the master key\033[0m"
	gpg --gen-revoke $(KEYID) > revocation.txt
	gpg --import revocation.txt
	@echo "\033[0;31mKey revoked! Use 'make publish' to send it around.\033[0m"

publish:
	@echo -e "\033[0;32mPublishing the key\033[0m"
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
