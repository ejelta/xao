=head1 NAME

XAO::IndexerSupport - utility functions for XAO::Indexer

=head1 SYNOPSIS

  use XAO::IndexerSupport;

=head1 DESCRIPTION

This is a very specific module used by XAO::Indexer internally.

=head1 METHODS

=over

=cut

###############################################################################
package XAO::IndexerSupport;
require 5.005;
use strict;
use XAO::Utils;

require DynaLoader;

use vars qw(@ISA $VERSION);

@ISA = qw(DynaLoader);

($VERSION)=(q$Id: IndexerSupport.pm,v 1.2 2004/02/29 20:02:18 am Exp $ =~ /(\d+\.\d+)/);

bootstrap XAO::IndexerSupport $VERSION;

###############################################################################

=item sorted_intersection

C-optimized variant of finding the intersection of multiple arrays
sorted in the same way (all being sub-sets of some master sorted
set). Used when finding multiple words search results.

=cut

sub sorted_intersection (@) {
    return [ ] if !@_;
    return $_[0] if @_==1;
    my @packed=map { pack('L*',@$_) } @_;
    my $res=sorted_intersection_do(\@packed);
    return [ unpack('L*',$res) ];
}

###############################################################################

=item sorted_intersection_perl

Pure-perl variant of finding the intersection of multiple arrays sorted
in the same way (all being sub-sets of some master sorted set). Used
when finding multiple words search results.

Not used except for benchmarking.

=cut

sub sorted_intersection_perl (@) {
    my ($base,@results)=sort { scalar(@$a) <=> scalar(@$b) } @_;

    if(!@results) {
        return $base;
    }

    my @cursors;
    my @final;
    BASE_ID:
    foreach my $id (@$base) {
        RESULT:
        for(my $i=0; $i<@results; $i++) {
            my $rdata=$results[$i];
            my $j=$cursors[$i] || 0;
            for(; $j<@$rdata; $j++) {
                if($id == $rdata->[$j]) {
                    $cursors[$i]=$j;
                    next RESULT;
                }
            }
            next BASE_ID;
        }
        push(@final,$id);
    }

    return \@final;
}

###############################################################################

=item template_sort_clear

Clears data from the internal index, but keeps the memory still
allocated. Useful if a different ordering of the same data is about to
be used.

This is called automatically in template_sort_prepare(), no need to call
it manually.

=cut

###############################################################################

=item template_sort_compare

Compares positions of two U32 arguments in the array
template_sort_prepare() was called on.

=cut

###############################################################################

=item template_sort_free

Frees memory occupied by the internal index.

=cut

###############################################################################

=item template_sort_position

For a given unsigned integer returns its position in the array
template_sort_prepare() was called on.

=cut

###############################################################################

=item template_sort_prepare

Gets a reference to an array of unsigned integers (U32) and prepares
internal index for later sorting of its subsets using this array as a
template.

The C routine underneath is optimised for the case of relatively
sequential distribution of integers in the array -- meaning that the
order can be anything, but they are not randomly distributed over the
entire U32 range, they form a couple of clusters instead. This is
usually the case with auto-increment database IDs.

Performance wise there is no difference, but it will take much more
memory if the distribution is random.

=cut

sub template_sort_prepare ($) {
    my $aref=shift;
    template_sort_prepare_do(pack('L*',@$aref));
}

###############################################################################

=item template_sort_print_tree

For debugging only -- prints the internal index representation to the
standard error.

=cut

###############################################################################

=item template_sort

Takes a reference to an array of integers -- a subset of array earlier
given to template_sort_prepare(). Returns a reference to an sorted
array.

Values that are not in the template array will be grouped in the end in
random order.

=cut

sub template_sort ($) {
    my $aref=shift;
    my $part=pack('L*',@$aref);
    template_sort_do($part);
    return [ unpack('L*',$part) ];
}

###############################################################################
1;
__END__

=back

=head1 AUTHOR

Andrew Maltsev
<am@xao.com>

=head1 SEE ALSO

L<XAO::Indexer>.

=cut
