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

<%PREVIOUS%> <%FIRSTFEW%> <%PREVIOUS_BLOCKS%> <%PREVIOUS_ADJACENT%> <%CURRENT%> <%NEXT_ADJACENT%> <%NEXT_BLOCKS%> <%LASTFEW%> <%NEXT%>

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
($VERSION)=(q$Id: MultiPageNav.pm,v 1.3 2001/12/15 04:01:27 am Exp $ =~ /(\d+\.\d+)/);

###############################################################################
# Displaying multi page navigation display
#
sub display ($;%) {

    #dprint "\n\n***\n***\n"
    #     . "*** XAO::DO::Web::MultiPageNav::display() START\n"
    #     . "***\n***";

    my $self = shift;
    my $args = get_args(\@_);
    #dprint "    %% PASSED ARGS:";
    #for (sort keys %$args){ dprint "    %% * $_ = $args->{$_}"; }

    ##
    # Check numerical arguments
    #
    $args->{start_item}       = exists($args->{start_item})
                              ? int($args->{start_item})
                              : throw XAO::E::DO::Web::MultiPageNav
                                "display - no 'start_item' argument given";
    $args->{items_per_page}   = exists($args->{items_per_page})
                              ? int($args->{items_per_page})
                              : throw XAO::E::DO::Web::MultiPageNav
                                "display - no 'items_per_page' argument given";
    $args->{total_items}      = exists($args->{total_items})
                              ? int($args->{total_items})-1 # XXX start at one issue?
                              : throw XAO::E::DO::Web::MultiPageNav
                                "display - no 'total_items' argument given";
    $args->{n_edge_pages}     = exists($args->{n_edge_pages})
                              ? int($args->{n_edge_pages})
                              : throw XAO::E::DO::Web::MultiPageNav
                                "display - no 'n_edge_pages' argument given";
    $args->{n_adjacent_pages} = exists($args->{n_adjacent_pages})
                              ? int($args->{n_adjacent_pages})
                              : throw XAO::E::DO::Web::MultiPageNav
                                "display - no 'n_adjacent_pages' argument given";
    $args->{n_block_pages}    = exists($args->{n_block_pages})
                              ? int($args->{n_block_pages})
                              : throw XAO::E::DO::Web::MultiPageNav
                                "display - no 'n_block_pages' argument given";
    $args->{max_blocks}       = exists($args->{max_blocks})
                              ? int($args->{max_blocks})
                              : throw XAO::E::DO::Web::MultiPageNav
                                "display - no 'max_blocks' argument given";
    $args->{min_period}       = exists($args->{min_period})
                              ? int($args->{min_period})
                              : throw XAO::E::DO::Web::MultiPageNav
                                "display - no 'min_period' argument given";

    ##
    # Check template arguments
    #
    $args->{path}                 || throw XAO::E::DO::Web::MultiPageNav
                                     "display - no 'path' template argument given";
    $args->{'previous_page.path'} || throw XAO::E::DO::Web::MultiPageNav
                                     "display - no 'previous_page' template argument given";
    $args->{'next_page.path'}     || throw XAO::E::DO::Web::MultiPageNav
                                     "display - no 'next_page' template argument given";
    $args->{'current_page.path'}  || throw XAO::E::DO::Web::MultiPageNav
                                     "display - no  'current_page' template argument given";
    $args->{'numbered_page.path'} || throw XAO::E::DO::Web::MultiPageNav
                                     "display - no 'numbered_page' template argument given";
    $args->{'spacer.path'}        || throw XAO::E::DO::Web::MultiPageNav
                                     "display - no 'spacer' template argument given";
    
    ##
    # Validate arguments
    #
    $args->{start_item} = 1 unless $args->{start_item} > 0;
    #throw XAO::E::DO::Web::MultiPageNav "display - 'start_item' has to be greater than 1"
    #    if $args->{start_item} < 1;
    #throw XAO::E::DO::Web::MultiPageNav "display - 'start_item' has to less than 'total_items'"
    #    if $args->{start_item} >= $args->{total_items};
    
    ##
    # Calculate total page number and number of current page
    #
    $args->{total_pages}  = int($args->{total_items}/$args->{items_per_page});
    $args->{total_pages}++  if  $args->{total_items} % $args->{items_per_page};
    $args->{current_page} = int($args->{start_item}/$args->{items_per_page});
    $args->{current_page}++ if  $args->{start_item}  % $args->{items_per_page};
    #dprint "    %% NUMERICAL ARGS:";
    #for (sort keys %$args){ dprint "    %% # $_ = $args->{$_}" unless /path$/; }

    ##
    # Initialize for loop
    #
    my $spacer_type = '';
    my $count       = 0;
    my $obj         = $self->object;
    my $params      = {};
    for ('PREVIOUS',
         'NEXT',
         'FIRSTFEW',
         'LASTFEW',
         'PREVIOUS_BLOCKS',
         'NEXT_BLOCKS',
         'PREVIOUS_ADJACENT',
         'NEXT_ADJACENT',
        ) { $params->{$_} = '';}

    ##
    # Loop through pages
    #
    for ($self->get_page_types($args)) {

        my $pgstart = int(($count-1) * $args->{items_per_page} + 1);

        if (/^PREVIOUS$/) {
           $pgstart = $args->{current_page} <= 1 ? 1 : $args->{current_page}-1;
           $params->{PREVIOUS} = $obj->expand(
                                     path            => $args->{'previous_page.path'},
                                     PAGE_START_ITEM => (($pgstart-1)*$args->{items_per_page}+1),
                                     PAGE_NUMBER     => $pgstart,
                                     PAGE_TYPE       => $_,
                                 );
        }
        elsif (/^FIRSTFEW$/) {
            $params->{FIRSTFEW} .= $obj->expand( 
                                       path            => $args->{'numbered_page.path'},
                                       PAGE_START_ITEM => $pgstart,
                                       PAGE_NUMBER     => $count,
                                       PAGE_TYPE       => $_,
                                   );
            $spacer_type = 'prev';
        }
        elsif (/^PREVIOUS_BLOCKS$/) {
            $params->{PREVIOUS_BLOCKS} .= $obj->expand(
                                              path            => $args->{'numbered_page.path'},
                                              PAGE_START_ITEM => $pgstart,
                                              PAGE_NUMBER     => $count,
                                              PAGE_TYPE       => $_,
                                          );
            $spacer_type = 'prev'; 
        }
        elsif (/^PREVIOUS_ADJACENT$/) {
            $params->{PREVIOUS_ADJACENT} .= $obj->expand(
                                                path            =>$args->{'numbered_page.path'},
                                                PAGE_START_ITEM => $pgstart,
                                                PAGE_NUMBER     => $count,
                                                PAGE_TYPE       => $_,
                                            );
        }
        elsif (/^CURRENT$/) {
            $params->{CURRENT} = $obj->expand( 
                                     path            => $args->{'current_page.path'},
                                     PAGE_START_ITEM => $pgstart,
                                     PAGE_NUMBER     => $count,
                                     PAGE_TYPE       => $_,
                                 );
        }
        elsif (/^NEXT_ADJACENT$/) {
            $params->{NEXT_ADJACENT} .= $obj->expand(
                                            path            =>$args->{'numbered_page.path'},
                                            PAGE_START_ITEM => $pgstart,
                                            PAGE_NUMBER     => $count,
                                            PAGE_TYPE       => $_,
                                        );
            $spacer_type = 'next';
        }
        elsif (/^NEXT_BLOCKS$/) {
            $params->{NEXT_BLOCKS} .= $obj->expand(
                                          path            =>$args->{'numbered_page.path'},
                                          PAGE_START_ITEM => $pgstart,
                                          PAGE_NUMBER     => $count,
                                          PAGE_TYPE       => $_,
                                      );
            $spacer_type = 'next';
        }
        elsif (/^LASTFEW$/) {
            $params->{LASTFEW} .= $obj->expand(
                                      path            => $args->{'numbered_page.path'},
                                      PAGE_START_ITEM => $pgstart,
                                      PAGE_NUMBER     => $count,
                                      PAGE_TYPE       => $_,
                                  );
        }
        elsif (/^NEXT$/) {
            $pgstart = ($args->{current_page}==$args->{total_pages})
                     ? $args->{total_pages}
                     : $args->{current_page}+1;
            $params->{NEXT} = $obj->expand(
                                  path            => $args->{'next_page.path'},
                                  PAGE_START_ITEM => (($pgstart-1)*$args->{items_per_page}+1),
                                  PAGE_NUMBER     => $pgstart,
                                  PAGE_TYPE       => $_,
                              );
        }
        else {
            my $spacer_text = $obj->expand(path => $args->{'spacer.path'});
            if    ($spacer_type eq 'prev') { $params->{PREVIOUS_BLOCKS} .= $spacer_text; }
            elsif ($spacer_type eq 'next') { $params->{NEXT_BLOCKS}     .= $spacer_text; }
            $spacer_type = '';
        }
        $count++;
    }

    $params->{path} = $args->{path};
    $self->SUPER::display($params);

    #dprint "***\n***\n"
    #     . "*** XAO::DO::Web::Order::check_mode() STOP\n"
    #     . "***\n***";
}

