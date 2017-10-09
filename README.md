# lib4ri_tools

Proof-of-concept web-application hosting tools for Lib4RI

## Introduction

In its first incarnation, this set of tools is intendend to allow several people (some of whom might not have access to a Unix machine) to execute a set of `bash` scripts on a certain number of files. For this, a web-application was written which gives those users a graphical interface that guides them through the process.

Right now, the `bash` scripts are intended to combine certain (previously prepared) data files related to a Scopus alert into a ZIP archive containing MODS (XML) files and PDFs that are ready to ingest in our Islandora-based institutional repository [DORA](https://www.dora.lib4ri.ch). The user interface is crude and needs to be reworked. The aforementioned `bash` scripts would also benefit from a revisit.

## CAVEAT

THIS IS WORK IN PROGRESS!!! FOR THE MOMENT, IT SEEMS TO DO ITS JOB FOR US, BUT WE ARE AWARE THAT IT IS NOT ALWAYS CODED IN THE CORRECT WAY. DUE TO TIME CONSTRAINTS, THIS EVALUATION CODE WILL BE USED TEMPORARILY IN PRODUCTION, BUT WE HOPE TO UPDATE IT AT SOME POINT. YOU SHOULD PROBABLY NOT USE THIS CODE YOURSELF, AS IT MIGHT NOT WORK FOR YOU OR EVEN BREAK YOUR SYSTEM (SEE ALSO 'License.md'). UNDER NO CIRCUMSTANCES WHATSOEVER ARE WE TO BE HELD LIABLE FOR ANYTHING. YOU HAVE BEEN WARNED.

## @TODO

* Write a proper documentation instead of this one
* Revisit the code (especially the `bash` scripts) and re-design the user interface

## Requirements (@TODO: make the dependency list more explicit)

This software was successfully run in an [LXC](https://linuxcontainers.org/lxc/) container inside a x86_64 GNU/Linux host using
* [`python`](https://www.python.org) (2.7.13)
* the following additional packages from the repositories:
    - `iconv`
    - `xmllint`
    - `libxml2-utils`
    - `icu-devtools`
    - `zip`
    - `unzip`

* the following `perl` packages:
    - [XML-Twig](http://search.cpan.org/~mirod/XML-Twig/) (3.52)
    - [XML-Parser](http://search.cpan.org/~msergeant/XML-Parser-2.36/) (2.36)

* _possibly other tools not present in a default installation_

In addition, the software needs the following subdirectories to be present:
* `persistent_data/{eawag,empa,wsl}`
* `temporary_data`
* `tmp`

Ensure that the service can write in all of them (e.g., either by `chown`ing appropriately, or by `chmod`ding to `777`)!

## Installation

tbd

@IMPORTANT: In production, the key for session information encryption should be set to something different than `'extremely_secure_random_secret_key'` (see L18 in `lib4ri_tools.py`)!

## Usage

Currently, the code works for the three institutes: Eawag, Empa, WSL. After selecting the institute, the user is prompted to upload the following files:
* `Authors.csv` (institute-specific, persistent)
* `Departments.csv` (institute-specific, persistent)
* `Journals.csv` (shared across institutes, persistent)
* `OpenAccess_Info.csv` (shared across institutes, persistent)
* `WOS.txt` (alert-specific, ephemeral)
* `PDFs.zip` (alert-specific, ephemeral)
* `scopus.xml` (alert-specific, ephemeral)

When all the files are uploaded, the user can press "Process..." to execute the scripts. After a short while, he or she obtains the tty-output (stdout and, seperately, stderr) of the scripts, and is prompted for a filename (defaulting to `scopus.zip`). The user can then press "Retrieve file" to obtain the ZIPped up output directory (containing the XML and PDF files) and have his or her session ended.

Note: If a concurrent request is performed, the new user is blocked in order to avoid overwriting of the files that need processing. After a certain amount of time the original user makes no request to the server (currently five minutes), the new user has the possibility to press "Reset server" in order to make his or her own session active (the original user is subsequently denied access).

<br/><br/><br/>
> _This document is Copyright &copy; 2017 by Harald von Waldow (Eawag), d-r-p (Lib4RI) and licensed under [CC&nbsp;BY&nbsp;4.0](https://creativecommons.org/licenses/by/4.0/)._