[![Build Status](https://travis-ci.org/chmduquesne/gpg-workflow.svg?branch=master)](https://travis-ci.org/chmduquesne/gpg-workflow)

# gpg-workflow

## Intro

As a [pass](https://www.passwordstore.org/) user, I decided to
[strenghten](https://www.grepular.com/An_NFC_PGP_SmartCard_For_Android) my
gpg game and use a smartcard in my everyday life.

If you have any experience with gpg, you know that correctly managing a
keypair is challenging. There are numerous guides on the web about how to
create the perfect keypair, none of which I found to be practically
usable. Dealing with expired subkeys is incredibly painful, and it is
certainly not something you want to do in a rush.

I started this project because I wanted to simplify my workflow. I wanted
to be able to create, version, renew subkeys, transfer them to my
smartcard with simple commands and sane defaults.

## Security tradeoffs

In this workflow, I make a few security tradeoffs that it is worth
mentioning:

1. No paper export, because I do not have safe access to a printer
2. No air gapped computer, because I don't have one

What I garantee:

1. The master private key is kept off any running laptop (outside key
   updates)
2. The subkeys can be renewed frequently
3. No interactive choices

## Workflow

TODO
