=head1 NAME

XAO::DO::Data::Product - default dynamic data object for Data::Product

=head1 SYNOPSIS

None

=head1 DESCRIPTION

The Data::Product object is derived from XAO::FS::Hash and does not add
any new methods.

=cut

###############################################################################
package XAO::DO::Data::Product;
use strict;
use XAO::Objects;

use vars qw(@ISA);
@ISA=XAO::Objects->load(objname => 'FS::Hash');

###############################################################################
1;
__END__

=head1 AUTHOR

Copyright (c) 2001 XAO Inc.

The author is Andrew Maltsev <am@xao.com>
