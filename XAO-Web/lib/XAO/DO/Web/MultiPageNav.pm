=head1 NAME

XAO::DO::Web::MultiPageNav - Multi page navigation display

=head1 SYNOPSYS

Currently is only useful in XAO::Web site context.

=head1 DESCRIPTION

The 'MultiPageNav' object is a part of some 'Search' object that
displays a header template, a search results template for each search
result, and a footer template. The header and footer templates
includes MultiPageNav object. There are three parameters available
for substitution: START_ITEM, ITEMS_PER_PAGE and TOTAL_ITEMS. These
parameters can be used to display subsequent links with the MultiPageNav
object

The parameters for the MultiPageNav object are defined as follows:

=over

=item start_item - Count of first item of current page

Note: count of first item of first page is 1

=item items_per_page 

Maximum number of items per page

=item total_items 

Total number of items

=item n_edge_pages

Maximum number of first few and last few numbered page links

=item n_adjacent_pages 

Maximum number of numbered page links immediately preceding and following current page

=item n_block_pages

Maximum number of numbered page links in blocks between 'edge' and 'adjacent' links

=item max_blocks

Maximum number of page link blocks (not including 'edge' and 'adjacent' links)

=item min_period

Minimum number of pages between blocks

=item previous_page.path

Path to template for displaying link to previous page

=item next_page.path

Path to template for displaying link to next page

=item current_page.path

Path to template for displaying (non)link to current page

=item numbered_page.path

Path to template for displaying link to numbered pages

=item spacer.path

Path to template for displaying spacer between numbered page links

=item path

Path to template for displaying all multi-page nav links

=back

The 'MultiPageNav' object performs all necessary calculations and
template substitutions (using xxx.path templates). The values for these
parameters so that a list of parameters is available to the 'path'
template. The values for this parameters correspond to the navigation
display content. Following is a listing of said parameters with a
description of thier values' display contents:

=over

=item PREVIOUS

Link to previous page

=item FIRSTFEW

Links to first few pages

=item PREVIOUS_BLOCKS

Blocks of links to pages between first few and previous adjacent pages
includingspacers

=item PREVIOUS_ADJACENT

Links to pages immediately preceding current page

=item CURRENT

(Non)link to current page

=item NEXT_ADJACENT

Links to pages immediately following current page

=item NEXT_BLOCKS

Blocks of links to pages between next adjacent and last few pages
including spacers

=item LASTFEW

Links to last few pages

=item NEXT

Link to next page

=back

The CGI parameters that are necessary for creating links in the
'xxx.path' templates are available via XAO::DO::Web::Utility object.
Also, the following parameters available to these templates:

=over

=item PAGE_START_ITEM

The count of the first item to appear on the page the link points to

=item PAGE_NUMBER

The page number the link points to

=item PAGE_TYPE

Type of page the link points to. Values can be PREVIOUS, FIRSTFEW,
PREVIOUS_BLOCKS, PREVIOUS_ADJACENT, CURRENT, NEXT_ADJACENT, NEXT_BLOCKS,
LASTFEW, NEXT
 
=back

=head1 EXAMPLE
 
This example shows how a header or footer template might use this object:

 <%MultiPageNav
   start_item="<%START_ITEM%>"
   items_per_page="<%ITEMS_PER_PAGE%>"
   total_items="<%TOTAL_ITEMS%>"
   n_adjacent_pages="2"
   n_edje_pages="3"
   n_block_pages="2"
   max_blocks="4"
   min_period="7"
   path="/bits/multi_page_nav/base"
   previous_page.path="/bits/multi_page_nav/prev"
   next_page.path="/bits/multi_page_nav/next"
   current_page.path="/bits/multi_page_nav/current"
   numbered_page.path="/bits/multi_page_nav/page"
   spacer.path="/bits/multi_page_nav/spacer"
 %>

File /bits/multi_page_nav/page contents:

<A HREF="/search.html?<%Utility
                mode="pass-cgi-params"
                params="*"
                except="start_item"
                result="query"
              %>&start_item=<%PAGE_START_ITEM%>"><%PAGE_NUMBER%></A>

