package XAO::Base;
use strict;
require 5.006_000;
use XAO::BaseConfig;
use base qw(XAO::BaseConfig);

###############################################################################
1;
__END__

=head1 NAME

XAO::Base - Set of base classes for the XAO family of products

=head1 DESCRIPTION

XAO::Base is really a collection of some very basic modules that are
used throughout XAO suite. They include:

=over

=item XAO::Errors

Generator of error namespaces for use in error throwing catching.

=item XAO::Objects

Loader of dynamic objects, practically everything else in the XAO suite
depends on this module.

=item XAO::Projects

Registry of projects and context switcher. Mostly used in XAO::Web to
store site configurations and database handlers in mod_perl environment,
but is not limited to that.

=item XAO::SimpleHash

Probably the oldest object in the suite, represents interface to a hash
with some extended functionality like URI style references to hashes.

=item XAO::Utils

Variety of small exportable subroutines -- random key generation, text
utilities, debugging.

=item XAO::DO::Config

Base configuration object that allows to embed other configuration
objects into it.

=back

=head1 AUTHORS

XAO Inc., Copyright (C) 1997-2003
