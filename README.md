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

## Security tradeoffs

In this workflow, I make a few security tradeoffs that are worth
mentioning.

1. No paper export, because I do not have safe access to a printer
2. No air gapped computer, because it adds too many moving parts

What I wanted to achieve:

1. The private master key is kept off my devices
2. The subkeys can be renewed frequently
3. No interactive choices

## Workflow

### Initializing the key

    cp config.mk.example config.mk

Edit config.mk to suit your needs.

* `UID` should match your primary email and name
* `BACKUPDIR` is the location where your secrets are going to be saved.
  I use a removable usb stick.
* `EXPIRE` is how long you want the subkeys to be valid.

Once you are done, you can go ahead and type

    make new

TODO: give info about what this does

