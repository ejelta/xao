=head1 NAME

XAO::DO::FS::Collection - Collection class for XAO::FS

=head1 SYNOPSIS

 my $orders=$odb->collection(class => 'Data::Order');

 my $sr=$orders->search('placed_by', 'eq', 'user@host.name');

=head1 DESCRIPTION

Collection class is similar to List object in the sense that it contains
Hash objects joined by some criteria.

All Collection objects are read-only, you can use them to search for
data and to get data objects from them but not to store.

Methods are (alphabetically):

=over

=cut

###############################################################################
package XAO::DO::FS::Collection;
use strict;
use XAO::Utils;
use XAO::Objects;

use vars qw(@ISA);
@ISA=XAO::Objects->load(objname => 'FS::Glue');

###############################################################################

=item container_key ()

Makes no sense for Collection, will throw an error.

=cut

sub container_key () {
    my $self=shift;
    $self->throw("container_key() - makes no sense on Collection object");
}

###############################################################################

=item delete ($)

Makes no sense for Collection, will throw an error.

=cut

sub delete () {
    my $self=shift;
    $self->throw("delete() - makes no sense on Collection object");
}

###############################################################################

=item detach ()

Not implemented, but safe to use.

=cut

sub detach ($) {
}

###############################################################################

=item exists ($)

Checks if an object with the given name exists in the collection and
returns boolean value.

=cut

sub exists ($$) {
    my $self=shift;
    my $name=shift;
    $self->_collection_exists($name);
}

###############################################################################

=item get (@)

Retrieves a Hash object from the Collection using the given name.

As a convenience you can pass more then one object name to the get()
method to retrieve multiple Hash references at once.

If an object does not exist an error will be thrown, use exists() method
to check if you really need to.

=cut

sub get ($$) {
    my $self=shift;

    $self->throw("get - at least one ID required") unless @_;

    my @results=map {
        $_ || $self->throw("get - no object ID given");
        XAO::Objects->new(objname => $$self->{class_name},
                          glue => $self->_glue,
                          unique_id => $_,
                          key_name => $$self->{key_name},
                          list_base_name => $$self->{base_name},
                         );
    } @_;

    @_==1 ? $results[0] : @results;
}

###############################################################################

=item keys ()

Returns unsorted list of all keys for all objects stored in that list.

=cut

sub keys ($) {
    my $self=shift;

    @{$self->_collection_keys()};
}

###############################################################################

=item new (%)

You cannot use this method directly. Use collection() method on Glue to
get a collection reference. Example:

 my $orders=$odb->collection(class => 'Data::Order');

Currently the only supported type of collection is by class name, a
collection that joins together all Hashes of the same class.

=cut

sub new ($%) {
    my $class=shift;
    my $self=$class->SUPER::new(@_);

    my $args=get_args(\@_);
    $$self->{class_name}=$args->{class} || $args->{class_name};

    $self->_collection_setup();

    $self;
}

###############################################################################

=item objtype ()

For all Collection objects always return a string 'Collection'.

=cut

sub objtype ($) {
    'Collection';
}

###############################################################################

=item put ($;$)

Makes no sense on collections. Will throw an error.

=cut

sub put ($$;$) {
    my $self=shift;
    $self->throw("put - you can't store into collections");
}

###############################################################################

=item search (@)

Supports the same syntax as List's search() method. See
L<XAO::DO::FS::List> for reference.

=cut

sub search ($@) {
    my $self=shift;
    $self->_list_search(@_);
}

###############################################################################

=item values ()

Returns a list of all Hash objects in the list.

B<Note:> the order of values is the same as the order of keys returned
by keys() method. At least until you modify the object directly on
indirectly. It is not recommended to use values() method for the reason
of pure predictability.

=cut

# implemented in Glue.pm

###############################################################################

=item uri ($)

Makes no sense on collections, will throw an error.

=cut

sub uri () {
    my $self=shift;
    $self->throw("uri - makes no sense on collections");
}

###############################################################################
1;
__END__

=back

=head1 AUTHORS

Xao, Inc. (c) 2001. This module was developed by Andrew Maltsev
<am@xao.com> with the help and valuable comments from other team
members.

=head1 SEE ALSO

Further reading:
L<XAO::FS>,
L<XAO::DO::FS::Hash> (aka FS::Hash),
L<XAO::DO::FS::List> (aka FS::List).
L<XAO::DO::FS::Glue> (aka FS::Glue).

=cut
