=head1 NAME

XAO::DO::Web::Footer - simple HTML footer

=head1 SYNOPSIS

Currently is only useful in XAO::Web site context.

=head1 DESCRIPTION

Displays "/bits/page-footer" template (can be overriden with "path"
argument) giving it the following arguments:

=over

=item VERSION

Current XAO::Web package version.

=item COPYRIGHT

Copyright information for XAO::Web.

=back

In most cases you would want to extend or override this object or at
least its default template with something site specific.

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
package XAO::DO::Web::Footer;
use strict;
use XAO::Web;
use XAO::Utils;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Web::Page');

use vars qw($VERSION);
($VERSION)=(q$Id: Footer.pm,v 1.3 2002/01/04 02:13:23 am Exp $ =~ /(\d+\.\d+)/);

sub display ($;%) {
    my $self=shift;
    my $args=get_args(\@_);

    my %a=(
        path => '/bits/page-footer',
        VERSION => $XAO::Web::VERSION,
        COPYRIGHT => 'Copyright (C) 2000,2001 XAO, Inc.'
    );

    $self->SUPER::display($self->merge_args(oldargs => \%a,
                                            newargs => $args));
}

###############################################################################
1;