File /bits/multi_page_nav/prev contents:

<A HREF="/search.html<%Utility
                mode="pass-cgi-params"
                params="*"
                except="start_item"
                result="query"
              %>&start_item=<%PAGE_START_ITEM%>">&lt;&lt;prev</A>

File /bits/multi_page_nav/spacer contents: ...

File /bits/multi_page_nav/current contents:

[<%PAGE_NUMBER%>]

File /bits/multi_page_nav/base contents:

<%PREVIOUS%> <%FIRSTFEW%> <%PREVIOUS_BLOCKS%> <%PREVIOUS_ADJACENT%> <%CURRENT%> <%NEXT_ADJACENT%> <%NEXT_BLOCKS%> <%NEXT_ADJACENT%> <%NEXT%>

If the value of START_ITEM, ITEMS_PER_PAGE and TOTAL_ITEMS are 250, 10
and 500 respactively text representation result of this example looks
like

<<prev 1 2 ... 11 12 ... 22 23 24 [25] 26 27 28 ... 38 39 ... 49 50 next>>

=head1 METHODS

No publicly available methods except overriden display()

=head1 EXPORTS

Nothing

=head1 AUTHOR

Copyright (c) 2001 XAO, Inc.

=head1 SEE ALSO

Recommended reading: 
L<XAO::Web>,
L<XAO::DO::Web::Page>,
L<XAO::DO::Web::CgiParam>,
L<XAO::DO::Web::Utility>.

=cut

package XAO::DO::Web::MultiPageNav;
use strict;
use XAO::Utils;
use XAO::Errors qw(XAO::DO::Web::MultiPageNav);
use base XAO::Objects->load(objname => 'Web::Page');

use vars qw($VERSION);
($VERSION)=(q$Id: MultiPageNav.pm,v 1.2 2001/12/14 01:29:54 am Exp $ =~ /(\d+\.\d+)/);

