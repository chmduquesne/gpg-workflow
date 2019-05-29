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

ifndef ALGORITHM_PRIM
ALGORITHM_PRIM := "rsa4096"
endif
ifndef ALGORITHM_SUB
ALGORITHM_SUB := "rsa4096"
endif

KEYID = $(shell gpg -k --with-colons $(UID) | grep "^fpr" | head -n1 | cut -d: -f10)
KGRIP = $(shell gpg -K --with-colons $(UID) | sed -n 3p | cut -d: -f10)

# Check that BACKUPDIR exists and is a git repository
backupdir:
	@./bin/green "Making sure the backup path is a git directory"
	test -d $(BACKUPDIR) || mkdir -p $(BACKUPDIR)
	test -d $(BACKUPDIR)/.git || git init $(BACKUPDIR)

# Save the complete key with its secrets and ownertrust in a new commit
export: backupdir
	@./bin/green "Creating a backup of the complete key"
	gpg --export-secret-keys $(KEYID) > $(BACKUPDIR)/$(KEYID).gpg
	gpg --export-ownertrust > $(BACKUPDIR)/ownertrust.gpg
	GIT_DIR=$(BACKUPDIR)/.git GIT_WORK_TREE=$(BACKUPDIR) git add '.'
	GIT_DIR=$(BACKUPDIR)/.git GIT_WORK_TREE=$(BACKUPDIR) git commit -m "Updating secrets"

# Restores the complete key and ownertrust
import: backupdir purge-secrets
	@./bin/green "Importing a backup of the complete key"
	gpg --import --import-options restore $(BACKUPDIR)/$(KEYID).gpg
	gpg --import-ownertrust $(BACKUPDIR)/ownertrust.gpg

# Create a key from scratch
new-key:
	@./bin/green "Generating a new key"
	gpg --quick-gen-key $(UID) $(ALGORITHM_PRIM) cert never

# Add new encryption/signing/authentication subkeys to the key
add-subkeys:
	@./bin/green "Generating subkeys for encr, sign and auth"
	gpg --quick-add-key $(KEYID) $(ALGORITHM_SUB) encr $(EXPIRE)
	gpg --quick-add-key $(KEYID) $(ALGORITHM_SUB) sign $(EXPIRE)
	gpg --quick-add-key $(KEYID) $(ALGORITHM_SUB) auth $(EXPIRE)

# Revoke all the subkeys of the key (reason is "key superseded")
rev-subkeys:
	@./bin/green "Revoking all subkeys"
	./bin/revoke-all-subkeys $(KEYID)

# Transfer all non-expired/non-revoked subkeys to the smartcard
keystocard:
	@./bin/green "Transferring all valid subkeys to the smartcard"
	./bin/transfer-subkeys-to-card $(KEYID)
	@./bin/blue "You should now run 'make publish'"

# Remove the secret of the master key
strip-master:
	@./bin/green "Removing the master secret"
	rm -f ${GNUPGHOME}/private-keys-v1.d/$(KGRIP).key
	@./bin/blue "You should now run 'make keystocard'"

# Remove all secrets from the key
purge-secrets:
	@./bin/green "Removing all secrets"
	gpg -K --with-colons $(UID) | grep "^grp" | cut -d: -f10 | \
		xargs -I% rm -f ${GNUPGHOME}/private-keys-v1.d/%.key

# Revoke the key (requires the secret of the master)
revoke:
	@./bin/green "Revoking the master key"
	gpg --gen-revoke $(KEYID) > revocation.txt
	gpg --import revocation.txt
	@./bin/red "Key revoked! Use 'make publish' to send it around."

# Publish the key
publish:
	@./bin/green "Publishing the key"
	keybase pgp update
	gpg --keyserver pgp.mit.edu --send-keys $(KEYID)
	gpg --keyserver hkp://keyring.debian.org --send-key $(KEYID)
	gpg --keyserver hkp://pool.sks-keyservers.net --send-key $(KEYID)

# Run the test suite
test:
	./bin/test

# Create a new key and save it
new:
	$(MAKE) new-key
	$(MAKE) add-subkeys
	$(MAKE) export
	@./bin/blue "To make another backup, run 'BACKUPDIR=/path/to/backup make export'"
	@./bin/blue "Otherwise run 'make strip-master'"

# Revoke all subkeys and create new ones
renew:
	$(MAKE) import
	$(MAKE) rev-subkeys
	$(MAKE) add-subkeys
	$(MAKE) export
	@./bin/blue "To make another backup, run 'BACKUPDIR=/path/to/backup make export'"
	@./bin/blue "Otherwise run 'make strip-master'"
