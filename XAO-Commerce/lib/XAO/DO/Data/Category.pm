=head1 NAME

XAO::DO::Data::Category - category description

=head1 DESCRIPTION

Category objects are stored in /Categories and have the following
properties:

=over

=item category_id

Internal category ID. Up to 30 characters.

=item description

Long category description, up to 2000 characters (optional).

=item image_url

Image URL, up to 200 characters (optional).

=item name

Category name, up to 40 characters.

=item parent_id

The id of upper level category. Empty or undefined if current category
is on top level.

=item thumbnail_url

Image thumbnail URL, up to 200 characters (optional).

=back

=cut

###############################################################################
package XAO::DO::Data::Category;
use strict;
use XAO::Objects;
use base XAO::Objects->load(objname => 'FS::Hash');
###############################################################################
1;
__END__

=head1 AUTHORS

Copyright (c) 2001-2002 XAO Inc.

Andrew Maltsev <am@xao.com>