###############################################################################
# Displaying multi page navigation display
#
sub display ($;%) {
    my $self=shift;
    my $args=get_args(\@_);
    my $obj=$self->object;
    for (keys %$args){ $self->{$_} = $args->{$_}; }

    ##
    # Checking arguments
    #
    $self->{start_item} ||
        throw XAO::E::DO::Web::MultiPageNav "display - no 'start_item' given";
    $self->{items_per_page} ||
        throw XAO::E::DO::Web::MultiPageNav "display - no 'items_per_page' given";
    $self->{total_items} ||
        throw XAO::E::DO::Web::MultiPageNav "display - no 'total_items' given";
    $self->{n_edge_pages} ||
        throw XAO::E::DO::Web::MultiPageNav "display - no 'n_edge_pages' given";
    $self->{n_adjacent_pages} ||
        throw XAO::E::DO::Web::MultiPageNav "display - no 'n_adjacent_pages' given";
    $self->{n_block_pages} ||
        throw XAO::E::DO::Web::MultiPageNav "display - no 'n_block_pages' given";
    $self->{max_blocks} ||
        throw XAO::E::DO::Web::MultiPageNav "display - no 'max_blocks' given";
    $self->{min_period} ||
        throw XAO::E::DO::Web::MultiPageNav "display - no 'min_period' given";
    $self->{path} ||
        throw XAO::E::DO::Web::MultiPageNav "display - no 'path' template given";
    $args->{'previous_page.path'} ||
        throw XAO::E::DO::Web::MultiPageNav "display - no 'previous_page' template given";
    $self->{'next_page.path'} ||
        throw XAO::E::DO::Web::MultiPageNav "display - no 'next_page' template given";
    $self->{'current_page.path'} ||
        throw XAO::E::DO::Web::MultiPageNav "display - no  'current_page' template given";
    $self->{'numbered_page.path'} ||
        throw XAO::E::DO::Web::MultiPageNav "display - no 'numbered_page' template given";
    $self->{'spacer.path'} ||
        throw XAO::E::DO::Web::MultiPageNav "display - no 'spacer' template given";
    
    ##
    # Validating arguments
    #
    1 < $self->{start_item} &&
        $self->{start_item}<$self->{total_items} || 
        throw XAO::E::DO::Web::MultiPageNav "display - start_item value have to be more then 1 and" .
                                            " less then total_item value";
    

    ##
    # Calculating total page number and number of current page
    #
    $self->{total_pages}=int($self->{total_items}/$self->{items_per_page});
    $self->{total_pages}++ if $self->{total_items} % $self->{items_per_page};
    $self->{current_page}=int($self->{start_item}/$self->{items_per_page});
    $self->{current_page}++ if $self->{start_item} % $self->{items_per_page};
    $self->get_links();
    my $flag=0;
    my $x=0;
    my $counter=-1;
    for (qw(previous next firstfew lastfew previous_blocks next_blocks previous_adjacent next_adjacent)) { $self->{$_}='';}
    for     (@{$self->{links}}){
            $counter++;
            SWITCH: {
                    /^PREVIOUS$/ && do {
                            $x=($self->{current_page}==1)?1:$self->{current_page}-1;
                            $self->{previous}=$obj->expand(
                                            path => $self->{'previous_page.path'},
                                            PAGE_START_ITEM => (($x-1)*$self->{items_per_page}+1),
                                            PAGE_NUMBER => $x,
                                            PAGE_TYPE => $_);
                            last SWITCH;
                    };
                    /^FIRSTFEW$/ && do {
                            $self->{firstfew}.=$obj->expand( 
                                            path => $self->{'numbered_page.path'},
                                            PAGE_START_ITEM => (($counter-1)*$self->{items_per_page}+1),
                                            PAGE_NUMBER => $counter,
                                            PAGE_TYPE => $_);
                            $flag=1;
                            last SWITCH;
                    };
                    /^PREVIOUS_BLOCKS$/ && do {
                            $self->{previous_blocks}.=$obj->expand(
                                            path =>$self->{'numbered_page.path'},
                                            PAGE_START_ITEM => (($counter-1)*$self->{items_per_page}+1),
                                            PAGE_NUMBER => $counter,
                                            PAGE_TYPE => $_);
                            $flag=1; 
                            last SWITCH;
                    };
                    /^PREVIOUS_ADJACENT$/ && do {
                            $self->{previous_adjacent}.=$obj->expand(
                                            path =>$self->{'numbered_page.path'},
                                            PAGE_START_ITEM => (($counter-1)*$self->{items_per_page}+1),
                                            PAGE_NUMBER => $counter,
                                            PAGE_TYPE => $_);
                            last SWITCH;
                    };
                    /^CURRENT$/ && do {
                            $self->{current}=$obj->expand( 
                                            path => $self->{'current_page.path'},
                                            PAGE_START_ITEM => (($counter-1)*$self->{items_per_page}+1),
                                            PAGE_NUMBER => $counter,
                                            PAGE_TYPE => $_);
                            last SWITCH;
                    };
                    /^NEXT_ADJACENT$/ && do {
                            $self->{next_adjacent}.=$obj->expand(
                                            path =>$self->{'numbered_page.path'},
                                            PAGE_START_ITEM => (($counter-1)*$self->{items_per_page}+1),
                                            PAGE_NUMBER => $counter,
                                            PAGE_TYPE => $_);
                            $flag=2;
                            last SWITCH;
                    };
                    /^NEXT_BLOCKS$/ && do {
                            $self->{next_blocks}.=$obj->expand(
                                            path =>$self->{'numbered_page.path'},
                                            PAGE_START_ITEM => (($counter-1)*$self->{items_per_page}+1),
                                            PAGE_NUMBER => $counter,
                                            PAGE_TYPE => $_);
                            $flag=2;
                            last SWITCH;
                    };
                    /^LASTFEW$/ && do {
                            $self->{lastfew}.=$obj->expand( path => $self->{'numbered_page.path'},
                                            PAGE_START_ITEM => (($counter-1)*$self->{items_per_page}+1),
                                            PAGE_NUMBER => $counter,
                                            PAGE_TYPE => $_);
                            last SWITCH;
                    };
                    /^NEXT$/ && do {
                            $x=($self->{current_page}==$self->{total_pages})?$self->{total_pages}:$self->{current_page}+1;
                            $self->{'next'}=$obj->expand( path => $self->{'next_page.path'},
                                            PAGE_START_ITEM => (($x-1)*$self->{items_per_page}+1),
                                            PAGE_NUMBER => $x,
                                            PAGE_TYPE => $_ );
                            last SWITCH;
                    };
                    ##
                    # Default part (if $_ is undefined)
                    #
                    $self->{previous_blocks}.=$obj->expand(path => $args->{'spacer.path'}) if $flag==1;
                    $self->{next_blocks}.=$obj->expand(path => $args->{'spacer.path'}) if $flag==2;
                    $flag=0;
            }
    }
    
    $self->SUPER::display( path => $self->{path},
                                                                                             PREVIOUS => $self->{previous},
                                                                                             FIRSTFEW => $self->{firstfew},
                                                                                             PREVIOUS_BLOCKS => $self->{previous_blocks},
                                                                                             PREVIOUS_ADJACENT => $self->{previous_adjacent},
                                                                                             CURRENT => $self->{current},
                                                                                             NEXT_ADJACENT => $self->{next_adjacent},
                                                                                             NEXT_BLOCKS => $self->{next_blocks},
                                                                                             LASTFEW => $self->{lastfew},
                                                                                             NEXT => $self->{'next'} );
}

