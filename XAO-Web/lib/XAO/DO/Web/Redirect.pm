=head1 NAME

XAO::DO::Web::Redirect - browser redirection object

=head1 SYNOPSIS

 <%Redirect url="/login.html"%>

=head1 DESCRIPTION

Redirector object. 
Can set cookies on the redirect.

=cut

###############################################################################
package XAO::DO::Web::Redirect;
use strict;
use XAO::Utils;
use base XAO::Objects->load(objname => 'Web::Page');

use vars qw($VERSION);
($VERSION)=(q$Id: Redirect.pm,v 1.3 2003/01/08 21:33:46 am Exp $ =~ /(\d+\.\d+)/);

###############################################################################

=pod

Arguments are:

 url => new url or short path.
 target => target frame (optional)

=cut

sub display {
    my $self=shift;
    my $args=get_args(\@_);
    my $config=$self->siteconfig;

    ##
    # Checking parameters.
    #
    if(! $args->{url}) {
        eprint "No URL or path in Redirect";
        return;
    }

    ##
    # Additional fields into standard header.
    #
    my %qa=( -Status => '302 Moved' );

    ##
    # Target window works only with Netscape, but we do not care here and
    # do our best.
    #
    if($args->{target}) {
        $qa{-Target}=$args->{target};
        dprint ref($self),"::display - 'target=$args->{target}' does not work with MSIE!";
    }

    ##
    # Getting redirection URL
    #
    my $url;
    if($args->{url} =~ /^\w+:\/\//) {
        $url=$args->{url};
    }
    else {
        $url=$self->base_url(active => 1);
        my $url_path=$args->{url};
        $url_path="/".$url_path unless substr($url_path,0,1) eq '/';
        $url.=$url_path;
    }

    ##
    # Redirecting
    #
    $qa{-Location}=$url;
    $config->header_args(\%qa);
    $self->finaltextout(<<EOT);
The document is moved <A HREF="$url">here</A>.
EOT
}

###############################################################################
1;
__END__

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2000-2003 XAO, Inc.

Andrew Maltsev <am@xao.com>.

=head1 SEE ALSO

Recommended reading:
L<XAO::Web>,
L<XAO::DO::Web::Page>.
