=head1 NAME

XAO::Objects::Page - core object of XAO::Web rendering system

=head1 SYNOPSIS

Currently is only useful in XAO::Web site context.

=head1 DESCRIPTION

This is the default default (sic!) page handler. It is called when there
is no template for the given path and there is no path-to-object mapping
defined for this path.

Feel free to override it per-site to make it do something more useful
then just displaying 404 error message.

=head1 METHODS

=over

=cut

###############################################################################
package XAO::DO::Web::Default;
use strict;
use XAO::Utils;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Web::Page');

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: Default.pm,v 2.1 2005/01/14 01:39:57 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################

=item display (%)

Takes only one argument - file path and displays
/bits/errors/file-not-found template providing that path as a FILEPATH
argument.

=cut

sub display ($%) {
    my $self=shift;
    my $args=get_args(\@_);
    my $config=$self->siteconfig;
    $config->header_args(-Status => '404 File not found');
    $self->SUPER::display(path => '/bits/errors/file-not-found',
                          FILEPATH => $args->{path} || '');
}

###############################################################################
1;
__END__

=over

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2005 Andrew Maltsev

Copyright (c) 2001-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Recommended reading:
L<XAO::Web>.
