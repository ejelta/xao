=head1 NAME

XAO::DO::Data::Index - XAO Indexer storable index object

=head1 SYNOPSIS

 my $keywords=$cgi->param('keywords');
 my $cn_index=$odb->fetch('/Indexes/customer_names');
 my $sr=$cn_index->search_by_string('name',$keywords);

=head1 DESCRIPTION

XAO::DO::Data::Index is based on XAO::FS Hash object and provides
wrapper methods for most useful XAO Indexer functions.

=head1 METHODS

=over

=cut

###############################################################################
package XAO::DO::Data::Index;
use strict;
use XAO::Utils;
use XAO::Objects;
use XAO::Projects;
use base XAO::Objects->load(objname => 'FS::Hash');

###############################################################################

=item build_structure ()

If called without arguments creates initial structure in the object
required for it to function properly. Safe to call on already existing
data.

Will create a certain number data fields to be then used to store
specifically ordered object IDs according to get_orderings() method of
the corresponding indexer. The number is taken from site's configuration
'/indexer/max_orderings' parameter and defaults to 10.

Should be called from site config's build_structure() method in a way
similar to this:

 $odb->fetch('/Indexes')->get_new->build_structure;

Where '/Indexes' is a container objects with class 'Data::Index'. It
does not have to be named 'Indexes'.

=cut

sub build_structure ($@) {
    my $self=shift;

    if(@_) {
        my $args=get_args(\@_);
        $self->SUPER::build_structure($args);
    }
    else {
        $self->SUPER::build_structure($self->data_structure);
    }
}

###############################################################################

=item data_structure ($)

Returns data structure of Index data object, can be directly used in
build_structure() method. Number of fields to hold orderings depends on
site configuration's '/indexer/max_orderings' parameter and defaults to
10.

=cut

sub data_structure ($) {
    my ($self,$max_orderings)=shift;

    if(!$max_orderings) {
        my $config=XAO::Projects::get_current_project;
        $max_orderings=$config->get('/indexer/max_orderings') || 10;
    }

    return {
        Data => {
            type        => 'list',
            class       => 'Data::IndexData',
            key         => 'data_id',
            structure   => {
                count => {
                    type        => 'integer',
                    minvalue    => 0,
                },
                create_time => {
                    type        => 'integer',
                    minvalue    => 0,
                    index       => 1,
                },
                keyword => {
                    type        => 'text',
                    maxlength   => 50,
                    index       => 1,
                    unique      => 1,
                },
                map {
                    (   "id_$_" => {
                            type        => 'text',
                            maxlength   => 65000,
                        },
                        "idpos_$_" => {
                            type        => 'text',
                            maxlength   => 65000,
                        }
                    );
                } (1..$max_orderings),
            },
        },
        Ignore => {
            type        => 'list',
            class       => 'Data::IndexIgnore',
            key         => 'data_id',
            structure   => {
                count => {
                    type        => 'integer',
                    minvalue    => 0,
                },
                create_time => {
                    type        => 'integer',
                    minvalue    => 0,
                    index       => 1,
                },
                keyword => {
                    type        => 'text',
                    maxlength   => 50,
                    index       => 1,
                    unique      => 1,
                },
            },
        },
        indexer_objname => {
            type        => 'text',
            maxlength   => 100,
        },
    };
}

###############################################################################

=item indexer (;$)

Returns corresponding indexer object, its name taken from
'indexer_objname' property.

=cut

sub indexer ($$) {
    my ($self,$indexer_objname)=@_;

    $indexer_objname||=$self->get('indexer_objname');

    $indexer_objname || throw $self "init - no 'indexer_objname'";

    return XAO::Objects->new(objname => $indexer_objname) ||
        throw $self "init - can't load object '$indexer_objname'";
}

###############################################################################

=item search_by_string ($)

Most widely used method - parses string into keywords and performs a
search on them. Honors double quotes to mark words that have to be
together in a specific order.

Returns a reference to the list of collection IDs. IDs are not checked
against real collection. If index is not in sync with the content of the
actual data collection IDs of objects that don't exist any more can be
returned as well as irrelevant results.

Example:

 my $keywords=$cgi->param('keywords');
 my $cn_index=$odb->fetch('/Indexes/customer_names');
 my $sr=$cn_index->search_by_string('name',$keywords);

=cut

sub search_by_string ($$) {
    my ($self,$ordering,$str)=@_;

    return $self->indexer->search(
        index_object    => $self,
        search_string   => $str,
        ordering        => $ordering,
    );
}

###############################################################################

=item update ($)

Updates the index with the current data. Exactly what data it is based
on depends entirely on the corresponding indexer object.

The update usually takes significant time, there is no way to update
only a part of the index, the whole index and all orderings are updated
at once.

With drivers that support transactions the update is wrapped into a
transaction, so that index data is consistent while being updated.

=cut

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
