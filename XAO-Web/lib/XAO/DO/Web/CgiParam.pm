=head1 NAME

XAO::DO::Web::CgiParam - Retrieves parameter from CGI environment

=head1 SYNOPSIS

 <%CgiParam param="username" default="test"%>

=head1 DESCRIPTION

Displays CGI parameter. Arguments are:

 param => parameter name
 default => default text

=cut

###############################################################################
package XAO::DO::Web::CgiParam;
use strict;
use XAO::Utils;
use base XAO::Objects->load(objname => 'Web::Page');

use vars qw($VERSION);
($VERSION)=(q$Id: CgiParam.pm,v 1.1 2001/12/07 22:00:13 am Exp $ =~ /(\d+\.\d+)/);

sub display ($;%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $text;
    $text=$self->{siteconfig}->cgi->param($args->{param});
    $text=$args->{default} unless defined $text;
    return unless defined $text;

    $self->textout(text => $text, objargs => $args);
}

###############################################################################
1;
__END__

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