#############################################################################
# Method calculate model of navigation panel
# returns array of size (total_pages+2) with types of links
#
sub get_page_types ($) {

    my $self = shift;
    my $args = get_args(\@_);
 
    # Always initialize!
    my $ra_pgtypes = [];
    foreach (0..$args->{total_pages}+1) { $ra_pgtypes->[$_] = ''; }
    my ($strt, $stop) = ({}, {});

    ##
    # Previous and Next pages
    #

    $ra_pgtypes->[0]                      = 'PREVIOUS';
    $ra_pgtypes->[$args->{total_pages}+1] = 'NEXT';

    $strt->{CURRENT}           = $stop->{CURRENT} = $args->{current_page};
    $strt->{PREVIOUS_ADJACENT} = $args->{current_page} - $args->{n_adjacent_pages};
    $strt->{PREVIOUS_ADJACENT} = 0 if $strt->{PREVIOUS_ADJACENT} < 0;
    $stop->{PREVIOUS_ADJACENT} = $args->{current_page};
    $strt->{NEXT_ADJACENT}     = $args->{current_page};
    $stop->{NEXT_ADJACENT}     = $args->{current_page} + $args->{n_adjacent_pages};
    $stop->{NEXT_ADJACENT}     = $args->{total_pages}
                                   if $stop->{NEXT_ADJACENT} > $args->{total_pages};
    $strt->{FIRSTFEW}          = 1;
    $stop->{FIRSTFEW}          = $args->{n_edge_pages} > $args->{current_page}
                               ? $args->{current_page} : $args->{n_edge_pages};
    $strt->{LASTFEW}           = 1 + $args->{total_pages} - $args->{n_edge_pages};
    $strt->{LASTFEW}           = $args->{current_page}
                                   if $strt->{LASTFEW} < $args->{current_page};
    $stop->{LASTFEW}           = $args->{total_pages};
    $strt->{PREVIOUS_BLOCKS}   = $args->{n_edge_pages};
    $stop->{PREVIOUS_BLOCKS}   = $args->{current_page} - $args->{n_adjacent_pages};
    $strt->{NEXT_BLOCKS}       = $args->{current_page} + $args->{n_adjacent_pages};
    $stop->{NEXT_BLOCKS}       = $args->{total_pages}  - $args->{n_edge_pages};

    if ($strt->{PREVIOUS_ADJACENT} - $stop->{FIRSTFEW} > $args->{min_period}) {
        for ($strt->{FIRSTFEW}..$stop->{FIRSTFEW}){
            $ra_pgtypes->[int($_)] = 'FIRSTFEW' unless $ra_pgtypes->[$_];
        }
    }
    $self->get_blocks(
        'PREVIOUS_BLOCKS',
        $ra_pgtypes,
        $strt->{PREVIOUS_BLOCKS},
        $stop->{PREVIOUS_BLOCKS},
        $args->{min_period},
        $args->{max_blocks},
        $args->{n_block_pages},
    );
    for ($strt->{PREVIOUS_ADJACENT}..$stop->{PREVIOUS_ADJACENT}){
        $ra_pgtypes->[int($_)] = 'PREVIOUS_ADJACENT' unless $ra_pgtypes->[$_];
    }
    $ra_pgtypes->[$args->{current_page}]  = 'CURRENT';
    for ($strt->{NEXT_ADJACENT}..$stop->{NEXT_ADJACENT}){
        $ra_pgtypes->[int($_)] = 'NEXT_ADJACENT' unless $ra_pgtypes->[$_];
    }
    $self->get_blocks(
        'NEXT_BLOCKS',
        $ra_pgtypes,
        $strt->{NEXT_BLOCKS},
        $stop->{NEXT_BLOCKS},
        $args->{min_period},
        $args->{max_blocks},
        $args->{n_block_pages},
    );
    if ($strt->{LASTFEW} - $stop->{NEXT_ADJACENT} > $args->{min_period}) {
        for ($strt->{LASTFEW}..$stop->{LASTFEW}){
            $ra_pgtypes->[int($_)] = 'LASTFEW' unless $ra_pgtypes->[$_];
        }
    }

    return @$ra_pgtypes;
}
#############################################################################
# Separating sequence of numbers to blocks
#
sub get_blocks() {

    my $self = shift;
    my ($type, $ra_pgtypes, $pg_strt, $pg_stop, $min_period, $max_blocks, $n_pages_show,) = @_;

    my $tot_pages = $pg_stop-$pg_strt;
    return if $tot_pages <= 1;
    my $n_blks   = int($tot_pages/$min_period) || return;
    $n_blks      = $n_blks > $max_blocks ? $max_blocks : $n_blks;
    my $period   = int($tot_pages/$n_blks) || 1;
    my $mid_page = int($tot_pages/2);
#dprint "\n\n";
#dprint "    ** tot_pages    = $tot_pages";
#dprint "    ** n_pages_show = $n_pages_show";
#dprint "    ** pg_strt      = $pg_strt";
#dprint "    ** pg_stop      = $pg_stop";
#dprint "    ** n_blks       = $n_blks";
#dprint "    ** period       = $period";
    my $min      = $pg_strt + $mid_page - int($n_blks/2);
    for my $blk (0..$n_blks-1) {
        last if $min >= $pg_stop;
#dprint "    ** blk $blk";
        my $max = $min + $n_pages_show;
        $max    = $pg_stop if $max > $pg_stop;
        $max--;
#dprint "       >> $min..$max:";
        for my $page ($min..$max){
#dprint "          %% $page = [$ra_pgtypes->[$page]] or [$type]";
            $ra_pgtypes->[$page] ||= $type;
        }
        $min += ($period+$n_pages_show);
    }
}
###############################################################################
1;
