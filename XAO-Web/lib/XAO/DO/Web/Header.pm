=head1 NAME

XAO::DO::Web::Header - Simple HTML header

=head1 SYNOPSIS

Currently is only useful in XAO::Web site context.

=head1 DESCRIPTION

Simple HTML header object. Accepts the following arguments, modifies
them as appropriate and displays "/bits/page-header" template passing the
rest of arguments unmodified.

=over

=item title => 'Page title'

Passed as is.

=item description => 'Page description for search engines'

This is converted to
<META NAME="Description" CONTENT="Page..">.

=item keywords => 'Page keywords for search engines'

This is converted to
<META NAME="Keywords" CONTENT="Page keywords..">.

=item path => '/bits/alternative-template-path'

Header template path, default is "/bits/page-header".

=item type => 'text/csv'

Allows you to set page type to something different then default
"text/html". If you set type the template would not be displayed! If you
still need it - call Header again without "type" argument.

=back

Would pass the folowing arguments to the template:

=over

=item META

Keywords and description combined.

=item TITLE

The value of 'title' argument above.

=back

Example:

 <%Header title="Site Search" keywords="super, duper, hyper, commerce"%>

=head1 METHODS

No publicly available methods except overriden display().

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2000-2001 XAO, Inc.

Andrew Maltsev <am@xao.com>.

=head1 SEE ALSO

Recommended reading:
L<XAO::Web>,
L<XAO::DO::Web::Page>.

=cut

###############################################################################
package XAO::DO::Web::Header;
use strict;
use XAO::Utils;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Web::Page');

use vars qw($VERSION);
($VERSION)=(q$Id: Header.pm,v 1.6 2002/11/09 02:22:15 am Exp $ =~ /(\d+\.\d+)/);

###############################################################################
# Displaying HTML header.
#
sub display ($;%) {
    my $self=shift;
    my $args=get_args(\@_);

    if($args->{type}) {
        $self->siteconfig->header_args(-type => $args->{type});
        return;
    }

    if($args->{'http.name'}) {
        $self->siteconfig->header_args(
            $args->{'http.name'}    => $args->{'http.value'} || ''
        );
        return;
    }

    my $meta="";
    $meta.=qq(<META NAME="Keywords" CONTENT="$args->{keywords}">\n) if $args->{keywords};
    $meta.=qq(<META NAME="Description" CONTENT="$args->{description}">\n) if $args->{description};

    $self->SUPER::display(merge_refs($args, {
                            path        => $args->{path} || "/bits/page-header",
                            TITLE       => $args->{title} || "XAO::Web -- No Title",
                            GIVEN_TITLE => $args->{title} || '',
                            META        => $meta,
                         }));
}

###############################################################################
1;
