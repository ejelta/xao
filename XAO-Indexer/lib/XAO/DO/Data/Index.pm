=head1 NAME

XAO::DO::Data::Index - XAO Indexer storable index object

=head1 DESCRIPTION

XAO::DO::Data::Index is based on XAO::FS Hash object and provides
wrapper methods for most useful XAO Indexer functions.

=head1 METHODS

=cut

###############################################################################
package XAO::DO::Data::Index;
use strict;
use XAO::Utils;
use XAO::Objects;
use base XAO::Objects->load(objname => 'FS::Hash');

###############################################################################

=item indexer (;$)

Returns corresponding indexer object. Optional argument is its XAO
object name; if missed it is taken from 'indexer_objname' property.

=cut

sub indexer ($$) {
    my ($self,$indexer_objname)=@_;

    $indexer_objname||=$self->get('indexer_objname');

    $indexer_objname || throw $self "init - no 'indexer_objname'";

    return XAO::Objects->new(objname => $indexer_objname) ||
        throw $self "init - can't load object '$indexer_objname'";
}

###############################################################################

=item build_structure ()

Creates initial structure in the object required for it to function
properly. Safe to call on already existing data. Will also check and
update orderings data fields as ............

XXX -- need to pre-wire certain number of index data fields as they all
use the same data object/table. Names like 'id_name' and 'idpos_name'
won't work, we need something like 'id_1', 'id_2' and so on and a way
to map these numbers to more meaningful strings/subroutines that will
actually perform sorting.

sub init ($) {
    my $self=shift;

    $self->indexer->init(
        index_object    => $self,
    );
}

###############################################################################

sub search_indexer ($$) {
    my ($self,$ordering,$str)=@_;

    return $self->indexer->search(
        index_object    => $self,
        search_string   => $str,
        ordering        => $ordering,
    );
}

###############################################################################

sub update ($) {
    my $self=shift;

    $self->indexer->update(
        index_object    => $self,
    );
}

###############################################################################
1;
__END__

=back

=head1 AUTHORS

Copyright (c) 2003 XAO Inc.

Andrew Maltsev <am@xao.com>.

=head1 SEE ALSO

Recommended reading:
L<XAO::Indexer>,
L<XAO::DO::Indexer::Base>,
L<XAO::FS>,
L<XAO::Web>.
