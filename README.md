# mwlib - MediaWiki Parser and Utility Library

## Overview
**mwlib** is a versatile library designed for parsing MediaWiki articles and converting them to various output formats. A notable application of mwlib is in Wikipedia's "Print/export" feature, where it is used to create PDF documents from Wikipedia articles.

This fork of **mwlib** was created to manage the Clicklaw Wiki publishing system.

## Installation

### Docker

The docker version is easier to install and maintain. First, create a `.env` file with:

```
PUBLIC_HOSTNAME=127.0.0.1
PRODUCTION_HOSTNAME=whatever.com
DATA_IMPORT_USER=remote_docker_data_user
WIKI_NAME=Wikibooks
DB_SERVER=wiki-database
DB_NAME=wikidb
DB_USER=wikiuser
DB_PASSWORD=password
DB_ROOT_PASSWORD=password
SMTP_HOST=smtp.server.com
SMTP_PORT=587
SMTP_AUTH=true
SMTP_USER=admin@whatever.com
SMTP_PASS=password
```

The `PRODUCTION_HOSTNAME` and `DATA_IMPORT_USER` variables are used for copying live production data down to your docker during build. You will need to place SSH keys in `/mediawiki/keys/` and name them `id_docker_data` and `id_docker_data.pub`.

And then run:

    $ docker compose up --build

You can leave `--build` off in subsequent runs to maintain the existing installation.

To shut down, run:

    $ docker compose down


### Source Build

To build mwlib from source, ensure you have the following software installed:

- Python (version 3.8 or later)
- Ploticus
- re2c
- Perl
- Pillow / PyImage
- ImageMagick


Setup a virtual environment for Python 3.8 or later and activate it.

mwlib uses `pip-compile-multi <https://pip-compile-multi.readthedocs.io/en/latest/index.html>`_ to
manage dependencies. To install all dependencies, run the following commands:

    $ make install

To build mwlib, run the following commands:

    $ python setup.py build
    $ python setup.py install

Documentation

Please visit http://mwlib.readthedocs.org/en/latest/index.html for
detailed documentation.


## License

Copyright (c) 2007-2012 PediaPress GmbH

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above
  copyright notice, this list of conditions and the following
  disclaimer in the documentation and/or other materials provided
  with the distribution. 

* Neither the name of PediaPress GmbH nor the names of its
  contributors may be used to endorse or promote products derived
  from this software without specific prior written permission. 

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

.. _SpamBayes: http://spambayes.sourceforge.net/
