###############################################################################
package XAO::DO::Data::Index;
use strict;
use XAO::Utils;
use XAO::Objects;
use base XAO::Objects->load(objname => 'FS::Hash');
###############################################################################

sub indexer ($$) {
    my ($self,$object_name)=@_;

    $object_name||=$self->get('object_name');

    $object_name || throw $self "init - no 'object_name'";

    return XAO::Objects->new(objname => $object_name) ||
        throw $self "init - can't load object '$object_name'";
}

###############################################################################

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
