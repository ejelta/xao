=head1 NAME

XAO::DO::Data::CatalogData - untranslated catalog data

=head1 DESCRIPTION

Contains a piece of original catalog that describes one product or one
category or holds extra data that do not belong to any category or
product.

Data::CatalogData is a Hash that has the following properties:

=over

=item type

One of `category', `product' or `extra'.

=item value

Arbitrary content up to 60000 characters long. Depends on the catalog.

=back

=cut

###############################################################################
package XAO::DO::Data::CatalogData;
use strict;
use XAO::Objects;
use base XAO::Objects->load(objname => 'FS::Hash');
###############################################################################
1;
__END__

=head1 AUTHORS

Copyright (c) 2001 XAO Inc.

Andrew Maltsev <am@xao.com>
