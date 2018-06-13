XAO Suite
=========

XAO Suite is a set of perl modules that includes a database wrapper, a
templating system, utilities, and derived modules.

See https://ejelta.com/xao/ for more details.

## Structure

This repository is a collection of sub-modules. These modules can and
should be installed individually. For a web project you would typically
want these:
    - https://github.com/amaltsev/XAO-Base  Project isolation and utilities
    - https://github.com/amaltsev/XAO-FS    Database layer
    - https://github.com/amaltsev/XAO-Web   Web routing and templating

Working, but not recommended:
    - https://github.com/amaltsev/XAO-ImageCache    Image scaling
    - https://github.com/amaltsev/XAO-MySQL         Direct MySQL driver (slower than DBD::mysql)
    - https://github.com/amaltsev/XAO-Indexer       Text search index
    - https://github.com/amaltsev/XAO-PodView       Perl POD viewer

Obsolete:
    - https://github.com/amaltsev/XAO-Catalogs      Data mangling
    - https://github.com/amaltsev/XAO-Commerce      Ecommerce basic site
    - https://github.com/amaltsev/XAO-Content       Content management
    - https://github.com/amaltsev/XAO-Wiki          Wiki parser

### After download

To pull all modules run this after cloning or downloading this meta
package.

```
$ git submodule update --remote
```

## Installation

An easy way to pull most current modules is by using cpanm or Carton:

```
$ cat cpanfile
FIXME
$ cpanm --installdeps .
```
