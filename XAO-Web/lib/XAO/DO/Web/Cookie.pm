=head1 NAME

XAO::DO::Web::Cookie - cookies manipulations

=head1 SYNOPSIS

 Hello, <%Cookie/html name="customername"%>

 <%Cookie name="customername" value={<%CgiParam/f param="cname"%>}"%>

=head1 DESCRIPTION

Displays or sets a cookie. Arguments are:

  name => cookie name
  value => cookie value; nothing is displayed if value is given
  default => what to display if there is no cookie set, nothing by default
  expires => when to expire the cookie (same as in CGI->cookie)
  path => cookie visibility path (same as in CGI->cookie)
  domain => cookie domain (same as in CGI->cookie)
  secure => cookie secure flag (same as in CGI->cookie)

=cut

###############################################################################
package XAO::DO::Web::Cookie;
use strict;
use XAO::Utils;
use base XAO::Objects->load(objname => 'Web::Page');

use vars qw($VERSION);
($VERSION)=(q$Id: Cookie.pm,v 1.3 2002/01/04 02:13:23 am Exp $ =~ /(\d+\.\d+)/);

sub display ($;%) {
    my $self=shift;
    my $args=get_args(\@_);
    my $cgi=$self->{siteconfig}->cgi;
    my $name=$args->{name};
    defined($name) || throw Symphero::Errors::Page ref($self)."::display - no name given";
    if(defined($args->{value})) {
        my $value=$args->{value};
        my $c=$cgi->cookie(-name => $name,
                           -value => $value,
                           -expires => $args->{expires},
                           -path => $args->{path},
                           -domain => $args->{domain},
                           -secure => $args->{secure});
        $self->{siteconfig}->add_cookie($c);
        return;
    }

    my $c=$cgi->cookie($name) || $args->{default} || '';

    $self->textout($c);
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
