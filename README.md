[![Build Status](https://travis-ci.org/chmduquesne/gpg-workflow.svg?branch=master)](https://travis-ci.org/chmduquesne/gpg-workflow)

# gpg-workflow

## Intro

As a [pass](https://www.passwordstore.org/) user, I decided to
[strenghten](https://www.grepular.com/An_NFC_PGP_SmartCard_For_Android) my
gpg game and use a smartcard in my everyday life.

If you have any experience with gpg, you know that correctly managing a
keypair is challenging. There are numerous guides about how to create the
perfect keypair, none of which I found to be practically usable in a
situation of emergency when some subkey is about to expire. Dealing with
expired subkeys is incredibly painful, and it is certainly not something
you want to do in a rush.

I started this project because I wanted to simplify my workflow. I wanted
to be able to create, version, renew subkeys, transfer them to my
smartcard with simple commands and sane defaults, and I thought a Makefile
would be adapted for this.

## Workflow

### Creating or renewing the key secrets

The only 2 really important targets are `new` and `renew`, because they
are the starting points of the flow. After you execute a target, it
provides helpful text as to what to do next.

    make new

will initialize the key according to the parameters from the file
`config.mk`

    make renew

will renew the subkeys of your already existing key.

### Smartcard support

After creating or updating your keypair, you will want to move the secrets
to a smartcard. This process is guided by the makefile and involves
multiple steps:

#### Backup the full keypair

Mount a usb stick as /path/to/backup, then

    BACKUPDIR=/path/to/backup make export

If it does not exist already, a git repository is initialized. Repeat this
as many times as desired for multiple backups.

#### Remove the secret of the master key

After making a backup (preferably multiple), remove the keygrip file.

    make strip-master

#### Move the subkeys to the smartcard

Finally, plug-in your smartcard, then run

    make keystocard

You will be asked for the admin pin of the smartcard, and the passphrase
to the key multiple times.

## Details

### File config.mk

The file config.mk lets you configure your preference about how the key
should be maintained.

    cp config.mk.example config.mk

Edit it to suit your needs.

* `UID` should match your primary email and name
* `BACKUPDIR` is the location where your secrets are going to be saved.
  I use a removable usb stick.
* `EXPIRE` is how long you want the subkeys to be valid.

### Target dumpvars (default target)

    make [dumpvars]

will let you see all variables use by the Makefile. This lets you make
sure which keyid is being used, the expiration time, the backup directory,
etc.

### Target backupdir

    make backupdir

ensures that the directory in the variable BACKUPDIR exists. If it does
not, the target will attempt to create this directory. If it does not
contain a .git directory, it will also attempt to initialize a new git
repository in it.

### Target export

    make export

saves the complete key, secrets and ownertrust in a new commit in the
BACKUPDIR. This target calls backupdir as a dependency.

### make new

    make new

will create the new key set including:

- A primary key with Certify attribute
- A subkey with Authentication attribute
- A subkey with Encryption attribute
- A subkey with Signature attribute

The primary key is backed up in the backup directory set in the configuation
file.

Once the keys have been generated, the primary key may be removed from the
keyring (recommended) by running:

    make strip-master

The primary secret key can be imported later using

    make import

After removing the primary key, the subkeys can be moved to a keycard using

    make keystocard

The public key is now ready to be published with

    make publish

When time comes, the subkeys can be renewed using the target

    make renew

This command will reimport the backed up secret key, revoke the current subkeys
and generate three new subkeys. The workflow continues with strip-master etc.

In case of theft, or loss of the keys they can be manually revoked using

    make rev-subkeys

In the same way, the master key can be revoked using

    make revoke

Do not forget to publish your keys after every key creations, or revokations.

#### Todo

Document:

- export
- new-key
- backupdir
- purge-secrets

## Security tradeoffs

In this workflow, I make a few security tradeoffs that are worth
mentioning:

1. No paper export, because I do not have safe access to a printer
2. No air gapped computer, because it adds too many moving parts

What I wanted to achieve:

1. The private master key is kept off my devices
2. The subkeys can be renewed frequently
3. No interactive choices



