=head1 NAME

XAO::DO::Cache::Memory - memory storage back-end for XAO::Cache

=head1 SYNOPSIS

You should not use this object directly, it is a back-end for
XAO::Cache.

 if($backend->exists(\@c)) {
     return $backend->get(\@c);
 }

=head1 DESCRIPTION

Cache::Memory is the default implementation of XAO::Cache back-end. It
stores data in memory.

=head1 METHODS

=over

=cut

###############################################################################
package XAO::DO::Cache::Memory;
use strict;
use XAO::Utils;
use XAO::Objects;

use base XAO::Objects->load(objname => 'Atom');

use vars qw($VERSION);
($VERSION)=(q$Id: Memory.pm,v 1.1 2002/02/12 03:46:00 am Exp $ =~ /(\d+\.\d+)/);

###############################################################################

=item calculate_size ($)

Calculates size in bytes of the given reference.

=cut

sub calculate_size ($$) {
    return 0;
}

###############################################################################

=item exists (@)

Checks if an element exists in the cache. Does not update its access
time, but checks it. If the element should be expired it removes it from
the cache and returns false.

=cut

sub exists ($$) {
    my $self=shift;

    my $key=$self->make_key($_[0]);
    my $ed=$self->{data}->{$key};
    return '' unless $ed;
    if($ed->{access_time} + $self->{expire} <= time) {
        delete $self->{data}->{$key};
        return '';
    }
    
    return 1;
}

###############################################################################

=item get (\@)

Retrieves an element from the cache. Does not check if it is expired or
not, that is done in exists() method, but update access time.

=cut

sub get ($$) {
    my $self=shift;

    my $key=$self->make_key($_[0]);
    my $ed=$self->{data}->{$key} ||
        throw $self "get - no such element in the cache ($key), internal error";
    $ed->{access_time}=time;
    return $ed->{element};
}

###############################################################################

=item make_key (\@)

Makes a key from the given list of coordinates.

=cut

sub make_key ($$) {
    my $self=shift;
    return join("\001",@{$_[0]});
}

###############################################################################

=item put (\@\$)

Add a new element to the cache; before adding it checks cache size and
throws out elements to make space for the new element. Order of removal
depends on when an element was accessed last.

=cut

sub put ($$$) {
    my $self=shift;
    my $key=$self->make_key(shift);
    my $element=shift;

    my $data=$self->{data};
    my $size=$self->{size};
    my $nsz=0;
    if($size) {
        $nsz=$self->calculate_size($element);

        if($self->{current_size}+$nsz > $size) {

            my @list=sort {
                $data->{$a}->{access_time} <=> $data->{$b}->{access_time}
            } keys %$data;

            my $csz=$self->{current_size};
            for(my $i=0; $i!=@list && $csz+$nsz>$size; $i++) {
                my $k=$list[$i];
                $csz-=$data->{$k}->{size};
                delete $data->{$k};
            }
        }
    }

    my $ed={
        size        => $nsz,
        data        => $element,
        access_time => time,
    };

    $data->{$key}=$ed;

    undef;
}

###############################################################################

=item setup (%)

Sets expiration time and maximum cache size.

=cut

sub setup ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    $self->{data}={};
    $self->{current_size}=0;
    $self->{expire}=$args->{expire} || 60;
    $self->{size}=$args->{size} || 0;
}

###############################################################################
1;
__END__

=head1 AUTHORS

Copyright (c) 2002 XAO Inc.

Andrew Maltsev <am@xao.com>.

=head1 SEE ALSO

Have a look at:
L<XAO::DO::Cache::Memory>,
L<XAO::Objects>,
L<XAO::Base>,
L<XAO::FS>,
L<XAO::Web>.