#############################################################################
# Method calculate model of navigation panel
# $self->{links} - array with size (total_pages+2) with types of links
#
sub get_links ($){
        my $self=shift;
        $self->{links}==\();
        $self->{links}[0]="PREVIOUS";
        $self->{links}[$self->{total_pages}+1]="NEXT";
        $self->{links}[$self->{current_page}]="CURRENT";
        for (1..$self->{n_edge_pages}){
                last if $_>$self->{current_page};
                $self->{links}[$_]||="FIRSTFEW";
        }
        for ((1+$self->{total_pages}-$self->{n_edge_pages})
                        ..$self->{total_pages}){
                next if $_<$self->{current};
                $self->{links}[$_]||="LASTFEW";
        }
        for (($self->{current_page}-$self->{n_adjacent_pages})
                        ..$self->{current_page}){
                next if $_<0;
                $self->{links}[$_]||="PREVIOUS_ADJACENT";
        }
        for ($self->{current_page}
                        ..($self->{current_page}+$self->{n_adjacent_pages})){
                last if $_>$self->{total_pages};
                $self->{links}[$_]||="NEXT_ADJACENT";
        }

        $self->get_blocks($self->{n_edge_pages},
                $self->{current_page}-$self->{n_adjacent_pages},"PREVIOUS_BLOCKS");

        $self->get_blocks($self->{current_page}+$self->{n_adjacent_pages}, 
                $self->{total_pages}-$self->{n_edge_pages},"NEXT_BLOCKS");
        
        return $self->{links};
}

#############################################################################
# Separating sequence of numbers to blocks
#
sub get_blocks($;@){
        my $self=shift;
        my ($start,$end,$type)=@_;
        return if ($end-$start<=1);
        my $q_intervals=int(($end-$start)/$self->{min_period});
        my $q_blocks=($q_intervals-1)>$self->{max_blocks}?$self->{max_blocks}:$q_intervals-1;
        $q_intervals || return;
  my $average_period=int(($end-$start-$q_blocks*$self->{n_block_pages})/($q_intervals));
        my ($min_bound,$max_bound);
        for my $x (1..$q_blocks){
                $min_bound=(($start+$average_period)+($x-1)*($average_period+$self->{n_block_pages}));
                $min_bound=$start+1 if $min_bound<=$start;
                $max_bound=$min_bound+$self->{n_block_pages}-1;
                $max_bound=$end-1 if $max_bound>=$end;
                for my $y ($min_bound..$max_bound){
                        $self->{links}[$y]||=$type;
                }
        }
}

###############################################################################
1;
