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

ifndef EXPIRE
EXPIRE := "1m"
endif

KEYID = $(shell gpg -K --with-colons $(UID) | grep "^sec" | cut -d: -f5)
FGRPR = $(shell gpg -K --with-colons $(UID) | grep "^fpr" | grep $(KEYID) | cut -d: -f10)
KGRIP = $(shell gpg -K --with-colons $(UID) | sed -n 3p | cut -d: -f10)

backupdir:
	@./bin/blue "Making sure the backup path is a git directory"
	test -d $(BACKUPDIR) || mkdir -p $(BACKUPDIR)
	test -d $(BACKUPDIR)/.git || git init $(BACKUPDIR)

export: backupdir
	@./bin/blue "Creating a backup of the complete key"
	gpg --export-secret-keys $(KEYID) > $(BACKUPDIR)/$(KEYID).gpg
	gpg --export-ownertrust > $(BACKUPDIR)/ownertrust.gpg
	GIT_DIR=$(BACKUPDIR)/.git GIT_WORK_TREE=$(BACKUPDIR) git add '.'
	GIT_DIR=$(BACKUPDIR)/.git GIT_WORK_TREE=$(BACKUPDIR) git commit -m "Updating secrets"

import: backupdir remove-all-secrets
	@./bin/blue "Importing a backup of the complete key"
	gpg --import $(BACKUPDIR)/$(KEYID).gpg
	gpg --import-ownertrust $(BACKUPDIR)/ownertrust.gpg

new-key:
	@./bin/blue "Generating a new key"
	gpg --quick-gen-key $(UID) rsa4096 cert never

add-subkeys:
	@./bin/blue "Generating subkeys for encr, sign and auth"
	gpg --quick-add-key $(FGRPR) rsa4096 encr $(EXPIRE)
	gpg --quick-add-key $(FGRPR) rsa4096 sign $(EXPIRE)
	gpg --quick-add-key $(FGRPR) rsa4096 auth $(EXPIRE)

rev-subkeys:
	@./bin/blue "Revoking all subkeys"
	./bin/revoke-all-subkeys $(KEYID)

keystocard:
	@./bin/blue "Transferring all valid subkeys to the card"
	./bin/transfer-subkeys-to-card $(KEYID)
	@./bin/green "You should now run 'make publish'"

strip-master:
	@./bin/blue "Removing the master secret"
	rm -f ${GNUPGHOME}/private-keys-v1.d/$(KGRIP).key

remove-all-secrets:
	@./bin/blue "Removing all secrets"
	gpg -K --with-colons $(UID) | grep "^grp" | cut -d: -f10 | \
		xargs -I% echo rm -f ${GNUPGHOME}/private-keys-v1.d/%.key

revoke:
	@./bin/blue "Revoking the master key"
	gpg --gen-revoke $(KEYID) > revocation.txt
	gpg --import revocation.txt
	@./bin/red "Key revoked! Use 'make publish' to send it around."

publish:
	@./bin/blue "Publishing the key"
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
	@./bin/green "You should now run remove your backup, then run 'make keystocard'"

renew:
	$(MAKE) import
	$(MAKE) rev-subkeys
	$(MAKE) add-subkeys
	$(MAKE) export
	$(MAKE) strip-master
	@./bin/green "You should now run remove your backup, then run 'make keystocard'"
