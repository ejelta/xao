=head1 NAME

XAO::DO::Data::Order - default dynamic data object for Data::Order

=head1 SYNOPSIS

None

=head1 DESCRIPTION

The Data::Order object is derived from XAO::FS::Hash and does not add
any new methods.

=cut

###############################################################################
package XAO::DO::Data::Order;
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
