=head1 NAME

XAO::DO::Web::CgiParam - Retrieves parameter from CGI environment

=head1 SYNOPSIS

 <%CgiParam param="username" default="test"%>

=head1 DESCRIPTION

Displays CGI parameter. Arguments are:

 name => parameter name
 default => default text

=cut

###############################################################################
package XAO::DO::Web::CgiParam;
use strict;
use XAO::Utils;
use XAO::Errors qw(XAO::DO::Web::CgiParam);
use base XAO::Objects->load(objname => 'Web::Page');

use vars qw($VERSION);
($VERSION)=(q$Id: CgiParam.pm,v 1.2 2001/12/08 02:51:23 am Exp $ =~ /(\d+\.\d+)/);

sub display ($;%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $name=$args->{name} || $args->{param} ||
        throw XAO::E::DO::Web::CgiParam "display - no 'param' and no 'name' given";

    my $text;
    $text=$self->cgi->param($name);
    $text=$args->{default} unless defined $text;
    return unless defined $text;

    $self->textout($text);
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
